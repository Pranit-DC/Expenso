// features/dashboard/screens/dashboard_screen.dart
// Cashew-inspired dashboard: greeting header, sliding filter, weekly chart, recent transactions.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';

import '../../../core/database/models/transaction_model.dart';
import '../../../core/database/models/category_model.dart';
import '../../../core/database/repositories/transaction_repository.dart';
import '../../../core/database/repositories/category_repository.dart';
import '../../../core/database/repositories/budget_repository.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/constants.dart';

// ── Sliding filter enum ──
enum _SpendingFilter { all, expense, income }

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  _SpendingFilter _filter = _SpendingFilter.all;
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

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

    // ── Monthly calculations ──
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

    // ── Last 7 days ──
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

    // ── Filter + group recent transactions ──
    final filteredTransactions = transactions.where((t) {
      if (_filter == _SpendingFilter.expense) return t.type == TransactionType.expense;
      if (_filter == _SpendingFilter.income) return t.type == TransactionType.income;
      return true;
    }).take(10).toList();

    // Group by day
    final grouped = <String, List<TransactionModel>>{};
    for (final t in filteredTransactions) {
      final key = Formatters.dateRelative(t.date);
      grouped.putIfAbsent(key, () => []).add(t);
    }

    final categoryMap = {for (var c in categories) c.id: c};

    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Cashew-style Greeting App Bar ──
          _GreetingAppBar(
            greeting: _getGreeting(),
            month: DateFormat('MMMM yyyy').format(now),
            colorScheme: colorScheme,
            theme: theme,
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
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
                  ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.08, end: 0),
                  const SizedBox(height: 16),

                  // ── Budget Progress ──
                  _BudgetCard(
                    limit: budgetLimit,
                    spent: totalExpense,
                    progress: budgetProgress,
                    colorScheme: colorScheme,
                    theme: theme,
                    onSetBudget: () =>
                        _showBudgetDialog(context, ref, budgetLimit),
                  ).animate().fadeIn(delay: 80.ms, duration: 400.ms).slideY(begin: 0.08, end: 0),
                  const SizedBox(height: 20),

                  // ── Weekly Chart ──
                  Text(
                    'Last 7 Days',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _WeeklyChart(
                    data: last7Days,
                    colorScheme: colorScheme,
                    theme: theme,
                  ).animate().fadeIn(delay: 140.ms, duration: 400.ms),
                  const SizedBox(height: 24),

                  // ── Sliding income/expense selector (Cashew SlidingSelectorIncomeExpense) ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (transactions.isNotEmpty)
                        TextButton(
                          onPressed: () {},
                          child: const Text('See all'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _SlidingFilterSelector(
                    selected: _filter,
                    onChanged: (f) => setState(() => _filter = f),
                    colorScheme: colorScheme,
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),

          // ── Grouped recent transactions ──
          if (filteredTransactions.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 18),
                child: Center(
                  child: Column(
                    children: [
                      Icon(PhosphorIconsDuotone.plusCircle,
                          size: 48,
                          color: colorScheme.primary.withValues(alpha: 0.4)),
                      const SizedBox(height: 12),
                      Text(
                        'Tap Add to record your first transaction',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            ...grouped.entries.map((entry) {
              // compute daily total (net: income positive, expense negative)
              double dayTotal = entry.value.fold(0.0, (s, t) {
                return s + (t.type == TransactionType.income ? t.amount : -t.amount);
              });
              final isPositiveDay = dayTotal >= 0;

              return SliverMainAxisGroup(
                slivers: [
                  // Date divider with daily total (Cashew DateDivider)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding:
                          const EdgeInsets.fromLTRB(18, 4, 18, 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            entry.key,
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: colorScheme.primary,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            '${isPositiveDay ? '+' : ''}${Formatters.currencyCompact(dayTotal)}',
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isPositiveDay
                                  ? const Color(0xFF59A849)
                                  : const Color(0xFFCA5A5A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverList.builder(
                    itemCount: entry.value.length,
                    itemBuilder: (context, index) {
                      final t = entry.value[index];
                      final cat = categoryMap[t.categoryId];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: _RecentTransactionTile(
                          transaction: t,
                          category: cat,
                          colorScheme: colorScheme,
                          theme: theme,
                          index: index,
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

  void _showBudgetDialog(
      BuildContext context, WidgetRef ref, double currentLimit) {
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

// ══════════════════════════════════════════════════
//  Greeting App Bar (Cashew HomePageUsername style)
// ══════════════════════════════════════════════════

class _GreetingAppBar extends StatelessWidget {
  final String greeting;
  final String month;
  final ColorScheme colorScheme;
  final ThemeData theme;

  const _GreetingAppBar({
    required this.greeting,
    required this.month,
    required this.colorScheme,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: true,
      snap: true,
      pinned: false,
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        titlePadding: const EdgeInsetsDirectional.only(start: 18, bottom: 14),
        title: Text(
          month,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        background: Padding(
          padding: EdgeInsets.only(
            left: 18,
            right: 18,
            top: MediaQuery.of(context).padding.top + 12,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                  height: 1.1,
                ),
              ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.1, end: 0),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════
//  Sliding Filter (Cashew SlidingSelectorIncomeExpense)
// ══════════════════════════════════════════════════

class _SlidingFilterSelector extends StatelessWidget {
  final _SpendingFilter selected;
  final ValueChanged<_SpendingFilter> onChanged;
  final ColorScheme colorScheme;

  const _SlidingFilterSelector({
    required this.selected,
    required this.onChanged,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: [
          _filterChip('All', _SpendingFilter.all),
          _filterChip('Expense', _SpendingFilter.expense),
          _filterChip('Income', _SpendingFilter.income),
        ],
      ),
    );
  }

  Widget _filterChip(String label, _SpendingFilter filter) {
    final isSelected = selected == filter;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(filter),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.primaryContainer : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════
//  Balance Card
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
            colorScheme.primary.withValues(alpha: 0.75),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Balance',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.75),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            Formatters.currency(balance),
            style: theme.textTheme.headlineLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 32,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _BalanceMini(
                icon: PhosphorIconsFill.arrowDown,
                label: 'Income',
                amount: Formatters.currencyCompact(income),
                iconColor: const Color(0xFF62CA77),
              ),
              const SizedBox(width: 28),
              _BalanceMini(
                icon: PhosphorIconsFill.arrowUp,
                label: 'Expense',
                amount: Formatters.currencyCompact(expense),
                iconColor: const Color(0xFFDA7272),
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
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: iconColor),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.7))),
            Text(amount,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
          ],
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════
//  Budget Progress Card
// ══════════════════════════════════════════════════

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
          padding: const EdgeInsets.all(18),
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
              Icon(PhosphorIconsRegular.caretRight, color: colorScheme.outline),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onSetBudget,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
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
                    color: isOver
                        ? const Color(0xFFCA5A5A)
                        : colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: progress.clamp(0.0, 1.0)),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
                builder: (_, value, __) => LinearProgressIndicator(
                  value: value,
                  minHeight: 10,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isOver
                        ? const Color(0xFFCA5A5A)
                        : colorScheme.primary,
                  ),
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
                    color: isOver
                        ? const Color(0xFFCA5A5A)
                        : const Color(0xFF59A849),
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

// ══════════════════════════════════════════════════
//  Weekly Bar Chart
// ══════════════════════════════════════════════════

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
              tooltipPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
                  gradient: isToday
                      ? LinearGradient(
                          colors: [
                            colorScheme.primary,
                            colorScheme.primary.withValues(alpha: 0.7),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        )
                      : null,
                  color: isToday
                      ? null
                      : colorScheme.primary.withValues(alpha: 0.3),
                  width: 26,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(8),
                  ),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: maxAmount > 0 ? maxAmount * 1.3 : 100,
                    color: colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.5),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
        swapAnimationDuration: const Duration(milliseconds: 600),
        swapAnimationCurve: Curves.easeOutCubic,
      ),
    );
  }
}

// ══════════════════════════════════════════════════
//  Recent Transaction Tile (Cashew-style with accent bar)
// ══════════════════════════════════════════════════

class _RecentTransactionTile extends StatelessWidget {
  final TransactionModel transaction;
  final CategoryModel? category;
  final ColorScheme colorScheme;
  final ThemeData theme;
  final int index;

  const _RecentTransactionTile({
    required this.transaction,
    required this.category,
    required this.colorScheme,
    required this.theme,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final isExpense = transaction.type == TransactionType.expense;
    final catColor = category != null
        ? Color(int.parse('FF${category!.colorHex}', radix: 16))
        : colorScheme.outline;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            // Cashew left accent bar
            Container(width: 4, height: 56, color: catColor),
            const SizedBox(width: 12),
            // Category icon
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
                  if (transaction.note != null && transaction.note!.isNotEmpty)
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
    )
        .animate(delay: (index * 40).ms)
        .fadeIn(duration: 300.ms)
        .slideX(begin: 0.04, end: 0);
  }
}
