import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/payment.dart';
import '../core/errors/app_exception.dart';

class PaymentRepository {
  void _handleException(dynamic e) {
    if (e is SocketException || e.toString().contains('SocketException') || e.toString().contains('Failed host lookup')) {
      throw NetworkException(e.toString());
    }
    if (e is TimeoutException || e.toString().contains('TimeoutException')) {
      throw NetworkException('Request timed out');
    }
    if (e is PostgrestException) {
      throw DatabaseException(e.message, e.details?.toString());
    }
    if (e is AppException) throw e;
    throw UnknownException(e.toString());
  }
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
      _handleException(e);
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
      _handleException(e);
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
      _handleException(e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getTotalCollection({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      String? accountId;
      if (userId != null) {
        final userResponse = await _client
            .from('users')
            .select('account_id')
            .eq('id', userId)
            .maybeSingle()
            .timeout(_timeout);
        if (userResponse != null) {
          accountId = userResponse['account_id'];
        }
      }

      if (accountId != null) {
        final response = await _client.rpc('get_total_collection_amount', params: {
          'p_account_id': accountId,
          'p_start_date': startDate?.toIso8601String(),
          'p_end_date': endDate?.toIso8601String(),
        }).timeout(_timeout);

        if (response is List && response.isNotEmpty) {
          final map = response.first as Map;
          return {
            'total': (map['total'] as num?)?.toDouble() ?? 0.0,
            'count': (map['count'] as num?)?.toInt() ?? 0,
          };
        }
      }
      return {'total': 0.0, 'count': 0};
    } catch (e) {
      debugPrint('[PaymentRepo][OFFLINE] getTotalCollection failed: $e');
      _handleException(e);
      rethrow;
    }
  }

  Future<Payment> createPayment(
    Map<String, dynamic> paymentData,
    List<Map<String, dynamic>> feeAllocations,
  ) async {
    return createPaymentOnline(paymentData, feeAllocations, null);
  }

  Future<Payment> createPaymentOnline(
    Map<String, dynamic> paymentData,
    List<Map<String, dynamic>> feeAllocations,
    String? tempId,
  ) async {
    try {
      final receiptNumber = 'RCP-${DateTime.now().millisecondsSinceEpoch}';

      final insertData = {
        ...paymentData,
        'receipt_number': receiptNumber,
      };

      if (tempId != null) {
        insertData.remove('id'); // Ensure we don't send the tempId if Supabase generates it, or we can send it if UUIDs match Supabase format. Let's remove to be safe.
      }

      final response = await _client
          .from('payments')
          .insert(insertData)
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
      _handleException(e);
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
      _handleException(e);
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
      _handleException(e);
      rethrow;
    }
  }
}
