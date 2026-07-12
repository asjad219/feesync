// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter_test/flutter_test.dart';
import 'package:feesync_mobile/core/billing/quota_checker.dart';
import 'package:feesync_mobile/models/subscription.dart';
import 'package:feesync_mobile/core/billing/feature_gate.dart';
import 'package:feesync_mobile/providers/subscription_provider.dart';

// ---------------------------------------------------------------------------
// Helper — builds a Subscription with overridable limits.
// ---------------------------------------------------------------------------
Subscription _makeSub({
  String planType = 'growth',
  String status = 'active',
  int maxStudents = -1,
  int maxBatches = -1,
  int maxStaff = -1,
  int waReceiptsLimit = -1,
  int waRemindersLimit = -1,
  DateTime? expiryDate,
}) {
  return Subscription(
    id: 'test-id',
    userId: 'user-123',
    planType: planType,
    startDate: DateTime.now(),
    expiryDate: expiryDate ?? DateTime.now().add(const Duration(days: 30)),
    status: status,
    maxStudents: maxStudents,
    maxBatches: maxBatches,
    maxStaff: maxStaff,
    whatsappReceiptsLimit: waReceiptsLimit,
    whatsappRemindersLimit: waRemindersLimit,
  );
}

// ---------------------------------------------------------------------------
// Helper — builds a FeatureGate with default zero usage.
// ---------------------------------------------------------------------------
FeatureGate _makeGate({
  required Subscription sub,
  int students = 0,
  int batches = 0,
  int staff = 0,
  int waReceipts = 0,
  int waReminders = 0,
}) {
  return FeatureGate(
    subscription: sub,
    activeStudentCount: students,
    activeBatchCount: batches,
    activeStaffCount: staff,
    waReceiptsUsedThisMonth: waReceipts,
    waRemindersUsedThisMonth: waReminders,
  );
}

// ---------------------------------------------------------------------------
// Helper — builds a SubscriptionScreenData.
// ---------------------------------------------------------------------------
SubscriptionScreenData _makeScreenData({
  required Subscription sub,
  int students = 0,
  int batches = 0,
  int staff = 0,
  Map<String, int> usage = const {},
}) {
  return SubscriptionScreenData(
    subscription: sub,
    activeStudentCount: students,
    activeBatchCount: batches,
    activeStaffCount: staff,
    usage: usage,
  );
}

void main() {
  // =========================================================================
  // SECTION 1 — QuotaChecker unit tests (the centralized logic layer)
  // =========================================================================

  group('QuotaChecker — core predicate tests', () {
    // --- canCreate ---
    group('canCreate', () {
      test('usage=0, limit=-1 → unlimited, always allowed', () {
        expect(QuotaChecker.canCreate(0, -1), isTrue);
      });

      test('usage=1000, limit=-1 → unlimited, still allowed', () {
        expect(QuotaChecker.canCreate(1000, -1), isTrue);
      });

      test('usage=0, limit=0 → unavailable, blocked', () {
        expect(QuotaChecker.canCreate(0, 0), isFalse);
      });

      test('usage=4, limit=5 → under cap, allowed', () {
        expect(QuotaChecker.canCreate(4, 5), isTrue);
      });

      test('usage=5, limit=5 → at cap, blocked', () {
        expect(QuotaChecker.canCreate(5, 5), isFalse);
      });

      test('usage=6, limit=5 → over cap, blocked', () {
        expect(QuotaChecker.canCreate(6, 5), isFalse);
      });
    });

    // --- hasReachedLimit ---
    group('hasReachedLimit', () {
      test('usage=0, limit=-1 → unlimited, not reached', () {
        expect(QuotaChecker.hasReachedLimit(0, -1), isFalse);
      });

      test('usage=1000, limit=-1 → unlimited, not reached', () {
        expect(QuotaChecker.hasReachedLimit(1000, -1), isFalse);
      });

      test('usage=0, limit=0 → unavailable, always reached', () {
        expect(QuotaChecker.hasReachedLimit(0, 0), isTrue);
      });

      test('usage=4, limit=5 → under cap, not reached', () {
        expect(QuotaChecker.hasReachedLimit(4, 5), isFalse);
      });

      test('usage=5, limit=5 → at cap, reached', () {
        expect(QuotaChecker.hasReachedLimit(5, 5), isTrue);
      });

      test('usage=6, limit=5 → over cap, reached', () {
        expect(QuotaChecker.hasReachedLimit(6, 5), isTrue);
      });
    });

    // --- usageRatio ---
    group('usageRatio', () {
      test('limit=-1 → ratio=0.0 (unlimited: empty bar)', () {
        expect(QuotaChecker.usageRatio(0, -1), 0.0);
        expect(QuotaChecker.usageRatio(9999, -1), 0.0);
      });

      test('limit=0 → ratio=1.0 (unavailable: full bar)', () {
        expect(QuotaChecker.usageRatio(0, 0), 1.0);
      });

      test('usage=0, limit=10 → ratio=0.0', () {
        expect(QuotaChecker.usageRatio(0, 10), 0.0);
      });

      test('usage=5, limit=10 → ratio=0.5', () {
        expect(QuotaChecker.usageRatio(5, 10), 0.5);
      });

      test('usage=10, limit=10 → ratio=1.0', () {
        expect(QuotaChecker.usageRatio(10, 10), 1.0);
      });

      test('usage=12, limit=10 → ratio clamped to 1.0', () {
        expect(QuotaChecker.usageRatio(12, 10), 1.0);
      });
    });

    // --- remainingSlots ---
    group('remainingSlots', () {
      test('limit=-1 → -1 (unlimited)', () {
        expect(QuotaChecker.remainingSlots(0, -1), -1);
        expect(QuotaChecker.remainingSlots(9999, -1), -1);
      });

      test('limit=0 → 0 (unavailable)', () {
        expect(QuotaChecker.remainingSlots(0, 0), 0);
      });

      test('usage=3, limit=5 → remaining=2', () {
        expect(QuotaChecker.remainingSlots(3, 5), 2);
      });

      test('usage=5, limit=5 → remaining=0', () {
        expect(QuotaChecker.remainingSlots(5, 5), 0);
      });

      test('usage=7, limit=5 → remaining=0 (no negative slots)', () {
        expect(QuotaChecker.remainingSlots(7, 5), 0);
      });
    });

    // --- formatLimit ---
    group('formatLimit', () {
      test('limit=-1 → ∞', () {
        expect(QuotaChecker.formatLimit(-1), '∞');
      });

      test('limit=0 → N/A', () {
        expect(QuotaChecker.formatLimit(0), 'N/A');
      });

      test('limit=500 → "500"', () {
        expect(QuotaChecker.formatLimit(500), '500');
      });
    });

    // --- formatUsageDisplay ---
    group('formatUsageDisplay', () {
      test('used=0, limit=-1 → "0 / ∞"', () {
        expect(QuotaChecker.formatUsageDisplay(0, -1), '0 / ∞');
      });

      test('used=1000, limit=-1 → "1000 / ∞"', () {
        expect(QuotaChecker.formatUsageDisplay(1000, -1), '1000 / ∞');
      });

      test('used=0, limit=0 → "N/A"', () {
        expect(QuotaChecker.formatUsageDisplay(0, 0), 'N/A');
      });

      test('used=3, limit=50 → "3 / 50"', () {
        expect(QuotaChecker.formatUsageDisplay(3, 50), '3 / 50');
      });
    });
  });

  // =========================================================================
  // SECTION 2 — FeatureGate tests (all plan tiers)
  // =========================================================================

  group('FeatureGate — Free plan', () {
    final sub = _makeSub(
      planType: 'free',
      maxStudents: 20,
      maxBatches: 2,
      maxStaff: 2,
      waReceiptsLimit: 100,
      waRemindersLimit: 30,
      expiryDate: null,
    );

    test('can add student when under limit', () {
      expect(_makeGate(sub: sub, students: 19).canAddStudent, isTrue);
    });

    test('blocked at student limit', () {
      expect(_makeGate(sub: sub, students: 20).canAddStudent, isFalse);
    });

    test('blocked over student limit', () {
      expect(_makeGate(sub: sub, students: 21).canAddStudent, isFalse);
    });

    test('can add batch when under limit', () {
      expect(_makeGate(sub: sub, batches: 1).canAddBatch, isTrue);
    });

    test('blocked at batch limit', () {
      expect(_makeGate(sub: sub, batches: 2).canAddBatch, isFalse);
    });

    test('can add staff when under limit', () {
      expect(_makeGate(sub: sub, staff: 1).canAddStaff, isTrue);
    });

    test('blocked at staff limit', () {
      expect(_makeGate(sub: sub, staff: 2).canAddStaff, isFalse);
    });

    test('can send WhatsApp receipt when under limit', () {
      expect(_makeGate(sub: sub, waReceipts: 99).canSendWhatsappReceipt, isTrue);
    });

    test('blocked at WhatsApp receipt limit', () {
      expect(_makeGate(sub: sub, waReceipts: 100).canSendWhatsappReceipt, isFalse);
    });
  });

  group('FeatureGate — Starter plan', () {
    final sub = _makeSub(
      planType: 'starter',
      maxStudents: 200,
      maxBatches: 10,
      maxStaff: 5,
      waReceiptsLimit: 2000,
      waRemindersLimit: 300,
    );

    test('can add student under limit', () {
      expect(_makeGate(sub: sub, students: 199).canAddStudent, isTrue);
    });

    test('blocked at student limit', () {
      expect(_makeGate(sub: sub, students: 200).canAddStudent, isFalse);
    });

    test('remainingStudentSlots correct', () {
      expect(_makeGate(sub: sub, students: 195).remainingStudentSlots, 5);
    });

    test('blocked at batch limit', () {
      expect(_makeGate(sub: sub, batches: 10).canAddBatch, isFalse);
    });

    test('blocked at staff limit', () {
      expect(_makeGate(sub: sub, staff: 5).canAddStaff, isFalse);
    });
  });

  group('FeatureGate — Growth plan with DB limits (500/50/10/5000)', () {
    // These are the finite limits that get_plan_limits() returns for 'growth'.
    final sub = _makeSub(
      planType: 'growth',
      maxStudents: 500,
      maxBatches: 50,
      maxStaff: 10,
      waReceiptsLimit: 5000,
      waRemindersLimit: 1000,
    );

    test('can add student under limit', () {
      expect(_makeGate(sub: sub, students: 499).canAddStudent, isTrue);
    });

    test('blocked at student limit', () {
      expect(_makeGate(sub: sub, students: 500).canAddStudent, isFalse);
    });

    test('can add batch under limit', () {
      expect(_makeGate(sub: sub, batches: 0).canAddBatch, isTrue);
    });

    test('blocked at batch limit', () {
      expect(_makeGate(sub: sub, batches: 50).canAddBatch, isFalse);
    });
  });

  group('FeatureGate — Growth plan with -1 sentinel (unlimited)', () {
    // Critical regression test: -1 must always allow creation.
    final sub = _makeSub(
      planType: 'growth',
      maxStudents: -1,
      maxBatches: -1,
      maxStaff: -1,
      waReceiptsLimit: -1,
      waRemindersLimit: -1,
    );

    test('usage=0, limit=-1 → canAddStudent=true', () {
      expect(_makeGate(sub: sub, students: 0).canAddStudent, isTrue);
    });

    test('usage=1000, limit=-1 → canAddStudent=true (regression test)', () {
      expect(_makeGate(sub: sub, students: 1000).canAddStudent, isTrue);
    });

    test('usage=0, limit=-1 → canAddBatch=true', () {
      expect(_makeGate(sub: sub, batches: 0).canAddBatch, isTrue);
    });

    test('usage=9999, limit=-1 → canAddBatch=true (regression test)', () {
      expect(_makeGate(sub: sub, batches: 9999).canAddBatch, isTrue);
    });

    test('usage=0, limit=-1 → canAddStaff=true', () {
      expect(_makeGate(sub: sub, staff: 0).canAddStaff, isTrue);
    });

    test('usage=9999, limit=-1 → canAddStaff=true', () {
      expect(_makeGate(sub: sub, staff: 9999).canAddStaff, isTrue);
    });

    test('usage=0, limit=-1 → canSendWhatsappReceipt=true', () {
      expect(_makeGate(sub: sub, waReceipts: 0).canSendWhatsappReceipt, isTrue);
    });

    test('usage=9999, limit=-1 → canSendWhatsappReceipt=true', () {
      expect(_makeGate(sub: sub, waReceipts: 9999).canSendWhatsappReceipt, isTrue);
    });

    test('remainingStudentSlots=-1 (unlimited)', () {
      expect(_makeGate(sub: sub, students: 0).remainingStudentSlots, -1);
    });

    test('remainingBatchSlots=-1 (unlimited)', () {
      expect(_makeGate(sub: sub, batches: 0).remainingBatchSlots, -1);
    });

    test('studentUsageFraction=0.0 for unlimited (empty progress bar)', () {
      expect(_makeGate(sub: sub, students: 9999).studentUsageFraction, 0.0);
    });

    test('isAtBatchLimit=false for unlimited', () {
      expect(_makeGate(sub: sub, batches: 9999).isAtBatchLimit, isFalse);
    });

    test('isNearStudentLimit=false for unlimited', () {
      expect(_makeGate(sub: sub, students: 9999).isNearStudentLimit, isFalse);
    });
  });

  group('FeatureGate — Institute plan', () {
    final sub = _makeSub(
      planType: 'institute',
      maxStudents: 5000,
      maxBatches: 500,
      maxStaff: 50,
      waReceiptsLimit: 50000,
      waRemindersLimit: 10000,
    );

    test('can add student under limit', () {
      expect(_makeGate(sub: sub, students: 4999).canAddStudent, isTrue);
    });

    test('blocked at student limit', () {
      expect(_makeGate(sub: sub, students: 5000).canAddStudent, isFalse);
    });

    test('can add batch under limit', () {
      expect(_makeGate(sub: sub, batches: 499).canAddBatch, isTrue);
    });

    test('blocked at batch limit', () {
      expect(_makeGate(sub: sub, batches: 500).canAddBatch, isFalse);
    });
  });

  // =========================================================================
  // SECTION 3 — SubscriptionScreenData tests (the provider-level class)
  //   This is where the original bug lived: canAddBatch used raw integer
  //   comparison (0 < -1 == false) instead of sentinel-aware logic.
  // =========================================================================

  group('SubscriptionScreenData — unlimited sentinel fix (critical regression)', () {
    final unlimitedSub = _makeSub(
      planType: 'growth',
      maxStudents: -1,
      maxBatches: -1,
      maxStaff: -1,
      waReceiptsLimit: -1,
    );

    test('canAddStudent: usage=0, limit=-1 → true (was false before fix)', () {
      final data = _makeScreenData(sub: unlimitedSub, students: 0);
      expect(data.canAddStudent, isTrue);
    });

    test('canAddBatch: usage=0, limit=-1 → true (was false before fix)', () {
      final data = _makeScreenData(sub: unlimitedSub, batches: 0);
      expect(data.canAddBatch, isTrue);
    });

    test('canAddStaff: usage=0, limit=-1 → true (was false before fix)', () {
      final data = _makeScreenData(sub: unlimitedSub, staff: 0);
      expect(data.canAddStaff, isTrue);
    });

    test('studentUsageRatio=0.0 for unlimited', () {
      final data = _makeScreenData(sub: unlimitedSub, students: 9999);
      expect(data.studentUsageRatio, 0.0);
    });

    test('batchUsageRatio=0.0 for unlimited', () {
      final data = _makeScreenData(sub: unlimitedSub, batches: 9999);
      expect(data.batchUsageRatio, 0.0);
    });

    test('staffUsageRatio=0.0 for unlimited', () {
      final data = _makeScreenData(sub: unlimitedSub, staff: 9999);
      expect(data.staffUsageRatio, 0.0);
    });

    test('isAtBatchLimit=false for unlimited', () {
      final data = _makeScreenData(sub: unlimitedSub, batches: 9999);
      expect(data.isAtBatchLimit, isFalse);
    });

    test('isAtStudentLimit=false for unlimited', () {
      final data = _makeScreenData(sub: unlimitedSub, students: 9999);
      expect(data.isAtStudentLimit, isFalse);
    });

    test('isAtStaffLimit=false for unlimited', () {
      final data = _makeScreenData(sub: unlimitedSub, staff: 9999);
      expect(data.isAtStaffLimit, isFalse);
    });
  });

  group('SubscriptionScreenData — finite limits still work correctly', () {
    final finiteSub = _makeSub(
      planType: 'growth',
      maxStudents: 500,
      maxBatches: 50,
      maxStaff: 10,
      waReceiptsLimit: 5000,
    );

    test('canAddBatch: usage=0, limit=50 → true', () {
      final data = _makeScreenData(sub: finiteSub, batches: 0);
      expect(data.canAddBatch, isTrue);
    });

    test('canAddBatch: usage=50, limit=50 → false', () {
      final data = _makeScreenData(sub: finiteSub, batches: 50);
      expect(data.canAddBatch, isFalse);
    });

    test('batchUsageRatio correct for finite limit', () {
      final data = _makeScreenData(sub: finiteSub, batches: 25);
      expect(data.batchUsageRatio, closeTo(0.5, 0.001));
    });
  });

  // =========================================================================
  // SECTION 4 — Required test cases from specification
  // =========================================================================

  group('Required spec test cases via QuotaChecker', () {
    test('usage=0,  limit=-1 → allowed', () => expect(QuotaChecker.canCreate(0, -1),    isTrue));
    test('usage=1000, limit=-1 → allowed', () => expect(QuotaChecker.canCreate(1000, -1), isTrue));
    test('usage=0,  limit=0  → blocked', () => expect(QuotaChecker.canCreate(0, 0),     isFalse));
    test('usage=4,  limit=5  → allowed', () => expect(QuotaChecker.canCreate(4, 5),     isTrue));
    test('usage=5,  limit=5  → blocked', () => expect(QuotaChecker.canCreate(5, 5),     isFalse));
    test('usage=6,  limit=5  → blocked', () => expect(QuotaChecker.canCreate(6, 5),     isFalse));
  });

  group('Required spec test cases via FeatureGate (end-to-end)', () {
    test('usage=0, limit=-1 (students) → canAddStudent=true', () {
      final sub = _makeSub(maxStudents: -1);
      expect(_makeGate(sub: sub, students: 0).canAddStudent, isTrue);
    });

    test('usage=1000, limit=-1 (students) → canAddStudent=true', () {
      final sub = _makeSub(maxStudents: -1);
      expect(_makeGate(sub: sub, students: 1000).canAddStudent, isTrue);
    });

    test('usage=0, limit=0 (students) → canAddStudent=false', () {
      final sub = _makeSub(maxStudents: 0);
      expect(_makeGate(sub: sub, students: 0).canAddStudent, isFalse);
    });

    test('usage=4, limit=5 (batches) → canAddBatch=true', () {
      final sub = _makeSub(maxBatches: 5);
      expect(_makeGate(sub: sub, batches: 4).canAddBatch, isTrue);
    });

    test('usage=5, limit=5 (batches) → canAddBatch=false', () {
      final sub = _makeSub(maxBatches: 5);
      expect(_makeGate(sub: sub, batches: 5).canAddBatch, isFalse);
    });

    test('usage=6, limit=5 (batches) → canAddBatch=false', () {
      final sub = _makeSub(maxBatches: 5);
      expect(_makeGate(sub: sub, batches: 6).canAddBatch, isFalse);
    });
  });
}
