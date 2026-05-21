class AppConstants {
  static const String appName = 'FeeSync';
  static const String currencySymbol = '\$';

  // User roles
  static const String roleAdmin = 'admin';
  static const String roleAccountant = 'accountant';
  static const String roleParent = 'parent';
  static const String roleStudent = 'student';

  // Payment methods
  static const String paymentCash = 'cash';
  static const String paymentBankTransfer = 'bank_transfer';
  static const String paymentMobileMoney = 'mobile_money';
  static const String paymentCard = 'card';
  static const String paymentOther = 'other';

  // Notification types
  static const String notifPaymentReminder = 'payment_reminder';
  static const String notifPaymentConfirmation = 'payment_confirmation';
  static const String notifWelcome = 'welcome';
  static const String notifFeeUpdate = 'fee_update';
}
