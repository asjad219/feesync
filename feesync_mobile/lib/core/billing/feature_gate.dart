import '../../models/subscription.dart';
import 'quota_checker.dart';

/// FeatureGate — single source of truth for all feature-access decisions.
///
/// Inject via [featureGateProvider] (see subscription_provider.dart).
/// All UI code should call methods here rather than reading plan tier directly.
///
/// Design rule: gate checks are purely functional — no side effects.
/// Showing the paywall dialog is the caller's responsibility.
///
/// Quota sentinel convention:
///   -1  →  unlimited (QuotaChecker.isUnlimited)
///    0  →  feature unavailable
///   > 0 →  finite cap
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
  bool get canAddStudent => QuotaChecker.canCreate(
        activeStudentCount,
        subscription.currentMaxStudents,
      );

  /// How many more students the user can add. -1 = unlimited.
  int get remainingStudentSlots => QuotaChecker.remainingSlots(
        activeStudentCount,
        subscription.currentMaxStudents,
      );

  /// Student usage as a fraction (0.0–1.0).
  double get studentUsageFraction => QuotaChecker.usageRatio(
        activeStudentCount,
        subscription.currentMaxStudents,
      );

  // ── Batch limits ───────────────────────────────────────────────────────────

  /// True if the user can create more batches.
  bool get canAddBatch => QuotaChecker.canCreate(
        activeBatchCount,
        subscription.currentMaxBatches,
      );

  /// How many more batches the user can create. -1 = unlimited.
  int get remainingBatchSlots => QuotaChecker.remainingSlots(
        activeBatchCount,
        subscription.currentMaxBatches,
      );

  // ── Staff limits ───────────────────────────────────────────────────────────

  /// True if the user can add more staff.
  bool get canAddStaff => QuotaChecker.canCreate(
        activeStaffCount,
        subscription.currentMaxStaff,
      );

  /// How many more staff the user can add. -1 = unlimited.
  int get remainingStaffSlots => QuotaChecker.remainingSlots(
        activeStaffCount,
        subscription.currentMaxStaff,
      );

  /// Staff usage as a fraction (0.0–1.0).
  double get staffUsageFraction => QuotaChecker.usageRatio(
        activeStaffCount,
        subscription.currentMaxStaff,
      );

  // ── WhatsApp limits ────────────────────────────────────────────────────────

  /// True if the user can send another WhatsApp receipt.
  bool get canSendWhatsappReceipt => QuotaChecker.canCreate(
        waReceiptsUsedThisMonth,
        subscription.currentWaReceiptsLimit,
      );

  /// True if the user can send another WhatsApp reminder.
  bool get canSendWhatsappReminder => QuotaChecker.canCreate(
        waRemindersUsedThisMonth,
        subscription.currentWaRemindersLimit,
      );

  /// Remaining WhatsApp receipts. -1 = unlimited.
  int get remainingWaReceipts => QuotaChecker.remainingSlots(
        waReceiptsUsedThisMonth,
        subscription.currentWaReceiptsLimit,
      );

  /// Remaining WhatsApp reminders. -1 = unlimited.
  int get remainingWaReminders => QuotaChecker.remainingSlots(
        waRemindersUsedThisMonth,
        subscription.currentWaRemindersLimit,
      );

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
    return '$activeStudentCount / ${QuotaChecker.formatLimit(subscription.currentMaxStudents)} students used';
  }

  /// Human-readable limit status for batch usage.
  String get batchLimitStatus {
    return '$activeBatchCount / ${QuotaChecker.formatLimit(subscription.currentMaxBatches)} batches used';
  }

  /// Human-readable limit status for staff usage.
  String get staffLimitStatus {
    return '$activeStaffCount / ${QuotaChecker.formatLimit(subscription.currentMaxStaff)} staff used';
  }
}
