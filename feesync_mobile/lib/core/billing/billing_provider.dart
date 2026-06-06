import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'billing_service.dart';
import '../../providers/subscription_provider.dart';

/// Singleton BillingService exposed as a Riverpod provider.
final billingServiceProvider = Provider<BillingService>((ref) {
  final service = BillingService();
  ref.onDispose(service.dispose);
  return service;
});

/// Initializes the billing service once at app startup.
/// Usage: `ref.watch(billingInitProvider)` inside ProviderScope.
final billingInitProvider = FutureProvider<void>((ref) async {
  final service = ref.watch(billingServiceProvider);
  await service.initialize();

  // Listen to purchase results and update the subscription in real-time.
  final sub = service.purchaseResultStream.listen((result) {
    if (result.success && result.updatedSubscription != null) {
      // Invalidate the subscription provider so the UI refreshes.
      ref.invalidate(subscriptionProvider);
    }
  });
  ref.onDispose(sub.cancel);
});

/// Exposes the stream of billing results so screens can react.
final billingResultStreamProvider = StreamProvider<BillingResult>((ref) {
  final service = ref.watch(billingServiceProvider);
  return service.purchaseResultStream;
});

/// State notifier for managing a purchase flow.
/// Usage: call `ref.read(purchaseControllerProvider.notifier).purchase(productId)`.
class PurchaseController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  /// Initiates a purchase for the given Google Play product ID.
  Future<bool> purchase(String productId) async {
    state = const AsyncLoading();
    final service = ref.read(billingServiceProvider);
    try {
      final started = await service.purchase(productId);
      state = const AsyncData(null);
      return started;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  /// Restores previous purchases after reinstall.
  Future<void> restore() async {
    state = const AsyncLoading();
    final service = ref.read(billingServiceProvider);
    try {
      await service.restorePurchases();
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final purchaseControllerProvider =
    AsyncNotifierProvider<PurchaseController, void>(PurchaseController.new);
