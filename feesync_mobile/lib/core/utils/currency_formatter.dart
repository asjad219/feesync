import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _formatter = NumberFormat.currency(
    symbol: '₹',
    decimalDigits: 2,
  );

  static String format(double amount) {
    return _formatter.format(amount);
  }

  static String normalizeCurrencyCode(String? raw) {
    if (raw == null || raw.trim().isEmpty) return 'INR';
    final value = raw.trim().toUpperCase();

    if (value.contains('USD')) return 'USD';
    if (value.contains('EUR')) return 'EUR';
    if (value.contains('INR')) return 'INR';

    // Handles values like `INR (₹)` / `USD ($)` by taking prefix.
    final code = value.split(' ').first;
    if (code.length == 3) return code;

    return 'INR';
  }

  static String symbolFor(String? raw) {
    switch (normalizeCurrencyCode(raw)) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'INR':
      default:
        return '₹';
    }
  }

  static String localeFor(String? raw) {
    switch (normalizeCurrencyCode(raw)) {
      case 'USD':
        return 'en_US';
      case 'EUR':
        return 'de_DE';
      case 'INR':
      default:
        return 'en_IN';
    }
  }

  static NumberFormat numberFormat(String? raw, {int decimalDigits = 0}) {
    final code = normalizeCurrencyCode(raw);
    return NumberFormat.currency(
      locale: localeFor(code),
      name: code,
      symbol: symbolFor(code),
      decimalDigits: decimalDigits,
    );
  }

  static NumberFormat compactNumberFormat(String? raw, {int decimalDigits = 1}) {
    final code = normalizeCurrencyCode(raw);
    return NumberFormat.compactCurrency(
      locale: localeFor(code),
      symbol: symbolFor(code),
      decimalDigits: decimalDigits,
    );
  }
}

class DateFormatter {
  static String formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  static String formatDateTime(DateTime date) {
    return DateFormat('MMM dd, yyyy HH:mm').format(date);
  }

  static String formatShortDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }
}
