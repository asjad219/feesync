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
    final query = _client.from('students').select();

    if (studentClass != null) {
      query.eq('class', studentClass);
    }
    if (section != null) {
      query.eq('section', section);
    }
    if (search != null && search.isNotEmpty) {
      query.or(
        'first_name.ilike.%$search%,last_name.ilike.%$search%,admission_number.ilike.%$search%',
      );
    }

    query.order('last_name');

    final response = await query;
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
    final response = await _client
        .from('student_balances')
        .select()
        .order('last_name');

    return (response as List).map((json) => StudentBalance.fromJson(json)).toList();
  }

  Future<Student> createStudent(Map<String, dynamic> data) async {
    final response = await _client
        .from('students')
        .insert(data)
        .select()
        .single();

    return Student.fromJson(response);
  }

  Future<Student> updateStudent(String id, Map<String, dynamic> data) async {
    final response = await _client
        .from('students')
        .update(data)
        .eq('id', id)
        .select()
        .single();

    return Student.fromJson(response);
  }

  Future<void> deleteStudent(String id) async {
    await _client.from('students').delete().eq('id', id);
  }
}
