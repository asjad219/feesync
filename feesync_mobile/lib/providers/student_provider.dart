import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/student.dart';
import '../models/payment.dart';
import '../repositories/student_repository.dart';
import 'supabase_provider.dart';
import 'payment_provider.dart';

final studentRepositoryProvider = Provider<StudentRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return StudentRepository(client);
});

final studentsProvider = FutureProvider<List<Student>>((ref) async {
  final repository = ref.watch(studentRepositoryProvider);
  return repository.getStudents();
});

final studentBalancesProvider = FutureProvider<List<StudentBalance>>((ref) async {
  final repository = ref.watch(studentRepositoryProvider);
  return repository.getStudentBalances();
});

final studentSearchProvider = StateProvider<String>((ref) => '');
final studentClassFilterProvider = StateProvider<String?>((ref) => null);

final filteredStudentsProvider = FutureProvider<List<Student>>((ref) async {
  final repository = ref.watch(studentRepositoryProvider);
  final search = ref.watch(studentSearchProvider);
  final studentClass = ref.watch(studentClassFilterProvider);

  return repository.getStudents(
    search: search.isEmpty ? null : search,
    studentClass: studentClass,
  );
});

final studentByIdProvider = FutureProvider.family<Student?, String>((ref, id) async {
  final repository = ref.watch(studentRepositoryProvider);
  return repository.getStudentById(id);
});

final studentBalanceByIdProvider = FutureProvider.family<StudentBalance?, String>((ref, id) async {
  final repository = ref.watch(studentRepositoryProvider);
  final balances = await repository.getStudentBalances();
  try {
    return balances.firstWhere((b) => b.id == id);
  } catch (e) {
    return null;
  }
});

final studentPaymentsProvider = FutureProvider.family<List<Payment>, String>((ref, id) async {
  final repository = ref.watch(paymentRepositoryProvider);
  return repository.getPayments(studentId: id);
});

class StudentNotifier extends StateNotifier<AsyncValue<List<Student>>> {
  final StudentRepository _repository;

  StudentNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadStudents();
  }

  Future<void> loadStudents() async {
    state = const AsyncValue.loading();
    try {
      final students = await _repository.getStudents();
      state = AsyncValue.data(students);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> createStudent(Map<String, dynamic> data) async {
    try {
      await _repository.createStudent(data);
      await loadStudents();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateStudent(String id, Map<String, dynamic> data) async {
    try {
      await _repository.updateStudent(id, data);
      await loadStudents();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteStudent(String id) async {
    try {
      await _repository.deleteStudent(id);
      await loadStudents();
    } catch (e) {
      rethrow;
    }
  }
}

final studentNotifierProvider =
    StateNotifierProvider<StudentNotifier, AsyncValue<List<Student>>>((ref) {
  final repository = ref.watch(studentRepositoryProvider);
  return StudentNotifier(repository);
});
