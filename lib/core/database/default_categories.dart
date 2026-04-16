// core/database/default_categories.dart
// Seeds the categories box with defaults on first launch.

import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'models/category_model.dart';
import 'database_service.dart';

class DefaultCategories {
  DefaultCategories._();

  /// Call once on startup — if box is empty, populate defaults.
  static Future<void> seed() async {
    final box = DatabaseService.categoriesBox;
    if (box.isNotEmpty) return; // Already seeded

    final defaults = _buildDefaults();
    for (final category in defaults) {
      await box.put(category.id, category);
    }
  }

  static List<CategoryModel> _buildDefaults() {
    return [
      // ── Expense Categories ──
      CategoryModel(
        id: 'cat_groceries',
        name: 'Groceries',
        iconCodePoint: PhosphorIconsFill.shoppingCart.codePoint,
        colorHex: '4CAF50',
        type: 0,
        isDefault: true,
      ),
      CategoryModel(
        id: 'cat_food',
        name: 'Food & Dining',
        iconCodePoint: PhosphorIconsFill.forkKnife.codePoint,
        colorHex: 'FF9800',
        type: 0,
        isDefault: true,
      ),
      CategoryModel(
        id: 'cat_transport',
        name: 'Transport',
        iconCodePoint: PhosphorIconsFill.car.codePoint,
        colorHex: '2196F3',
        type: 0,
        isDefault: true,
      ),
      CategoryModel(
        id: 'cat_shopping',
        name: 'Shopping',
        iconCodePoint: PhosphorIconsFill.bag.codePoint,
        colorHex: 'E91E63',
        type: 0,
        isDefault: true,
      ),
      CategoryModel(
        id: 'cat_entertainment',
        name: 'Entertainment',
        iconCodePoint: PhosphorIconsFill.filmSlate.codePoint,
        colorHex: '9C27B0',
        type: 0,
        isDefault: true,
      ),
      CategoryModel(
        id: 'cat_bills',
        name: 'Bills & Utilities',
        iconCodePoint: PhosphorIconsFill.lightning.codePoint,
        colorHex: 'F44336',
        type: 0,
        isDefault: true,
      ),
      CategoryModel(
        id: 'cat_health',
        name: 'Health',
        iconCodePoint: PhosphorIconsFill.heartbeat.codePoint,
        colorHex: '00BCD4',
        type: 0,
        isDefault: true,
      ),
      CategoryModel(
        id: 'cat_education',
        name: 'Education',
        iconCodePoint: PhosphorIconsFill.graduationCap.codePoint,
        colorHex: '3F51B5',
        type: 0,
        isDefault: true,
      ),
      CategoryModel(
        id: 'cat_rent',
        name: 'Rent',
        iconCodePoint: PhosphorIconsFill.house.codePoint,
        colorHex: '795548',
        type: 0,
        isDefault: true,
      ),
      CategoryModel(
        id: 'cat_other_expense',
        name: 'Other',
        iconCodePoint: PhosphorIconsFill.dotsThreeOutline.codePoint,
        colorHex: '607D8B',
        type: 0,
        isDefault: true,
      ),

      // ── Income Categories ──
      CategoryModel(
        id: 'cat_salary',
        name: 'Salary',
        iconCodePoint: PhosphorIconsFill.wallet.codePoint,
        colorHex: '4CAF50',
        type: 1,
        isDefault: true,
      ),
      CategoryModel(
        id: 'cat_freelance',
        name: 'Freelance',
        iconCodePoint: PhosphorIconsFill.laptop.codePoint,
        colorHex: '00BCD4',
        type: 1,
        isDefault: true,
      ),
      CategoryModel(
        id: 'cat_investment',
        name: 'Investment',
        iconCodePoint: PhosphorIconsFill.chartLineUp.codePoint,
        colorHex: 'FF9800',
        type: 1,
        isDefault: true,
      ),
      CategoryModel(
        id: 'cat_gift_income',
        name: 'Gifts',
        iconCodePoint: PhosphorIconsFill.gift.codePoint,
        colorHex: 'E91E63',
        type: 1,
        isDefault: true,
      ),
      CategoryModel(
        id: 'cat_other_income',
        name: 'Other Income',
        iconCodePoint: PhosphorIconsFill.plusCircle.codePoint,
        colorHex: '9E9E9E',
        type: 1,
        isDefault: true,
      ),
    ];
  }
}
