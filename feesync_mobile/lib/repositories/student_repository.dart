import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/student.dart';
import '../core/errors/app_exception.dart';

class StudentRepository {
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

  StudentRepository(this._client);

  Future<List<Student>> getStudents({
    String? search,
    String? studentClass,
    String? section,
  }) async {
    try {
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

      final response =
          await query.order('last_name').timeout(_timeout);
      return (response as List).map((json) => Student.fromJson(json)).toList();
    } catch (e) {
      debugPrint('[StudentRepo][OFFLINE] getStudents failed: $e');
      _handleException(e);
      rethrow;
    }
  }

  Future<Student?> getStudentById(String id) async {
    try {
      final response = await _client
          .from('students')
          .select()
          .eq('id', id)
          .single()
          .timeout(_timeout);
      return Student.fromJson(response);
    } catch (e) {
      debugPrint('[StudentRepo][OFFLINE] getStudentById($id) failed: $e');
      _handleException(e);
      rethrow;
    }
  }

  Future<List<StudentBalance>> getStudentBalances() async {
    try {
      final userId = _client.auth.currentUser?.id;
      var query = _client.from('student_balances').select();

      if (userId != null) {
        final userResponse = await _client
            .from('users')
            .select('account_id')
            .eq('id', userId)
            .maybeSingle()
            .timeout(_timeout);
        if (userResponse != null && userResponse['account_id'] != null) {
          query = query.eq('account_id', userResponse['account_id']);
        }
      }

      final response = await query.order('last_name').timeout(_timeout);
      return (response as List)
          .map((json) => StudentBalance.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('[StudentRepo][OFFLINE] getStudentBalances failed: $e');
      _handleException(e);
      rethrow;
    }
  }

  Future<Student> createStudent(Map<String, dynamic> data) async {
    try {
      final response = await _client
          .from('students')
          .insert(data)
          .select()
          .single()
          .timeout(_timeout);

      final student = Student.fromJson(response);

      if (data['batch_id'] != null) {
        await _client.from('student_enrollments').upsert({
          'account_id': data['account_id'],
          'student_id': student.id,
          'batch_id': data['batch_id'],
          'status': 'active',
        }).timeout(_timeout);
      }

      return student;
    } on PostgrestException catch (e) {
      if (e.code == '23505' ||
          e.message.contains('student_enrollments_student_id_batch_id_key')) {
        throw Exception(
            'This student is already enrolled in the selected batch.');
      }
      _handleException(e);
      rethrow;
    } catch (e) {
      _handleException(e);
      rethrow;
    }
  }

  Future<Student> updateStudent(String id, Map<String, dynamic> data) async {
    try {
      final currentStudent = await _client
          .from('students')
          .select('batch_id')
          .eq('id', id)
          .single()
          .timeout(_timeout);
      final originalBatchId = currentStudent['batch_id'] as String?;
      final selectedBatchId = data['batch_id'] as String?;

      debugPrint('[StudentRepo] Updating student $id');

      final updates = Map<String, dynamic>.from(data);
      updates.remove('admission_number');

      final response = await _client
          .from('students')
          .update(updates)
          .eq('id', id)
          .select()
          .single()
          .timeout(_timeout);

      final student = Student.fromJson(response);

      if (selectedBatchId != null && selectedBatchId != originalBatchId) {
        if (originalBatchId != null) {
          await _client
              .from('student_enrollments')
              .update({'status': 'dropped'})
              .eq('student_id', id)
              .eq('batch_id', originalBatchId)
              .timeout(_timeout);
        }

        final existingEnrollment = await _client
            .from('student_enrollments')
            .select()
            .eq('student_id', id)
            .eq('batch_id', selectedBatchId)
            .maybeSingle()
            .timeout(_timeout);

        if (existingEnrollment != null) {
          await _client
              .from('student_enrollments')
              .update({'status': 'active'})
              .eq('id', existingEnrollment['id'])
              .timeout(_timeout);
        } else {
          await _client.from('student_enrollments').insert({
            'account_id': data['account_id'],
            'student_id': id,
            'batch_id': selectedBatchId,
            'status': 'active',
          }).timeout(_timeout);
        }
      }

      return student;
    } on PostgrestException catch (e) {
      debugPrint('[StudentRepo] PostgrestException in updateStudent: $e');
      if (e.code == '23505' ||
          e.message.contains('student_enrollments_student_id_batch_id_key')) {
        throw Exception(
            'This student is already enrolled in the selected batch.');
      }
      _handleException(e);
      rethrow;
    } catch (e) {
      debugPrint('[StudentRepo] Exception in updateStudent: $e');
      _handleException(e);
      rethrow;
    }
  }

  Future<void> deleteStudent(String id) async {
    try {
      await _client
          .from('students')
          .delete()
          .eq('id', id)
          .timeout(_timeout);
    } catch (e) {
      debugPrint('[StudentRepo] deleteStudent($id) failed: $e');
      _handleException(e);
      rethrow;
    }
  }
}
