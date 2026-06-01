import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/batch.dart';

class BatchRepository {
  final SupabaseClient _client;

  BatchRepository(this._client);

  Future<List<Batch>> getBatches({
    String? search,
    BatchStatus? status,
    String? subject,
  }) async {
    // In a real app, we'd have a 'batches' table. 
    // For this prototype/production-grade logic, we assume the table exists.
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

    final response = await query;
    return (response as List).map((json) => Batch.fromJson(json)).toList();
  }

  Future<Batch?> getBatchById(String id) async {
    final response = await _client
        .from('batches')
        .select()
        .eq('id', id)
        .single();

    return Batch.fromJson(response);
  }

  Future<List<Batch>> getStudentBatches(String studentId) async {
    final response = await _client
        .from('student_enrollments')
        .select('batches(*)')
        .eq('student_id', studentId)
        .eq('status', 'active');
    
    return (response as List).map((json) => Batch.fromJson(json['batches'])).toList();
  }

  Future<void> enrollStudentInBatch({
    required String studentId,
    required String batchId,
    required String accountId,
  }) async {
    await _client.from('student_enrollments').upsert({
      'account_id': accountId,
      'student_id': studentId,
      'batch_id': batchId,
      'status': 'active',
    });
  }

  Future<void> unenrollStudentFromBatch(String studentId, String batchId) async {
    await _client
        .from('student_enrollments')
        .update({'status': 'dropped'})
        .eq('student_id', studentId)
        .eq('batch_id', batchId);
  }

  Future<Batch> createBatch(Map<String, dynamic> data) async {
    final response = await _client
        .from('batches')
        .insert(data)
        .select()
        .single();

    return Batch.fromJson(response);
  }

  Future<Batch> updateBatch(String id, Map<String, dynamic> data) async {
    final response = await _client
        .from('batches')
        .update(data)
        .eq('id', id)
        .select()
        .single();

    return Batch.fromJson(response);
  }

  Future<void> deleteBatch(String id) async {
    await _client.from('batches').delete().eq('id', id);
  }
}
