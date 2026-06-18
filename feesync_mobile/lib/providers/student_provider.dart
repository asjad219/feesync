import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/student.dart';
import '../models/payment.dart';
import '../repositories/student_repository.dart';
import '../core/services/cache_service.dart';
import 'supabase_provider.dart';
import 'payment_provider.dart';
import 'sync_provider.dart';

// ── Repository provider ───────────────────────────────────────────────────────

final studentRepositoryProvider = Provider<StudentRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return StudentRepository(client);
});

// ── Search / filter state ─────────────────────────────────────────────────────

final studentSearchProvider = StateProvider<String>((ref) => '');
final studentClassFilterProvider = StateProvider<String?>((ref) => null);

// ── Account id helper ─────────────────────────────────────────────────────────

final _studentAccountIdProvider = Provider<String?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client.auth.currentUser?.id;
});

// ── StudentBalances Notifier ──────────────────────────────────────────────────

class StudentBalancesNotifier
    extends StateNotifier<AsyncValue<List<StudentBalance>>> {
  final StudentRepository _repo;
  final CacheService _cache;
  final String? _accountId;
  final Ref _ref;

  StudentBalancesNotifier(this._repo, this._cache, this._accountId, this._ref)
      : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    if (_accountId == null) return;
    // 1. Emit cached data immediately
    final cached = _cache.loadStudentBalances(_accountId);
    if (cached != null) {
      state = AsyncValue.data(cached);
      debugPrint('[Students] Loaded ${cached.length} balances from cache');
    }
    // 2. Fetch fresh data in background
    await loadStudents();
  }

  Future<void> loadStudents() async {
    if (_accountId == null) return;
    try {
      final balances = await _repo
          .getStudentBalances()
          .timeout(const Duration(seconds: 10));
      await _cache.saveStudentBalances(_accountId, balances);
      _ref.read(lastSyncTimesProvider.notifier).update(
            (s) => {...s, 'students': DateTime.now()},
          );
      state = AsyncValue.data(balances);
      debugPrint('[Students] Fetched ${balances.length} balances from network');
    } catch (e, st) {
      debugPrint('[Students][OFFLINE] getStudentBalances failed: $e');
      if (state is AsyncData) {
        _ref.read(offlineToastProvider.notifier).state = "You're offline. Showing saved data.";
      } else {
        state = AsyncValue.error(e, st);
      }
    }
  }
}

final studentBalancesProvider = StateNotifierProvider<StudentBalancesNotifier,
    AsyncValue<List<StudentBalance>>>((ref) {
  final repo = ref.watch(studentRepositoryProvider);
  final cache = ref.watch(cacheServiceProvider);
  final accountId = ref.watch(_studentAccountIdProvider);
  return StudentBalancesNotifier(repo, cache, accountId, ref);
});

// ── Students list (full Student objects) ──────────────────────────────────────

class StudentsNotifier extends StateNotifier<AsyncValue<List<Student>>> {
  final StudentRepository _repo;

  StudentsNotifier(this._repo) : super(const AsyncValue.loading()) {
    loadStudents();
  }

  Future<void> loadStudents() async {
    try {
      final students = await _repo
          .getStudents()
          .timeout(const Duration(seconds: 10));
      state = AsyncValue.data(students);
    } catch (e, st) {
      debugPrint('[Students][OFFLINE] getStudents failed: $e');
      if (state is! AsyncData) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  Future<void> createStudent(Map<String, dynamic> data) async {
    await _repo.createStudent(data);
    await loadStudents();
  }

  Future<void> updateStudent(String id, Map<String, dynamic> data) async {
    await _repo.updateStudent(id, data);
    await loadStudents();
  }

  Future<void> deleteStudent(String id) async {
    await _repo.deleteStudent(id);
    await loadStudents();
  }
}

final studentsProvider = FutureProvider<List<Student>>((ref) async {
  final repository = ref.watch(studentRepositoryProvider);
  return repository.getStudents().timeout(const Duration(seconds: 10));
});

final filteredStudentsProvider = FutureProvider<List<Student>>((ref) async {
  final repository = ref.watch(studentRepositoryProvider);
  final search = ref.watch(studentSearchProvider);
  final studentClass = ref.watch(studentClassFilterProvider);

  return repository
      .getStudents(
        search: search.isEmpty ? null : search,
        studentClass: studentClass,
      )
      .timeout(const Duration(seconds: 10));
});

final studentByIdProvider =
    FutureProvider.family<Student?, String>((ref, id) async {
  final repository = ref.watch(studentRepositoryProvider);
  try {
    return await repository
        .getStudentById(id)
        .timeout(const Duration(seconds: 10));
  } catch (e) {
    debugPrint('[Students][OFFLINE] getStudentById($id) failed: $e');
    return null;
  }
});

final studentBalanceByIdProvider =
    FutureProvider.family<StudentBalance?, String>((ref, id) async {
  final balancesAsync = ref.watch(studentBalancesProvider);
  final balances = balancesAsync.valueOrNull ?? [];
  try {
    return balances.firstWhere((b) => b.id == id);
  } catch (_) {
    return null;
  }
});

final studentPaymentsProvider =
    FutureProvider.family<List<Payment>, String>((ref, id) async {
  final repository = ref.watch(paymentRepositoryProvider);
  try {
    return await repository
        .getPayments(studentId: id)
        .timeout(const Duration(seconds: 10));
  } catch (e) {
    debugPrint('[Students][OFFLINE] getPayments for $id failed: $e');
    return [];
  }
});

class StudentNotifier extends StateNotifier<AsyncValue<List<Student>>> {
  final StudentRepository _repository;

  StudentNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadStudents();
  }

  Future<void> loadStudents() async {
    state = const AsyncValue.loading();
    try {
      final students = await _repository
          .getStudents()
          .timeout(const Duration(seconds: 10));
      state = AsyncValue.data(students);
    } catch (e, st) {
      debugPrint('[StudentNotifier][OFFLINE] loadStudents failed: $e');
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> createStudent(Map<String, dynamic> data) async {
    await _repository.createStudent(data);
    await loadStudents();
  }

  Future<void> updateStudent(String id, Map<String, dynamic> data) async {
    await _repository.updateStudent(id, data);
    await loadStudents();
  }

  Future<void> deleteStudent(String id) async {
    await _repository.deleteStudent(id);
    await loadStudents();
  }
}

final studentNotifierProvider =
    StateNotifierProvider<StudentNotifier, AsyncValue<List<Student>>>((ref) {
  final repository = ref.watch(studentRepositoryProvider);
  return StudentNotifier(repository);
});
