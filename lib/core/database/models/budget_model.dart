// core/database/models/budget_model.dart
// Hive model for monthly budget configuration.

import 'package:hive/hive.dart';

part 'budget_model.g.dart';

@HiveType(typeId: 3)
class BudgetModel extends HiveObject {
  @HiveField(0)
  double monthlyLimit;

  BudgetModel({
    this.monthlyLimit = 0.0,
  });

  BudgetModel copyWith({double? monthlyLimit}) {
    return BudgetModel(
      monthlyLimit: monthlyLimit ?? this.monthlyLimit,
    );
  }

  /// Serialize to JSON for backup.
  Map<String, dynamic> toJson() => {
        'monthlyLimit': monthlyLimit,
      };

  /// Deserialize from JSON for restore.
  factory BudgetModel.fromJson(Map<String, dynamic> json) {
    return BudgetModel(
      monthlyLimit: (json['monthlyLimit'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
