// core/database/repositories/budget_repository.dart
// Riverpod-powered repository for the monthly budget.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database_service.dart';
import '../models/budget_model.dart';

class BudgetRepository extends StateNotifier<BudgetModel> {
  BudgetRepository() : super(BudgetModel()) {
    _load();
  }

  static const String _budgetKey = 'active_budget';

  void _load() {
    final box = DatabaseService.budgetBox;
    final existing = box.get(_budgetKey);
    if (existing != null) {
      state = existing;
    } else {
      // Create default budget entry
      final defaultBudget = BudgetModel(monthlyLimit: 0.0);
      box.put(_budgetKey, defaultBudget);
      state = defaultBudget;
    }
  }

  Future<void> setMonthlyLimit(double limit) async {
    final box = DatabaseService.budgetBox;
    final updated = BudgetModel(monthlyLimit: limit);
    await box.put(_budgetKey, updated);
    state = updated;
  }

  double get monthlyLimit => state.monthlyLimit;
  bool get hasBudget => state.monthlyLimit > 0;
}

/// Global provider for budget state.
final budgetProvider =
    StateNotifierProvider<BudgetRepository, BudgetModel>(
  (ref) => BudgetRepository(),
);
