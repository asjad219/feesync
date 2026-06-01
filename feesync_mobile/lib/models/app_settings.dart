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
  final String themeMode;
  final String dashboardLayout;
  final bool glassEffectsEnabled;

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
    required this.themeMode,
    required this.dashboardLayout,
    required this.glassEffectsEnabled,
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
      themeMode: json['theme_mode'] ?? 'dark_luxury',
      dashboardLayout: json['dashboard_layout'] ?? 'bento',
      glassEffectsEnabled: json['glass_effects_enabled'] ?? true,
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
      'theme_mode': themeMode,
      'dashboard_layout': dashboardLayout,
      'glass_effects_enabled': glassEffectsEnabled,
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
    String? themeMode,
    String? dashboardLayout,
    bool? glassEffectsEnabled,
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
      themeMode: themeMode ?? this.themeMode,
      dashboardLayout: dashboardLayout ?? this.dashboardLayout,
      glassEffectsEnabled: glassEffectsEnabled ?? this.glassEffectsEnabled,
    );
  }
}
