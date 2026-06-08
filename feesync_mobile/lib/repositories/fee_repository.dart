import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/fee.dart';

class FeeRepository {
  final SupabaseClient _client;

  FeeRepository(this._client);

  // Fee Categories
  Future<List<FeeCategory>> getFeeCategories() async {
    final response = await _client
        .from('fee_categories')
        .select()
        .order('name');

    return (response as List).map((json) => FeeCategory.fromJson(json)).toList();
  }

  Future<FeeCategory> createFeeCategory(Map<String, dynamic> data) async {
    final response = await _client
        .from('fee_categories')
        .insert(data)
        .select()
        .single();

    return FeeCategory.fromJson(response);
  }

  Future<FeeCategory> updateFeeCategory(String id, Map<String, dynamic> data) async {
    final response = await _client
        .from('fee_categories')
        .update(data)
        .eq('id', id)
        .select()
        .single();

    return FeeCategory.fromJson(response);
  }

  Future<void> deleteFeeCategory(String id) async {
    await _client.from('fee_categories').delete().eq('id', id);
  }

  // Fee Structures
  Future<List<FeeStructure>> getFeeStructures({
    String? categoryId,
    String? studentClass,
  }) async {
    var query = _client.from('fee_structures').select('*, fee_categories(name)');

    if (categoryId != null) {
      query = query.eq('category_id', categoryId);
    }
    if (studentClass != null) {
      query = query.eq('class', studentClass);
    }

    final response = await query.order('name');
    return (response as List).map((json) => FeeStructure.fromJson(json)).toList();
  }

  Future<List<FeeStructure>> getFeeStructuresByClass(String studentClass) async {
    final response = await _client
        .from('fee_structures')
        .select('*, fee_categories(name)')
        .eq('class', studentClass)
        .eq('is_active', true)
        .order('name');

    return (response as List).map((json) => FeeStructure.fromJson(json)).toList();
  }

  Future<FeeStructure> createFeeStructure(Map<String, dynamic> data) async {
    final response = await _client
        .from('fee_structures')
        .insert(data)
        .select()
        .single();

    return FeeStructure.fromJson(response);
  }

  Future<FeeStructure> updateFeeStructure(String id, Map<String, dynamic> data) async {
    final response = await _client
        .from('fee_structures')
        .update(data)
        .eq('id', id)
        .select()
        .single();

    return FeeStructure.fromJson(response);
  }

  Future<void> deleteFeeStructure(String id) async {
    await _client.from('fee_structures').delete().eq('id', id);
  }

  // Fee Assignments
  Future<List<FeeAssignment>> getFeeAssignments({String? studentId}) async {
    var query = _client.from('fee_assignments').select('*, fee_structures(*)');
    if (studentId != null) {
      query = query.eq('student_id', studentId);
    }
    final response = await query.order('created_at', ascending: false);
    return (response as List).map((json) => FeeAssignment.fromJson(json)).toList();
  }

  // Dues
  Future<List<Due>> getDues({
    String? studentId,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    var query = _client.from('dues').select('*, fee_structures(*)');
    if (studentId != null) {
      query = query.eq('student_id', studentId);
    }
    if (status != null) {
      query = query.eq('status', status);
    }
    if (startDate != null) {
      query = query.gte('due_date', startDate.toIso8601String());
    }
    if (endDate != null) {
      query = query.lte('due_date', endDate.toIso8601String());
    }
    final response = await query.order('due_date', ascending: true);
    return (response as List).map((json) => Due.fromJson(json)).toList();
  }
}
