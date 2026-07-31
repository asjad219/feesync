import 'package:purchases_flutter/purchases_flutter.dart';
import '../../models/subscription.dart';
import 'plan_config.dart';

class SubscriptionMapper {
  /// Maps RevenueCat CustomerInfo to FeeSync Subscription domain model.
  /// Precedence: Institute > growth > starter > free.
  /// NEVER returns a paid plan on error — returns null to signal loading/error.
  static Subscription? fromCustomerInfo(CustomerInfo? info, String userId) {
    if (info == null) return null; // loading — caller uses Supabase mirror or shows loading
    
    final entitlements = info.entitlements.active;
    
    String planType = 'free';
    String? entitlementId;
    
    // Precedence check (highest first):
    if (entitlements.containsKey('Institute')) {
      planType = 'institute';
      entitlementId = 'Institute';
    } else if (entitlements.containsKey('growth')) {
      planType = 'growth';
      entitlementId = 'growth';
    } else if (entitlements.containsKey('starter')) {
      planType = 'starter';
      entitlementId = 'starter';
    }
    
    final config = PlanConfig.fromTier(planType);
    final activeEntitlement = entitlementId != null ? entitlements[entitlementId] : null;
    
    return Subscription(
      id: info.originalAppUserId,
      userId: userId,
      planType: planType,
      billingCycle: _extractBillingCycle(activeEntitlement),
      expiryDate: activeEntitlement?.expirationDate != null 
          ? DateTime.parse(activeEntitlement!.expirationDate!)
          : null,
      status: 'active',
      startDate: activeEntitlement?.latestPurchaseDate != null 
          ? DateTime.parse(activeEntitlement!.latestPurchaseDate!)
          : DateTime.now(),
      maxStudents: config.maxStudents,
      maxBatches: config.maxBatches,
      whatsappReceiptsLimit: config.whatsappReceiptsPerMonth,
      whatsappRemindersLimit: config.whatsappRemindersPerMonth,
      smsLimit: 0,
      maxStaff: config.maxStaff,
      revenueCatEntitlementId: entitlementId,
    );
  }

  static String _extractBillingCycle(EntitlementInfo? entitlement) {
    if (entitlement == null) return 'monthly';
    final pId = entitlement.productIdentifier;
    if (pId.contains('annual') || pId.contains('yearly')) return 'annual';
    return 'monthly';
  }
}
