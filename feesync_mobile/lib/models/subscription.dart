/// Subscription model matching Supabase `subscriptions` table.
/// Tiers: free (≤50 students), starter (≤200, ₹199/mo), growth (unlimited, ₹499/mo).
class Subscription {
  final String id;
  final String ownerId;
  final String planTier; // 'free' | 'starter' | 'growth'
  final DateTime? validUntil;
  final int maxStudents;
  final String? razorpaySubId;
  final String? googlePlayPurchaseToken;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Subscription({
    required this.id,
    required this.ownerId,
    required this.planTier,
    this.validUntil,
    required this.maxStudents,
    this.razorpaySubId,
    this.googlePlayPurchaseToken,
    this.createdAt,
    this.updatedAt,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      planTier: (json['plan_tier'] as String?) ?? 'free',
      validUntil: json['valid_until'] != null
          ? DateTime.tryParse(json['valid_until'] as String)
          : null,
      maxStudents: (json['max_students'] as int?) ?? 50,
      razorpaySubId: json['razorpay_sub_id'] as String?,
      googlePlayPurchaseToken: json['google_play_purchase_token'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'owner_id': ownerId,
        'plan_tier': planTier,
        'valid_until': validUntil?.toIso8601String(),
        'max_students': maxStudents,
        'razorpay_sub_id': razorpaySubId,
        'google_play_purchase_token': googlePlayPurchaseToken,
      };

  /// Whether the subscription is currently active (not expired).
  bool get isActive {
    if (planTier == 'free') return true; // Free never expires
    if (validUntil == null) return false;
    return validUntil!.isAfter(DateTime.now());
  }

  /// Resolved effective plan (falls back to 'free' if expired paid plan).
  String get effectivePlan {
    if (planTier == 'free') return 'free';
    if (!isActive) return 'free';
    return planTier;
  }

  /// Human-readable plan label.
  String get planLabel {
    switch (effectivePlan) {
      case 'starter':
        return 'Starter';
      case 'growth':
        return 'Growth';
      default:
        return 'Free';
    }
  }

  /// Monthly price in INR for display.
  int get monthlyPriceInr {
    switch (planTier) {
      case 'starter':
        return 199;
      case 'growth':
        return 499;
      default:
        return 0;
    }
  }

  /// Whether the user is on the free plan.
  bool get isFree => effectivePlan == 'free';

  /// Whether the user is on the starter plan.
  bool get isStarter => effectivePlan == 'starter';

  /// Whether the user is on the growth plan.
  bool get isGrowth => effectivePlan == 'growth';

  /// Days remaining until expiry (null for free / no expiry).
  int? get daysRemaining {
    if (validUntil == null) return null;
    final diff = validUntil!.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

  /// Default free-tier subscription (used as fallback when DB has no record).
  static Subscription defaultFree(String ownerId) => Subscription(
        id: '',
        ownerId: ownerId,
        planTier: 'free',
        maxStudents: 20,
      );

  /// Copy with updated fields.
  Subscription copyWith({
    String? planTier,
    DateTime? validUntil,
    int? maxStudents,
    String? razorpaySubId,
    String? googlePlayPurchaseToken,
  }) {
    return Subscription(
      id: id,
      ownerId: ownerId,
      planTier: planTier ?? this.planTier,
      validUntil: validUntil ?? this.validUntil,
      maxStudents: maxStudents ?? this.maxStudents,
      razorpaySubId: razorpaySubId ?? this.razorpaySubId,
      googlePlayPurchaseToken:
          googlePlayPurchaseToken ?? this.googlePlayPurchaseToken,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

/// Static plan definitions for UI comparisons.
class SubscriptionPlan {
  final String tier;
  final String name;
  final int monthlyPrice;
  final int annualPrice; // effectively 10 months (2 months free)
  final int maxStudents; // -1 means unlimited
  final int maxBatches;  // -1 means unlimited
  final int whatsappReceiptsPerMonth; // -1 = unlimited
  final int whatsappRemindersPerMonth; // -1 = unlimited
  final int smsPerMonth;
  final int aiFeatures;
  final int reportCount;
  final bool csvExport;
  final bool razorpayPaymentLinks;
  final bool razorpayAutoDebit;
  final bool scheduledEmailReports;
  final bool prioritySupport;
  final bool whatsappSupport;

  const SubscriptionPlan({
    required this.tier,
    required this.name,
    required this.monthlyPrice,
    required this.annualPrice,
    required this.maxStudents,
    required this.maxBatches,
    required this.whatsappReceiptsPerMonth,
    required this.whatsappRemindersPerMonth,
    required this.smsPerMonth,
    required this.aiFeatures,
    required this.reportCount,
    required this.csvExport,
    required this.razorpayPaymentLinks,
    required this.razorpayAutoDebit,
    required this.scheduledEmailReports,
    required this.prioritySupport,
    required this.whatsappSupport,
  });

  static const SubscriptionPlan free = SubscriptionPlan(
    tier: 'free',
    name: 'Free',
    monthlyPrice: 0,
    annualPrice: 0,
    maxStudents: 20,
    maxBatches: 1,
    whatsappReceiptsPerMonth: 200,
    whatsappRemindersPerMonth: 50,
    smsPerMonth: 0,
    aiFeatures: 0,
    reportCount: 5,
    csvExport: false,
    razorpayPaymentLinks: false,
    razorpayAutoDebit: false,
    scheduledEmailReports: false,
    prioritySupport: false,
    whatsappSupport: false,
  );

  static const SubscriptionPlan starter = SubscriptionPlan(
    tier: 'starter',
    name: 'Starter',
    monthlyPrice: 199,
    annualPrice: 1990,
    maxStudents: 200,
    maxBatches: 10,
    whatsappReceiptsPerMonth: -1,
    whatsappRemindersPerMonth: -1,
    smsPerMonth: 100,
    aiFeatures: 3,
    reportCount: 14,
    csvExport: true,
    razorpayPaymentLinks: true,
    razorpayAutoDebit: false,
    scheduledEmailReports: false,
    prioritySupport: false,
    whatsappSupport: false,
  );

  static const SubscriptionPlan growth = SubscriptionPlan(
    tier: 'growth',
    name: 'Growth',
    monthlyPrice: 499,
    annualPrice: 4990,
    maxStudents: -1,
    maxBatches: -1,
    whatsappReceiptsPerMonth: -1,
    whatsappRemindersPerMonth: -1,
    smsPerMonth: 500,
    aiFeatures: 9,
    reportCount: 14,
    csvExport: true,
    razorpayPaymentLinks: true,
    razorpayAutoDebit: true,
    scheduledEmailReports: true,
    prioritySupport: true,
    whatsappSupport: true,
  );

  static const List<SubscriptionPlan> all = [free, starter, growth];
}
