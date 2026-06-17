import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/fee.dart';

class FeeRepository {
  final SupabaseClient _client;
  static const _timeout = Duration(seconds: 10);

  FeeRepository(this._client);

  // ── Fee Categories ──────────────────────────────────────────────────────────

  Future<List<FeeCategory>> getFeeCategories() async {
    try {
      final response = await _client
          .from('fee_categories')
          .select()
          .order('name')
          .timeout(_timeout);
      return (response as List)
          .map((json) => FeeCategory.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('[FeeRepo][OFFLINE] getFeeCategories failed: $e');
      rethrow;
    }
  }

  Future<FeeCategory> createFeeCategory(Map<String, dynamic> data) async {
    try {
      final response = await _client
          .from('fee_categories')
          .insert(data)
          .select()
          .single()
          .timeout(_timeout);
      return FeeCategory.fromJson(response);
    } catch (e) {
      debugPrint('[FeeRepo] createFeeCategory failed: $e');
      rethrow;
    }
  }

  Future<FeeCategory> updateFeeCategory(
      String id, Map<String, dynamic> data) async {
    try {
      final response = await _client
          .from('fee_categories')
          .update(data)
          .eq('id', id)
          .select()
          .single()
          .timeout(_timeout);
      return FeeCategory.fromJson(response);
    } catch (e) {
      debugPrint('[FeeRepo] updateFeeCategory($id) failed: $e');
      rethrow;
    }
  }

  Future<void> deleteFeeCategory(String id) async {
    try {
      await _client
          .from('fee_categories')
          .delete()
          .eq('id', id)
          .timeout(_timeout);
    } catch (e) {
      debugPrint('[FeeRepo] deleteFeeCategory($id) failed: $e');
      rethrow;
    }
  }

  // ── Fee Structures ──────────────────────────────────────────────────────────

  Future<List<FeeStructure>> getFeeStructures({
    String? categoryId,
    String? studentClass,
  }) async {
    try {
      var query =
          _client.from('fee_structures').select('*, fee_categories(name)');

      if (categoryId != null) {
        query = query.eq('category_id', categoryId);
      }
      if (studentClass != null) {
        query = query.eq('class', studentClass);
      }

      final response = await query.order('name').timeout(_timeout);
      return (response as List)
          .map((json) => FeeStructure.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('[FeeRepo][OFFLINE] getFeeStructures failed: $e');
      rethrow;
    }
  }

  Future<List<FeeStructure>> getFeeStructuresByClass(
      String studentClass) async {
    try {
      final response = await _client
          .from('fee_structures')
          .select('*, fee_categories(name)')
          .eq('class', studentClass)
          .eq('is_active', true)
          .order('name')
          .timeout(_timeout);
      return (response as List)
          .map((json) => FeeStructure.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint(
          '[FeeRepo][OFFLINE] getFeeStructuresByClass($studentClass) failed: $e');
      rethrow;
    }
  }

  Future<FeeStructure> createFeeStructure(Map<String, dynamic> data) async {
    try {
      final response = await _client
          .from('fee_structures')
          .insert(data)
          .select()
          .single()
          .timeout(_timeout);
      return FeeStructure.fromJson(response);
    } catch (e) {
      debugPrint('[FeeRepo] createFeeStructure failed: $e');
      rethrow;
    }
  }

  Future<FeeStructure> updateFeeStructure(
      String id, Map<String, dynamic> data) async {
    try {
      final response = await _client
          .from('fee_structures')
          .update(data)
          .eq('id', id)
          .select()
          .single()
          .timeout(_timeout);
      return FeeStructure.fromJson(response);
    } catch (e) {
      debugPrint('[FeeRepo] updateFeeStructure($id) failed: $e');
      rethrow;
    }
  }

  Future<void> deleteFeeStructure(String id) async {
    try {
      await _client
          .from('fee_structures')
          .delete()
          .eq('id', id)
          .timeout(_timeout);
    } catch (e) {
      debugPrint('[FeeRepo] deleteFeeStructure($id) failed: $e');
      rethrow;
    }
  }

  // ── Fee Assignments ─────────────────────────────────────────────────────────

  Future<List<FeeAssignment>> getFeeAssignments({String? studentId}) async {
    try {
      var query = _client.from('fee_assignments').select('*, fee_structures(*)');
      if (studentId != null) {
        query = query.eq('student_id', studentId);
      }
      final response =
          await query.order('created_at', ascending: false).timeout(_timeout);
      return (response as List)
          .map((json) => FeeAssignment.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('[FeeRepo][OFFLINE] getFeeAssignments failed: $e');
      rethrow;
    }
  }

  // ── Dues ────────────────────────────────────────────────────────────────────

  Future<List<Due>> getDues({
    String? studentId,
    String? status,
    List<String>? statuses,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = _client.from('dues').select('*, fee_structures(*)');
      if (studentId != null) {
        query = query.eq('student_id', studentId);
      }
      if (status != null) {
        query = query.eq('status', status);
      }
      if (statuses != null && statuses.isNotEmpty) {
        query = query.inFilter('status', statuses);
      }
      if (startDate != null) {
        query = query.gte('due_date', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('due_date', endDate.toIso8601String());
      }
      final response =
          await query.order('due_date', ascending: true).timeout(_timeout);
      return (response as List).map((json) => Due.fromJson(json)).toList();
    } catch (e) {
      debugPrint('[FeeRepo][OFFLINE] getDues failed: $e');
      rethrow;
    }
  }
}
