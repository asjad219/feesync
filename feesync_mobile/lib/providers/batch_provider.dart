import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/batch.dart';
import '../repositories/batch_repository.dart';
import 'supabase_provider.dart';

final batchRepositoryProvider = Provider<BatchRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return BatchRepository(client);
});

final batchSearchProvider = StateProvider<String>((ref) => '');
final batchStatusFilterProvider = StateProvider<BatchStatus?>((ref) => null);

final filteredBatchesProvider = FutureProvider<List<Batch>>((ref) async {
  final repository = ref.watch(batchRepositoryProvider);
  final search = ref.watch(batchSearchProvider);
  final status = ref.watch(batchStatusFilterProvider);

  return repository.getBatches(
    search: search.isEmpty ? null : search,
    status: status,
  );
});

final batchByIdProvider = FutureProvider.family<Batch?, String>((ref, id) async {
  final repository = ref.watch(batchRepositoryProvider);
  return repository.getBatchById(id);
});

final studentBatchesProvider = FutureProvider.family<List<Batch>, String>((ref, studentId) async {
  final repository = ref.watch(batchRepositoryProvider);
  return repository.getStudentBatches(studentId);
});

class BatchNotifier extends StateNotifier<AsyncValue<List<Batch>>> {
  final BatchRepository _repository;

  BatchNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadBatches();
  }

  Future<void> loadBatches() async {
    state = const AsyncValue.loading();
    try {
      final batches = await _repository.getBatches();
      state = AsyncValue.data(batches);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> createBatch(Map<String, dynamic> data) async {
    try {
      await _repository.createBatch(data);
      await loadBatches();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateBatch(String id, Map<String, dynamic> data) async {
    try {
      await _repository.updateBatch(id, data);
      await loadBatches();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteBatch(String id) async {
    try {
      await _repository.deleteBatch(id);
      await loadBatches();
    } catch (e) {
      rethrow;
    }
  }
}

final batchNotifierProvider =
    StateNotifierProvider<BatchNotifier, AsyncValue<List<Batch>>>((ref) {
  final repository = ref.watch(batchRepositoryProvider);
  return BatchNotifier(repository);
});
