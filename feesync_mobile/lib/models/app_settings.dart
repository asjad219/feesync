class AppSettings {
  final String id;
  final String accountId;
  final String centerName;
  final String? centerAddress;
  final String? centerPhone;
  final String? centerEmail;
  final String? centerWebsite;
  final String? gstin;
  final String academicYear;
  final String currency;
  final String timezone;
  final bool gstEnabled;
  final bool qrVerificationEnabled;
  final bool parentPortalEnabled;
  final bool digitalSignatureEnabled;
  final int defaultDueDay;
  final bool autoDueGeneration;
  final bool lateFinesEnabled;
  final double lateFineAmount;
  final int gracePeriodDays;
  final bool partialPaymentsAllowed;
  final bool aiRemindersEnabled;
  final bool aiPredictionsEnabled;
  final bool ocrEnabled;
  final bool whatsappEnabled;
  final bool smsFallbackEnabled;
  final bool autoReceiptEnabled;
  final int reminderDaysBefore;
  final String themeMode;
  final String dashboardLayout;
  final bool glassEffectsEnabled;

  // New Billing Settings
  final bool earlyPaymentDiscountEnabled;
  final double earlyPaymentDiscountPercent;
  final String earlyPaymentDiscountType;
  final int earlyPaymentDays;
  final bool convenienceFeeEnabled;
  final double convenienceFeePercent;
  final double taxPercentage;
  final String taxMode;
  final String lateFineType;

  // Message Templates
  final String tplFeeReminder;
  final String tplPaymentReceipt;
  final String tplOverdueNotice;
  final String tplLateFineApplied;
  final String tplNewFeeGenerated;

  AppSettings({
    required this.id,
    required this.accountId,
    required this.centerName,
    this.centerAddress,
    this.centerPhone,
    this.centerEmail,
    this.centerWebsite,
    this.gstin,
    required this.academicYear,
    required this.currency,
    required this.timezone,
    required this.gstEnabled,
    required this.qrVerificationEnabled,
    required this.parentPortalEnabled,
    required this.digitalSignatureEnabled,
    required this.defaultDueDay,
    required this.autoDueGeneration,
    required this.lateFinesEnabled,
    required this.lateFineAmount,
    required this.gracePeriodDays,
    required this.partialPaymentsAllowed,
    required this.aiRemindersEnabled,
    required this.aiPredictionsEnabled,
    required this.ocrEnabled,
    required this.whatsappEnabled,
    required this.smsFallbackEnabled,
    required this.autoReceiptEnabled,
    required this.reminderDaysBefore,
    required this.themeMode,
    required this.dashboardLayout,
    required this.glassEffectsEnabled,
    this.earlyPaymentDiscountEnabled = false,
    this.earlyPaymentDiscountPercent = 0.0,
    this.earlyPaymentDiscountType = 'percentage',
    this.earlyPaymentDays = 0,
    this.convenienceFeeEnabled = false,
    this.convenienceFeePercent = 0.0,
    this.taxPercentage = 18.0,
    this.taxMode = 'exclusive',
    this.lateFineType = 'fixed',
    required this.tplFeeReminder,
    required this.tplPaymentReceipt,
    required this.tplOverdueNotice,
    required this.tplLateFineApplied,
    required this.tplNewFeeGenerated,
  });

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      id: json['id'],
      accountId: json['account_id'],
      centerName: json['center_name'] ?? '',
      centerAddress: json['center_address'],
      centerPhone: json['center_phone'],
      centerEmail: json['center_email'],
      centerWebsite: json['center_website'],
      gstin: json['gstin'],
      academicYear: json['academic_year'] ?? '2024-25',
      currency: json['currency'] ?? 'INR',
      timezone: json['timezone'] ?? 'IST',
      gstEnabled: json['gst_enabled'] ?? true,
      qrVerificationEnabled: json['qr_verification_enabled'] ?? true,
      parentPortalEnabled: json['parent_portal_enabled'] ?? true,
      digitalSignatureEnabled: json['digital_signature_enabled'] ?? false,
      defaultDueDay: json['default_due_day'] ?? 5,
      autoDueGeneration: json['auto_due_generation'] ?? true,
      lateFinesEnabled: json['late_fines_enabled'] ?? true,
      lateFineAmount: double.parse((json['late_fine_amount'] ?? 100).toString()),
      gracePeriodDays: json['grace_period_days'] ?? 3,
      partialPaymentsAllowed: json['partial_payments_allowed'] ?? true,
      aiRemindersEnabled: json['ai_reminders_enabled'] ?? true,
      aiPredictionsEnabled: json['ai_predictions_enabled'] ?? true,
      ocrEnabled: json['ocr_enabled'] ?? true,
      whatsappEnabled: json['whatsapp_enabled'] ?? true,
      smsFallbackEnabled: json['sms_fallback_enabled'] ?? true,
      autoReceiptEnabled: json['auto_receipt_enabled'] ?? true,
      reminderDaysBefore: json['reminder_days_before'] ?? 3,
      themeMode: json['theme_mode'] ?? 'dark_luxury',
      dashboardLayout: json['dashboard_layout'] ?? 'bento',
      glassEffectsEnabled: json['glass_effects_enabled'] ?? true,
      earlyPaymentDiscountEnabled: json['early_payment_discount_enabled'] ?? false,
      earlyPaymentDiscountPercent: double.parse((json['early_payment_discount_percent'] ?? 0).toString()),
      earlyPaymentDiscountType: json['early_payment_discount_type'] ?? 'percentage',
      earlyPaymentDays: json['early_payment_days'] ?? 0,
      convenienceFeeEnabled: json['convenience_fee_enabled'] ?? false,
      convenienceFeePercent: double.parse((json['convenience_fee_percent'] ?? 0).toString()),
      taxPercentage: double.parse((json['tax_percentage'] ?? 18).toString()),
      taxMode: json['tax_mode'] ?? 'exclusive',
      lateFineType: json['late_fine_type'] ?? 'fixed',
      tplFeeReminder: json['tpl_fee_reminder'] ??
          'Hi {parent_name}, this is a reminder that a fee of ₹{amount} is due for {student_name} on {due_date}. Please pay on time to avoid late charges. — {school_name}',
      tplPaymentReceipt: json['tpl_payment_receipt'] ??
          'Dear {parent_name}, we have received ₹{amount} for {student_name} (Receipt #{receipt_no}). Thank you for your timely payment. — {school_name}',
      tplOverdueNotice: json['tpl_overdue_notice'] ??
          'URGENT: The fee of ₹{amount} for {student_name} is overdue by {days_overdue} day(s). Please clear the dues immediately to avoid further penalties. — {school_name}',
      tplLateFineApplied: json['tpl_late_fine_applied'] ??
          'Dear {parent_name}, a late fine of ₹{fine_amount} has been applied to {student_name}\'s account as the fee was not paid within the grace period. Total due: ₹{amount}. — {school_name}',
      tplNewFeeGenerated: json['tpl_new_fee_generated'] ??
          'Dear {parent_name}, a new monthly fee of ₹{amount} has been generated for {student_name} due on {due_date}. — {school_name}',
    );
  }

  /// Returns a safe in-memory default when Supabase is unreachable (e.g. offline).
  /// The dummy id/accountId prevent null-pointer errors downstream; real data
  /// will load once connectivity is restored and providers are invalidated.
  factory AppSettings.defaults() {
    return AppSettings(
      id: 'offline-default',
      accountId: 'offline-default',
      centerName: 'FeeSync',
      academicYear: '2024-25',
      currency: 'INR',
      timezone: 'IST',
      gstEnabled: false,
      qrVerificationEnabled: false,
      parentPortalEnabled: false,
      digitalSignatureEnabled: false,
      defaultDueDay: 5,
      autoDueGeneration: false,
      lateFinesEnabled: false,
      lateFineAmount: 0,
      gracePeriodDays: 3,
      partialPaymentsAllowed: true,
      aiRemindersEnabled: false,
      reminderDaysBefore: 3,
      aiPredictionsEnabled: false,
      ocrEnabled: false,
      whatsappEnabled: false,
      smsFallbackEnabled: false,
      autoReceiptEnabled: false,
      themeMode: 'dark_luxury',
      dashboardLayout: 'bento',
      glassEffectsEnabled: true,
      tplFeeReminder: '',
      tplPaymentReceipt: '',
      tplOverdueNotice: '',
      tplLateFineApplied: '',
      tplNewFeeGenerated: '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'center_name': centerName,
      'center_address': centerAddress,
      'center_phone': centerPhone,
      'center_email': centerEmail,
      'center_website': centerWebsite,
      'gstin': gstin,
      'academic_year': academicYear,
      'currency': currency,
      'timezone': timezone,
      'gst_enabled': gstEnabled,
      'qr_verification_enabled': qrVerificationEnabled,
      'parent_portal_enabled': parentPortalEnabled,
      'digital_signature_enabled': digitalSignatureEnabled,
      'default_due_day': defaultDueDay,
      'auto_due_generation': autoDueGeneration,
      'late_fines_enabled': lateFinesEnabled,
      'late_fine_amount': lateFineAmount,
      'grace_period_days': gracePeriodDays,
      'partial_payments_allowed': partialPaymentsAllowed,
      'ai_reminders_enabled': aiRemindersEnabled,
      'ai_predictions_enabled': aiPredictionsEnabled,
      'ocr_enabled': ocrEnabled,
      'whatsapp_enabled': whatsappEnabled,
      'sms_fallback_enabled': smsFallbackEnabled,
      'auto_receipt_enabled': autoReceiptEnabled,
      'reminder_days_before': reminderDaysBefore,
      'theme_mode': themeMode,
      'dashboard_layout': dashboardLayout,
      'glass_effects_enabled': glassEffectsEnabled,
      'early_payment_discount_enabled': earlyPaymentDiscountEnabled,
      'early_payment_discount_percent': earlyPaymentDiscountPercent,
      'early_payment_discount_type': earlyPaymentDiscountType,
      'early_payment_days': earlyPaymentDays,
      'convenience_fee_enabled': convenienceFeeEnabled,
      'convenience_fee_percent': convenienceFeePercent,
      'tax_percentage': taxPercentage,
      'tax_mode': taxMode,
      'late_fine_type': lateFineType,
      'tpl_fee_reminder': tplFeeReminder,
      'tpl_payment_receipt': tplPaymentReceipt,
      'tpl_overdue_notice': tplOverdueNotice,
      'tpl_late_fine_applied': tplLateFineApplied,
      'tpl_new_fee_generated': tplNewFeeGenerated,
    };
  }

  AppSettings copyWith({
    String? centerName,
    String? centerAddress,
    String? centerPhone,
    String? centerEmail,
    String? centerWebsite,
    String? gstin,
    String? academicYear,
    String? currency,
    String? timezone,
    bool? gstEnabled,
    bool? qrVerificationEnabled,
    bool? parentPortalEnabled,
    bool? digitalSignatureEnabled,
    int? defaultDueDay,
    bool? autoDueGeneration,
    bool? lateFinesEnabled,
    double? lateFineAmount,
    int? gracePeriodDays,
    bool? partialPaymentsAllowed,
    bool? aiRemindersEnabled,
    bool? aiPredictionsEnabled,
    bool? ocrEnabled,
    bool? whatsappEnabled,
    bool? smsFallbackEnabled,
    bool? autoReceiptEnabled,
    int? reminderDaysBefore,
    String? themeMode,
    String? dashboardLayout,
    bool? glassEffectsEnabled,
    bool? earlyPaymentDiscountEnabled,
    double? earlyPaymentDiscountPercent,
    String? earlyPaymentDiscountType,
    int? earlyPaymentDays,
    bool? convenienceFeeEnabled,
    double? convenienceFeePercent,
    double? taxPercentage,
    String? taxMode,
    String? lateFineType,
    String? tplFeeReminder,
    String? tplPaymentReceipt,
    String? tplOverdueNotice,
    String? tplLateFineApplied,
    String? tplNewFeeGenerated,
  }) {
    return AppSettings(
      id: id,
      accountId: accountId,
      centerName: centerName ?? this.centerName,
      centerAddress: centerAddress ?? this.centerAddress,
      centerPhone: centerPhone ?? this.centerPhone,
      centerEmail: centerEmail ?? this.centerEmail,
      centerWebsite: centerWebsite ?? this.centerWebsite,
      gstin: gstin ?? this.gstin,
      academicYear: academicYear ?? this.academicYear,
      currency: currency ?? this.currency,
      timezone: timezone ?? this.timezone,
      gstEnabled: gstEnabled ?? this.gstEnabled,
      qrVerificationEnabled: qrVerificationEnabled ?? this.qrVerificationEnabled,
      parentPortalEnabled: parentPortalEnabled ?? this.parentPortalEnabled,
      digitalSignatureEnabled: digitalSignatureEnabled ?? this.digitalSignatureEnabled,
      defaultDueDay: defaultDueDay ?? this.defaultDueDay,
      autoDueGeneration: autoDueGeneration ?? this.autoDueGeneration,
      lateFinesEnabled: lateFinesEnabled ?? this.lateFinesEnabled,
      lateFineAmount: lateFineAmount ?? this.lateFineAmount,
      gracePeriodDays: gracePeriodDays ?? this.gracePeriodDays,
      partialPaymentsAllowed: partialPaymentsAllowed ?? this.partialPaymentsAllowed,
      aiRemindersEnabled: aiRemindersEnabled ?? this.aiRemindersEnabled,
      aiPredictionsEnabled: aiPredictionsEnabled ?? this.aiPredictionsEnabled,
      ocrEnabled: ocrEnabled ?? this.ocrEnabled,
      whatsappEnabled: whatsappEnabled ?? this.whatsappEnabled,
      smsFallbackEnabled: smsFallbackEnabled ?? this.smsFallbackEnabled,
      autoReceiptEnabled: autoReceiptEnabled ?? this.autoReceiptEnabled,
      reminderDaysBefore: reminderDaysBefore ?? this.reminderDaysBefore,
      themeMode: themeMode ?? this.themeMode,
      dashboardLayout: dashboardLayout ?? this.dashboardLayout,
      glassEffectsEnabled: glassEffectsEnabled ?? this.glassEffectsEnabled,
      earlyPaymentDiscountEnabled: earlyPaymentDiscountEnabled ?? this.earlyPaymentDiscountEnabled,
      earlyPaymentDiscountPercent: earlyPaymentDiscountPercent ?? this.earlyPaymentDiscountPercent,
      earlyPaymentDiscountType: earlyPaymentDiscountType ?? this.earlyPaymentDiscountType,
      earlyPaymentDays: earlyPaymentDays ?? this.earlyPaymentDays,
      convenienceFeeEnabled: convenienceFeeEnabled ?? this.convenienceFeeEnabled,
      convenienceFeePercent: convenienceFeePercent ?? this.convenienceFeePercent,
      taxPercentage: taxPercentage ?? this.taxPercentage,
      taxMode: taxMode ?? this.taxMode,
      lateFineType: lateFineType ?? this.lateFineType,
      tplFeeReminder: tplFeeReminder ?? this.tplFeeReminder,
      tplPaymentReceipt: tplPaymentReceipt ?? this.tplPaymentReceipt,
      tplOverdueNotice: tplOverdueNotice ?? this.tplOverdueNotice,
      tplLateFineApplied: tplLateFineApplied ?? this.tplLateFineApplied,
      tplNewFeeGenerated: tplNewFeeGenerated ?? this.tplNewFeeGenerated,
    );
  }
}
