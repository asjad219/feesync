import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/student.dart';
import 'supabase_provider.dart';
import 'sync_provider.dart';

final batchStudentsProvider = FutureProvider.family<List<StudentBalance>, String>((ref, batchId) async {
  final client = ref.watch(supabaseClientProvider);
  final cache = ref.watch(cacheServiceProvider);
  final accountId = client.auth.currentUser?.id;
  
  try {
    // Step 1: Get the list of student IDs belonging to this batch from student_enrollments.
    final enrollmentsResponse = await client
        .from('student_enrollments')
        .select('student_id')
        .eq('batch_id', batchId)
        .eq('status', 'active')
        .timeout(const Duration(seconds: 10));
    
    final studentIds = (enrollmentsResponse as List).map((s) => s['student_id'] as String).toList();
    
    if (studentIds.isEmpty) return [];

    // Step 2: Fetch the full balance details for these specific students.
    final balancesResponse = await client
        .from('student_balances')
        .select()
        .inFilter('id', studentIds)
        .order('last_name')
        .timeout(const Duration(seconds: 10));
    
    return (balancesResponse as List).map((json) => StudentBalance.fromJson(json)).toList();
  } catch (e) {
    debugPrint('[BatchStudents][OFFLINE] batchStudentsProvider failed: $e');
    if (accountId != null) {
      final cached = cache.loadStudentBalances(accountId);
      if (cached != null) {
        final filtered = cached.where((s) => s.batchId == batchId).toList();
        debugPrint('[BatchStudents][OFFLINE] Returning ${filtered.length} students from cached balances');
        return filtered;
      }
    }
    rethrow;
  }
});
