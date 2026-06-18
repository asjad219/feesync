import '../../models/subscription.dart';

/// FeatureGate — single source of truth for all feature-access decisions.
///
/// Inject via [featureGateProvider] (see subscription_provider.dart).
/// All UI code should call methods here rather than reading plan tier directly.
///
/// Design rule: gate checks are purely functional — no side effects.
/// Showing the paywall dialog is the caller's responsibility.
class FeatureGate {
  final Subscription subscription;
  final int activeStudentCount;
  final int activeBatchCount;
  final int activeStaffCount;
  final int waReceiptsUsedThisMonth;
  final int waRemindersUsedThisMonth;

  const FeatureGate({
    required this.subscription,
    required this.activeStudentCount,
    required this.activeBatchCount,
    this.activeStaffCount = 0,
    this.waReceiptsUsedThisMonth = 0,
    this.waRemindersUsedThisMonth = 0,
  });

  // ── Student limits ─────────────────────────────────────────────────────────

  /// True if the user can add more students.
  bool get canAddStudent {
    if (subscription.hasUnlimitedStudents) return true;
    return activeStudentCount < subscription.currentMaxStudents;
  }

  /// How many more students the user can add.
  int get remainingStudentSlots {
    if (subscription.hasUnlimitedStudents) return -1;
    final remaining = subscription.currentMaxStudents - activeStudentCount;
    return remaining < 0 ? 0 : remaining;
  }

  /// Student usage as a fraction (0.0–1.0).
  double get studentUsageFraction {
    if (subscription.currentMaxStudents == 0) return 1.0;
    return (activeStudentCount / subscription.currentMaxStudents).clamp(0.0, 1.0);
  }

  // ── Batch limits ───────────────────────────────────────────────────────────

  /// True if the user can create more batches.
  bool get canAddBatch {
    if (subscription.hasUnlimitedBatches) return true;
    return activeBatchCount < subscription.currentMaxBatches;
  }

  /// How many more batches the user can create.
  int get remainingBatchSlots {
    if (subscription.hasUnlimitedBatches) return -1;
    final remaining = subscription.currentMaxBatches - activeBatchCount;
    return remaining < 0 ? 0 : remaining;
  }

  // ── Staff limits ───────────────────────────────────────────────────────────

  /// True if the user can add more staff.
  bool get canAddStaff {
    if (subscription.hasUnlimitedStaff) return true;
    return activeStaffCount < subscription.currentMaxStaff;
  }

  /// How many more staff the user can add.
  int get remainingStaffSlots {
    if (subscription.hasUnlimitedStaff) return -1;
    final remaining = subscription.currentMaxStaff - activeStaffCount;
    return remaining < 0 ? 0 : remaining;
  }

  /// Staff usage as a fraction (0.0–1.0).
  double get staffUsageFraction {
    if (subscription.currentMaxStaff == 0) return 1.0;
    return (activeStaffCount / subscription.currentMaxStaff).clamp(0.0, 1.0);
  }

  // ── WhatsApp limits ────────────────────────────────────────────────────────

  /// True if the user can send another WhatsApp receipt.
  bool get canSendWhatsappReceipt {
    if (subscription.hasUnlimitedWaReceipts) return true;
    return waReceiptsUsedThisMonth < subscription.currentWaReceiptsLimit;
  }

  /// True if the user can send another WhatsApp reminder.
  bool get canSendWhatsappReminder {
    if (subscription.hasUnlimitedWaReminders) return true;
    return waRemindersUsedThisMonth < subscription.currentWaRemindersLimit;
  }

  int get remainingWaReceipts {
    if (subscription.hasUnlimitedWaReceipts) return -1;
    return (subscription.currentWaReceiptsLimit - waReceiptsUsedThisMonth)
        .clamp(0, subscription.currentWaReceiptsLimit);
  }

  int get remainingWaReminders {
    if (subscription.hasUnlimitedWaReminders) return -1;
    return (subscription.currentWaRemindersLimit - waRemindersUsedThisMonth)
        .clamp(0, subscription.currentWaRemindersLimit);
  }

  // ── Feature flags ──────────────────────────────────────────────────────────


  bool get canExportCsv           => subscription.canExportCsv;

  /// True if the user is on any paid plan.
  bool get hasPaidAccess          => subscription.hasPaidAccess;

  /// True if the user is on free tier.
  bool get isOnFreePlan           => subscription.isFree;

  // ── Upgrade recommendations ─────────────────────────────────────────────────

  /// True if the student count is at or near the limit (>= 80% usage).
  bool get isNearStudentLimit {
    return studentUsageFraction >= 0.8;
  }

  /// True if the student limit is exactly reached.
  bool get isAtStudentLimit => !canAddStudent;

  /// True if the batch limit is exactly reached.
  bool get isAtBatchLimit => !canAddBatch;

  /// True if the staff count is at or near the limit (>= 80% usage).
  bool get isNearStaffLimit {
    return staffUsageFraction >= 0.8;
  }

  /// True if the staff limit is exactly reached.
  bool get isAtStaffLimit => !canAddStaff;

  /// Returns the recommended upgrade plan tier for the current user.
  /// Returns null if user is already on the highest plan.
  String? get recommendedUpgradeTier {
    switch (subscription.effectivePlan) {
      case 'free':
        return 'starter';
      case 'starter':
        return 'growth';
      case 'growth':
        return 'institute';
      default:
        return null;
    }
  }

  // ── Status messages ────────────────────────────────────────────────────────

  /// Human-readable limit status for student usage.
  String get studentLimitStatus {
    return '$activeStudentCount / ${subscription.currentMaxStudents} students used';
  }

  /// Human-readable limit status for batch usage.
  String get batchLimitStatus {
    return '$activeBatchCount / ${subscription.currentMaxBatches} batches used';
  }

  /// Human-readable limit status for staff usage.
  String get staffLimitStatus {
    return '$activeStaffCount / ${subscription.currentMaxStaff} staff used';
  }
}
