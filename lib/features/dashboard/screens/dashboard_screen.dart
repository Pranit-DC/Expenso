// features/dashboard/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/database/models/transaction_model.dart';
import '../../../core/database/models/category_model.dart';
import '../../../core/database/repositories/transaction_repository.dart';
import '../../../core/database/repositories/category_repository.dart';
import '../../../core/database/repositories/budget_repository.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/constants.dart';
import '../../../core/utils/color_utils.dart';
import '../../../core/routing/app_router.dart';
import 'package:flutter/services.dart';
import '../../transactions/screens/widgets/number_pad.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  TransactionType? _filter;
  bool _isAllTime = true;

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

    final allTimeIncome = transactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);

    final allTimeExpense = transactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);

    final currentIncome = _isAllTime ? allTimeIncome : totalIncome;
    final currentExpense = _isAllTime ? allTimeExpense : totalExpense;
    final balance = currentIncome - currentExpense;
    final budgetLimit = budget.monthlyLimit;
    final budgetProgress =
        budgetLimit > 0 ? (totalExpense / budgetLimit).clamp(0.0, 1.5) : 0.0;

    final last7Days = List.generate(7, (i) {
      final day = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: 6 - i));
      
      final categoryAmounts = <String, double>{};
      final dayTransactions = transactions.where((t) {
        return t.type == TransactionType.expense &&
            t.date.year == day.year &&
            t.date.month == day.month &&
            t.date.day == day.day;
      });

      double total = 0;
      for (final t in dayTransactions) {
        categoryAmounts.update(t.categoryId, (v) => v + t.amount, ifAbsent: () => t.amount);
        total += t.amount;
      }

      return _DaySpending(day: day, categoryAmounts: categoryAmounts, total: total);
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
      body: CustomScrollView(
        slivers: [
          SliverAppBar.medium(
            title: Text(_getGreeting()),
            pinned: true,
            centerTitle: false,
          ),
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _isAllTime ? 'Total Balance' : 'Monthly Balance',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                                ),
                              ),
                              SegmentedButton<bool>(
                                segments: const [
                                  ButtonSegment(value: false, label: Text('Month', style: TextStyle(fontSize: 10))),
                                  ButtonSegment(value: true, label: Text('All', style: TextStyle(fontSize: 10))),
                                ],
                                selected: {_isAllTime},
                                onSelectionChanged: (val) {
                                  setState(() => _isAllTime = val.first);
                                },
                                showSelectedIcon: false,
                                style: SegmentedButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  backgroundColor: colorScheme.primaryContainer,
                                  selectedBackgroundColor: colorScheme.onPrimaryContainer.withValues(alpha: 0.1),
                                  selectedForegroundColor: colorScheme.onPrimaryContainer,
                                  foregroundColor: colorScheme.onPrimaryContainer.withValues(alpha: 0.6),
                                  side: BorderSide(color: colorScheme.onPrimaryContainer.withValues(alpha: 0.1)),
                                ),
                              ),
                            ],
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
                                amount: Formatters.currencyCompact(currentIncome),
                                colorScheme: colorScheme,
                              ),
                              const SizedBox(width: 32),
                              _BalanceMini(
                                icon: Icons.arrow_upward,
                                label: 'Expense',
                                amount: Formatters.currencyCompact(currentExpense),
                                colorScheme: colorScheme,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => _showBudgetSheet(context, ref, budgetLimit),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: limitUI(budgetLimit, totalExpense, budgetProgress, theme, colorScheme),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Weekly Chart ──
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      children: [
                        Icon(PhosphorIconsFill.chartBar, size: 18, color: colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Spending Insights',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 240,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
                    ),
                    child: _WeeklyChart(
                      data: last7Days,
                      categoryMap: categoryMap,
                      colorScheme: colorScheme,
                      theme: theme,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── Recent Transactions ──
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(PhosphorIconsFill.clockCounterClockwise, size: 18, color: colorScheme.primary),
                            const SizedBox(width: 8),
                            Text(
                              'Recent Activity',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                        if (transactions.isNotEmpty)
                          TextButton(
                            onPressed: () => context.go(AppRoutes.history),
                            child: const Text('See all'),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<TransactionType?>(
                    showSelectedIcon: false,
                    style: SegmentedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      selectedBackgroundColor: colorScheme.primary,
                      selectedForegroundColor: colorScheme.onPrimary,
                    ),
                    segments: const [
                      ButtonSegment(value: null, label: Text('All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                      ButtonSegment(value: TransactionType.expense, label: Text('Expense', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                      ButtonSegment(value: TransactionType.income, label: Text('Income', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
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
              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                sliver: SliverMainAxisGroup(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: Text(
                          entry.key.toUpperCase(),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                            fontSize: 10,
                          ),
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
                          children: List.generate(entry.value.length, (index) {
                            final t = entry.value[index];
                            final cat = categoryMap[t.categoryId];
                            final isExpense = t.type == TransactionType.expense;

                            return Column(
                              children: [
                                ListTile(
                                  onTap: () => context.push(AppRoutes.addTransaction, extra: t),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                                  leading: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: cat != null
                                          ? Color(int.parse('FF${cat.colorHex}', radix: 16)).withValues(alpha: 0.15)
                                          : colorScheme.surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Icon(
                                      cat != null
                                          ? IconData(cat.iconCodePoint,
                                              fontFamily: PhosphorIconsFill.shoppingCart.fontFamily,
                                              fontPackage: 'phosphor_flutter')
                                          : PhosphorIconsFill.receipt,
                                      color: cat != null ? Color(int.parse('FF${cat.colorHex}', radix: 16)) : colorScheme.onSurfaceVariant,
                                      size: 20,
                                    ),
                                  ),
                                  title: Text(
                                    cat?.name ?? 'Unknown',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                  subtitle: t.note != null && t.note!.isNotEmpty
                                      ? Text(t.note!, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12))
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
                                if (index < entry.value.length - 1)
                                  Divider(
                                    height: 1,
                                    indent: 64,
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

  void _showBudgetSheet(BuildContext context, WidgetRef ref, double currentLimit) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (ctx) => _BudgetEntrySheet(
        initialLimit: currentLimit,
        onSave: (val) {
          ref.read(budgetProvider.notifier).setMonthlyLimit(val);
        },
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
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.onPrimaryContainer.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon == Icons.arrow_downward ? PhosphorIconsFill.arrowDown : PhosphorIconsFill.arrowUp,
            size: 16,
            color: colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
              ),
            ),
            Text(
              amount,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: colorScheme.onPrimaryContainer,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DaySpending {
  final DateTime day;
  final Map<String, double> categoryAmounts;
  final double total;
  const _DaySpending({required this.day, required this.categoryAmounts, required this.total});
}

class _WeeklyChart extends StatelessWidget {
  final List<_DaySpending> data;
  final Map<String, CategoryModel> categoryMap;
  final ColorScheme colorScheme;
  final ThemeData theme;

  const _WeeklyChart({
    required this.data,
    required this.categoryMap,
    required this.colorScheme,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final maxAmount = data.fold(0.0, (max, d) => d.total > max ? d.total : max);

    return SizedBox(
      height: 150,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxAmount > 0 ? maxAmount * 1.2 : 100,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              tooltipBgColor: colorScheme.surfaceContainerHighest,
              tooltipRoundedRadius: 8,
              tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              tooltipMargin: 8,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${AppConstants.currencySymbol}${rod.toY.toStringAsFixed(0)}',
                  theme.textTheme.labelLarge!.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
            touchCallback: (event, response) {
              if (event is FlTapDownEvent && response?.spot != null) {
                HapticFeedback.lightImpact();
              }
            },
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
            final spending = entry.value;
            final sortedCategories = spending.categoryAmounts.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));

            double runningTotal = 0;
            final stackItems = sortedCategories.asMap().entries.map((stackEntry) {
              final i = stackEntry.key;
              final catEntry = stackEntry.value;
              final start = runningTotal;
              runningTotal += catEntry.value;
              return BarChartRodStackItem(
                start,
                runningTotal,
                ColorUtils.getHarmonicColor(context, i, sortedCategories.length),
              );
            }).toList();

            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: spending.total > 0 ? spending.total : 0,
                  width: 16,
                  borderRadius: BorderRadius.circular(4),
                  rodStackItems: stackItems,
                  color: colorScheme.surfaceContainerHighest, // Background color for empty rod
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _BudgetEntrySheet extends StatefulWidget {
  final double initialLimit;
  final ValueChanged<double> onSave;

  const _BudgetEntrySheet({
    required this.initialLimit,
    required this.onSave,
  });

  @override
  State<_BudgetEntrySheet> createState() => _BudgetEntrySheetState();
}

class _BudgetEntrySheetState extends State<_BudgetEntrySheet> {
  late String _amountStr;

  @override
  void initState() {
    super.initState();
    _amountStr = widget.initialLimit > 0 ? widget.initialLimit.toStringAsFixed(0) : '';
  }

  void _onKeyPressed(String key) {
    if (key == '.' && _amountStr.contains('.')) return;
    if (_amountStr.length >= 9) return;
    setState(() {
      _amountStr += key;
    });
  }

  void _onBackspace() {
    if (_amountStr.isEmpty) return;
    setState(() {
      _amountStr = _amountStr.substring(0, _amountStr.length - 1);
    });
  }

  void _onClear() {
    setState(() {
      _amountStr = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          Text(
            'Set Monthly Budget',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Budget Amount',
            style: theme.textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${AppConstants.currencySymbol}${_amountStr.isEmpty ? "0" : _amountStr}',
            style: theme.textTheme.displayMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 32),
          NumberPad(
            onKeyPressed: _onKeyPressed,
            onBackspace: _onBackspace,
            onClear: _onClear,
            activeColor: colorScheme.primary,
            onDone: () {
              final val = double.tryParse(_amountStr);
              if (val != null && val > 0) {
                widget.onSave(val);
              }
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
