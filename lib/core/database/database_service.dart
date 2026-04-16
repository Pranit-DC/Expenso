// core/database/database_service.dart
// Initializes Hive and registers all adapters.

import 'package:hive_flutter/hive_flutter.dart';
import 'models/transaction_model.dart';
import 'models/category_model.dart';
import 'models/budget_model.dart';
import '../utils/constants.dart';

class DatabaseService {
  DatabaseService._();

  static Future<void> initialize() async {
    // Register Hive adapters
    Hive.registerAdapter(TransactionTypeAdapter());
    Hive.registerAdapter(TransactionModelAdapter());
    Hive.registerAdapter(CategoryModelAdapter());
    Hive.registerAdapter(BudgetModelAdapter());

    // Open all boxes
    await Hive.openBox<TransactionModel>(AppConstants.transactionsBox);
    await Hive.openBox<CategoryModel>(AppConstants.categoriesBox);
    await Hive.openBox<BudgetModel>(AppConstants.budgetBox);
    await Hive.openBox('settings');
  }

  static Box<TransactionModel> get transactionsBox =>
      Hive.box<TransactionModel>(AppConstants.transactionsBox);

  static Box<CategoryModel> get categoriesBox =>
      Hive.box<CategoryModel>(AppConstants.categoriesBox);

  static Box<BudgetModel> get budgetBox =>
      Hive.box<BudgetModel>(AppConstants.budgetBox);
}
