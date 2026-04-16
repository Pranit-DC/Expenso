// features/dashboard/screens/dashboard_screen.dart
// Main dashboard with balance card, budget progress, and weekly spending chart.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';

import '../../../core/database/models/transaction_model.dart';
import '../../../core/database/models/category_model.dart';
import '../../../core/database/repositories/transaction_repository.dart';
import '../../../core/database/repositories/category_repository.dart';
import '../../../core/database/repositories/budget_repository.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/constants.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final transactions = ref.watch(transactionProvider);
    final budget = ref.watch(budgetProvider);
    final categories = ref.watch(categoryProvider);

    final now = DateTime.now();

    // ── Calculations ──
    final monthTransactions = transactions
        .where((t) => t.date.year == now.year && t.date.month == now.month)
        .toList();

    final totalIncome = monthTransactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);

    final totalExpense = monthTransactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);

    final balance = totalIncome - totalExpense;

    final budgetLimit = budget.monthlyLimit;
    final budgetProgress =
        budgetLimit > 0 ? (totalExpense / budgetLimit).clamp(0.0, 1.5) : 0.0;

    // Last 7 days spending
    final last7Days = List.generate(7, (i) {
      final day = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: 6 - i));
      final dayExpenses = transactions.where((t) {
        return t.type == TransactionType.expense &&
            t.date.year == day.year &&
            t.date.month == day.month &&
            t.date.day == day.day;
      }).fold(0.0, (sum, t) => sum + t.amount);
      return _DaySpending(day: day, amount: dayExpenses);
    });

    // Recent transactions (last 5)
    final recent = transactions.take(5).toList();
    final categoryMap = {for (var c in categories) c.id: c};

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── App Bar ──
          SliverAppBar.large(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Expenso',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(PhosphorIconsRegular.bell),
                onPressed: () {},
                tooltip: 'Notifications',
              ),
              const SizedBox(width: 8),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Balance Card ──
                  _BalanceCard(
                    balance: balance,
                    income: totalIncome,
                    expense: totalExpense,
                    colorScheme: colorScheme,
                    theme: theme,
                  ),
                  const SizedBox(height: 20),

                  // ── Budget Progress ──
                  _BudgetCard(
                    limit: budgetLimit,
                    spent: totalExpense,
                    progress: budgetProgress,
                    colorScheme: colorScheme,
                    theme: theme,
                    onSetBudget: () =>
                        _showBudgetDialog(context, ref, budgetLimit),
                  ),
                  const SizedBox(height: 20),

                  // ── Weekly Chart ──
                  Text(
                    'Last 7 Days',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _WeeklyChart(
                    data: last7Days,
                    colorScheme: colorScheme,
                    theme: theme,
                  ),
                  const SizedBox(height: 24),

                  // ── Recent Transactions ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Transactions',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (transactions.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            // Navigate to history tab — index 1
                          },
                          child: const Text('See all'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (recent.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(PhosphorIconsDuotone.plusCircle,
                                size: 48,
                                color: colorScheme.primary
                                    .withValues(alpha: 0.4)),
                            const SizedBox(height: 12),
                            Text(
                              'Tap + to add your first transaction',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...recent.map((t) {
                      final cat = categoryMap[t.categoryId];
                      return _RecentTransactionTile(
                        transaction: t,
                        category: cat,
                        colorScheme: colorScheme,
                        theme: theme,
                      );
                    }),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showBudgetDialog(
      BuildContext context, WidgetRef ref, double currentLimit) {
    final controller =
        TextEditingController(text: currentLimit > 0 ? currentLimit.toStringAsFixed(0) : '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set Monthly Budget'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            prefixText: '${AppConstants.currencySymbol} ',
            hintText: 'e.g. 50000',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final val = double.tryParse(controller.text.trim());
              if (val != null && val > 0) {
                ref.read(budgetProvider.notifier).setMonthlyLimit(val);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════
//  Dashboard Widgets
// ══════════════════════════════════════════════════

class _BalanceCard extends StatelessWidget {
  final double balance, income, expense;
  final ColorScheme colorScheme;
  final ThemeData theme;

  const _BalanceCard({
    required this.balance,
    required this.income,
    required this.expense,
    required this.colorScheme,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary,
            colorScheme.primary.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Balance',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            Formatters.currency(balance),
            style: theme.textTheme.headlineLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _BalanceMini(
                icon: PhosphorIconsFill.arrowDown,
                label: 'Income',
                amount: Formatters.currencyCompact(income),
                iconColor: Colors.greenAccent.shade200,
              ),
              const SizedBox(width: 24),
              _BalanceMini(
                icon: PhosphorIconsFill.arrowUp,
                label: 'Expense',
                amount: Formatters.currencyCompact(expense),
                iconColor: Colors.redAccent.shade100,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BalanceMini extends StatelessWidget {
  final IconData icon;
  final String label, amount;
  final Color iconColor;

  const _BalanceMini({
    required this.icon,
    required this.label,
    required this.amount,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: iconColor),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.7))),
            Text(amount,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
          ],
        ),
      ],
    );
  }
}

// ── Budget Progress Card ──
class _BudgetCard extends StatelessWidget {
  final double limit, spent, progress;
  final ColorScheme colorScheme;
  final ThemeData theme;
  final VoidCallback onSetBudget;

  const _BudgetCard({
    required this.limit,
    required this.spent,
    required this.progress,
    required this.colorScheme,
    required this.theme,
    required this.onSetBudget,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = (limit - spent).clamp(0.0, double.infinity);
    final isOver = spent > limit && limit > 0;

    if (limit <= 0) {
      return GestureDetector(
        onTap: onSetBudget,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            children: [
              Icon(PhosphorIconsDuotone.target,
                  size: 32, color: colorScheme.primary),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Set a monthly budget',
                        style: theme.textTheme.bodyLarge
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    Text('Track your spending goals',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              Icon(PhosphorIconsRegular.caretRight,
                  color: colorScheme.outline),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onSetBudget,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Monthly Budget',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
                Text(
                  '${(progress * 100).toStringAsFixed(0)}%',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isOver ? Colors.red.shade400 : colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                minHeight: 10,
                backgroundColor:
                    colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isOver ? Colors.red.shade400 : colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Spent: ${Formatters.currencyCompact(spent)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  isOver
                      ? 'Over by ${Formatters.currencyCompact(spent - limit)}'
                      : 'Left: ${Formatters.currencyCompact(remaining)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isOver ? Colors.red.shade400 : Colors.green.shade500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Weekly Spending Chart ──
class _DaySpending {
  final DateTime day;
  final double amount;
  const _DaySpending({required this.day, required this.amount});
}

class _WeeklyChart extends StatelessWidget {
  final List<_DaySpending> data;
  final ColorScheme colorScheme;
  final ThemeData theme;

  const _WeeklyChart({
    required this.data,
    required this.colorScheme,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final maxAmount =
        data.fold(0.0, (max, d) => d.amount > max ? d.amount : max);

    return Container(
      height: 180,
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxAmount > 0 ? maxAmount * 1.3 : 100,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              tooltipRoundedRadius: 10,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  Formatters.currencyCompact(rod.toY),
                  TextStyle(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= data.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      DateFormat('E').format(data[index].day).substring(0, 2),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: data.asMap().entries.map((entry) {
            final isToday = entry.key == data.length - 1;
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: entry.value.amount > 0 ? entry.value.amount : 0,
                  color: isToday
                      ? colorScheme.primary
                      : colorScheme.primary.withValues(alpha: 0.35),
                  width: 28,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(8),
                  ),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: maxAmount > 0 ? maxAmount * 1.3 : 100,
                    color: colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.4),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
        swapAnimationDuration: const Duration(milliseconds: 300),
      ),
    );
  }
}

// ── Recent Transaction Tile ──
class _RecentTransactionTile extends StatelessWidget {
  final TransactionModel transaction;
  final CategoryModel? category;
  final ColorScheme colorScheme;
  final ThemeData theme;

  const _RecentTransactionTile({
    required this.transaction,
    required this.category,
    required this.colorScheme,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final isExpense = transaction.type == TransactionType.expense;
    final catColor = category != null
        ? Color(int.parse('FF${category!.colorHex}', radix: 16))
        : colorScheme.outline;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: catColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                category != null
                    ? IconData(category!.iconCodePoint,
                        fontFamily: 'Phosphor-Fill',
                        fontPackage: 'phosphor_flutter')
                    : PhosphorIconsFill.question,
                size: 20,
                color: catColor,
              ),
            ),
            const SizedBox(width: 12),
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
                  Text(
                    Formatters.dateRelative(transaction.date),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.outline,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${isExpense ? '−' : '+'}${Formatters.currency(transaction.amount)}',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color:
                    isExpense ? Colors.red.shade400 : Colors.green.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
