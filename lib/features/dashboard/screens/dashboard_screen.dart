// features/dashboard/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/database/models/transaction_model.dart';
import '../../../core/database/repositories/transaction_repository.dart';
import '../../../core/database/repositories/category_repository.dart';
import '../../../core/database/repositories/budget_repository.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/constants.dart';
import '../../../core/routing/app_router.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  TransactionType? _filter;

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final transactions = ref.watch(transactionProvider);
    final budget = ref.watch(budgetProvider);
    final categories = ref.watch(categoryProvider);
    final now = DateTime.now();

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

    final filteredTransactions = transactions.where((t) {
      if (_filter == null) return true;
      return t.type == _filter;
    }).take(10).toList();

    final grouped = <String, List<TransactionModel>>{};
    for (final t in filteredTransactions) {
      final key = Formatters.dateRelative(t.date);
      grouped.putIfAbsent(key, () => []).add(t);
    }

    final categoryMap = {for (var c in categories) c.id: c};

    return Scaffold(
      appBar: AppBar(
        title: Text(_getGreeting()),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Balance Card (M3) ──
                  Card(
                    color: colorScheme.primaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Balance',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            Formatters.currency(balance),
                            style: theme.textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              _BalanceMini(
                                icon: Icons.arrow_downward,
                                label: 'Income',
                                amount: Formatters.currencyCompact(totalIncome),
                                colorScheme: colorScheme,
                              ),
                              const SizedBox(width: 32),
                              _BalanceMini(
                                icon: Icons.arrow_upward,
                                label: 'Expense',
                                amount: Formatters.currencyCompact(totalExpense),
                                colorScheme: colorScheme,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Budget Progress ──
                  Card(
                    child: InkWell(
                      onTap: () => _showBudgetDialog(context, ref, budgetLimit),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: limitUI(budgetLimit, totalExpense, budgetProgress, theme, colorScheme),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Weekly Chart ──
                  Text(
                    'Last 7 Days',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: _WeeklyChart(
                        data: last7Days,
                        colorScheme: colorScheme,
                        theme: theme,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Recent Transactions ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Recent Transactions', style: theme.textTheme.titleMedium),
                      if (transactions.isNotEmpty)
                        TextButton(
                          onPressed: () => context.go(AppRoutes.history),
                          child: const Text('See all'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<TransactionType?>(
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
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          
          if (filteredTransactions.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Center(
                  child: Text(
                    'No transactions found.',
                    style: theme.textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                ),
              ),
            )
          else
            ...grouped.entries.map((entry) {
              return SliverMainAxisGroup(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: Text(
                        entry.key,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                  SliverList.builder(
                    itemCount: entry.value.length,
                    itemBuilder: (context, index) {
                      final t = entry.value[index];
                      final cat = categoryMap[t.categoryId];
                      final isExpense = t.type == TransactionType.expense;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: ListTile(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          tileColor: colorScheme.surfaceContainerLow,
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
                                      fontFamily: PhosphorIconsFill.shoppingCart.fontFamily,
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

  Widget limitUI(double limit, double spent, double progress, ThemeData theme, ColorScheme colorScheme) {
    if (limit <= 0) {
      return Row(
        children: [
          Icon(Icons.track_changes, color: colorScheme.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Set a monthly budget', style: theme.textTheme.titleMedium),
                Text('Track your spending goals', style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      );
    }

    final isOver = spent > limit;
    final remaining = (limit - spent).clamp(0.0, double.infinity);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Monthly Budget', style: theme.textTheme.titleMedium),
            Text(
              '${((progress * 100).clamp(0.0, 100.0)).toStringAsFixed(0)}%',
              style: theme.textTheme.titleMedium?.copyWith(
                color: isOver ? colorScheme.error : colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: colorScheme.surfaceContainerHighest,
          color: isOver ? colorScheme.error : colorScheme.primary,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Spent: ${Formatters.currencyCompact(spent)}', style: theme.textTheme.bodySmall),
            Text(
              isOver ? 'Over by ${Formatters.currencyCompact(spent - limit)}' : 'Left: ${Formatters.currencyCompact(remaining)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isOver ? colorScheme.error : colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showBudgetDialog(BuildContext context, WidgetRef ref, double currentLimit) {
    final controller = TextEditingController(
        text: currentLimit > 0 ? currentLimit.toStringAsFixed(0) : '');

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

class _BalanceMini extends StatelessWidget {
  final IconData icon;
  final String label, amount;
  final ColorScheme colorScheme;

  const _BalanceMini({
    required this.icon,
    required this.label,
    required this.amount,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: colorScheme.onPrimaryContainer.withValues(alpha: 0.7)),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 12, color: colorScheme.onPrimaryContainer.withValues(alpha: 0.8))),
            Text(amount, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorScheme.onPrimaryContainer)),
          ],
        ),
      ],
    );
  }
}

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
    final maxAmount = data.fold(0.0, (max, d) => d.amount > max ? d.amount : max);

    return SizedBox(
      height: 150,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxAmount > 0 ? maxAmount * 1.2 : 100,
          barTouchData: BarTouchData(enabled: false),
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
                  if (index < 0 || index >= data.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      DateFormat('E').format(data[index].day).substring(0, 1),
                      style: theme.textTheme.bodySmall,
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
                  color: isToday ? colorScheme.primary : colorScheme.primaryContainer,
                  width: 16,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
