import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/payment.dart';
import '../repositories/payment_repository.dart';
import 'supabase_provider.dart';

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return PaymentRepository(client);
});

final recentPaymentsProvider = FutureProvider<List<Payment>>((ref) async {
  final repository = ref.watch(paymentRepositoryProvider);
  return repository.getRecentPayments(limit: 10);
});

final totalCollectionProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repository = ref.watch(paymentRepositoryProvider);
  return repository.getTotalCollection();
});

final todayCollectionProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repository = ref.watch(paymentRepositoryProvider);
  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);
  final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
  return repository.getTotalCollection(startDate: startOfDay, endDate: endOfDay);
});

final monthCollectionProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repository = ref.watch(paymentRepositoryProvider);
  final now = DateTime.now();
  final startOfMonth = DateTime(now.year, now.month, 1);
  final nextMonth = now.month == 12 ? DateTime(now.year + 1, 1, 1) : DateTime(now.year, now.month + 1, 1);
  final endOfMonth = nextMonth.subtract(const Duration(seconds: 1));
  return repository.getTotalCollection(startDate: startOfMonth, endDate: endOfMonth);
});

final allPaymentsProvider = FutureProvider<List<Payment>>((ref) async {
  final repository = ref.watch(paymentRepositoryProvider);
  return repository.getPayments();
});

final paymentSearchProvider = StateProvider<String>((ref) => '');
final paymentStatusFilterProvider = StateProvider<PaymentStatus?>((ref) => null);
final paymentMethodFilterProvider = StateProvider<PaymentMethod?>((ref) => null);

final filteredPaymentsProvider = Provider<AsyncValue<List<Payment>>>((ref) {
  final paymentsAsync = ref.watch(paymentNotifierProvider);
  final search = ref.watch(paymentSearchProvider).toLowerCase();
  final statusFilter = ref.watch(paymentStatusFilterProvider);
  final methodFilter = ref.watch(paymentMethodFilterProvider);

  return paymentsAsync.whenData((payments) {
    return payments.where((payment) {
      final matchesSearch = search.isEmpty ||
          (payment.student?.fullName.toLowerCase().contains(search) ?? false) ||
          (payment.receiptNumber?.toLowerCase().contains(search) ?? false) ||
          (payment.transactionId?.toLowerCase().contains(search) ?? false);
      
      final matchesStatus = statusFilter == null || payment.status == statusFilter;
      final matchesMethod = methodFilter == null || payment.paymentMethod == methodFilter;

      return matchesSearch && matchesStatus && matchesMethod;
    }).toList();
  });
});

class PaymentNotifier extends StateNotifier<AsyncValue<List<Payment>>> {
  final PaymentRepository _repository;

  PaymentNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadPayments();
  }

  Future<void> loadPayments() async {
    state = const AsyncValue.loading();
    try {
      final payments = await _repository.getPayments();
      state = AsyncValue.data(payments);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> createPayment(
    Map<String, dynamic> data,
    List<Map<String, dynamic>> feeAllocations,
  ) async {
    try {
      await _repository.createPayment(data, feeAllocations);
      await loadPayments();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updatePayment(String id, Map<String, dynamic> data) async {
    try {
      await _repository.updatePayment(id, data);
      await loadPayments();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deletePayment(String id) async {
    try {
      await _repository.deletePayment(id);
      await loadPayments();
    } catch (e) {
      rethrow;
    }
  }
}

final paymentNotifierProvider =
    StateNotifierProvider<PaymentNotifier, AsyncValue<List<Payment>>>((ref) {
  final repository = ref.watch(paymentRepositoryProvider);
  return PaymentNotifier(repository);
});
