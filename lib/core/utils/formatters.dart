// core/utils/formatters.dart
// Common formatting utilities.

import 'package:intl/intl.dart';
import 'constants.dart';

class Formatters {
  Formatters._();

  /// Format amount with currency symbol.
  /// e.g. ₹1,234.56
  static String currency(double amount) {
    final formatter = NumberFormat.currency(
      symbol: AppConstants.currencySymbol,
      decimalDigits: 2,
      locale: 'en_IN',
    );
    return formatter.format(amount);
  }

  /// Format amount without decimals for compact display.
  /// e.g. ₹1,235
  static String currencyCompact(double amount) {
    final formatter = NumberFormat.currency(
      symbol: AppConstants.currencySymbol,
      decimalDigits: 0,
      locale: 'en_IN',
    );
    return formatter.format(amount);
  }

  /// e.g. "16 Apr 2026"
  static String dateShort(DateTime date) {
    return DateFormat('d MMM yyyy').format(date);
  }

  /// e.g. "Wednesday, 16 April"
  static String dateLong(DateTime date) {
    return DateFormat('EEEE, d MMMM').format(date);
  }

  /// e.g. "Apr 2026"
  static String monthYear(DateTime date) {
    return DateFormat('MMM yyyy').format(date);
  }

  /// e.g. "Today", "Yesterday", or "16 Apr"
  static String dateRelative(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = today.difference(target).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return DateFormat('EEEE').format(date);
    return DateFormat('d MMM').format(date);
  }
}
