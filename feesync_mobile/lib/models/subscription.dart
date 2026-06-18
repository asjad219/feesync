import '../core/billing/plan_config.dart';

/// Subscription model matching Supabase `subscriptions` table.
///
///   free      – 20 students, 2 batches, 2 staff, 100 WhatsApp (₹0)
///   starter   – 200 students, 10 batches, 5 staff, 2000 WhatsApp (₹299/mo)
///   growth    – 500 students, 50 batches, 10 staff, 5000 WhatsApp (₹999/mo)
///   institute – 5000 students, 500 batches, 50 staff, 50000 WhatsApp (₹1,499/mo)
class Subscription {
  final String id;
  final String userId;

  /// Plan type: 'free' | 'starter' | 'growth' | 'institute'
  final String planType;

  /// Billing cycle: 'monthly' | 'annual'
  final String billingCycle;

  final DateTime? expiryDate;
  final String status;
  final DateTime startDate;

  // --- Limits (stored from DB, override via upsert_subscription RPC) ---
  final int maxStudents;          // -1 = unlimited
  final int maxBatches;           // -1 = unlimited
  final int whatsappReceiptsLimit;  // -1 = unlimited
  final int whatsappRemindersLimit; // -1 = unlimited
  final int smsLimit;             // -1 = unlimited
  final int maxStaff;             // -1 = unlimited

  // --- Payment tokens ---
  final String? razorpaySubId;
  final String? razorpayPaymentId;
  final String? googlePlayPurchaseToken;
  final String? googlePlayProductId;

  // --- Trial ---
  final DateTime? trialEndsAt;
  final bool isTrial;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Backward compatibility getters
  String get ownerId => userId;
  String get planTier => planType;
  DateTime? get validUntil => expiryDate;

  const Subscription({
    required this.id,
    required this.userId,
    required this.planType,
    this.billingCycle = 'monthly',
    this.expiryDate,
    this.status = 'active',
    required this.startDate,
    required this.maxStudents,
    required this.maxBatches,
    this.whatsappReceiptsLimit = 100,
    this.whatsappRemindersLimit = 30,
    this.smsLimit = 0,
    this.maxStaff = 1,
    this.razorpaySubId,
    this.razorpayPaymentId,
    this.googlePlayPurchaseToken,
    this.googlePlayProductId,
    this.trialEndsAt,
    this.isTrial = false,
    this.createdAt,
    this.updatedAt,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: (json['id'] as String?) ?? '',
      userId: (json['user_id'] as String?) ?? (json['owner_id'] as String?) ?? '',
      planType: (json['plan_type'] as String?) ?? (json['plan_tier'] as String?) ?? 'free',
      billingCycle: (json['billing_cycle'] as String?) ?? 'monthly',
      expiryDate: json['expiry_date'] != null
          ? DateTime.tryParse(json['expiry_date'] as String)
          : json['valid_until'] != null
              ? DateTime.tryParse(json['valid_until'] as String)
              : null,
      status: (json['status'] as String?) ?? 'active',
      startDate: json['start_date'] != null
          ? DateTime.tryParse(json['start_date'] as String) ?? DateTime.now()
          : DateTime.now(),
      maxStudents: (json['max_students'] as int?) ?? 20,
      maxBatches: (json['max_batches'] as int?) ?? 2,
      whatsappReceiptsLimit:
          (json['whatsapp_receipts_limit'] as int?) ?? 100,
      whatsappRemindersLimit:
          (json['whatsapp_reminders_limit'] as int?) ?? 30,
      smsLimit: (json['sms_limit'] as int?) ?? 0,
      maxStaff: (json['max_staff'] as int?) ?? 1,
      razorpaySubId: json['razorpay_sub_id'] as String?,
      razorpayPaymentId: json['razorpay_payment_id'] as String?,
      googlePlayPurchaseToken:
          json['google_play_purchase_token'] as String?,
      googlePlayProductId: json['google_play_product_id'] as String?,
      trialEndsAt: json['trial_ends_at'] != null
          ? DateTime.tryParse(json['trial_ends_at'] as String)
          : null,
      isTrial: (json['is_trial'] as bool?) ?? false,
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
        'user_id': userId,
        'plan_type': planType,
        'billing_cycle': billingCycle,
        'expiry_date': expiryDate?.toIso8601String(),
        'status': status,
        'start_date': startDate.toIso8601String(),
        'max_students': maxStudents,
        'max_batches': maxBatches,
        'whatsapp_receipts_limit': whatsappReceiptsLimit,
        'whatsapp_reminders_limit': whatsappRemindersLimit,
        'sms_limit': smsLimit,
        'max_staff': maxStaff,
        'razorpay_sub_id': razorpaySubId,
        'razorpay_payment_id': razorpayPaymentId,
        'google_play_purchase_token': googlePlayPurchaseToken,
        'google_play_product_id': googlePlayProductId,
        'trial_ends_at': trialEndsAt?.toIso8601String(),
        'is_trial': isTrial,
      };

  // ── Computed properties ────────────────────────────────────────────────────

  /// True if the trial period is still active.
  bool get isTrialActive {
    if (!isTrial || trialEndsAt == null) return false;
    return trialEndsAt!.isAfter(DateTime.now());
  }

  /// True if the paid subscription has not expired.
  bool get isPaidActive {
    if (planType == 'free') return true;
    if (status != 'active') return false;
    if (expiryDate == null) return false;
    return expiryDate!.isAfter(DateTime.now());
  }

  /// Backward-compatible alias for [isPaidActive].
  bool get isActive => isPaidActive;

  /// Resolved effective plan. Falls back to 'free' when paid plan expires.
  /// Respects active trials — during trial, returns the trialled plan.
  String get effectivePlan {
    if (planType == 'free') return 'free';
    if (isPaidActive) return planType;
    if (isTrialActive) return planType;
    return 'free';
  }

  /// True if the subscription allows unlimited staff.
  bool get hasUnlimitedStaff => maxStaff < 0;

  /// Human-readable plan label.
  String get planLabel {
    switch (effectivePlan) {
      case 'starter':
        return 'Starter';
      case 'growth':
        return 'Growth';
      case 'institute':
        return 'Institute';
      default:
        return 'Free';
    }
  }

  /// Monthly price in INR for the current plan.
  int get monthlyPriceInr {
    switch (planType) {
      case 'starter':
        return billingCycle == 'annual' ? 249 : 299;
      case 'growth':
        return billingCycle == 'annual' ? 832 : 999;
      case 'institute':
        return billingCycle == 'annual' ? 1000 : 1499;
      default:
        return 0;
    }
  }

  /// Convenience booleans.
  bool get isFree => effectivePlan == 'free';
  bool get isStarter => effectivePlan == 'starter';
  bool get isGrowth => effectivePlan == 'growth';
  bool get isInstitute => effectivePlan == 'institute';

  /// Whether any paid plan is active (including trial).
  bool get hasPaidAccess => !isFree;

  /// Days remaining until expiry. Returns null for free plan.
  int? get daysRemaining {
    if (expiryDate == null) return null;
    final diff = expiryDate!.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

  /// Whether the plan is expiring within the next 7 days.
  bool get isExpiringSoon {
    final days = daysRemaining;
    if (days == null) return false;
    return days <= 7;
  }

  // ── Resolved effective limits ──────────────────────────────────────────────
  
  int get currentMaxStudents {
    if (effectivePlan == 'free' && planType != 'free') {
      return PlanConfig.free.maxStudents;
    }
    return maxStudents;
  }

  int get currentMaxBatches {
    if (effectivePlan == 'free' && planType != 'free') {
      return PlanConfig.free.maxBatches;
    }
    return maxBatches;
  }

  int get currentWaReceiptsLimit {
    if (effectivePlan == 'free' && planType != 'free') {
      return PlanConfig.free.whatsappReceiptsPerMonth;
    }
    return whatsappReceiptsLimit;
  }

  int get currentWaRemindersLimit {
    if (effectivePlan == 'free' && planType != 'free') {
      return PlanConfig.free.whatsappRemindersPerMonth;
    }
    return whatsappRemindersLimit;
  }

  int get currentMaxStaff {
    if (effectivePlan == 'free' && planType != 'free') {
      return PlanConfig.free.maxStaff;
    }
    return maxStaff;
  }

  /// True if unlimited students are allowed.
  bool get hasUnlimitedStudents => currentMaxStudents < 0;

  /// True if unlimited batches are allowed.
  bool get hasUnlimitedBatches => currentMaxBatches < 0;

  /// True if unlimited WhatsApp receipts are allowed.
  bool get hasUnlimitedWaReceipts => currentWaReceiptsLimit < 0;

  /// True if unlimited WhatsApp reminders are allowed.
  bool get hasUnlimitedWaReminders => currentWaRemindersLimit < 0;

  // ── Feature gates by effective plan ───────────────────────────────────────

  bool get canExportCsv =>
      effectivePlan != 'free';

  // ── Defaults ───────────────────────────────────────────────────────────────

  /// Default free-tier subscription (used when DB has no record yet).
  static Subscription defaultFree(String userId) => Subscription(
        id: '',
        userId: userId,
        planType: 'free',
        maxStudents: 20,
        maxBatches: 2,
        whatsappReceiptsLimit: 100,
        whatsappRemindersLimit: 30,
        smsLimit: 0,
        maxStaff: 1,
        startDate: DateTime.now(),
      );

  /// Returns a subscription pre-configured for a 30-day Growth trial.
  static Subscription newUserTrial(String userId) => Subscription(
        id: '',
        userId: userId,
        planType: 'growth',
        maxStudents: -1,
        maxBatches: -1,
        whatsappReceiptsLimit: -1,
        whatsappRemindersLimit: -1,
        smsLimit: 500,
        maxStaff: -1,
        isTrial: true,
        trialEndsAt: DateTime.now().add(const Duration(days: 30)),
        startDate: DateTime.now(),
      );

  /// Copy with updated fields.
  Subscription copyWith({
    String? planType,
    String? billingCycle,
    DateTime? expiryDate,
    String? status,
    DateTime? startDate,
    int? maxStudents,
    int? maxBatches,
    int? whatsappReceiptsLimit,
    int? whatsappRemindersLimit,
    int? smsLimit,
    int? maxStaff,
    String? razorpaySubId,
    String? razorpayPaymentId,
    String? googlePlayPurchaseToken,
    String? googlePlayProductId,
    DateTime? trialEndsAt,
    bool? isTrial,
  }) {
    return Subscription(
      id: id,
      userId: userId,
      planType: planType ?? this.planType,
      billingCycle: billingCycle ?? this.billingCycle,
      expiryDate: expiryDate ?? this.expiryDate,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      maxStudents: maxStudents ?? this.maxStudents,
      maxBatches: maxBatches ?? this.maxBatches,
      whatsappReceiptsLimit:
          whatsappReceiptsLimit ?? this.whatsappReceiptsLimit,
      whatsappRemindersLimit:
          whatsappRemindersLimit ?? this.whatsappRemindersLimit,
      smsLimit: smsLimit ?? this.smsLimit,
      maxStaff: maxStaff ?? this.maxStaff,
      razorpaySubId: razorpaySubId ?? this.razorpaySubId,
      razorpayPaymentId: razorpayPaymentId ?? this.razorpayPaymentId,
      googlePlayPurchaseToken:
          googlePlayPurchaseToken ?? this.googlePlayPurchaseToken,
      googlePlayProductId:
          googlePlayProductId ?? this.googlePlayProductId,
      trialEndsAt: trialEndsAt ?? this.trialEndsAt,
      isTrial: isTrial ?? this.isTrial,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

