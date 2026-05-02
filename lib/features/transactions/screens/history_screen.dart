// features/transactions/screens/history_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/database/models/transaction_model.dart';
import '../../../core/database/repositories/transaction_repository.dart';
import '../../../core/database/repositories/category_repository.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/icon_utils.dart';
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
      body: CustomScrollView(
        slivers: [
          SliverAppBar.medium(
            title: const Text('History'),
            pinned: true,
            centerTitle: false,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(64),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: SegmentedButton<TransactionType?>(
                  showSelectedIcon: false,
                  style: SegmentedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    selectedBackgroundColor: colorScheme.primary,
                    selectedForegroundColor: colorScheme.onPrimary,
                  ),
                  segments: const [
                    ButtonSegment(
                      value: null,
                      label: Text('All', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    ButtonSegment(
                      value: TransactionType.expense,
                      label: Text('Expense', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    ButtonSegment(
                      value: TransactionType.income,
                      label: Text('Income', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
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

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                sliver: SliverMainAxisGroup(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              dateKey.toUpperCase(),
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                                fontSize: 11,
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
                    SliverToBoxAdapter(
                      child: Container(
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          children: List.generate(dayTransactions.length, (index) {
                            final t = dayTransactions[index];
                            final cat = categoryMap[t.categoryId];
                            final isExpense = t.type == TransactionType.expense;

                            return Column(
                              children: [
                                Slidable(
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
                                        icon: PhosphorIconsBold.trash,
                                        label: 'Delete',
                                      ),
                                    ],
                                  ),
                                  child: ListTile(
                                    onTap: () => appRouter.push(AppRoutes.addTransaction, extra: t),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                    leading: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: cat != null
                                            ? Color(int.parse('FF${cat.colorHex}', radix: 16)).withValues(alpha: 0.15)
                                            : colorScheme.surfaceContainerHighest,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Icon(
                                        cat != null
                                            ? IconUtils.fromCodePoint(cat.iconCodePoint)
                                            : PhosphorIconsFill.receipt,
                                        color: cat != null ? Color(int.parse('FF${cat.colorHex}', radix: 16)) : colorScheme.onSurfaceVariant,
                                        size: 22,
                                      ),
                                    ),
                                    title: Text(
                                      cat?.name ?? 'Unknown',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    subtitle: t.note != null && t.note!.isNotEmpty
                                        ? Text(t.note!, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13))
                                        : null,
                                    trailing: Text(
                                      '${isExpense ? '−' : '+'}${Formatters.currencyCompact(t.amount)}',
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        color: isExpense ? colorScheme.error : colorScheme.primary,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                  ),
                                ),
                                if (index < dayTransactions.length - 1)
                                  Divider(
                                    height: 1,
                                    indent: 72,
                                    endIndent: 20,
                                    color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                                  ),
                              ],
                            );
                          }),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}
