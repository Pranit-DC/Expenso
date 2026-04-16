// features/insights/screens/insights_screen.dart
// Cashew-inspired: month selector, progress bars per category, animated pie chart.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';

import '../../../core/database/models/transaction_model.dart';
import '../../../core/database/repositories/transaction_repository.dart';
import '../../../core/database/repositories/category_repository.dart';
import '../../../core/utils/formatters.dart';

class InsightsScreen extends ConsumerStatefulWidget {
  const InsightsScreen({super.key});

  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends ConsumerState<InsightsScreen>
    with SingleTickerProviderStateMixin {
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  int? _hoveredIndex;
  late AnimationController _pieController;
  late Animation<double> _pieAnimation;

  @override
  void initState() {
    super.initState();
    _pieController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _pieAnimation = CurvedAnimation(
      parent: _pieController,
      curve: Curves.easeOutCubic,
    );
    _pieController.forward();
  }

  @override
  void dispose() {
    _pieController.dispose();
    super.dispose();
  }

  void _changeMonth(int delta) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedMonth =
          DateTime(_selectedMonth.year, _selectedMonth.month + delta);
      _hoveredIndex = null;
      _pieController.forward(from: 0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final transactions = ref.watch(transactionProvider);
    final categories = ref.watch(categoryProvider);
    final categoryMap = {for (var c in categories) c.id: c};
    final now = DateTime.now();
    final isCurrentMonth = _selectedMonth.year == now.year &&
        _selectedMonth.month == now.month;

    // Filter by selected month
    final monthExpenses = transactions
        .where((t) =>
            t.type == TransactionType.expense &&
            t.date.year == _selectedMonth.year &&
            t.date.month == _selectedMonth.month)
        .toList();

    final monthIncome = transactions
        .where((t) =>
            t.type == TransactionType.income &&
            t.date.year == _selectedMonth.year &&
            t.date.month == _selectedMonth.month)
        .fold(0.0, (s, t) => s + t.amount);

    final totalExpense =
        monthExpenses.fold(0.0, (s, t) => s + t.amount);

    // Group by category
    final categoryTotals = <String, double>{};
    for (final t in monthExpenses) {
      categoryTotals.update(t.categoryId, (v) => v + t.amount,
          ifAbsent: () => t.amount);
    }

    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Pie slices (top 5 + others)
    final slices = <_Slice>[];
    double othersTotal = 0;
    for (int i = 0; i < sortedCategories.length; i++) {
      if (i < 5) {
        slices.add(_Slice(
          categoryId: sortedCategories[i].key,
          amount: sortedCategories[i].value,
        ));
      } else {
        othersTotal += sortedCategories[i].value;
      }
    }
    if (othersTotal > 0) {
      slices.add(_Slice(categoryId: '_others', amount: othersTotal));
    }

    // Pie colors from category colors (fallback palette)
    final fallbackColors = [
      const Color(0xFF4CAF50),
      const Color(0xFF2196F3),
      const Color(0xFFFF9800),
      const Color(0xFFE91E63),
      const Color(0xFF9C27B0),
      const Color(0xFF607D8B),
    ];

    List<Color> pieColors = slices.asMap().entries.map((e) {
      final cat = categoryMap[e.value.categoryId];
      if (cat != null) {
        return Color(int.parse('FF${cat.colorHex}', radix: 16));
      }
      return fallbackColors[e.key % fallbackColors.length];
    }).toList();

    // Key metrics
    final daysPassed = isCurrentMonth
        ? now.day
        : DateUtils.getDaysInMonth(_selectedMonth.year, _selectedMonth.month);
    final dailyAvg = daysPassed > 0 ? totalExpense / daysPassed : 0.0;
    final dayTotals = <int, double>{};
    for (final t in monthExpenses) {
      dayTotals.update(t.date.day, (v) => v + t.amount,
          ifAbsent: () => t.amount);
    }
    int? highestDay;
    double highestDayAmount = 0;
    for (final entry in dayTotals.entries) {
      if (entry.value > highestDayAmount) {
        highestDay = entry.key;
        highestDayAmount = entry.value;
      }
    }

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar.medium(
            title: const Text('Insights'),
            pinned: true,
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Month selector (Cashew < April 2026 >) ──
                  _MonthSelector(
                    month: _selectedMonth,
                    onPrevious: () => _changeMonth(-1),
                    onNext: isCurrentMonth ? null : () => _changeMonth(1),
                    colorScheme: colorScheme,
                    theme: theme,
                  ).animate().fadeIn(duration: 350.ms),

                  const SizedBox(height: 16),

                  if (monthExpenses.isEmpty) ...[
                    SizedBox(
                      height: 320,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(PhosphorIconsDuotone.chartPieSlice,
                                    size: 64,
                                    color: colorScheme.primary
                                        .withValues(alpha: 0.35))
                                .animate()
                                .scale(
                                    duration: 400.ms,
                                    curve: Curves.elasticOut),
                            const SizedBox(height: 16),
                            Text(
                              'No spending this month',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                  color: colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else ...[
                    // ── Income vs Expense summary row ──
                    Row(
                      children: [
                        Expanded(
                          child: _MiniStatCard(
                            label: 'Expenses',
                            value: Formatters.currency(totalExpense),
                            icon: PhosphorIconsFill.arrowUp,
                            iconColor: const Color(0xFFCA5A5A),
                            colorScheme: colorScheme,
                            theme: theme,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _MiniStatCard(
                            label: 'Income',
                            value: Formatters.currency(monthIncome),
                            icon: PhosphorIconsFill.arrowDown,
                            iconColor: const Color(0xFF59A849),
                            colorScheme: colorScheme,
                            theme: theme,
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 50.ms, duration: 350.ms),

                    const SizedBox(height: 20),

                    // ── Animated Pie Chart ──
                    AnimatedBuilder(
                      animation: _pieAnimation,
                      builder: (_, __) => Center(
                        child: SizedBox(
                          height: 240,
                          child: PieChart(
                            PieChartData(
                              sectionsSpace: 2,
                              centerSpaceRadius: 60,
                              pieTouchData: PieTouchData(
                                touchCallback: (event, response) {
                                  setState(() {
                                    if (!event.isInterestedForInteractions ||
                                        response == null ||
                                        response.touchedSection == null) {
                                      _hoveredIndex = null;
                                      return;
                                    }
                                    _hoveredIndex = response
                                        .touchedSection!.touchedSectionIndex;
                                  });
                                },
                              ),
                              sections: slices.asMap().entries.map((entry) {
                                final i = entry.key;
                                final slice = entry.value;
                                final color = pieColors[i];
                                final pct = totalExpense > 0
                                    ? (slice.amount / totalExpense * 100)
                                    : 0.0;
                                final isTouched = _hoveredIndex == i;

                                return PieChartSectionData(
                                  value: slice.amount * _pieAnimation.value,
                                  color: color,
                                  radius: isTouched ? 52 : 42,
                                  title: pct >= 6
                                      ? '${pct.toStringAsFixed(0)}%'
                                      : '',
                                  titleStyle: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                  badgeWidget: isTouched
                                      ? _PieBadge(
                                          color: color,
                                          value: Formatters.currencyCompact(
                                              slice.amount),
                                        )
                                      : null,
                                  badgePositionPercentageOffset: 1.2,
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Category breakdown with Cashew-style progress bars ──
                    Text(
                      'By Category',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),

                    ...slices.asMap().entries.map((entry) {
                      final i = entry.key;
                      final slice = entry.value;
                      final color = pieColors[i];
                      final cat = categoryMap[slice.categoryId];
                      final name = slice.categoryId == '_others'
                          ? 'Others'
                          : (cat?.name ?? 'Unknown');
                      final pct = totalExpense > 0
                          ? slice.amount / totalExpense
                          : 0.0;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _CategoryProgressRow(
                          name: name,
                          amount: slice.amount,
                          percentage: pct,
                          color: color,
                          catIcon: cat != null
                              ? IconData(cat.iconCodePoint,
                                  fontFamily: 'Phosphor-Fill',
                                  fontPackage: 'phosphor_flutter')
                              : PhosphorIconsFill.question,
                          colorScheme: colorScheme,
                          theme: theme,
                          index: i,
                        ),
                      );
                    }),

                    const SizedBox(height: 24),

                    // ── Key Metrics ──
                    Text(
                      'Key Metrics',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _MetricCard(
                            icon: PhosphorIconsFill.chartBar,
                            label: 'Daily Average',
                            value: Formatters.currencyCompact(dailyAvg),
                            colorScheme: colorScheme,
                            theme: theme,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _MetricCard(
                            icon: PhosphorIconsFill.flame,
                            label: 'Highest Day',
                            value: highestDay != null
                                ? 'Day ${highestDay} — ${Formatters.currencyCompact(highestDayAmount)}'
                                : '—',
                            colorScheme: colorScheme,
                            theme: theme,
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 200.ms, duration: 350.ms),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _MetricCard(
                            icon: PhosphorIconsFill.receipt,
                            label: 'Transactions',
                            value: '${monthExpenses.length}',
                            colorScheme: colorScheme,
                            theme: theme,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _MetricCard(
                            icon: PhosphorIconsFill.tag,
                            label: 'Categories Used',
                            value: '${categoryTotals.length}',
                            colorScheme: colorScheme,
                            theme: theme,
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 240.ms, duration: 350.ms),
                  ],

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Month Selector ──
class _MonthSelector extends StatelessWidget {
  final DateTime month;
  final VoidCallback onPrevious;
  final VoidCallback? onNext;
  final ColorScheme colorScheme;
  final ThemeData theme;

  const _MonthSelector({
    required this.month,
    required this.onPrevious,
    required this.onNext,
    required this.colorScheme,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: onPrevious,
            icon: const Icon(Icons.chevron_left_rounded),
            style: IconButton.styleFrom(
              foregroundColor: colorScheme.onSurface,
              padding: const EdgeInsets.all(8),
            ),
          ),
          Text(
            DateFormat('MMMM yyyy').format(month),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          IconButton(
            onPressed: onNext,
            icon: Icon(
              Icons.chevron_right_rounded,
              color: onNext == null
                  ? colorScheme.outlineVariant
                  : colorScheme.onSurface,
            ),
            style: IconButton.styleFrom(padding: const EdgeInsets.all(8)),
          ),
        ],
      ),
    );
  }
}

// ── Category progress bar row ──
class _CategoryProgressRow extends StatelessWidget {
  final String name;
  final double amount;
  final double percentage;
  final Color color;
  final IconData catIcon;
  final ColorScheme colorScheme;
  final ThemeData theme;
  final int index;

  const _CategoryProgressRow({
    required this.name,
    required this.amount,
    required this.percentage,
    required this.color,
    required this.catIcon,
    required this.colorScheme,
    required this.theme,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(catIcon, size: 18, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                Formatters.currency(amount),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 38,
                child: Text(
                  '${(percentage * 100).toStringAsFixed(0)}%',
                  textAlign: TextAlign.right,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.outline,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Cashew-style full-width progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: percentage),
              duration: Duration(milliseconds: 700 + index * 80),
              curve: Curves.easeOutCubic,
              builder: (_, value, __) => LinearProgressIndicator(
                value: value,
                minHeight: 7,
                backgroundColor: colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
        ],
      ),
    )
        .animate(delay: (index * 60).ms)
        .fadeIn(duration: 300.ms)
        .slideY(begin: 0.05, end: 0);
  }
}

// ── Mini stat card (income/expenses summary) ──
class _MiniStatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color iconColor;
  final ColorScheme colorScheme;
  final ThemeData theme;

  const _MiniStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.colorScheme,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant)),
              Text(value,
                  style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Pie tooltip badge ──
class _PieBadge extends StatelessWidget {
  final Color color;
  final String value;

  const _PieBadge({required this.color, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 6),
        ],
      ),
      child: Text(
        value,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ── Metric card ──
class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final ColorScheme colorScheme;
  final ThemeData theme;

  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.colorScheme,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: colorScheme.primary),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _Slice {
  final String categoryId;
  final double amount;
  const _Slice({required this.categoryId, required this.amount});
}
