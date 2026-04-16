// features/transactions/screens/history_screen.dart
// Cashew-inspired transaction history: sticky filter chips, daily dividers with totals, accent bars.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/models/transaction_model.dart';
import '../../../core/database/models/category_model.dart';
import '../../../core/database/repositories/transaction_repository.dart';
import '../../../core/database/repositories/category_repository.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/widgets/tappable.dart';

enum _HistoryFilter { all, expense, income }

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  _HistoryFilter _filter = _HistoryFilter.all;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final transactions = ref.watch(transactionProvider);
    final categories = ref.watch(categoryProvider);
    final categoryMap = {for (var c in categories) c.id: c};

    // Apply filter
    final filtered = transactions.where((t) {
      if (_filter == _HistoryFilter.expense) {
        return t.type == TransactionType.expense;
      }
      if (_filter == _HistoryFilter.income) {
        return t.type == TransactionType.income;
      }
      return true;
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    // Group by date
    final grouped = <String, List<TransactionModel>>{};
    for (final t in filtered) {
      final key = Formatters.dateRelative(t.date);
      grouped.putIfAbsent(key, () => []).add(t);
    }

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar.medium(
            title: const Text('History'),
            pinned: true,
          ),

          // ── Sticky filter chips (always visible, Cashew incomeExpenseTabSelector) ──
          SliverPersistentHeader(
            pinned: true,
            delegate: _FilterHeaderDelegate(
              filter: _filter,
              onChanged: (f) {
                HapticFeedback.selectionClick();
                setState(() => _filter = f);
              },
              colorScheme: colorScheme,
              theme: theme,
            ),
          ),

          if (filtered.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      PhosphorIconsDuotone.clockCounterClockwise,
                      size: 64,
                      color: colorScheme.primary.withValues(alpha: 0.35),
                    ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
                    const SizedBox(height: 16),
                    Text(
                      'No transactions yet',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap Add to record a transaction',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...grouped.entries.expand((entry) sync* {
              final dateKey = entry.key;
              final dayTransactions = entry.value;

              // Compute daily net
              double dayNet = dayTransactions.fold(0.0, (s, t) {
                return s + (t.type == TransactionType.income ? t.amount : -t.amount);
              });
              final isPositiveDay = dayNet >= 0;

              // Date divider sliver
              yield SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        dateKey,
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.primary,
                          letterSpacing: 0.3,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: (isPositiveDay
                                  ? const Color(0xFF59A849)
                                  : const Color(0xFFCA5A5A))
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${isPositiveDay ? '+' : ''}${Formatters.currencyCompact(dayNet)}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isPositiveDay
                                ? const Color(0xFF59A849)
                                : const Color(0xFFCA5A5A),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );

              // Transaction tiles sliver
              yield SliverList.separated(
                itemCount: dayTransactions.length,
                separatorBuilder: (_, __) => const SizedBox(height: 4),
                itemBuilder: (context, index) {
                  final t = dayTransactions[index];
                  final cat = categoryMap[t.categoryId];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: _HistoryTile(
                      transaction: t,
                      category: cat,
                      colorScheme: colorScheme,
                      theme: theme,
                      index: index,
                      onEdit: () => context.push(
                        AppRoutes.addTransaction,
                        extra: t,
                      ),
                      onDelete: () {
                        ref
                            .read(transactionProvider.notifier)
                            .delete(t.id);
                      },
                    ),
                  );
                },
              );
            }),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

// ── Persistent filter header delegate ──
class _FilterHeaderDelegate extends SliverPersistentHeaderDelegate {
  final _HistoryFilter filter;
  final ValueChanged<_HistoryFilter> onChanged;
  final ColorScheme colorScheme;
  final ThemeData theme;

  _FilterHeaderDelegate({
    required this.filter,
    required this.onChanged,
    required this.colorScheme,
    required this.theme,
  });

  @override
  double get minExtent => 56;
  @override
  double get maxExtent => 56;
  @override
  bool shouldRebuild(covariant _FilterHeaderDelegate old) =>
      old.filter != filter;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: colorScheme.surface,
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(3),
        child: Row(
          children: [
            _chip('All', _HistoryFilter.all),
            _chip('Expense', _HistoryFilter.expense),
            _chip('Income', _HistoryFilter.income),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, _HistoryFilter f) {
    final isSelected = filter == f;
    Color selectedBgColor;
    Color textColor;

    if (f == _HistoryFilter.expense) {
      selectedBgColor = const Color(0xFFCA5A5A).withValues(alpha: 0.15);
      textColor = const Color(0xFFCA5A5A);
    } else if (f == _HistoryFilter.income) {
      selectedBgColor = const Color(0xFF59A849).withValues(alpha: 0.15);
      textColor = const Color(0xFF59A849);
    } else {
      selectedBgColor = colorScheme.primaryContainer;
      textColor = colorScheme.onPrimaryContainer;
    }

    return Expanded(
      child: Tappable(
        onTap: () => onChanged(f),
        borderRadius: BorderRadius.circular(9),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: isSelected ? selectedBgColor : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? textColor : colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── History Transaction Tile ──
class _HistoryTile extends StatelessWidget {
  final TransactionModel transaction;
  final CategoryModel? category;
  final ColorScheme colorScheme;
  final ThemeData theme;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _HistoryTile({
    required this.transaction,
    required this.category,
    required this.colorScheme,
    required this.theme,
    required this.index,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isExpense = transaction.type == TransactionType.expense;
    final catColor = category != null
        ? Color(int.parse('FF${category!.colorHex}', radix: 16))
        : colorScheme.outline;

    return Slidable(
      key: ValueKey(transaction.id),
      endActionPane: ActionPane(
        motion: const BehindMotion(),
        extentRatio: 0.48,
        children: [
          CustomSlidableAction(
            onPressed: (_) => onEdit(),
            backgroundColor: colorScheme.primaryContainer,
            foregroundColor: colorScheme.onPrimaryContainer,
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(PhosphorIconsFill.pencilSimple, size: 20),
                const SizedBox(height: 4),
                Text('Edit',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          CustomSlidableAction(
            onPressed: (_) {
              HapticFeedback.mediumImpact();
              onDelete();
            },
            backgroundColor: const Color(0xFFCA5A5A),
            foregroundColor: Colors.white,
            borderRadius: const BorderRadius.horizontal(right: Radius.circular(16)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(PhosphorIconsFill.trashSimple, size: 20),
                const SizedBox(height: 4),
                const Text('Delete',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
      child: Tappable(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            // ── Cashew left accent bar ──
            Container(
              width: 4,
              height: 64,
              color: catColor,
            ),
            const SizedBox(width: 12),
            // ── Category icon ──
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: catColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                category != null
                    ? IconData(
                        category!.iconCodePoint,
                        fontFamily: PhosphorIconsFill.shoppingCart.fontFamily,
                        fontPackage: 'phosphor_flutter',
                      )
                    : PhosphorIconsFill.question,
                size: 22,
                color: catColor,
              ),
            ),
            const SizedBox(width: 12),
            // ── Title + note + date ──
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
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
                        transaction.note!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        transaction.note!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // ── Amount ──
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Text(
                '${isExpense ? '−' : '+'}${Formatters.currency(transaction.amount)}',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isExpense
                      ? const Color(0xFFCA5A5A)
                      : const Color(0xFF59A849),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  )
      .animate(delay: (index * 30).ms)
        .fadeIn(duration: 300.ms)
        .slideX(begin: 0.03, end: 0);
  }
}
