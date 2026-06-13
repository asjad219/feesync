import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:feesync_mobile/repositories/batch_repository.dart';

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
  final T result;
  final bool batchExists;

  MockPostgrestFilterBuilder(this.table, this.operation, this.logs, this.result, {required this.batchExists});

  @override
  PostgrestFilterBuilder<T> eq(String column, Object value) {
    logs.add('$operation on $table where $column = $value');
    return this;
  }

  @override
  PostgrestTransformBuilder<Map<String, dynamic>?> maybeSingle() {
    return MockPostgrestTransformBuilder<Map<String, dynamic>?>(
      Future.value(batchExists ? {'id': 'test-batch-id'} : null),
    );
  }

  @override
  Future<R> then<R>(FutureOr<R> Function(T) onValue, {Function? onError}) {
    return Future.value(result).then(onValue, onError: onError);
  }
}

class MockSupabaseQueryBuilder extends Fake implements SupabaseQueryBuilder {
  final String table;
  final List<String> logs;
  final bool batchExists;

  MockSupabaseQueryBuilder(this.table, this.logs, {required this.batchExists});

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> select([String columns = '*']) {
    return MockPostgrestFilterBuilder<List<Map<String, dynamic>>>(table, 'select', logs, [], batchExists: batchExists);
  }

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> delete() {
    return MockPostgrestFilterBuilder<List<Map<String, dynamic>>>(table, 'delete', logs, [], batchExists: batchExists);
  }

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> update(Map values) {
    return MockPostgrestFilterBuilder<List<Map<String, dynamic>>>(table, 'update $values', logs, [], batchExists: batchExists);
  }
}

class MockSupabaseClient extends Fake implements SupabaseClient {
  final List<String> logs = [];
  bool batchExists = true;

  @override
  SupabaseQueryBuilder from(String table) {
    return MockSupabaseQueryBuilder(table, logs, batchExists: batchExists);
  }
}

void main() {
  group('Batch Deletion Workflow Tests', () {
    late MockSupabaseClient mockClient;
    late BatchRepository repository;

    setUp(() {
      mockClient = MockSupabaseClient();
      repository = BatchRepository(mockClient);
    });

    test('Throws Exception if Batch not found in database', () async {
      mockClient.batchExists = false;

      expect(
        () => repository.deleteBatch('non-existent-id'),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('Batch not found.'))),
      );

      // Verify only the select log was recorded
      expect(mockClient.logs, equals(['select on batches where id = non-existent-id']));
    });

    test('Executes explicit deletion transaction sequence in correct order', () async {
      mockClient.batchExists = true;

      await repository.deleteBatch('test-batch-id');

      // Verify the log entries are recorded in order
      expect(mockClient.logs, hasLength(5));
      expect(mockClient.logs[0], equals('select on batches where id = test-batch-id'));
      expect(mockClient.logs[1], equals('delete on attendance where batch_id = test-batch-id'));
      expect(mockClient.logs[2], equals('delete on student_enrollments where batch_id = test-batch-id'));
      expect(mockClient.logs[3], equals('update {batch_id: null} on students where batch_id = test-batch-id'));
      expect(mockClient.logs[4], equals('delete on batches where id = test-batch-id'));
    });
  });
}
