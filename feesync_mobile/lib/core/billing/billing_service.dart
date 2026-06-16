import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/subscription.dart';

/// Google Play product IDs — must match Play Console subscriptions.
class BillingProductIds {
  static const String starterMonthly  = 'feesync_starter_monthly';
  static const String starterYearly   = 'feesync_starter_yearly';
  static const String growthMonthly   = 'feesync_growth_monthly';
  static const String growthYearly    = 'feesync_growth_yearly';
  static const String instituteMonthly = 'feesync_institute_monthly';
  static const String instituteYearly  = 'feesync_institute_yearly';

  static const Set<String> all = {
    starterMonthly,
    starterYearly,
    growthMonthly,
    growthYearly,
    instituteMonthly,
    instituteYearly,
  };

  /// Maps a plan tier + billing cycle to the correct product ID.
  static String forPlan(String tier, {bool annual = false}) {
    final cycle = annual ? 'yearly' : 'monthly';
    return 'feesync_${tier}_$cycle';
  }

  /// Extracts the plan tier from a product ID.
  static String tierFromProductId(String productId) {
    if (productId.startsWith('feesync_starter'))  return 'starter';
    if (productId.startsWith('feesync_growth'))   return 'growth';
    if (productId.startsWith('feesync_institute')) return 'institute';
    return 'free';
  }

  /// Extracts the billing cycle from a product ID.
  static String cycleFromProductId(String productId) {
    return productId.endsWith('_yearly') ? 'annual' : 'monthly';
  }
}

/// Result returned after a purchase attempt.
class BillingResult {
  final bool success;
  final String? error;
  final Subscription? updatedSubscription;

  const BillingResult({
    required this.success,
    this.error,
    this.updatedSubscription,
  });

  factory BillingResult.failed(String error) =>
      BillingResult(success: false, error: error);

  factory BillingResult.succeeded(Subscription sub) =>
      BillingResult(success: true, updatedSubscription: sub);
}

/// Wraps the `in_app_purchase` plugin with FeeSync-specific logic.
///
/// Responsibilities:
///   1. Initialize the billing connection.
///   2. Load product details from Google Play.
///   3. Initiate purchase flows and listen for results.
///   4. On successful purchase, call the Supabase `upsert_subscription` RPC
///      to persist the new plan server-side.
///   5. Expose the result via [purchaseResultStream].
class BillingService {
  static final BillingService _instance = BillingService._internal();
  factory BillingService() => _instance;
  BillingService._internal();

  final InAppPurchase _iap = InAppPurchase.instance;

  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;

  /// Products loaded from Google Play.
  final Map<String, ProductDetails> _productDetails = {};

  /// Whether billing is available on this device.
  bool _isAvailable = false;

  bool get isAvailable => _isAvailable;

  // Expose purchase results to the provider layer.
  final _resultController = StreamController<BillingResult>.broadcast();
  Stream<BillingResult> get purchaseResultStream => _resultController.stream;

  // ── Initialization ─────────────────────────────────────────────────────────

  /// Call once at app startup (from BillingProvider).
  Future<void> initialize() async {
    // Billing is only available on Android/iOS.
    if (!Platform.isAndroid && !Platform.isIOS) {
      debugPrint('[Billing] Not available on this platform.');
      return;
    }

    // Cap the entire initialization at 8 s to avoid blocking startup when offline.
    try {
      await _initializeInternal().timeout(
        const Duration(seconds: 8),
        onTimeout: () {
          debugPrint('[Billing] Initialization timed out — billing disabled for this session.');
          _isAvailable = false;
        },
      );
    } catch (e) {
      debugPrint('[Billing] Initialization failed: $e — billing disabled for this session.');
      _isAvailable = false;
    }
  }

  Future<void> _initializeInternal() async {
    try {
      _isAvailable = await _iap.isAvailable();
    } catch (e) {
      debugPrint('[Billing] isAvailable() failed: $e');
      _isAvailable = false;
      return;
    }

    if (!_isAvailable) {
      debugPrint('[Billing] In-app purchases not available.');
      return;
    }

    // Listen for purchase updates.
    _purchaseSubscription?.cancel();
    _purchaseSubscription = _iap.purchaseStream.listen(
      _handlePurchaseUpdates,
      onError: (Object e) {
        debugPrint('[Billing] Purchase stream error: $e');
        _resultController.add(BillingResult.failed('Purchase stream error: $e'));
      },
    );

    // Load product details.
    await _loadProducts();
    debugPrint('[Billing] Initialized. Available products: ${_productDetails.keys}');

    // Restore purchases automatically on app startup.
    try {
      await restorePurchases();
    } catch (e) {
      debugPrint('[Billing] Restore on startup failed: $e');
    }
  }

  Future<void> _loadProducts() async {
    try {
      final response = await _iap.queryProductDetails(BillingProductIds.all);
      if (response.error != null) {
        debugPrint('[Billing] Product query error: ${response.error}');
      }
      for (final p in response.productDetails) {
        _productDetails[p.id] = p;
      }
    } catch (e) {
      debugPrint('[Billing] Failed to load products: $e');
    }
  }

  // ── Purchase ───────────────────────────────────────────────────────────────

  /// Returns the [ProductDetails] for a given product ID, or null.
  ProductDetails? getProduct(String productId) => _productDetails[productId];

  /// Starts a purchase flow for [productId].
  /// Returns false if the product is not found or billing is unavailable.
  Future<bool> purchase(String productId) async {
    if (!_isAvailable) {
      _resultController.add(BillingResult.failed('Billing not available on this device.'));
      return false;
    }
    final product = _productDetails[productId];
    if (product == null) {
      debugPrint('[Billing] Product not found: $productId');
      _resultController.add(BillingResult.failed(
          'Product "$productId" not found. Please check Play Console.'));
      return false;
    }
    final params = PurchaseParam(productDetails: product);
    try {
      // Subscriptions use buyNonConsumable.
      await _iap.buyNonConsumable(purchaseParam: params);
      return true;
    } catch (e) {
      _resultController.add(BillingResult.failed('Could not start purchase: $e'));
      return false;
    }
  }

  /// Restores previous purchases (useful after reinstall).
  Future<void> restorePurchases() async {
    if (!_isAvailable) return;
    try {
      await _iap.restorePurchases();
    } catch (e) {
      debugPrint('[Billing] Restore failed: $e');
    }
  }

  // ── Purchase update handler ────────────────────────────────────────────────

  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          debugPrint('[Billing] Purchase pending: ${purchase.productID}');
          break;

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _verifyAndActivate(purchase);
          break;

        case PurchaseStatus.error:
          debugPrint('[Billing] Purchase error: ${purchase.error}');
          _resultController.add(
              BillingResult.failed(purchase.error?.message ?? 'Unknown error'));
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }
          break;

        case PurchaseStatus.canceled:
          debugPrint('[Billing] Purchase cancelled by user.');
          _resultController.add(BillingResult.failed('Purchase cancelled.'));
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }
          break;
      }
    }
  }

  // ── Server-side verification ───────────────────────────────────────────────

  Future<void> _verifyAndActivate(PurchaseDetails purchase) async {
    try {
      final productId = purchase.productID;
      final tier  = BillingProductIds.tierFromProductId(productId);
      final cycle = BillingProductIds.cycleFromProductId(productId);

      // Duration of validity based on billing cycle.
      final Duration validity = cycle == 'annual'
          ? const Duration(days: 366)
          : const Duration(days: 32);

      final validUntil = DateTime.now().add(validity);

      // Get the purchase token (Android) or transaction ID (iOS).
      final token = purchase.verificationData.serverVerificationData;

      // Call Supabase RPC to persist the subscription server-side.
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final result = await Supabase.instance.client.rpc('upsert_subscription', params: {
        'p_owner_id'           : userId,
        'p_plan_tier'          : tier,
        'p_billing_cycle'      : cycle,
        'p_valid_until'        : validUntil.toIso8601String(),
        'p_google_play_token'  : Platform.isAndroid ? token : null,
        'p_google_play_product': Platform.isAndroid ? productId : null,
      });

      // Complete the purchase with the store so it isn't re-delivered.
      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }

      if (result != null) {
        final updatedSub = Subscription.fromJson(
            Map<String, dynamic>.from(result as Map));
        debugPrint('[Billing] Subscription activated: ${updatedSub.planLabel}');
        _resultController.add(BillingResult.succeeded(updatedSub));
      } else {
        throw Exception('Server returned null after upsert.');
      }
    } catch (e) {
      debugPrint('[Billing] Verification failed: $e');
      _resultController.add(
          BillingResult.failed('Verification failed: $e'));
      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
  }

  // ── Cleanup ────────────────────────────────────────────────────────────────

  void dispose() {
    _purchaseSubscription?.cancel();
    _resultController.close();
  }
}
