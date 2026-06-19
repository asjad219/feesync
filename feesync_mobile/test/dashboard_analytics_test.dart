import 'package:feesync_mobile/models/fee.dart';
import 'package:feesync_mobile/models/student.dart';
import 'package:feesync_mobile/providers/dashboard_provider.dart';
import 'package:feesync_mobile/repositories/fee_repository.dart';
import 'package:feesync_mobile/repositories/payment_repository.dart';
import 'package:feesync_mobile/repositories/student_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FakeSupabaseClient extends Fake implements SupabaseClient {}

class FakePaymentRepository extends PaymentRepository {
  final double allTimeTotal;
  final Map<int, double> totalsByMonthOffset;

  FakePaymentRepository({
    required this.allTimeTotal,
    required this.totalsByMonthOffset,
  }) : super(FakeSupabaseClient());

  @override
  Future<Map<String, dynamic>> getTotalCollection({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (startDate == null && endDate == null) {
      return {'total': allTimeTotal, 'count': 0};
    }

    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month, 1);
    final targetMonth = DateTime(startDate!.year, startDate.month, 1);
    final monthOffset =
        (currentMonth.year - targetMonth.year) * 12 + (currentMonth.month - targetMonth.month);

    return {
      'total': totalsByMonthOffset[monthOffset] ?? 0.0,
      'count': 0,
    };
  }
}

class FakeStudentRepository extends StudentRepository {
  final List<Student> students;
  final List<StudentBalance> balances;

  FakeStudentRepository({
    required this.students,
    required this.balances,
  }) : super(FakeSupabaseClient());

  @override
  Future<List<Student>> getStudents({
    String? search,
    String? studentClass,
    String? section,
  }) async {
    return students;
  }

  @override
  Future<List<StudentBalance>> getStudentBalances() async {
    return balances;
  }
}

class FakeFeeRepository extends FeeRepository {
  final List<Due> dues;

  FakeFeeRepository({
    required this.dues,
  }) : super(FakeSupabaseClient());

  @override
  Future<List<Due>> getDues({
    String? studentId,
    String? status,
    List<String>? statuses,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return dues;
  }
}

void main() {
  group('DashboardAnalyticsRepository', () {
    test('calculates collection efficiency and positive monthly growth from real data', () async {
      final repository = DashboardAnalyticsRepository(
        FakePaymentRepository(
          allTimeTotal: 25000,
          totalsByMonthOffset: const {
            0: 15000,
            1: 10000,
          },
        ),
        FakeStudentRepository(
          students: List.generate(4, (index) => _buildStudent(id: 'student-$index')),
          balances: [
            _buildBalance(
              id: 'student-1',
              dueAmount: 25000,
            ),
          ],
        ),
        FakeFeeRepository(
          dues: [
            _buildDue(id: 'due-1', amountAssigned: 20000, status: 'paid'),
            _buildDue(id: 'due-2', amountAssigned: 30000, status: 'pending'),
            _buildDue(id: 'due-3', amountAssigned: 10000, status: 'cancelled'),
          ],
        ),
        FakeSupabaseClient(),
      );

      final stats = await repository.getDashboardStatsForCycle(TimeCycle.monthly);

      expect(stats.totalStudents, 4);
      expect(stats.totalFeesCollected, 15000);
      expect(stats.pendingFees, 25000);
      expect(stats.collectionRate, 50);
      expect(stats.growthPercentage, 50);
      expect(stats.isNewGrowth, isFalse);
    });

    test('marks growth as NEW when previous month has zero collections', () async {
      final repository = DashboardAnalyticsRepository(
        FakePaymentRepository(
          allTimeTotal: 12000,
          totalsByMonthOffset: const {
            0: 12000,
            1: 0,
          },
        ),
        FakeStudentRepository(
          students: [_buildStudent()],
          balances: [_buildBalance(dueAmount: 0)],
        ),
        FakeFeeRepository(
          dues: [
            _buildDue(amountAssigned: 12000, status: 'paid'),
          ],
        ),
        FakeSupabaseClient(),
      );

      final stats = await repository.getDashboardStatsForCycle(TimeCycle.monthly);

      expect(stats.totalFeesCollected, 12000);
      expect(stats.collectionRate, 100);
      expect(stats.isNewGrowth, isTrue);
      expect(stats.growthPercentage, 0);
    });

    test('returns zero efficiency and zero growth when there are no dues or collections', () async {
      final repository = DashboardAnalyticsRepository(
        FakePaymentRepository(
          allTimeTotal: 0,
          totalsByMonthOffset: const {
            0: 0,
            1: 0,
          },
        ),
        FakeStudentRepository(
          students: const [],
          balances: const [],
        ),
        FakeFeeRepository(dues: const []),
        FakeSupabaseClient(),
      );

      final stats = await repository.getDashboardStatsForCycle(TimeCycle.monthly);

      expect(stats.totalStudents, 0);
      expect(stats.totalFeesCollected, 0);
      expect(stats.collectionRate, 0);
      expect(stats.growthPercentage, 0);
      expect(stats.isNewGrowth, isFalse);
    });

    test('does not divide by zero for advance-only collections', () async {
      final repository = DashboardAnalyticsRepository(
        FakePaymentRepository(
          allTimeTotal: 5000,
          totalsByMonthOffset: const {
            0: 5000,
            1: 0,
          },
        ),
        FakeStudentRepository(
          students: [_buildStudent()],
          balances: [
            _buildBalance(dueAmount: -5000),
          ],
        ),
        FakeFeeRepository(dues: const []),
        FakeSupabaseClient(),
      );

      final stats = await repository.getDashboardStatsForCycle(TimeCycle.monthly);

      expect(stats.pendingFees, -5000);
      expect(stats.collectionRate, 0);
      expect(stats.isNewGrowth, isTrue);
    });
  });
}

Student _buildStudent({String id = 'student-1'}) {
  final now = DateTime.utc(2026, 6, 13);
  return Student(
    id: id,
    accountId: 'account-1',
    admissionNumber: 'ADM-001',
    firstName: 'John',
    lastName: 'Doe',
    studentClass: 'Class A',
    createdAt: now,
    updatedAt: now,
  );
}

StudentBalance _buildBalance({
  String id = 'student-1',
  double dueAmount = 0,
}) {
  return StudentBalance(
    id: id,
    accountId: 'account-1',
    admissionNumber: 'ADM-001',
    firstName: 'John',
    lastName: 'Doe',
    studentClass: 'Class A',
    totalFeeAmount: 50000,
    totalPaidAmount: 25000,
    balance: dueAmount,
    dueAmount: dueAmount,
    status: dueAmount > 0 ? 'DUE' : 'PAID',
  );
}

Due _buildDue({
  String id = 'due-1',
  double amountAssigned = 0,
  String status = 'pending',
}) {
  final now = DateTime.utc(2026, 6, 13);
  return Due(
    id: id,
    accountId: 'account-1',
    studentId: 'student-1',
    feeStructureId: 'fee-1',
    periodName: 'Jun 2026',
    dueDate: now,
    amountAssigned: amountAssigned,
    amountPaid: status == 'paid' ? amountAssigned : 0,
    dueAmount: status == 'paid' ? 0 : amountAssigned,
    lateFineApplied: 0,
    status: status,
    createdAt: now,
    updatedAt: now,
  );
}
