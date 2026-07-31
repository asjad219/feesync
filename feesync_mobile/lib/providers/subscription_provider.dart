import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../models/subscription.dart';
import '../repositories/subscription_repository.dart';
import '../core/billing/feature_gate.dart';
import '../core/billing/quota_checker.dart';
import '../core/billing/revenue_cat_provider.dart';
import '../core/billing/subscription_mapper.dart';
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
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return Subscription.defaultFree('');

  // Watch RC stream so provider re-evaluates on every CustomerInfo update:
  ref.watch(customerInfoStreamProvider);
  
  CustomerInfo? customerInfo;
  try {
    customerInfo = await ref.watch(customerInfoProvider.future);
  } catch (_) {
    // RC network error: fall back to Supabase mirror to avoid downgrading a paid user
    return ref.watch(subscriptionRepositoryProvider).getSubscription();
  }
  
  final mapped = SubscriptionMapper.fromCustomerInfo(customerInfo, userId);
  if (mapped == null) {
    // RC not initialized yet — fall back to Supabase mirror
    return ref.watch(subscriptionRepositoryProvider).getSubscription();
  }

  // Option C: Use Supabase mirror as fallback for existing subscribers
  if (mapped.planType == 'free') {
    final dbSub = await ref.watch(subscriptionRepositoryProvider).getSubscription();
    if (dbSub.planType != 'free' && dbSub.expiryDate != null && dbSub.expiryDate!.isAfter(DateTime.now())) {
      return dbSub;
    }
  }

  return mapped;
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

  /// Usage ratio 0.0–1.0. Returns 0.0 for unlimited (-1) so the progress bar
  /// appears empty, and 1.0 for unavailable (0) so the bar appears full.
  double get studentUsageRatio => QuotaChecker.usageRatio(
        activeStudentCount, subscription.currentMaxStudents);

  bool get isNearStudentLimit => studentUsageRatio >= 0.80;
  bool get isAtStudentLimit   => !canAddStudent;

  /// True if adding one more student is allowed.
  /// Correctly handles -1 (unlimited) and 0 (unavailable) sentinels.
  bool get canAddStudent => QuotaChecker.canCreate(
        activeStudentCount, subscription.currentMaxStudents);

  // ─── Batch limit ────────────────────────────────────────────────────────────

  double get batchUsageRatio => QuotaChecker.usageRatio(
        activeBatchCount, subscription.currentMaxBatches);

  bool get isAtBatchLimit => !canAddBatch;

  /// True if adding one more batch is allowed.
  /// Correctly handles -1 (unlimited) and 0 (unavailable) sentinels.
  bool get canAddBatch => QuotaChecker.canCreate(
        activeBatchCount, subscription.currentMaxBatches);

  // ─── Staff limit ────────────────────────────────────────────────────────────

  double get staffUsageRatio => QuotaChecker.usageRatio(
        activeStaffCount, subscription.currentMaxStaff);

  bool get isNearStaffLimit => staffUsageRatio >= 0.80;
  bool get isAtStaffLimit   => !canAddStaff;

  /// True if adding one more staff is allowed.
  /// Correctly handles -1 (unlimited) and 0 (unavailable) sentinels.
  bool get canAddStaff => QuotaChecker.canCreate(
        activeStaffCount, subscription.currentMaxStaff);

  // ─── WhatsApp Limits ────────────────────────────────────────────────────────

  int get waReceiptsUsed => usage['whatsapp_receipts_used'] ?? 0;

  double get waReceiptsUsageRatio => QuotaChecker.usageRatio(
        waReceiptsUsed, subscription.currentWaReceiptsLimit);

  bool get isNearWaReceiptsLimit => waReceiptsUsageRatio >= 0.80;
  bool get isAtWaReceiptsLimit   => QuotaChecker.hasReachedLimit(
        waReceiptsUsed, subscription.currentWaReceiptsLimit);

  // ─── Legacy aliases (keep backward compat with old code) ───────────────────
  bool get isNearLimit  => isNearStudentLimit;
  bool get isAtLimit    => isAtStudentLimit;
  double get studentUsage => studentUsageRatio;
}
