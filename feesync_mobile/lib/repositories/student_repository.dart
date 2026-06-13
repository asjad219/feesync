import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/student.dart';

class StudentRepository {
  final SupabaseClient _client;

  StudentRepository(this._client);

  Future<List<Student>> getStudents({
    String? search,
    String? studentClass,
    String? section,
  }) async {
    var query = _client.from('students').select();

    if (studentClass != null) {
      query = query.eq('class', studentClass);
    }
    if (section != null) {
      query = query.eq('section', section);
    }
    if (search != null && search.isNotEmpty) {
      query = query.or(
        'first_name.ilike.%$search%,last_name.ilike.%$search%,admission_number.ilike.%$search%',
      );
    }

    final response = await query.order('last_name');
    return (response as List).map((json) => Student.fromJson(json)).toList();
  }

  Future<Student?> getStudentById(String id) async {
    final response = await _client
        .from('students')
        .select()
        .eq('id', id)
        .single();

    return Student.fromJson(response);
  }

  Future<List<StudentBalance>> getStudentBalances() async {
    final userId = _client.auth.currentUser?.id;
    var query = _client.from('student_balances').select();

    if (userId != null) {
      final userResponse = await _client
          .from('users')
          .select('account_id')
          .eq('id', userId)
          .maybeSingle();
      if (userResponse != null && userResponse['account_id'] != null) {
        query = query.eq('account_id', userResponse['account_id']);
      }
    }

    final response = await query.order('last_name');
    return (response as List).map((json) => StudentBalance.fromJson(json)).toList();
  }

  Future<Student> createStudent(Map<String, dynamic> data) async {
    try {
      final response = await _client
          .from('students')
          .insert(data)
          .select()
          .single();

      final student = Student.fromJson(response);

      // Sync with student_enrollments
      if (data['batch_id'] != null) {
        await _client.from('student_enrollments').upsert({
          'account_id': data['account_id'],
          'student_id': student.id,
          'batch_id': data['batch_id'],
          'status': 'active',
        });
      }

      return student;
    } on PostgrestException catch (e) {
      if (e.code == '23505' || e.message.contains('student_enrollments_student_id_batch_id_key')) {
        throw Exception('This student is already enrolled in the selected batch.');
      }
      rethrow;
    }
  }

  Future<Student> updateStudent(String id, Map<String, dynamic> data) async {
    try {
      // Fetch the student's current record to see the original batch_id
      final currentStudent = await _client
          .from('students')
          .select('batch_id')
          .eq('id', id)
          .single();
      final originalBatchId = currentStudent['batch_id'] as String?;
      final selectedBatchId = data['batch_id'] as String?;

      debugPrint('--- STUDENT UPDATE DEBUG START ---');
      debugPrint('Student ID: $id');
      debugPrint('Original Batch ID: $originalBatchId');
      debugPrint('Selected Batch ID: $selectedBatchId');

      final updates = Map<String, dynamic>.from(data);
      // Avoid overwriting admission_number on update to keep it stable
      updates.remove('admission_number');

      final response = await _client
          .from('students')
          .update(updates)
          .eq('id', id)
          .select()
          .single();

      final student = Student.fromJson(response);

      // Sync with student_enrollments if batch_id changed
      if (selectedBatchId != null && selectedBatchId != originalBatchId) {
        debugPrint('Batch changed from $originalBatchId to $selectedBatchId. Updating enrollments...');
        
        // Mark old enrollment as dropped (if originalBatchId exists)
        if (originalBatchId != null) {
          debugPrint('Updating old enrollment status to dropped for student_id: $id, batch_id: $originalBatchId');
          await _client
              .from('student_enrollments')
              .update({'status': 'dropped'})
              .eq('student_id', id)
              .eq('batch_id', originalBatchId);
        }

        // Check whether enrollment already exists for selectedBatchId
        final existingEnrollment = await _client
            .from('student_enrollments')
            .select()
            .eq('student_id', id)
            .eq('batch_id', selectedBatchId)
            .maybeSingle();

        debugPrint('Existing enrollment check result: ${existingEnrollment != null}');

        if (existingEnrollment != null) {
          final enrollmentId = existingEnrollment['id'];
          debugPrint('Enrollment ID: $enrollmentId');
          debugPrint('Attempting UPDATE on existing enrollment status to active...');
          await _client
              .from('student_enrollments')
              .update({'status': 'active'})
              .eq('id', enrollmentId);
        } else {
          debugPrint('Attempting INSERT of new active enrollment...');
          await _client.from('student_enrollments').insert({
            'account_id': data['account_id'],
            'student_id': id,
            'batch_id': selectedBatchId,
            'status': 'active',
          });
        }
      } else {
        debugPrint('Batch did not change or selectedBatchId is null. Skipping student_enrollments modification.');
      }

      debugPrint('--- STUDENT UPDATE DEBUG END ---');
      return student;
    } on PostgrestException catch (e) {
      debugPrint('PostgrestException in updateStudent: $e');
      if (e.code == '23505' || e.message.contains('student_enrollments_student_id_batch_id_key')) {
        throw Exception('This student is already enrolled in the selected batch.');
      }
      rethrow;
    } catch (e) {
      debugPrint('Exception in updateStudent: $e');
      rethrow;
    }
  }

  Future<void> deleteStudent(String id) async {
    await _client.from('students').delete().eq('id', id);
  }
}
