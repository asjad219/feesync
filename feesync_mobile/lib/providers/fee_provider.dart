import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/fee.dart';
import '../repositories/fee_repository.dart';
import 'supabase_provider.dart';

// ── Repository provider ───────────────────────────────────────────────────────

final feeRepositoryProvider = Provider<FeeRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return FeeRepository(client);
});

// ── Simple FutureProviders (read-only, offline-safe) ─────────────────────────

final feeCategoriesProvider = FutureProvider<List<FeeCategory>>((ref) async {
  final repository = ref.watch(feeRepositoryProvider);
  try {
    return await repository
        .getFeeCategories()
        .timeout(const Duration(seconds: 10));
  } catch (e) {
    debugPrint('[Fees][OFFLINE] getFeeCategories failed: $e');
    return [];
  }
});

final feeStructuresProvider = FutureProvider<List<FeeStructure>>((ref) async {
  final repository = ref.watch(feeRepositoryProvider);
  try {
    return await repository
        .getFeeStructures()
        .timeout(const Duration(seconds: 10));
  } catch (e) {
    debugPrint('[Fees][OFFLINE] getFeeStructures failed: $e');
    return [];
  }
});

final feeStructuresByClassProvider =
    FutureProvider.family<List<FeeStructure>, String>((ref, studentClass) async {
  final repository = ref.watch(feeRepositoryProvider);
  try {
    return await repository
        .getFeeStructuresByClass(studentClass)
        .timeout(const Duration(seconds: 10));
  } catch (e) {
    debugPrint('[Fees][OFFLINE] getFeeStructuresByClass($studentClass) failed: $e');
    return [];
  }
});

final studentDuesProvider =
    FutureProvider.family<List<Due>, String>((ref, studentId) async {
  final repository = ref.watch(feeRepositoryProvider);
  try {
    return await repository
        .getDues(studentId: studentId, statuses: ['pending', 'partial', 'overdue'])
        .timeout(const Duration(seconds: 10));
  } catch (e) {
    debugPrint('[Fees][OFFLINE] getDues($studentId) failed: $e');
    return [];
  }
});

final studentAssignmentsProvider =
    FutureProvider.family<List<FeeAssignment>, String>((ref, studentId) async {
  final repository = ref.watch(feeRepositoryProvider);
  try {
    return await repository
        .getFeeAssignments(studentId: studentId)
        .timeout(const Duration(seconds: 10));
  } catch (e) {
    debugPrint('[Fees][OFFLINE] getFeeAssignments($studentId) failed: $e');
    return [];
  }
});

// ── Mutable notifiers ─────────────────────────────────────────────────────────

class FeeCategoryNotifier extends StateNotifier<AsyncValue<List<FeeCategory>>> {
  final FeeRepository _repository;

  FeeCategoryNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadCategories();
  }

  Future<void> loadCategories() async {
    try {
      final categories = await _repository
          .getFeeCategories()
          .timeout(const Duration(seconds: 10));
      state = AsyncValue.data(categories);
    } catch (e, st) {
      debugPrint('[Fees][OFFLINE] loadCategories failed: $e');
      if (state is! AsyncData) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  Future<void> createCategory(Map<String, dynamic> data) async {
    await _repository.createFeeCategory(data);
    await loadCategories();
  }

  Future<void> updateCategory(String id, Map<String, dynamic> data) async {
    await _repository.updateFeeCategory(id, data);
    await loadCategories();
  }

  Future<void> deleteCategory(String id) async {
    await _repository.deleteFeeCategory(id);
    await loadCategories();
  }
}

final feeCategoryNotifierProvider =
    StateNotifierProvider<FeeCategoryNotifier, AsyncValue<List<FeeCategory>>>(
        (ref) {
  final repository = ref.watch(feeRepositoryProvider);
  return FeeCategoryNotifier(repository);
});

class FeeStructureNotifier
    extends StateNotifier<AsyncValue<List<FeeStructure>>> {
  final FeeRepository _repository;

  FeeStructureNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadStructures();
  }

  Future<void> loadStructures() async {
    try {
      final structures = await _repository
          .getFeeStructures()
          .timeout(const Duration(seconds: 10));
      state = AsyncValue.data(structures);
    } catch (e, st) {
      debugPrint('[Fees][OFFLINE] loadStructures failed: $e');
      if (state is! AsyncData) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  Future<void> createStructure(Map<String, dynamic> data) async {
    await _repository.createFeeStructure(data);
    await loadStructures();
  }

  Future<void> updateStructure(String id, Map<String, dynamic> data) async {
    await _repository.updateFeeStructure(id, data);
    await loadStructures();
  }

  Future<void> deleteStructure(String id) async {
    await _repository.deleteFeeStructure(id);
    await loadStructures();
  }
}

final feeStructureNotifierProvider =
    StateNotifierProvider<FeeStructureNotifier, AsyncValue<List<FeeStructure>>>(
        (ref) {
  final repository = ref.watch(feeRepositoryProvider);
  return FeeStructureNotifier(repository);
});
