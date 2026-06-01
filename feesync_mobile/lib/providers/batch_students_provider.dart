import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/student.dart';
import 'supabase_provider.dart';

final batchStudentsProvider = FutureProvider.family<List<StudentBalance>, String>((ref, batchId) async {
  final client = ref.watch(supabaseClientProvider);
  
  // Step 1: Get the list of student IDs belonging to this batch from student_enrollments.
  final enrollmentsResponse = await client
      .from('student_enrollments')
      .select('student_id')
      .eq('batch_id', batchId)
      .eq('status', 'active');
  
  final studentIds = (enrollmentsResponse as List).map((s) => s['student_id'] as String).toList();
  
  if (studentIds.isEmpty) return [];

  // Step 2: Fetch the full balance details for these specific students.
  final balancesResponse = await client
      .from('student_balances')
      .select()
      .filter('id', 'in', '(${studentIds.join(',')})')
      .order('last_name');
  
  return (balancesResponse as List).map((json) => StudentBalance.fromJson(json)).toList();
});
