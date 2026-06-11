/// Subscription model matching Supabase `subscriptions` table.
///
/// Tiers:
///   free      – 30 students, 2 batches, limited WhatsApp (₹0)
///   starter   – 200 students, 15 batches, unlimited WA (₹199/mo)
///   growth    – unlimited, all AI features, auto-debit (₹499/mo)
///   institute – unlimited + staff accounts + API (₹1,499/mo)
class Subscription {
  final String id;
  final String ownerId;

  /// Plan tier: 'free' | 'starter' | 'growth' | 'institute'
  final String planTier;

  /// Billing cycle: 'monthly' | 'annual'
  final String billingCycle;

  final DateTime? validUntil;

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

  const Subscription({
    required this.id,
    required this.ownerId,
    required this.planTier,
    this.billingCycle = 'monthly',
    this.validUntil,
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
      ownerId: (json['owner_id'] as String?) ?? '',
      planTier: (json['plan_tier'] as String?) ?? 'free',
      billingCycle: (json['billing_cycle'] as String?) ?? 'monthly',
      validUntil: json['valid_until'] != null
          ? DateTime.tryParse(json['valid_until'] as String)
          : null,
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
        'owner_id': ownerId,
        'plan_tier': planTier,
        'billing_cycle': billingCycle,
        'valid_until': validUntil?.toIso8601String(),
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
    if (planTier == 'free') return true;
    if (validUntil == null) return false;
    return validUntil!.isAfter(DateTime.now());
  }

  /// Backward-compatible alias for [isPaidActive].
  bool get isActive => isPaidActive;

  /// Resolved effective plan. Falls back to 'free' when paid plan expires.
  /// Respects active trials — during trial, returns the trialled plan.
  String get effectivePlan {
    if (planTier == 'free') return 'free';
    if (isPaidActive) return planTier;
    if (isTrialActive) return planTier;
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
    switch (planTier) {
      case 'starter':
        return billingCycle == 'annual' ? 149 : 199;
      case 'growth':
        return billingCycle == 'annual' ? 332 : 499;
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
    if (validUntil == null) return null;
    final diff = validUntil!.difference(DateTime.now()).inDays;
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
    final planLimit = SubscriptionPlan.fromTier(effectivePlan).maxStudents;
    if (planLimit < 0 || maxStudents < 0) return -1;
    return maxStudents > planLimit ? maxStudents : planLimit;
  }

  int get currentMaxBatches {
    final planLimit = SubscriptionPlan.fromTier(effectivePlan).maxBatches;
    if (planLimit < 0 || maxBatches < 0) return -1;
    return maxBatches > planLimit ? maxBatches : planLimit;
  }

  int get currentWaReceiptsLimit {
    final planLimit = SubscriptionPlan.fromTier(effectivePlan).whatsappReceiptsPerMonth;
    if (planLimit < 0 || whatsappReceiptsLimit < 0) return -1;
    return whatsappReceiptsLimit > planLimit ? whatsappReceiptsLimit : planLimit;
  }

  int get currentWaRemindersLimit {
    final planLimit = SubscriptionPlan.fromTier(effectivePlan).whatsappRemindersPerMonth;
    if (planLimit < 0 || whatsappRemindersLimit < 0) return -1;
    return whatsappRemindersLimit > planLimit ? whatsappRemindersLimit : planLimit;
  }

  int get currentMaxStaff {
    final planLimit = SubscriptionPlan.fromTier(effectivePlan).maxStaff;
    if (planLimit < 0 || maxStaff < 0) return -1;
    return maxStaff > planLimit ? maxStaff : planLimit;
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
  static Subscription defaultFree(String ownerId) => Subscription(
        id: '',
        ownerId: ownerId,
        planTier: 'free',
        maxStudents: 20,
        maxBatches: 2,
        whatsappReceiptsLimit: 100,
        whatsappRemindersLimit: 30,
        smsLimit: 0,
        maxStaff: 1,
      );

  /// Returns a subscription pre-configured for a 30-day Growth trial.
  static Subscription newUserTrial(String ownerId) => Subscription(
        id: '',
        ownerId: ownerId,
        planTier: 'growth',
        maxStudents: -1,
        maxBatches: -1,
        whatsappReceiptsLimit: -1,
        whatsappRemindersLimit: -1,
        smsLimit: 500,
        maxStaff: -1,
        isTrial: true,
        trialEndsAt: DateTime.now().add(const Duration(days: 30)),
      );

  /// Copy with updated fields.
  Subscription copyWith({
    String? planTier,
    String? billingCycle,
    DateTime? validUntil,
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
      ownerId: ownerId,
      planTier: planTier ?? this.planTier,
      billingCycle: billingCycle ?? this.billingCycle,
      validUntil: validUntil ?? this.validUntil,
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

// ── Static plan definitions ────────────────────────────────────────────────────
/// Used by UI for plan comparison tables and the subscription screen.
class SubscriptionPlan {
  final String tier;
  final String name;
  final String tagline;
  final int monthlyPrice;
  final int annualPrice; // Total annual charge (saves 2 months vs monthly)
  final int annualMonthlyEquivalent; // Per-month cost when billed annually
  final int maxStudents;            // -1 = unlimited
  final int maxBatches;             // -1 = unlimited
  final int whatsappReceiptsPerMonth;  // -1 = unlimited
  final int whatsappRemindersPerMonth; // -1 = unlimited
  final int maxStaff;
  final bool csvExport;
  final bool biometricAuth;
  final bool supportSystem;
  final bool cloudBackup;
  final bool dueReminders;
  final bool invoiceSend;

  const SubscriptionPlan({
    required this.tier,
    required this.name,
    required this.tagline,
    required this.monthlyPrice,
    required this.annualPrice,
    required this.annualMonthlyEquivalent,
    required this.maxStudents,
    required this.maxBatches,
    required this.whatsappReceiptsPerMonth,
    required this.whatsappRemindersPerMonth,
    required this.maxStaff,
    required this.csvExport,
    required this.biometricAuth,
    required this.supportSystem,
    required this.cloudBackup,
    required this.dueReminders,
    required this.invoiceSend,
  });

  // ── Google Play product IDs ──────────────────────────────────────────────
  /// Returns the Google Play product ID for this plan + billing cycle.
  String googlePlayProductId({bool annual = false}) {
    if (tier == 'free') return '';
    final cycle = annual ? 'annual' : 'monthly';
    return 'feesync_${tier}_$cycle';
  }

  // ── Plan constants ─────────────────────────────────────────────────────────

  static const SubscriptionPlan free = SubscriptionPlan(
    tier: 'free',
    name: 'Free',
    tagline: 'Try & Grow',
    monthlyPrice: 0,
    annualPrice: 0,
    annualMonthlyEquivalent: 0,
    maxStudents: 20,
    maxBatches: 2,
    whatsappReceiptsPerMonth: 100,
    whatsappRemindersPerMonth: 30,
    maxStaff: 1,
    csvExport: false,
    biometricAuth: true,
    supportSystem: false,
    cloudBackup: false,
    dueReminders: true,
    invoiceSend: true,
  );

  static const SubscriptionPlan starter = SubscriptionPlan(
    tier: 'starter',
    name: 'Starter',
    tagline: 'Professional Solo Operator',
    monthlyPrice: 299,
    annualPrice: 2990,       // 2 months free vs 299×12=3588
    annualMonthlyEquivalent: 249,
    maxStudents: 150,
    maxBatches: 10,
    whatsappReceiptsPerMonth: -1,
    whatsappRemindersPerMonth: -1,
    maxStaff: 3,
    csvExport: true,
    biometricAuth: true,
    supportSystem: true,
    cloudBackup: true,
    dueReminders: true,
    invoiceSend: true,
  );

  static const SubscriptionPlan growth = SubscriptionPlan(
    tier: 'growth',
    name: 'Growth',
    tagline: 'Scale with Pro',
    monthlyPrice: 999,
    annualPrice: 9990,       // saves vs 999×12=11988
    annualMonthlyEquivalent: 832,
    maxStudents: -1,
    maxBatches: -1,
    whatsappReceiptsPerMonth: -1,
    whatsappRemindersPerMonth: -1,
    maxStaff: -1,
    csvExport: true,
    biometricAuth: true,
    supportSystem: true,
    cloudBackup: true,
    dueReminders: true,
    invoiceSend: true,
  );

  static const SubscriptionPlan institute = SubscriptionPlan(
    tier: 'institute',
    name: 'Institute',
    tagline: 'Multi-Batch Enterprise',
    monthlyPrice: 1499,
    annualPrice: 11999,      // saves ₹5,989 vs 1499×12=17988
    annualMonthlyEquivalent: 1000,
    maxStudents: -1,
    maxBatches: -1,
    whatsappReceiptsPerMonth: -1,
    whatsappRemindersPerMonth: -1,
    maxStaff: -1,
    csvExport: true,
    biometricAuth: true,
    supportSystem: true,
    cloudBackup: true,
    dueReminders: true,
    invoiceSend: true,
  );

  static const List<SubscriptionPlan> all = [
    free,
    starter,
    growth,
    institute,
  ];

  /// Returns the plan definition matching [tier].
  static SubscriptionPlan fromTier(String tier) {
    return all.firstWhere(
      (p) => p.tier == tier,
      orElse: () => free,
    );
  }

  // ── Display helpers ────────────────────────────────────────────────────────

  String get studentsLabel =>
      maxStudents < 0 ? 'Unlimited' : '$maxStudents students';

  String get batchesLabel =>
      maxBatches < 0 ? 'Unlimited' : '$maxBatches batches';

  String get waReceiptsLabel =>
      whatsappReceiptsPerMonth < 0 ? 'Unlimited' : '$whatsappReceiptsPerMonth/mo';

  String get waRemindersLabel =>
      whatsappRemindersPerMonth < 0 ? 'Unlimited' : '$whatsappRemindersPerMonth/mo';

  String get annualSavingLabel {
    if (monthlyPrice == 0) return '';
    final saving = (monthlyPrice * 12) - annualPrice;
    return saving > 0 ? 'Save ₹$saving/year' : '';
  }
}
