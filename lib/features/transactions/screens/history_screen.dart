// features/transactions/screens/history_screen.dart
// Transaction history with date grouping, filters, and swipe-to-delete.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/database/models/transaction_model.dart';
import '../../../core/database/models/category_model.dart';
import '../../../core/database/repositories/transaction_repository.dart';
import '../../../core/database/repositories/category_repository.dart';
import '../../../core/utils/formatters.dart';

import 'add_transaction_screen.dart';

// ── Filter State ──
enum HistoryFilter { all, income, expense }

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  HistoryFilter _filter = HistoryFilter.all;
  String? _categoryFilter;
  DateTimeRange? _dateRange;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final allTransactions = ref.watch(transactionProvider);
    final categories = ref.watch(categoryProvider);

    // Build category lookup map
    final categoryMap = {for (var c in categories) c.id: c};

    // Apply filters
    var filtered = allTransactions.where((t) {
      if (_filter == HistoryFilter.income &&
          t.type != TransactionType.income) {
        return false;
      }
      if (_filter == HistoryFilter.expense &&
          t.type != TransactionType.expense) {
        return false;
      }
      if (_categoryFilter != null && t.categoryId != _categoryFilter) {
        return false;
      }
      if (_dateRange != null) {
        if (t.date.isBefore(_dateRange!.start) ||
            t.date.isAfter(
                _dateRange!.end.add(const Duration(days: 1)))) {
          return false;
        }
      }
      return true;
    }).toList();

    // Group by date
    final grouped = <String, List<TransactionModel>>{};
    for (final t in filtered) {
      final key = Formatters.dateRelative(t.date);
      grouped.putIfAbsent(key, () => []).add(t);
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: const Text('History'),
            actions: [
              IconButton(
                icon: Badge(
                  isLabelVisible: _filter != HistoryFilter.all ||
                      _categoryFilter != null ||
                      _dateRange != null,
                  child: const Icon(PhosphorIconsRegular.funnel),
                ),
                onPressed: () => _showFilterSheet(context, categories),
                tooltip: 'Filters',
              ),
              const SizedBox(width: 8),
            ],
          ),

          if (filtered.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      PhosphorIconsDuotone.receipt,
                      size: 64,
                      color: colorScheme.primary.withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No transactions found',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (_filter != HistoryFilter.all ||
                        _categoryFilter != null ||
                        _dateRange != null) ...[
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => setState(() {
                          _filter = HistoryFilter.all;
                          _categoryFilter = null;
                          _dateRange = null;
                        }),
                        child: const Text('Clear filters'),
                      ),
                    ],
                  ],
                ),
              ),
            )
          else
            ...grouped.entries.map((entry) {
              return SliverMainAxisGroup(
                slivers: [
                  // Date header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Text(
                        entry.key,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                  // Transaction items
                  SliverList.builder(
                    itemCount: entry.value.length,
                    itemBuilder: (context, index) {
                      final t = entry.value[index];
                      final cat = categoryMap[t.categoryId];
                      return _TransactionTile(
                        transaction: t,
                        category: cat,
                        colorScheme: colorScheme,
                        theme: theme,
                        onTap: () => _editTransaction(t),
                        onDelete: () => _deleteTransaction(t.id),
                      );
                    },
                  ),
                ],
              );
            }),
          // Bottom padding
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  void _editTransaction(TransactionModel t) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddTransactionScreen(existingTransaction: t),
      ),
    );
  }

  void _deleteTransaction(String id) {
    ref.read(transactionProvider.notifier).delete(id);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Transaction deleted'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showFilterSheet(
      BuildContext context, List<CategoryModel> categories) {
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.5,
              maxChildSize: 0.7,
              minChildSize: 0.3,
              builder: (_, scrollCtrl) {
                return ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      'Filters',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 20),

                    // Type filter
                    Text('Type',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 8),
                    SegmentedButton<HistoryFilter>(
                      segments: const [
                        ButtonSegment(
                            value: HistoryFilter.all, label: Text('All')),
                        ButtonSegment(
                            value: HistoryFilter.income,
                            label: Text('Income')),
                        ButtonSegment(
                            value: HistoryFilter.expense,
                            label: Text('Expense')),
                      ],
                      selected: {_filter},
                      onSelectionChanged: (s) {
                        setSheetState(() => _filter = s.first);
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 20),

                    // Date range
                    Text('Date Range',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                          initialDateRange: _dateRange,
                        );
                        if (picked != null) {
                          setSheetState(() => _dateRange = picked);
                          setState(() {});
                        }
                      },
                      icon: const Icon(PhosphorIconsRegular.calendarBlank),
                      label: Text(_dateRange == null
                          ? 'Select date range'
                          : '${Formatters.dateShort(_dateRange!.start)} — ${Formatters.dateShort(_dateRange!.end)}'),
                    ),
                    const SizedBox(height: 20),

                    // Clear all
                    if (_filter != HistoryFilter.all ||
                        _categoryFilter != null ||
                        _dateRange != null)
                      TextButton(
                        onPressed: () {
                          setSheetState(() {
                            _filter = HistoryFilter.all;
                            _categoryFilter = null;
                            _dateRange = null;
                          });
                          setState(() {});
                        },
                        child: const Text('Clear all filters'),
                      ),
                    const SizedBox(height: 20),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}

// ─── Transaction Tile ───
class _TransactionTile extends StatelessWidget {
  final TransactionModel transaction;
  final CategoryModel? category;
  final ColorScheme colorScheme;
  final ThemeData theme;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _TransactionTile({
    required this.transaction,
    required this.category,
    required this.colorScheme,
    required this.theme,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isExpense = transaction.type == TransactionType.expense;
    final catColor = category != null
        ? Color(int.parse('FF${category!.colorHex}', radix: 16))
        : colorScheme.outline;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      child: Slidable(
        endActionPane: ActionPane(
          motion: const BehindMotion(),
          extentRatio: 0.25,
          children: [
            SlidableAction(
              onPressed: (_) => onDelete(),
              backgroundColor: colorScheme.errorContainer,
              foregroundColor: colorScheme.onErrorContainer,
              icon: PhosphorIconsBold.trash,
              borderRadius: BorderRadius.circular(16),
            ),
          ],
        ),
        child: Material(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  // Category icon
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: catColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      category != null
                          ? IconData(category!.iconCodePoint,
                              fontFamily: 'Phosphor-Fill',
                              fontPackage: 'phosphor_flutter')
                          : PhosphorIconsFill.question,
                      size: 22,
                      color: catColor,
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Name & note
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category?.name ?? 'Unknown',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (transaction.note != null &&
                            transaction.note!.isNotEmpty)
                          Text(
                            transaction.note!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),

                  // Amount
                  Text(
                    '${isExpense ? '−' : '+'}${Formatters.currency(transaction.amount)}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isExpense
                          ? Colors.red.shade400
                          : Colors.green.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
