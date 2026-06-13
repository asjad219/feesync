import 'package:flutter_test/flutter_test.dart';
import 'package:feesync_mobile/models/subscription.dart';
import 'package:feesync_mobile/core/billing/feature_gate.dart';

void main() {
  group('Subscription Limit Enforcement - Free Plan', () {
    final freeSub = Subscription(
      id: 'test-free',
      userId: 'user-123',
      planType: 'free',
      startDate: DateTime.now(),
      maxStudents: 20,
      maxBatches: 2,
      maxStaff: 1,
      whatsappReceiptsLimit: 100,
      status: 'active',
    );

    test('Student limits: student #21 is blocked', () {
      // Under limit: 19 students
      final gateUnder = FeatureGate(
        subscription: freeSub,
        activeStudentCount: 19,
        activeBatchCount: 0,
      );
      expect(gateUnder.canAddStudent, isTrue);
      expect(gateUnder.remainingStudentSlots, 1);

      // At limit: 20 students
      final gateAt = FeatureGate(
        subscription: freeSub,
        activeStudentCount: 20,
        activeBatchCount: 0,
      );
      expect(gateAt.canAddStudent, isFalse);
      expect(gateAt.remainingStudentSlots, 0);

      // Over limit: 21 students
      final gateOver = FeatureGate(
        subscription: freeSub,
        activeStudentCount: 21,
        activeBatchCount: 0,
      );
      expect(gateOver.canAddStudent, isFalse);
      expect(gateOver.remainingStudentSlots, 0);
    });

    test('Batch limits: batch #3 is blocked', () {
      // Under limit: 1 batch
      final gateUnder = FeatureGate(
        subscription: freeSub,
        activeStudentCount: 0,
        activeBatchCount: 1,
      );
      expect(gateUnder.canAddBatch, isTrue);
      expect(gateUnder.remainingBatchSlots, 1);

      // At limit: 2 batches
      final gateAt = FeatureGate(
        subscription: freeSub,
        activeStudentCount: 0,
        activeBatchCount: 2,
      );
      expect(gateAt.canAddBatch, isFalse);
      expect(gateAt.remainingBatchSlots, 0);

      // Over limit: 3 batches
      final gateOver = FeatureGate(
        subscription: freeSub,
        activeStudentCount: 0,
        activeBatchCount: 3,
      );
      expect(gateOver.canAddBatch, isFalse);
      expect(gateOver.remainingBatchSlots, 0);
    });

    test('Staff limits: staff #2 is blocked', () {
      // Under limit: 0 staff
      final gateUnder = FeatureGate(
        subscription: freeSub,
        activeStudentCount: 0,
        activeBatchCount: 0,
        activeStaffCount: 0,
      );
      expect(gateUnder.canAddStaff, isTrue);
      expect(gateUnder.remainingStaffSlots, 1);

      // At limit: 1 staff
      final gateAt = FeatureGate(
        subscription: freeSub,
        activeStudentCount: 0,
        activeBatchCount: 0,
        activeStaffCount: 1,
      );
      expect(gateAt.canAddStaff, isFalse);
      expect(gateAt.remainingStaffSlots, 0);

      // Over limit: 2 staff
      final gateOver = FeatureGate(
        subscription: freeSub,
        activeStudentCount: 0,
        activeBatchCount: 0,
        activeStaffCount: 2,
      );
      expect(gateOver.canAddStaff, isFalse);
      expect(gateOver.remainingStaffSlots, 0);
    });

    test('WhatsApp receipt limits: receipt #101 is blocked', () {
      // Under limit: 99 receipts
      final gateUnder = FeatureGate(
        subscription: freeSub,
        activeStudentCount: 0,
        activeBatchCount: 0,
        waReceiptsUsedThisMonth: 99,
      );
      expect(gateUnder.canSendWhatsappReceipt, isTrue);
      expect(gateUnder.remainingWaReceipts, 1);

      // At limit: 100 receipts
      final gateAt = FeatureGate(
        subscription: freeSub,
        activeStudentCount: 0,
        activeBatchCount: 0,
        waReceiptsUsedThisMonth: 100,
      );
      expect(gateAt.canSendWhatsappReceipt, isFalse);
      expect(gateAt.remainingWaReceipts, 0);

      // Over limit: 101 receipts
      final gateOver = FeatureGate(
        subscription: freeSub,
        activeStudentCount: 0,
        activeBatchCount: 0,
        waReceiptsUsedThisMonth: 101,
      );
      expect(gateOver.canSendWhatsappReceipt, isFalse);
      expect(gateOver.remainingWaReceipts, 0);
    });
  });

  group('Subscription Limit Enforcement - Starter Plan', () {
    final starterSub = Subscription(
      id: 'test-starter',
      userId: 'user-123',
      planType: 'starter',
      startDate: DateTime.now(),
      maxStudents: 200,
      maxBatches: 10,
      maxStaff: 5,
      whatsappReceiptsLimit: 1000,
      status: 'active',
    );

    test('Student limits: student #201 is blocked', () {
      // Under limit: 199 students
      final gateUnder = FeatureGate(
        subscription: starterSub,
        activeStudentCount: 199,
        activeBatchCount: 0,
      );
      expect(gateUnder.canAddStudent, isTrue);
      expect(gateUnder.remainingStudentSlots, 1);

      // At limit: 200 students
      final gateAt = FeatureGate(
        subscription: starterSub,
        activeStudentCount: 200,
        activeBatchCount: 0,
      );
      expect(gateAt.canAddStudent, isFalse);
      expect(gateAt.remainingStudentSlots, 0);

      // Over limit: 201 students
      final gateOver = FeatureGate(
        subscription: starterSub,
        activeStudentCount: 201,
        activeBatchCount: 0,
      );
      expect(gateOver.canAddStudent, isFalse);
      expect(gateOver.remainingStudentSlots, 0);
    });

    test('Batch limits: batch #11 is blocked', () {
      // Under limit: 9 batches
      final gateUnder = FeatureGate(
        subscription: starterSub,
        activeStudentCount: 0,
        activeBatchCount: 9,
      );
      expect(gateUnder.canAddBatch, isTrue);
      expect(gateUnder.remainingBatchSlots, 1);

      // At limit: 10 batches
      final gateAt = FeatureGate(
        subscription: starterSub,
        activeStudentCount: 0,
        activeBatchCount: 10,
      );
      expect(gateAt.canAddBatch, isFalse);
      expect(gateAt.remainingBatchSlots, 0);

      // Over limit: 11 batches
      final gateOver = FeatureGate(
        subscription: starterSub,
        activeStudentCount: 0,
        activeBatchCount: 11,
      );
      expect(gateOver.canAddBatch, isFalse);
      expect(gateOver.remainingBatchSlots, 0);
    });

    test('Staff limits: staff #6 is blocked', () {
      // Under limit: 4 staff
      final gateUnder = FeatureGate(
        subscription: starterSub,
        activeStudentCount: 0,
        activeBatchCount: 0,
        activeStaffCount: 4,
      );
      expect(gateUnder.canAddStaff, isTrue);
      expect(gateUnder.remainingStaffSlots, 1);

      // At limit: 5 staff
      final gateAt = FeatureGate(
        subscription: starterSub,
        activeStudentCount: 0,
        activeBatchCount: 0,
        activeStaffCount: 5,
      );
      expect(gateAt.canAddStaff, isFalse);
      expect(gateAt.remainingStaffSlots, 0);

      // Over limit: 6 staff
      final gateOver = FeatureGate(
        subscription: starterSub,
        activeStudentCount: 0,
        activeBatchCount: 0,
        activeStaffCount: 6,
      );
      expect(gateOver.canAddStaff, isFalse);
      expect(gateOver.remainingStaffSlots, 0);
    });

    test('WhatsApp receipt limits: receipt #1001 is blocked', () {
      // Under limit: 999 receipts
      final gateUnder = FeatureGate(
        subscription: starterSub,
        activeStudentCount: 0,
        activeBatchCount: 0,
        waReceiptsUsedThisMonth: 999,
      );
      expect(gateUnder.canSendWhatsappReceipt, isTrue);
      expect(gateUnder.remainingWaReceipts, 1);

      // At limit: 1000 receipts
      final gateAt = FeatureGate(
        subscription: starterSub,
        activeStudentCount: 0,
        activeBatchCount: 0,
        waReceiptsUsedThisMonth: 1000,
      );
      expect(gateAt.canSendWhatsappReceipt, isFalse);
      expect(gateAt.remainingWaReceipts, 0);

      // Over limit: 1001 receipts
      final gateOver = FeatureGate(
        subscription: starterSub,
        activeStudentCount: 0,
        activeBatchCount: 0,
        waReceiptsUsedThisMonth: 1001,
      );
      expect(gateOver.canSendWhatsappReceipt, isFalse);
      expect(gateOver.remainingWaReceipts, 0);
    });
  });

  group('Subscription Limit Enforcement - Growth Plan', () {
    final growthSub = Subscription(
      id: 'test-growth',
      userId: 'user-123',
      planType: 'growth',
      startDate: DateTime.now(),
      maxStudents: -1,
      maxBatches: -1,
      maxStaff: -1,
      whatsappReceiptsLimit: -1,
      status: 'active',
    );

    test('Growth plan is unlimited for all quotas', () {
      final gate = FeatureGate(
        subscription: growthSub,
        activeStudentCount: 9999,
        activeBatchCount: 9999,
        activeStaffCount: 9999,
        waReceiptsUsedThisMonth: 9999,
      );

      expect(gate.canAddStudent, isTrue);
      expect(gate.remainingStudentSlots, -1);
      
      expect(gate.canAddBatch, isTrue);
      expect(gate.remainingBatchSlots, -1);

      expect(gate.canAddStaff, isTrue);
      expect(gate.remainingStaffSlots, -1);

      expect(gate.canSendWhatsappReceipt, isTrue);
      expect(gate.remainingWaReceipts, -1);
    });
  });
}
