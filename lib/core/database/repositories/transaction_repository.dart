// core/database/repositories/transaction_repository.dart
// Riverpod-powered CRUD repository for transactions.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database_service.dart';
import '../models/transaction_model.dart';

/// Provides a reactive list of all transactions, sorted by date descending.
class TransactionRepository extends StateNotifier<List<TransactionModel>> {
  TransactionRepository() : super([]) {
    _loadAll();
  }

  void _loadAll() {
    final box = DatabaseService.transactionsBox;
    final all = box.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    state = all;
  }

  Future<void> add(TransactionModel transaction) async {
    final box = DatabaseService.transactionsBox;
    await box.put(transaction.id, transaction);
    _loadAll();
  }

  Future<void> update(TransactionModel transaction) async {
    final box = DatabaseService.transactionsBox;
    await box.put(transaction.id, transaction);
    _loadAll();
  }

  Future<void> delete(String id) async {
    final box = DatabaseService.transactionsBox;
    await box.delete(id);
    _loadAll();
  }

  Future<void> deleteAll() async {
    final box = DatabaseService.transactionsBox;
    await box.clear();
    state = [];
  }

  TransactionModel? getById(String id) {
    final box = DatabaseService.transactionsBox;
    return box.get(id);
  }

  /// Get transactions for a specific month.
  List<TransactionModel> getForMonth(int year, int month) {
    return state.where((t) {
      return t.date.year == year && t.date.month == month;
    }).toList();
  }

  /// Get all expenses for a specific month.
  List<TransactionModel> getExpensesForMonth(int year, int month) {
    return getForMonth(year, month)
        .where((t) => t.type == TransactionType.expense)
        .toList();
  }

  /// Get all income for a specific month.
  List<TransactionModel> getIncomeForMonth(int year, int month) {
    return getForMonth(year, month)
        .where((t) => t.type == TransactionType.income)
        .toList();
  }
}

/// Global provider for transaction state.
final transactionProvider =
    StateNotifierProvider<TransactionRepository, List<TransactionModel>>(
  (ref) => TransactionRepository(),
);
