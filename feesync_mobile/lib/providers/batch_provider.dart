import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/batch.dart';
import '../repositories/batch_repository.dart';
import '../core/services/cache_service.dart';
import 'supabase_provider.dart';
import 'sync_provider.dart';

// ── Repository provider ───────────────────────────────────────────────────────

final batchRepositoryProvider = Provider<BatchRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return BatchRepository(client);
});

// ── Filter state ──────────────────────────────────────────────────────────────

final batchSearchProvider = StateProvider<String>((ref) => '');
final batchStatusFilterProvider = StateProvider<BatchStatus?>((ref) => null);

// ── Account id helper ─────────────────────────────────────────────────────────

final _batchAccountIdProvider = Provider<String?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client.auth.currentUser?.id;
});

// ── BatchNotifier ─────────────────────────────────────────────────────────────

class BatchNotifier extends StateNotifier<AsyncValue<List<Batch>>> {
  final BatchRepository _repository;
  final CacheService _cache;
  final String? _accountId;
  final Ref _ref;

  BatchNotifier(this._repository, this._cache, this._accountId, this._ref)
      : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    if (_accountId == null) return;
    // 1. Emit cached data immediately
    final cached = _cache.loadBatches(_accountId!);
    if (cached != null) {
      state = AsyncValue.data(cached);
      debugPrint('[Batches] Loaded ${cached.length} batches from cache');
    }
    await loadBatches();
  }

  Future<void> loadBatches() async {
    if (_accountId == null) return;
    try {
      final batches = await _repository
          .getBatches()
          .timeout(const Duration(seconds: 10));
      await _cache.saveBatches(_accountId!, batches);
      _ref.read(lastSyncTimesProvider.notifier).update(
            (s) => {...s, 'batches': DateTime.now()},
          );
      state = AsyncValue.data(batches);
      debugPrint('[Batches] Fetched ${batches.length} batches from network');
    } catch (e, st) {
      debugPrint('[Batches][OFFLINE] loadBatches failed: $e');
      if (state is! AsyncData) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  Future<void> createBatch(Map<String, dynamic> data) async {
    await _repository.createBatch(data);
    await loadBatches();
  }

  Future<void> updateBatch(String id, Map<String, dynamic> data) async {
    await _repository.updateBatch(id, data);
    await loadBatches();
  }

  Future<void> deleteBatch(String id) async {
    await _repository.deleteBatch(id);
    await loadBatches();
  }
}

final batchNotifierProvider =
    StateNotifierProvider<BatchNotifier, AsyncValue<List<Batch>>>((ref) {
  final repository = ref.watch(batchRepositoryProvider);
  final cache = ref.watch(cacheServiceProvider);
  final accountId = ref.watch(_batchAccountIdProvider);
  return BatchNotifier(repository, cache, accountId, ref);
});

final filteredBatchesProvider = FutureProvider<List<Batch>>((ref) async {
  final repository = ref.watch(batchRepositoryProvider);
  final search = ref.watch(batchSearchProvider);
  final status = ref.watch(batchStatusFilterProvider);

  try {
    return await repository
        .getBatches(
          search: search.isEmpty ? null : search,
          status: status,
        )
        .timeout(const Duration(seconds: 10));
  } catch (e) {
    debugPrint('[Batches][OFFLINE] filteredBatchesProvider failed: $e');
    return [];
  }
});

final batchByIdProvider =
    FutureProvider.family<Batch?, String>((ref, id) async {
  final repository = ref.watch(batchRepositoryProvider);
  try {
    return await repository
        .getBatchById(id)
        .timeout(const Duration(seconds: 10));
  } catch (e) {
    debugPrint('[Batches][OFFLINE] getBatchById($id) failed: $e');
    // Try to find in cache
    final batches = ref.read(batchNotifierProvider).valueOrNull ?? [];
    try {
      return batches.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }
});

final studentBatchesProvider =
    FutureProvider.family<List<Batch>, String>((ref, studentId) async {
  final repository = ref.watch(batchRepositoryProvider);
  try {
    return await repository
        .getStudentBatches(studentId)
        .timeout(const Duration(seconds: 10));
  } catch (e) {
    debugPrint('[Batches][OFFLINE] getStudentBatches($studentId) failed: $e');
    return [];
  }
});
