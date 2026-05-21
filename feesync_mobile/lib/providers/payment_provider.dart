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

final allPaymentsProvider = FutureProvider<List<Payment>>((ref) async {
  final repository = ref.watch(paymentRepositoryProvider);
  return repository.getPayments();
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
