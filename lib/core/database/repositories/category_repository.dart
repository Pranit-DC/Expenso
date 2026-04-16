// core/database/repositories/category_repository.dart
// Riverpod-powered CRUD repository for categories.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database_service.dart';
import '../models/category_model.dart';

class CategoryRepository extends StateNotifier<List<CategoryModel>> {
  CategoryRepository() : super([]) {
    _loadAll();
  }

  void _loadAll() {
    final box = DatabaseService.categoriesBox;
    state = box.values.toList();
  }

  Future<void> add(CategoryModel category) async {
    final box = DatabaseService.categoriesBox;
    await box.put(category.id, category);
    _loadAll();
  }

  Future<void> update(CategoryModel category) async {
    final box = DatabaseService.categoriesBox;
    await box.put(category.id, category);
    _loadAll();
  }

  Future<void> delete(String id) async {
    final box = DatabaseService.categoriesBox;
    final category = box.get(id);
    if (category != null && category.isDefault) return; // Don't delete defaults
    await box.delete(id);
    _loadAll();
  }

  CategoryModel? getById(String id) {
    final box = DatabaseService.categoriesBox;
    return box.get(id);
  }

  /// Get categories filtered by type: 0=expense, 1=income, 2=both.
  List<CategoryModel> getByType(int type) {
    return state.where((c) => c.type == type || c.type == 2).toList();
  }

  /// Get expense categories.
  List<CategoryModel> get expenseCategories => getByType(0);

  /// Get income categories.
  List<CategoryModel> get incomeCategories => getByType(1);
}

/// Global provider for category state.
final categoryProvider =
    StateNotifierProvider<CategoryRepository, List<CategoryModel>>(
  (ref) => CategoryRepository(),
);
