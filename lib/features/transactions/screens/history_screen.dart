// features/transactions/screens/history_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/models/transaction_model.dart';
import '../../../core/database/repositories/transaction_repository.dart';
import '../../../core/database/repositories/category_repository.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/routing/app_router.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  TransactionType? _filter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final transactions = ref.watch(transactionProvider);
    final categories = ref.watch(categoryProvider);
    final categoryMap = {for (var c in categories) c.id: c};

    // Apply filter
    final filtered = transactions.where((t) {
      if (_filter == null) return true;
      return t.type == _filter;
    }).toList();

    // Group by date
    final grouped = <String, List<TransactionModel>>{};
    for (final t in filtered) {
      final key = Formatters.dateRelative(t.date);
      grouped.putIfAbsent(key, () => []).add(t);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SegmentedButton<TransactionType?>(
              segments: const [
                ButtonSegment(value: null, label: Text('All')),
                ButtonSegment(value: TransactionType.expense, label: Text('Expense')),
                ButtonSegment(value: TransactionType.income, label: Text('Income')),
              ],
              selected: {_filter},
              onSelectionChanged: (Set<TransactionType?> newSelection) {
                setState(() {
                  _filter = newSelection.first;
                });
              },
            ),
          ),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          
          if (filtered.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Text(
                  'No transactions yet',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            ...grouped.entries.map((entry) {
              final dateKey = entry.key;
              final dayTransactions = entry.value;

              double dayNet = dayTransactions.fold(0.0, (s, t) {
                return s + (t.type == TransactionType.income ? t.amount : -t.amount);
              });
              final isPositiveDay = dayNet >= 0;

              return SliverMainAxisGroup(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            dateKey,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: colorScheme.primary,
                            ),
                          ),
                          Text(
                            '${isPositiveDay ? '+' : ''}${Formatters.currencyCompact(dayNet)}',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: isPositiveDay ? colorScheme.primary : colorScheme.error,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverList.builder(
                    itemCount: dayTransactions.length,
                    itemBuilder: (context, index) {
                      final t = dayTransactions[index];
                      final cat = categoryMap[t.categoryId];
                      final isExpense = t.type == TransactionType.expense;
                      
                      return Slidable(
                        key: ValueKey(t.id),
                        endActionPane: ActionPane(
                          motion: const BehindMotion(),
                          extentRatio: 0.25,
                          children: [
                            SlidableAction(
                              onPressed: (_) {
                                ref.read(transactionProvider.notifier).delete(t.id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('Transaction deleted'),
                                    action: SnackBarAction(
                                      label: 'Undo',
                                      onPressed: () => ref.read(transactionProvider.notifier).add(t),
                                    ),
                                  ),
                                );
                              },
                              backgroundColor: colorScheme.error,
                              foregroundColor: colorScheme.onError,
                              icon: Icons.delete,
                              label: 'Delete',
                            ),
                          ],
                        ),
                        child: ListTile(
                          onTap: () => context.push(AppRoutes.addTransaction, extra: t),
                          leading: CircleAvatar(
                            backgroundColor: cat != null
                                ? Color(int.parse('FF${cat.colorHex}', radix: 16)).withValues(alpha: 0.2)
                                : colorScheme.surfaceContainerHighest,
                            foregroundColor: cat != null
                                ? Color(int.parse('FF${cat.colorHex}', radix: 16))
                                : colorScheme.onSurfaceVariant,
                            child: Icon(
                              cat != null
                                  ? IconData(cat.iconCodePoint,
                                      fontFamily: 'Phosphor',
                                      fontPackage: 'phosphor_flutter')
                                  : Icons.receipt,
                            ),
                          ),
                          title: Text(cat?.name ?? 'Unknown'),
                          subtitle: t.note != null && t.note!.isNotEmpty ? Text(t.note!) : null,
                          trailing: Text(
                            '${isExpense ? '−' : '+'}${Formatters.currency(t.amount)}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: isExpense ? colorScheme.error : colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              );
            }),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}
