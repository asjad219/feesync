class PlanConfig {
  final String tier;
  final String name;
  final String tagline;
  final int monthlyPrice;
  final int annualPrice;
  final int annualMonthlyEquivalent;
  final int maxStudents;
  final int maxBatches;
  final int whatsappReceiptsPerMonth;
  final int whatsappRemindersPerMonth;
  final int maxStaff;
  final bool csvExport;
  final bool biometricAuth;
  final bool supportSystem;
  final bool cloudBackup;
  final bool dueReminders;
  final bool invoiceSend;
  final List<String> highlights;

  const PlanConfig({
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
    required this.highlights,
  });

  static const PlanConfig free = PlanConfig(
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
    maxStaff: 2,
    csvExport: false,
    biometricAuth: true,
    supportSystem: false,
    cloudBackup: false,
    dueReminders: true,
    invoiceSend: true,
    highlights: [
      'Up to 20 active students',
      'Up to 2 batches',
      'Up to 2 staff accounts',
      '100 WhatsApp Receipts/month',
      '30 WhatsApp Reminders/month',
    ],
  );

  static const PlanConfig starter = PlanConfig(
    tier: 'starter',
    name: 'Starter',
    tagline: 'Professional Solo Operator',
    monthlyPrice: 299,
    annualPrice: 2868,             // Play Console: ₹2,868/yr (₹239/mo)
    annualMonthlyEquivalent: 239,  // 2868 ÷ 12 = 239
    maxStudents: 200,
    maxBatches: 10,
    whatsappReceiptsPerMonth: 2000,
    whatsappRemindersPerMonth: 300,
    maxStaff: 5,
    csvExport: true,
    biometricAuth: true,
    supportSystem: true,
    cloudBackup: true,
    dueReminders: true,
    invoiceSend: true,
    highlights: [
      'Up to 200 active students',
      'Up to 10 batches',
      'Up to 5 staff accounts',
      '2,000 WhatsApp Receipts/month',
      '300 WhatsApp Reminders/month',
      'Export reports to CSV',
    ],
  );

  static const PlanConfig growth = PlanConfig(
    tier: 'growth',
    name: 'Growth',
    tagline: 'Scale with Pro',
    monthlyPrice: 999,
    annualPrice: 9984,             // Play Console: ₹9,984/yr (₹832/mo)
    annualMonthlyEquivalent: 832,  // 9984 ÷ 12 = 832
    maxStudents: 500,
    maxBatches: 50,
    whatsappReceiptsPerMonth: 5000,
    whatsappRemindersPerMonth: 1000,
    maxStaff: 10,
    csvExport: true,
    biometricAuth: true,
    supportSystem: true,
    cloudBackup: true,
    dueReminders: true,
    invoiceSend: true,
    highlights: [
      'Up to 500 active students',
      'Up to 50 batches',
      'Up to 10 staff accounts',
      '5,000 WhatsApp Receipts/month',
      '1,000 WhatsApp Reminders/month',
      'Full reports & AI features',
    ],
  );

  static const PlanConfig institute = PlanConfig(
    tier: 'institute',
    name: 'Institute',
    tagline: 'Multi-Batch Enterprise',
    monthlyPrice: 1999,
    annualPrice: 19992,             // Play Console: ₹19,992/yr (₹1,666/mo)
    annualMonthlyEquivalent: 1666,  // 19992 ÷ 12 = 1666
    maxStudents: 5000,
    maxBatches: 500,
    whatsappReceiptsPerMonth: 50000,
    whatsappRemindersPerMonth: 10000,
    maxStaff: 50,
    csvExport: true,
    biometricAuth: true,
    supportSystem: true,
    cloudBackup: true,
    dueReminders: true,
    invoiceSend: true,
    highlights: [
      'Up to 5,000 active students',
      'Up to 500 batches',
      'Up to 50 staff accounts',
      '50,000 WhatsApp Receipts/month',
      '10,000 WhatsApp Reminders/month',
      'Includes all Growth features',
      'Priority Support & Advanced Analytics',
    ],
  );

  static const List<PlanConfig> all = [
    free,
    starter,
    growth,
    institute,
  ];

  static PlanConfig fromTier(String tier) {
    return all.firstWhere(
      (p) => p.tier == tier,
      orElse: () => free,
    );
  }
}
