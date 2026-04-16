// core/database/backup_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'database_service.dart';
import 'models/budget_model.dart';
import 'models/category_model.dart';
import 'models/transaction_model.dart';

class BackupService {
  BackupService._();

  static Future<bool> createBackup() async {
    try {
      final transactions = DatabaseService.transactionsBox.values.map((t) => t.toJson()).toList();
      final categories = DatabaseService.categoriesBox.values.map((c) => c.toJson()).toList();
      final budget = DatabaseService.budgetBox.get('active_budget')?.toJson();

      final backupData = {
        'version': 1,
        'timestamp': DateTime.now().toIso8601String(),
        'transactions': transactions,
        'categories': categories,
        'budget': budget,
      };

      final jsonStr = jsonEncode(backupData);

      if (kIsWeb) {
        // On Web, use share mechanism (or standard HTML download but share_plus handles web downloads too)
        await Share.share(jsonStr, subject: 'Expenso Backup');
        return true;
      } else {
        // On Mobile/Desktop
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/expenso_backup_${DateTime.now().millisecondsSinceEpoch}.json');
        await file.writeAsString(jsonStr);

        final result = await Share.shareXFiles(
          [XFile(file.path)],
          subject: 'Expenso Backup',
        );
        return result.status == ShareResultStatus.success;
      }
    } catch (e) {
      debugPrint('Backup Error: $e');
      return false;
    }
  }

  static Future<bool> restoreBackup() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null) return false;

      String jsonStr;
      
      if (kIsWeb) {
        jsonStr = utf8.decode(result.files.single.bytes!);
      } else {
        final file = File(result.files.single.path!);
        jsonStr = await file.readAsString();
      }

      final Map<String, dynamic> backupData = jsonDecode(jsonStr);

      if (backupData['version'] != 1) {
        return false; // Unsupported version
      }

      final transactionsList = (backupData['transactions'] as List)
          .map((data) => TransactionModel.fromJson(data))
          .toList();

      final categoriesList = (backupData['categories'] as List)
          .map((data) => CategoryModel.fromJson(data))
          .toList();

      final Map<String, dynamic>? budgetData = backupData['budget'];
      final budgetModel = budgetData != null ? BudgetModel.fromJson(budgetData) : BudgetModel(monthlyLimit: 0);

      // Clear current data
      await DatabaseService.transactionsBox.clear();
      await DatabaseService.categoriesBox.clear();
      await DatabaseService.budgetBox.clear();

      // Restore new data
      for (var t in transactionsList) {
        await DatabaseService.transactionsBox.put(t.id, t);
      }
      for (var c in categoriesList) {
        await DatabaseService.categoriesBox.put(c.id, c);
      }
      await DatabaseService.budgetBox.put('active_budget', budgetModel);

      return true;
    } catch (e) {
      debugPrint('Restore Error: $e');
      return false;
    }
  }
}
