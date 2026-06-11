import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/payment.dart';

class PaymentRepository {
  final SupabaseClient _client;

  PaymentRepository(this._client);

  Future<List<Payment>> getPayments({
    String? studentId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    var query = _client
        .from('payments')
        .select('*, students(first_name, last_name, class, admission_number)');

    if (studentId != null) {
      query = query.eq('student_id', studentId);
    }
    if (startDate != null) {
      query = query.gte('payment_date', startDate.toIso8601String());
    }
    if (endDate != null) {
      query = query.lte('payment_date', endDate.toIso8601String());
    }

    final response = await query.order('payment_date', ascending: false);
    return (response as List).map((json) => Payment.fromJson(json)).toList();
  }

  Future<Payment> getPaymentById(String id) async {
    final response = await _client
        .from('payments')
        .select('*, students(first_name, last_name, class, admission_number)')
        .eq('id', id)
        .single();

    return Payment.fromJson(response);
  }

  Future<List<Payment>> getRecentPayments({int limit = 10}) async {
    final response = await _client
        .from('payments')
        .select('*, students(first_name, last_name, class, admission_number)')
        .eq('status', 'completed')
        .order('created_at', ascending: false)
        .limit(limit);

    return (response as List).map((json) => Payment.fromJson(json)).toList();
  }

  Future<Map<String, dynamic>> getTotalCollection({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    var query = _client
        .from('payments')
        .select('amount')
        .eq('status', 'completed');

    if (startDate != null) {
      query = query.gte('payment_date', startDate.toIso8601String());
    }
    if (endDate != null) {
      query = query.lte('payment_date', endDate.toIso8601String());
    }

    final response = await query;
    final data = response as List;

    final total = data.fold<double>(
      0,
      (sum, payment) => sum + double.parse(payment['amount'].toString()),
    );

    return {'total': total, 'count': data.length};
  }

  Future<Payment> createPayment(
    Map<String, dynamic> paymentData,
    List<Map<String, dynamic>> feeAllocations,
  ) async {
    final receiptNumber = 'RCP-${DateTime.now().millisecondsSinceEpoch}';

    final response = await _client
        .from('payments')
        .insert({
          ...paymentData,
          'receipt_number': receiptNumber,
        })
        .select()
        .single();

    final payment = Payment.fromJson(response);

    if (feeAllocations.isNotEmpty) {
      final records = feeAllocations.map((fa) {
        return {
          'payment_id': payment.id,
          'fee_structure_id': fa['fee_structure_id'],
          'due_id': fa['due_id'],
          'amount': fa['amount'],
        };
      }).toList();

      await _client.from('payment_records').insert(records);
    }

    return payment;
  }

  Future<Payment> updatePayment(String id, Map<String, dynamic> data) async {
    final response = await _client
        .from('payments')
        .update(data)
        .eq('id', id)
        .select()
        .single();

    return Payment.fromJson(response);
  }

  Future<void> deletePayment(String id) async {
    await _client.from('payments').delete().eq('id', id);
  }
}
