import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/fee.dart';
import '../repositories/fee_repository.dart';
import 'supabase_provider.dart';

final feeRepositoryProvider = Provider<FeeRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return FeeRepository(client);
});

final feeCategoriesProvider = FutureProvider<List<FeeCategory>>((ref) async {
  final repository = ref.watch(feeRepositoryProvider);
  return repository.getFeeCategories();
});

final feeStructuresProvider = FutureProvider<List<FeeStructure>>((ref) async {
  final repository = ref.watch(feeRepositoryProvider);
  return repository.getFeeStructures();
});

final feeStructuresByClassProvider =
    FutureProvider.family<List<FeeStructure>, String>((ref, studentClass) async {
  final repository = ref.watch(feeRepositoryProvider);
  return repository.getFeeStructuresByClass(studentClass);
});

final studentDuesProvider = FutureProvider.family<List<Due>, String>((ref, studentId) async {
  final repository = ref.watch(feeRepositoryProvider);
  return repository.getDues(studentId: studentId, status: 'pending');
});

final studentAssignmentsProvider = FutureProvider.family<List<FeeAssignment>, String>((ref, studentId) async {
  final repository = ref.watch(feeRepositoryProvider);
  return repository.getFeeAssignments(studentId: studentId);
});

class FeeCategoryNotifier extends StateNotifier<AsyncValue<List<FeeCategory>>> {
  final FeeRepository _repository;

  FeeCategoryNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadCategories();
  }

  Future<void> loadCategories() async {
    state = const AsyncValue.loading();
    try {
      final categories = await _repository.getFeeCategories();
      state = AsyncValue.data(categories);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> createCategory(Map<String, dynamic> data) async {
    try {
      await _repository.createFeeCategory(data);
      await loadCategories();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateCategory(String id, Map<String, dynamic> data) async {
    try {
      await _repository.updateFeeCategory(id, data);
      await loadCategories();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteCategory(String id) async {
    try {
      await _repository.deleteFeeCategory(id);
      await loadCategories();
    } catch (e) {
      rethrow;
    }
  }
}

final feeCategoryNotifierProvider =
    StateNotifierProvider<FeeCategoryNotifier, AsyncValue<List<FeeCategory>>>((ref) {
  final repository = ref.watch(feeRepositoryProvider);
  return FeeCategoryNotifier(repository);
});

class FeeStructureNotifier extends StateNotifier<AsyncValue<List<FeeStructure>>> {
  final FeeRepository _repository;

  FeeStructureNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadStructures();
  }

  Future<void> loadStructures() async {
    state = const AsyncValue.loading();
    try {
      final structures = await _repository.getFeeStructures();
      state = AsyncValue.data(structures);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> createStructure(Map<String, dynamic> data) async {
    try {
      await _repository.createFeeStructure(data);
      await loadStructures();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateStructure(String id, Map<String, dynamic> data) async {
    try {
      await _repository.updateFeeStructure(id, data);
      await loadStructures();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteStructure(String id) async {
    try {
      await _repository.deleteFeeStructure(id);
      await loadStructures();
    } catch (e) {
      rethrow;
    }
  }
}

final feeStructureNotifierProvider =
    StateNotifierProvider<FeeStructureNotifier, AsyncValue<List<FeeStructure>>>((ref) {
  final repository = ref.watch(feeRepositoryProvider);
  return FeeStructureNotifier(repository);
});
