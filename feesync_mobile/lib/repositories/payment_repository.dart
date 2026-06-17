import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/payment.dart';

class PaymentRepository {
  final SupabaseClient _client;
  static const _timeout = Duration(seconds: 10);

  PaymentRepository(this._client);

  Future<List<Payment>> getPayments({
    String? studentId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
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

      final response =
          await query.order('payment_date', ascending: false).timeout(_timeout);
      return (response as List).map((json) => Payment.fromJson(json)).toList();
    } catch (e) {
      debugPrint('[PaymentRepo][OFFLINE] getPayments failed: $e');
      rethrow;
    }
  }

  Future<Payment> getPaymentById(String id) async {
    try {
      final response = await _client
          .from('payments')
          .select('*, students(first_name, last_name, class, admission_number)')
          .eq('id', id)
          .single()
          .timeout(_timeout);
      return Payment.fromJson(response);
    } catch (e) {
      debugPrint('[PaymentRepo][OFFLINE] getPaymentById($id) failed: $e');
      rethrow;
    }
  }

  Future<List<Payment>> getRecentPayments({int limit = 10}) async {
    try {
      final response = await _client
          .from('payments')
          .select('*, students(first_name, last_name, class, admission_number)')
          .eq('status', 'completed')
          .order('created_at', ascending: false)
          .limit(limit)
          .timeout(_timeout);
      return (response as List).map((json) => Payment.fromJson(json)).toList();
    } catch (e) {
      debugPrint('[PaymentRepo][OFFLINE] getRecentPayments failed: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getTotalCollection({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
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

      final response = await query.timeout(_timeout);
      final data = response as List;

      final total = data.fold<double>(
        0,
        (sum, payment) => sum + double.parse(payment['amount'].toString()),
      );

      return {'total': total, 'count': data.length};
    } catch (e) {
      debugPrint('[PaymentRepo][OFFLINE] getTotalCollection failed: $e');
      rethrow;
    }
  }

  Future<Payment> createPayment(
    Map<String, dynamic> paymentData,
    List<Map<String, dynamic>> feeAllocations,
  ) async {
    try {
      final receiptNumber = 'RCP-${DateTime.now().millisecondsSinceEpoch}';

      final response = await _client
          .from('payments')
          .insert({
            ...paymentData,
            'receipt_number': receiptNumber,
          })
          .select()
          .single()
          .timeout(_timeout);

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

        await _client
            .from('payment_records')
            .insert(records)
            .timeout(_timeout);
      }

      return payment;
    } catch (e) {
      debugPrint('[PaymentRepo] createPayment failed: $e');
      rethrow;
    }
  }

  Future<Payment> updatePayment(String id, Map<String, dynamic> data) async {
    try {
      final response = await _client
          .from('payments')
          .update(data)
          .eq('id', id)
          .select()
          .single()
          .timeout(_timeout);
      return Payment.fromJson(response);
    } catch (e) {
      debugPrint('[PaymentRepo] updatePayment($id) failed: $e');
      rethrow;
    }
  }

  Future<void> deletePayment(String id) async {
    try {
      await _client
          .from('payments')
          .delete()
          .eq('id', id)
          .timeout(_timeout);
    } catch (e) {
      debugPrint('[PaymentRepo] deletePayment($id) failed: $e');
      rethrow;
    }
  }
}
