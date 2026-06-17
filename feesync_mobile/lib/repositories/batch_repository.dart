import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/batch.dart';

class BatchRepository {
  final SupabaseClient _client;
  static const _timeout = Duration(seconds: 10);

  BatchRepository(this._client);

  Future<List<Batch>> getBatches({
    String? search,
    BatchStatus? status,
    String? subject,
  }) async {
    try {
      final query = _client.from('batches').select();

      if (status != null) {
        query.eq('status', status.toString().split('.').last);
      }
      if (subject != null) {
        query.eq('subject', subject);
      }
      if (search != null && search.isNotEmpty) {
        query.ilike('name', '%$search%');
      }

      query.order('created_at', ascending: false);

      final response = await query.timeout(_timeout);
      return (response as List).map((json) => Batch.fromJson(json)).toList();
    } catch (e) {
      debugPrint('[BatchRepo][OFFLINE] getBatches failed: $e');
      rethrow;
    }
  }

  Future<Batch?> getBatchById(String id) async {
    try {
      final response = await _client
          .from('batches')
          .select()
          .eq('id', id)
          .single()
          .timeout(_timeout);
      return Batch.fromJson(response);
    } catch (e) {
      debugPrint('[BatchRepo][OFFLINE] getBatchById($id) failed: $e');
      rethrow;
    }
  }

  Future<List<Batch>> getStudentBatches(String studentId) async {
    try {
      final response = await _client
          .from('student_enrollments')
          .select('batches(*)')
          .eq('student_id', studentId)
          .eq('status', 'active')
          .timeout(_timeout);
      return (response as List)
          .map((json) => Batch.fromJson(json['batches']))
          .toList();
    } catch (e) {
      debugPrint(
          '[BatchRepo][OFFLINE] getStudentBatches($studentId) failed: $e');
      return [];
    }
  }

  Future<void> enrollStudentInBatch({
    required String studentId,
    required String batchId,
    required String accountId,
  }) async {
    try {
      await _client.from('student_enrollments').upsert({
        'account_id': accountId,
        'student_id': studentId,
        'batch_id': batchId,
        'status': 'active',
      }).timeout(_timeout);
    } catch (e) {
      debugPrint('[BatchRepo] enrollStudentInBatch failed: $e');
      rethrow;
    }
  }

  Future<void> unenrollStudentFromBatch(
      String studentId, String batchId) async {
    try {
      await _client
          .from('student_enrollments')
          .update({'status': 'dropped'})
          .eq('student_id', studentId)
          .eq('batch_id', batchId)
          .timeout(_timeout);
    } catch (e) {
      debugPrint('[BatchRepo] unenrollStudentFromBatch failed: $e');
      rethrow;
    }
  }

  Future<Batch> createBatch(Map<String, dynamic> data) async {
    try {
      final response = await _client
          .from('batches')
          .insert(data)
          .select()
          .single()
          .timeout(_timeout);
      return Batch.fromJson(response);
    } catch (e) {
      debugPrint('[BatchRepo] createBatch failed: $e');
      rethrow;
    }
  }

  Future<Batch> updateBatch(String id, Map<String, dynamic> data) async {
    try {
      final response = await _client
          .from('batches')
          .update(data)
          .eq('id', id)
          .select()
          .single()
          .timeout(_timeout);
      return Batch.fromJson(response);
    } catch (e) {
      debugPrint('[BatchRepo] updateBatch($id) failed: $e');
      rethrow;
    }
  }

  Future<void> deleteBatch(String id) async {
    try {
      debugPrint('[BatchRepo] deleteBatch($id) started');

      final existing = await _client
          .from('batches')
          .select('id')
          .eq('id', id)
          .maybeSingle()
          .timeout(_timeout);
      if (existing == null) {
        throw Exception('Batch not found.');
      }

      await _client
          .from('attendance')
          .delete()
          .eq('batch_id', id)
          .timeout(_timeout);
      await _client
          .from('student_enrollments')
          .delete()
          .eq('batch_id', id)
          .timeout(_timeout);
      await _client
          .from('students')
          .update({'batch_id': null})
          .eq('batch_id', id)
          .timeout(_timeout);
      await _client
          .from('batches')
          .delete()
          .eq('id', id)
          .timeout(_timeout);

      debugPrint('[BatchRepo] deleteBatch($id) completed');
    } catch (e) {
      debugPrint('[BatchRepo] deleteBatch($id) failed: $e');
      rethrow;
    }
  }
}
