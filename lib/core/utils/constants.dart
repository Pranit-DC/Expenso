// core/utils/constants.dart
// Global app constants.

class AppConstants {
  AppConstants._();

  static const String appName = 'Expenso';
  static const String appVersion = '0.1.0';
  static const String appDescription =
      'A clean, offline-first expense tracker.';

  // Hive box names
  static const String transactionsBox = 'transactions';
  static const String categoriesBox = 'categories';
  static const String budgetBox = 'budget';
  static const String settingsBox = 'settings';

  // Default budget
  static const double defaultMonthlyBudget = 0.0;

  // Currency (simplified — single currency for now)
  static const String currencySymbol = '₹';
}
