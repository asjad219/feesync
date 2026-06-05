import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/subscription.dart';
import '../repositories/subscription_repository.dart';
import 'supabase_provider.dart';

// ─── Repository provider ──────────────────────────────────────────────────────

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SubscriptionRepository(client);
});

// ─── Subscription data providers ─────────────────────────────────────────────

/// Provides the current user's subscription record.
/// Gracefully returns a Free plan if no DB record exists.
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

// ─── Combined state for subscription screen ───────────────────────────────────

/// Bundles subscription + student count + batch count for the subscription screen.
final subscriptionScreenDataProvider =
    FutureProvider<SubscriptionScreenData>((ref) async {
  final sub = await ref.watch(subscriptionProvider.future);
  final studentCount = await ref.watch(activeStudentCountProvider.future);
  final batchCount = await ref.watch(activeBatchCountProvider.future);
  return SubscriptionScreenData(
    subscription: sub,
    activeStudentCount: studentCount,
    activeBatchCount: batchCount,
  );
});

class SubscriptionScreenData {
  final Subscription subscription;
  final int activeStudentCount;
  final int activeBatchCount;

  const SubscriptionScreenData({
    required this.subscription,
    required this.activeStudentCount,
    required this.activeBatchCount,
  });

  // ─── Plan limits helper ───────────────────────────────────────────────────

  SubscriptionPlan get _plan => SubscriptionPlan.all.firstWhere(
        (p) => p.tier == subscription.effectivePlan,
        orElse: () => SubscriptionPlan.free,
      );

  // ─── Student limit ────────────────────────────────────────────────────────

  /// Usage ratio 0.0–1.0 (capped at 1.0). Returns 0 for unlimited plans.
  double get studentUsageRatio {
    final max = subscription.maxStudents;
    if (max <= 0) return 0.0;
    return (activeStudentCount / max).clamp(0.0, 1.0);
  }

  bool get isNearStudentLimit => studentUsageRatio >= 0.90;
  bool get isAtStudentLimit => studentUsageRatio >= 1.0;

  /// True if adding one more student would exceed the plan limit.
  bool get canAddStudent {
    final max = _plan.maxStudents;
    if (max <= 0) return true; // unlimited
    return activeStudentCount < max;
  }

  // ─── Batch limit ──────────────────────────────────────────────────────────

  double get batchUsageRatio {
    final max = _plan.maxBatches;
    if (max <= 0) return 0.0;
    return (activeBatchCount / max).clamp(0.0, 1.0);
  }

  bool get isAtBatchLimit => batchUsageRatio >= 1.0;

  /// True if adding one more batch would exceed the plan limit.
  bool get canAddBatch {
    final max = _plan.maxBatches;
    if (max <= 0) return true; // unlimited
    return activeBatchCount < max;
  }

  // ─── Legacy aliases (used by subscription screen) ─────────────────────────
  bool get isNearLimit => isNearStudentLimit;
  bool get isAtLimit => isAtStudentLimit;
  double get studentUsage => studentUsageRatio;
}
