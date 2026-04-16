// core/database/models/category_model.dart
// Hive model for transaction categories.

import 'package:hive/hive.dart';

part 'category_model.g.dart';

@HiveType(typeId: 2)
class CategoryModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  int iconCodePoint;

  @HiveField(3)
  String colorHex;

  @HiveField(4)
  int type; // 0 = expense, 1 = income, 2 = both

  @HiveField(5)
  bool isDefault;

  CategoryModel({
    required this.id,
    required this.name,
    required this.iconCodePoint,
    required this.colorHex,
    this.type = 0,
    this.isDefault = false,
  });

  CategoryModel copyWith({
    String? id,
    String? name,
    int? iconCodePoint,
    String? colorHex,
    int? type,
    bool? isDefault,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      colorHex: colorHex ?? this.colorHex,
      type: type ?? this.type,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  /// Serialize to JSON for backup.
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'iconCodePoint': iconCodePoint,
        'colorHex': colorHex,
        'type': type,
        'isDefault': isDefault,
      };

  /// Deserialize from JSON for restore.
  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      iconCodePoint: json['iconCodePoint'] as int,
      colorHex: json['colorHex'] as String,
      type: json['type'] as int? ?? 0,
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }
}
