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
  final int waReceiptsUsedThisMonth;
  final int waRemindersUsedThisMonth;

  const FeatureGate({
    required this.subscription,
    required this.activeStudentCount,
    required this.activeBatchCount,
    this.waReceiptsUsedThisMonth = 0,
    this.waRemindersUsedThisMonth = 0,
  });

  // ── Student limits ─────────────────────────────────────────────────────────

  /// True if the user can add more students.
  bool get canAddStudent {
    if (subscription.hasUnlimitedStudents) return true;
    return activeStudentCount < subscription.maxStudents;
  }

  /// How many more students the user can add (-1 = unlimited).
  int get remainingStudentSlots {
    if (subscription.hasUnlimitedStudents) return -1;
    final remaining = subscription.maxStudents - activeStudentCount;
    return remaining < 0 ? 0 : remaining;
  }

  /// Student usage as a fraction (0.0–1.0). Returns 0.0 for unlimited.
  double get studentUsageFraction {
    if (subscription.hasUnlimitedStudents) return 0.0;
    if (subscription.maxStudents == 0) return 1.0;
    return (activeStudentCount / subscription.maxStudents).clamp(0.0, 1.0);
  }

  // ── Batch limits ───────────────────────────────────────────────────────────

  /// True if the user can create more batches.
  bool get canAddBatch {
    if (subscription.hasUnlimitedBatches) return true;
    return activeBatchCount < subscription.maxBatches;
  }

  /// How many more batches the user can create (-1 = unlimited).
  int get remainingBatchSlots {
    if (subscription.hasUnlimitedBatches) return -1;
    final remaining = subscription.maxBatches - activeBatchCount;
    return remaining < 0 ? 0 : remaining;
  }

  // ── WhatsApp limits ────────────────────────────────────────────────────────

  /// True if the user can send another WhatsApp receipt.
  bool get canSendWhatsappReceipt {
    if (subscription.hasUnlimitedWaReceipts) return true;
    return waReceiptsUsedThisMonth < subscription.whatsappReceiptsLimit;
  }

  /// True if the user can send another WhatsApp reminder.
  bool get canSendWhatsappReminder {
    if (subscription.hasUnlimitedWaReminders) return true;
    return waRemindersUsedThisMonth < subscription.whatsappRemindersLimit;
  }

  int get remainingWaReceipts {
    if (subscription.hasUnlimitedWaReceipts) return -1;
    return (subscription.whatsappReceiptsLimit - waReceiptsUsedThisMonth)
        .clamp(0, subscription.whatsappReceiptsLimit);
  }

  int get remainingWaReminders {
    if (subscription.hasUnlimitedWaReminders) return -1;
    return (subscription.whatsappRemindersLimit - waRemindersUsedThisMonth)
        .clamp(0, subscription.whatsappRemindersLimit);
  }

  // ── Feature flags ──────────────────────────────────────────────────────────

  bool get canUseAiFeatures       => subscription.canUseAiFeatures;
  bool get canUseAllAiFeatures    => subscription.canUseAllAiFeatures;
  bool get canUseRazorpay         => subscription.canUseRazorpay;
  bool get canUseRazorpayAutoDebit => subscription.canUseRazorpayAutoDebit;
  bool get canExportCsv           => subscription.canExportCsv;
  bool get canScheduleEmailReports => subscription.canScheduleEmailReports;
  bool get hasPrioritySupport     => subscription.hasPrioritySupport;

  /// Number of report types the user can access.
  int get reportAccessCount       => subscription.reportAccessCount;

  /// True if the user is on any paid plan.
  bool get hasPaidAccess          => subscription.hasPaidAccess;

  /// True if the user is on free tier.
  bool get isOnFreePlan           => subscription.isFree;

  // ── Upgrade recommendations ─────────────────────────────────────────────────

  /// True if the student count is at or near the limit (>= 80% usage).
  bool get isNearStudentLimit {
    if (subscription.hasUnlimitedStudents) return false;
    return studentUsageFraction >= 0.8;
  }

  /// True if the student limit is exactly reached.
  bool get isAtStudentLimit => !canAddStudent;

  /// True if the batch limit is exactly reached.
  bool get isAtBatchLimit => !canAddBatch;

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
    if (subscription.hasUnlimitedStudents) return 'Unlimited students';
    return '$activeStudentCount / ${subscription.maxStudents} students used';
  }

  /// Human-readable limit status for batch usage.
  String get batchLimitStatus {
    if (subscription.hasUnlimitedBatches) return 'Unlimited batches';
    return '$activeBatchCount / ${subscription.maxBatches} batches used';
  }
}
