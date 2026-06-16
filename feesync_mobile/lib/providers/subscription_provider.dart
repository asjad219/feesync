import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/subscription.dart';
import '../repositories/subscription_repository.dart';
import '../core/billing/feature_gate.dart';
import '../repositories/usage_repository.dart';
import 'supabase_provider.dart';
import '../core/billing/plan_config.dart';

// ─── Repository provider ───────────────────────────────────────────────────────

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SubscriptionRepository(client);
});

final usageRepositoryProvider = Provider<UsageRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return UsageRepository(client);
});

// ─── Core subscription data ────────────────────────────────────────────────────

/// Provides the current user's subscription record.
/// Gracefully returns a Free plan if no DB record exists yet.
final subscriptionProvider = FutureProvider<Subscription>((ref) async {
  final repo = ref.watch(subscriptionRepositoryProvider);
  return repo.getSubscription();
});

/// Provides the active student count for the current owner.
final activeStudentCountProvider = FutureProvider<int>((ref) async {
  final repo = ref.watch(subscriptionRepositoryProvider);
  return repo.getActiveStudentCount();
});

/// Provides the active batch count for the current owner.
final activeBatchCountProvider = FutureProvider<int>((ref) async {
  final repo = ref.watch(subscriptionRepositoryProvider);
  return repo.getActiveBatchCount();
});

/// Provides the active staff count for the current owner.
final activeStaffCountProvider = FutureProvider<int>((ref) async {
  final repo = ref.watch(subscriptionRepositoryProvider);
  return repo.getActiveStaffCount();
});

/// Provides the current month's usage for the active user.
final currentMonthUsageProvider = FutureProvider<Map<String, int>>((ref) async {
  final repo = ref.watch(usageRepositoryProvider);
  return repo.getCurrentMonthUsage();
});

// ─── Feature Gate provider ─────────────────────────────────────────────────────

/// The authoritative feature gate — use this everywhere in the app to check
/// whether an action is allowed for the user's current plan.
///
/// Example:
///   final gate = ref.watch(featureGateProvider);
///   if (!gate.canAddStudent) { showPaywallDialog(...); return; }
final featureGateProvider = FutureProvider<FeatureGate>((ref) async {
  final sub          = await ref.watch(subscriptionProvider.future);
  final studentCount = await ref.watch(activeStudentCountProvider.future);
  final batchCount   = await ref.watch(activeBatchCountProvider.future);
  final staffCount   = await ref.watch(activeStaffCountProvider.future);
  final usage        = await ref.watch(currentMonthUsageProvider.future);

  return FeatureGate(
    subscription:              sub,
    activeStudentCount:        studentCount,
    activeBatchCount:          batchCount,
    activeStaffCount:          staffCount,
    waReceiptsUsedThisMonth:   usage['whatsapp_receipts_used'] ?? 0,
    waRemindersUsedThisMonth:  usage['whatsapp_reminders_used'] ?? 0,
  );
});

// ─── Combined screen data ──────────────────────────────────────────────────────

/// Bundles all subscription data for the subscription screen and paywall dialog.
/// Prefer [featureGateProvider] for gate checks; use this for display purposes.
final subscriptionScreenDataProvider =
    FutureProvider<SubscriptionScreenData>((ref) async {
  final sub          = await ref.watch(subscriptionProvider.future);
  final studentCount = await ref.watch(activeStudentCountProvider.future);
  final batchCount   = await ref.watch(activeBatchCountProvider.future);
  final staffCount   = await ref.watch(activeStaffCountProvider.future);
  final usage        = await ref.watch(currentMonthUsageProvider.future);
  return SubscriptionScreenData(
    subscription:       sub,
    activeStudentCount: studentCount,
    activeBatchCount:   batchCount,
    activeStaffCount:   staffCount,
    usage:              usage,
  );
});

// ─── Combined data class ───────────────────────────────────────────────────────

class SubscriptionScreenData {
  final Subscription subscription;
  final int activeStudentCount;
  final int activeBatchCount;
  final int activeStaffCount;
  final Map<String, int> usage;

  const SubscriptionScreenData({
    required this.subscription,
    required this.activeStudentCount,
    required this.activeBatchCount,
    required this.activeStaffCount,
    this.usage = const {},
  });

  // ─── Derived plan object ────────────────────────────────────────────────────

  PlanConfig get plan => PlanConfig.fromTier(subscription.effectivePlan);

  // ─── Student limit ──────────────────────────────────────────────────────────

  /// Usage ratio 0.0–1.0.
  double get studentUsageRatio {
    final max = subscription.currentMaxStudents;
    if (max == 0) return 1.0;
    return (activeStudentCount / max).clamp(0.0, 1.0);
  }

  bool get isNearStudentLimit => studentUsageRatio >= 0.80;
  bool get isAtStudentLimit   => studentUsageRatio >= 1.0;

  /// True if adding one more student is allowed.
  bool get canAddStudent {
    return activeStudentCount < subscription.currentMaxStudents;
  }

  // ─── Batch limit ────────────────────────────────────────────────────────────

  double get batchUsageRatio {
    final max = subscription.currentMaxBatches;
    if (max == 0) return 1.0;
    return (activeBatchCount / max).clamp(0.0, 1.0);
  }

  bool get isAtBatchLimit => batchUsageRatio >= 1.0;

  /// True if adding one more batch is allowed.
  bool get canAddBatch {
    return activeBatchCount < subscription.currentMaxBatches;
  }

  // ─── Staff limit ────────────────────────────────────────────────────────────

  double get staffUsageRatio {
    final max = subscription.currentMaxStaff;
    if (max == 0) return 1.0;
    return (activeStaffCount / max).clamp(0.0, 1.0);
  }

  bool get isNearStaffLimit => staffUsageRatio >= 0.80;
  bool get isAtStaffLimit   => staffUsageRatio >= 1.0;

  /// True if adding one more staff is allowed.
  bool get canAddStaff {
    return activeStaffCount < subscription.currentMaxStaff;
  }

  // ─── WhatsApp Limits ────────────────────────────────────────────────────────

  int get waReceiptsUsed => usage['whatsapp_receipts_used'] ?? 0;
  
  double get waReceiptsUsageRatio {
    final max = subscription.currentWaReceiptsLimit;
    if (max == 0) return 1.0;
    return (waReceiptsUsed / max).clamp(0.0, 1.0);
  }

  bool get isNearWaReceiptsLimit => waReceiptsUsageRatio >= 0.80;
  bool get isAtWaReceiptsLimit   => waReceiptsUsageRatio >= 1.0;

  // ─── Legacy aliases (keep backward compat with old code) ───────────────────
  bool get isNearLimit  => isNearStudentLimit;
  bool get isAtLimit    => isAtStudentLimit;
  double get studentUsage => studentUsageRatio;
}
