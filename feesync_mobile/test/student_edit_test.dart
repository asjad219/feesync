import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:feesync_mobile/repositories/student_repository.dart';

// --- MOCK BUILDERS AND CLIENT ---

class MockPostgrestTransformBuilder<T> extends Fake implements PostgrestTransformBuilder<T> {
  final Future<T> _future;
  MockPostgrestTransformBuilder(this._future);

  @override
  Future<R> then<R>(FutureOr<R> Function(T) onValue, {Function? onError}) {
    return _future.then(onValue, onError: onError);
  }
}

class MockPostgrestFilterBuilder<T> extends Fake implements PostgrestFilterBuilder<T> {
  final String table;
  final String operation;
  final List<String> logs;
  final Map<String, dynamic>? studentSelectResult;
  final Map<String, dynamic>? studentUpdateResult;
  final Map<String, dynamic>? enrollmentSelectResult;
  final bool throwDuplicateError;

  MockPostgrestFilterBuilder(
    this.table,
    this.operation,
    this.logs, {
    this.studentSelectResult,
    this.studentUpdateResult,
    this.enrollmentSelectResult,
    this.throwDuplicateError = false,
  });

  @override
  PostgrestFilterBuilder<T> eq(String column, Object value) {
    logs.add('$operation on $table where $column = $value');
    return this;
  }

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> select([String columns = '*']) {
    logs.add('select $columns on $table after filter');
    return MockPostgrestFilterBuilder<List<Map<String, dynamic>>>(
      table,
      'select-after-filter',
      logs,
      studentSelectResult: studentSelectResult,
      studentUpdateResult: studentUpdateResult,
      enrollmentSelectResult: enrollmentSelectResult,
      throwDuplicateError: throwDuplicateError,
    );
  }

  @override
  PostgrestTransformBuilder<Map<String, dynamic>> single() {
    if (table == 'students') {
      if (operation == 'select') {
        return MockPostgrestTransformBuilder<Map<String, dynamic>>(
          Future.value(studentSelectResult ?? {'batch_id': 'batch-old'}),
        );
      } else if (operation.startsWith('update') || operation.startsWith('select-after-filter')) {
        return MockPostgrestTransformBuilder<Map<String, dynamic>>(
          Future.value(studentUpdateResult ?? {
            'id': 'student-123',
            'account_id': 'account-456',
            'admission_number': '1001',
            'first_name': 'John',
            'last_name': 'Doe',
            'class': 'Batch Name',
            'batch_id': 'batch-new',
            'created_at': '2026-06-13T00:00:00Z',
            'updated_at': '2026-06-13T00:00:00Z',
          }),
        );
      }
    }
    return MockPostgrestTransformBuilder<Map<String, dynamic>>(Future.value({}));
  }

  @override
  PostgrestTransformBuilder<Map<String, dynamic>?> maybeSingle() {
    if (throwDuplicateError) {
      return MockPostgrestTransformBuilder<Map<String, dynamic>?>(
        Future.error(const PostgrestException(
          message: 'duplicate key value violates unique constraint "student_enrollments_student_id_batch_id_key"',
          code: '23505',
          details: 'Conflict',
        )),
      );
    }
    if (table == 'student_enrollments' && operation == 'select') {
      return MockPostgrestTransformBuilder<Map<String, dynamic>?>(
        Future.value(enrollmentSelectResult),
      );
    }
    return MockPostgrestTransformBuilder<Map<String, dynamic>?>(Future.value(null));
  }

  @override
  Future<R> then<R>(FutureOr<R> Function(T) onValue, {Function? onError}) {
    if (throwDuplicateError) {
      return Future<T>.error(const PostgrestException(
        message: 'duplicate key value violates unique constraint "student_enrollments_student_id_batch_id_key"',
        code: '23505',
        details: 'Conflict',
      )).then(onValue, onError: onError);
    }
    return Future.value(<Map<String, dynamic>>[] as T).then(onValue, onError: onError);
  }
}

class MockSupabaseQueryBuilder extends Fake implements SupabaseQueryBuilder {
  final String table;
  final List<String> logs;
  final Map<String, dynamic>? studentSelectResult;
  final Map<String, dynamic>? studentUpdateResult;
  final Map<String, dynamic>? enrollmentSelectResult;
  final bool throwDuplicateError;

  MockSupabaseQueryBuilder(
    this.table,
    this.logs, {
    this.studentSelectResult,
    this.studentUpdateResult,
    this.enrollmentSelectResult,
    this.throwDuplicateError = false,
  });

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> select([String columns = '*']) {
    logs.add('select $columns on $table');
    return MockPostgrestFilterBuilder<List<Map<String, dynamic>>>(
      table,
      'select',
      logs,
      studentSelectResult: studentSelectResult,
      studentUpdateResult: studentUpdateResult,
      enrollmentSelectResult: enrollmentSelectResult,
      throwDuplicateError: throwDuplicateError,
    );
  }

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> update(Map values) {
    logs.add('update $values on $table');
    return MockPostgrestFilterBuilder<List<Map<String, dynamic>>>(
      table,
      'update $values',
      logs,
      studentSelectResult: studentSelectResult,
      studentUpdateResult: studentUpdateResult,
      enrollmentSelectResult: enrollmentSelectResult,
      throwDuplicateError: throwDuplicateError,
    );
  }

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> insert(Object values, {bool defaultToNull = true}) {
    logs.add('insert $values on $table');
    return MockPostgrestFilterBuilder<List<Map<String, dynamic>>>(
      table,
      'insert $values',
      logs,
      studentSelectResult: studentSelectResult,
      studentUpdateResult: studentUpdateResult,
      enrollmentSelectResult: enrollmentSelectResult,
      throwDuplicateError: throwDuplicateError,
    );
  }
}

class MockSupabaseClient extends Fake implements SupabaseClient {
  final List<String> logs = [];
  Map<String, dynamic>? studentSelectResult;
  Map<String, dynamic>? studentUpdateResult;
  Map<String, dynamic>? enrollmentSelectResult;
  bool throwDuplicateError = false;

  @override
  SupabaseQueryBuilder from(String table) {
    return MockSupabaseQueryBuilder(
      table,
      logs,
      studentSelectResult: studentSelectResult,
      studentUpdateResult: studentUpdateResult,
      enrollmentSelectResult: enrollmentSelectResult,
      throwDuplicateError: throwDuplicateError,
    );
  }
}

// --- TEST CASES ---

void main() {
  group('Student Edit and Enrollment Workflow Tests', () {
    late MockSupabaseClient mockClient;
    late StudentRepository repository;

    setUp(() {
      mockClient = MockSupabaseClient();
      repository = StudentRepository(mockClient);
    });

    test('Case 1: Only student details changed (same batch_id)', () async {
      mockClient.studentSelectResult = {'batch_id': 'batch-1'};
      mockClient.studentUpdateResult = {
        'id': 'student-123',
        'account_id': 'account-456',
        'admission_number': '1001',
        'first_name': 'Jane',
        'last_name': 'Doe',
        'class': 'Batch 1',
        'batch_id': 'batch-1',
        'created_at': '2026-06-13T00:00:00Z',
        'updated_at': '2026-06-13T00:00:00Z',
      };

      final data = {
        'account_id': 'account-456',
        'first_name': 'Jane',
        'last_name': 'Doe',
        'admission_number': 'will-be-removed',
        'batch_id': 'batch-1',
      };

      final result = await repository.updateStudent('student-123', data);

      expect(result.firstName, equals('Jane'));
      expect(result.batchId, equals('batch-1'));

      final enrollmentLogs = mockClient.logs.where((log) => log.contains('student_enrollments'));
      expect(enrollmentLogs, isEmpty);

      final updateLog = mockClient.logs.firstWhere((log) => log.contains('update'));
      expect(updateLog, isNot(contains('admission_number')));
    });

    test('Case 2A: Batch changed, enrollment does not exist yet (insert new)', () async {
      mockClient.studentSelectResult = {'batch_id': 'batch-old'};
      mockClient.studentUpdateResult = {
        'id': 'student-123',
        'account_id': 'account-456',
        'admission_number': '1001',
        'first_name': 'John',
        'last_name': 'Doe',
        'class': 'Batch New',
        'batch_id': 'batch-new',
        'created_at': '2026-06-13T00:00:00Z',
        'updated_at': '2026-06-13T00:00:00Z',
      };
      mockClient.enrollmentSelectResult = null;

      final data = {
        'account_id': 'account-456',
        'first_name': 'John',
        'last_name': 'Doe',
        'batch_id': 'batch-new',
      };

      final result = await repository.updateStudent('student-123', data);
      expect(result.batchId, equals('batch-new'));

      expect(mockClient.logs, contains('update {status: dropped} on student_enrollments'));
      expect(mockClient.logs, contains('select * on student_enrollments'));
      expect(mockClient.logs, contains('insert {account_id: account-456, student_id: student-123, batch_id: batch-new, status: active} on student_enrollments'));
    });

    test('Case 2B: Batch changed, enrollment already exists (update existing to active)', () async {
      mockClient.studentSelectResult = {'batch_id': 'batch-old'};
      mockClient.studentUpdateResult = {
        'id': 'student-123',
        'account_id': 'account-456',
        'admission_number': '1001',
        'first_name': 'John',
        'last_name': 'Doe',
        'class': 'Batch New',
        'batch_id': 'batch-new',
        'created_at': '2026-06-13T00:00:00Z',
        'updated_at': '2026-06-13T00:00:00Z',
      };
      mockClient.enrollmentSelectResult = {
        'id': 'enrollment-789',
        'student_id': 'student-123',
        'batch_id': 'batch-new',
        'status': 'dropped',
      };

      final data = {
        'account_id': 'account-456',
        'first_name': 'John',
        'last_name': 'Doe',
        'batch_id': 'batch-new',
      };

      final result = await repository.updateStudent('student-123', data);
      expect(result.batchId, equals('batch-new'));

      expect(mockClient.logs, contains('update {status: dropped} on student_enrollments'));
      expect(mockClient.logs, contains('select * on student_enrollments'));
      expect(mockClient.logs, contains('update {status: active} on student_enrollments'));
      final insertLogs = mockClient.logs.where((log) => log.contains('insert') && log.contains('student_enrollments'));
      expect(insertLogs, isEmpty);
    });

    test('Error Handling: Translates Postgrest 23505 error to custom user-friendly exception', () async {
      mockClient.studentSelectResult = {'batch_id': 'batch-old'};
      mockClient.throwDuplicateError = true;

      final data = {
        'account_id': 'account-456',
        'first_name': 'John',
        'last_name': 'Doe',
        'batch_id': 'batch-new',
      };

      expect(
        () => repository.updateStudent('student-123', data),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('This student is already enrolled in the selected batch.'),
        )),
      );
    });
  });
}
