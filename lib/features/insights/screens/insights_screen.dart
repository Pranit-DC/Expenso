import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:flutter_heatmap_calendar/flutter_heatmap_calendar.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/database/models/transaction_model.dart';
import '../../../core/database/repositories/transaction_repository.dart';
import '../../../core/database/repositories/category_repository.dart';
import '../../../core/utils/color_utils.dart';
import '../../../core/utils/formatters.dart';

class InsightsScreen extends ConsumerStatefulWidget {
  const InsightsScreen({super.key});

  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

enum _HeatMapType { expense, income }

class _InsightsScreenState extends ConsumerState<InsightsScreen> {
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  int? _hoveredIndex;
  _HeatMapType _heatmapType = _HeatMapType.expense;

  void _changeMonth(int delta) {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + delta);
      _hoveredIndex = null;
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
    final isCurrentMonth = _selectedMonth.year == now.year && _selectedMonth.month == now.month;

    // Heatmap data preparation
    final heatmapData = <DateTime, int>{};
    final relevantTransactions = transactions.where((t) => t.type == (_heatmapType == _HeatMapType.expense ? TransactionType.expense : TransactionType.income));
    
    final dailyTotals = <DateTime, double>{};
    for (final t in relevantTransactions) {
      final date = DateTime(t.date.year, t.date.month, t.date.day);
      dailyTotals.update(date, (v) => v + t.amount, ifAbsent: () => t.amount);
    }

    if (dailyTotals.isNotEmpty) {
      final maxVal = dailyTotals.values.fold(0.0, (m, v) => v > m ? v : m);
      for (final entry in dailyTotals.entries) {
        // Map to 1-10 scale
        final intensity = (entry.value / maxVal * 10).ceil();
        heatmapData[entry.key] = intensity;
      }
    }

    // Filter by selected month
    final monthExpenses = transactions
        .where((t) => t.type == TransactionType.expense && t.date.year == _selectedMonth.year && t.date.month == _selectedMonth.month)
        .toList();

    final monthIncome = transactions
        .where((t) => t.type == TransactionType.income && t.date.year == _selectedMonth.year && t.date.month == _selectedMonth.month)
        .fold(0.0, (s, t) => s + t.amount);

    final totalExpense = monthExpenses.fold(0.0, (s, t) => s + t.amount);

    // Group by category
    final categoryTotals = <String, double>{};
    for (final t in monthExpenses) {
      categoryTotals.update(t.categoryId, (v) => v + t.amount, ifAbsent: () => t.amount);
    }

    final sortedCategories = categoryTotals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    // Pie slices
    final slices = <_Slice>[];
    double othersTotal = 0;
    for (int i = 0; i < sortedCategories.length; i++) {
      if (i < 5) {
        slices.add(_Slice(categoryId: sortedCategories[i].key, amount: sortedCategories[i].value));
      } else {
        othersTotal += sortedCategories[i].value;
      }
    }
    if (othersTotal > 0) {
      slices.add(_Slice(categoryId: '_others', amount: othersTotal));
    }

    // Pie colors (Monochromatic)
    final pieColors = ColorUtils.generateMonochromaticPalette(colorScheme.primary, slices.length);

    // MoM Trend
    final lastMonthDate = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    final lastMonthExpenses = transactions
        .where((t) => t.type == TransactionType.expense && t.date.year == lastMonthDate.year && t.date.month == lastMonthDate.month)
        .fold(0.0, (s, t) => s + t.amount);
    final momDiff = lastMonthExpenses > 0 ? ((totalExpense - lastMonthExpenses) / lastMonthExpenses) * 100 : 0.0;

    // Daily Average
    final daysPassed = isCurrentMonth ? now.day : DateUtils.getDaysInMonth(_selectedMonth.year, _selectedMonth.month);
    final dailyAvg = daysPassed > 0 ? totalExpense / daysPassed : 0.0;

    // Weekday vs Weekend & Top Day
    double weekdayTotal = 0;
    double weekendTotal = 0;
    final dayTotals = <int, double>{};
    for (final t in monthExpenses) {
      final wd = t.date.weekday;
      dayTotals.update(wd, (v) => v + t.amount, ifAbsent: () => t.amount);
      if (wd <= 5) {
        weekdayTotal += t.amount;
      } else {
        weekendTotal += t.amount;
      }
    }

    int topDay = 1;
    double maxDaySum = 0;
    dayTotals.forEach((day, sum) {
      if (sum > maxDaySum) {
        maxDaySum = sum;
        topDay = day;
      }
    });
    // 2024-01-01 was Monday
    final topDayName = monthExpenses.isEmpty ? 'N/A' : DateFormat('EEEE').format(DateTime(2024, 1, topDay));

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.medium(
            title: const Text('Insights'),
            pinned: true,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Month Selector ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => _changeMonth(-1),
                        style: IconButton.styleFrom(
                          backgroundColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: Icon(PhosphorIconsBold.caretLeft, size: 18, color: colorScheme.onSurface),
                      ),
                      Text(
                        DateFormat('MMMM yyyy').format(_selectedMonth),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      IconButton(
                        onPressed: isCurrentMonth ? null : () => _changeMonth(1),
                        style: IconButton.styleFrom(
                          backgroundColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: Icon(
                          PhosphorIconsBold.caretRight,
                          size: 18,
                          color: isCurrentMonth ? colorScheme.onSurface.withValues(alpha: 0.3) : colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (monthExpenses.isEmpty)
                    SizedBox(
                      height: 300,
                      child: Center(
                        child: Text(
                          'No spending this month',
                          style: theme.textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                      ),
                    )
                  else ...[
                    // ── Summary Cards ──
                    Row(
                      children: [
                        Expanded(
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.arrow_upward, size: 16, color: colorScheme.error),
                                      const SizedBox(width: 8),
                                      const Text('Expenses', style: TextStyle(fontSize: 10)),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(Formatters.currencyCompact(totalExpense), style: theme.textTheme.titleLarge),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.arrow_downward, size: 16, color: colorScheme.primary),
                                      const SizedBox(width: 8),
                                      const Text('Income', style: TextStyle(fontSize: 10)),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(Formatters.currencyCompact(monthIncome), style: theme.textTheme.titleLarge),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _InsightChip(
                            icon: momDiff <= 0 ? PhosphorIconsFill.trendDown : PhosphorIconsFill.trendUp,
                            label: 'Trend vs Prev',
                            value: '${momDiff > 0 ? '+' : ''}${momDiff.toStringAsFixed(1)}%',
                            color: momDiff <= 0 ? Colors.green : Colors.orange,
                          ),
                          const SizedBox(width: 8),
                          _InsightChip(
                            icon: PhosphorIconsFill.lightning,
                            label: 'Daily Average',
                            value: Formatters.currencyCompact(dailyAvg),
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          _InsightChip(
                            icon: PhosphorIconsFill.calendarBlank,
                            label: 'Top Day',
                            value: topDayName,
                            color: colorScheme.secondary,
                          ),
                          const SizedBox(width: 8),
                          _InsightChip(
                            icon: PhosphorIconsFill.house,
                            label: 'Lifestyle',
                            value: weekendTotal > weekdayTotal ? 'Weekend' : 'Weekday',
                            color: colorScheme.tertiary,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 250,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          PieChart(
                            PieChartData(
                              sectionsSpace: 4,
                              centerSpaceRadius: 70,
                              pieTouchData: PieTouchData(
                                touchCallback: (event, response) {
                                  if (event is FlTapDownEvent || event is FlPanUpdateEvent) {
                                    if (response?.touchedSection != null) {
                                      final newIndex = response!.touchedSection!.touchedSectionIndex;
                                      if (newIndex != _hoveredIndex && newIndex >= 0) {
                                        HapticFeedback.lightImpact();
                                      }
                                    }
                                  }
                                  setState(() {
                                    if (!event.isInterestedForInteractions ||
                                        response == null ||
                                        response.touchedSection == null ||
                                        response.touchedSection!.touchedSectionIndex < 0) {
                                      _hoveredIndex = null;
                                      return;
                                    }
                                    _hoveredIndex = response.touchedSection!.touchedSectionIndex;
                                  });
                                },
                              ),
                              sections: slices.asMap().entries.map((entry) {
                                final i = entry.key;
                                final slice = entry.value;
                                final color = pieColors[i];
                                final isTouched = _hoveredIndex == i;

                                return PieChartSectionData(
                                  value: slice.amount,
                                  color: color,
                                  radius: isTouched ? 30 : 25,
                                  showTitle: false,
                                  badgeWidget: isTouched
                                      ? Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: colorScheme.surface,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.1),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Icon(
                                            categoryMap[slice.categoryId]?.iconCodePoint != null
                                                ? IconData(categoryMap[slice.categoryId]!.iconCodePoint,
                                                    fontFamily: PhosphorIconsFill.shoppingCart.fontFamily, fontPackage: 'phosphor_flutter')
                                                : Icons.category,
                                            size: 16,
                                            color: color,
                                          ),
                                        )
                                      : null,
                                  badgePositionPercentageOffset: .98,
                                );
                              }).toList(),
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _hoveredIndex != null
                                    ? (slices[_hoveredIndex!].categoryId == '_others'
                                        ? 'Others'
                                        : (categoryMap[slices[_hoveredIndex!].categoryId]?.name ?? 'Unknown'))
                                    : 'Total',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                Formatters.currencyCompact(
                                  _hoveredIndex != null ? slices[_hoveredIndex!].amount : totalExpense,
                                ),
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: _hoveredIndex != null ? pieColors[_hoveredIndex!] : colorScheme.onSurface,
                                ),
                              ),
                              if (_hoveredIndex != null)
                                Text(
                                  '${(slices[_hoveredIndex!].amount / totalExpense * 100).toStringAsFixed(1)}%',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: pieColors[_hoveredIndex!],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // ── Category Breakdown ──
                    Text('By Category', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Card(
                      child: Column(
                        children: slices.asMap().entries.map((entry) {
                          final i = entry.key;
                          final slice = entry.value;
                          final cat = categoryMap[slice.categoryId];
                          final name = slice.categoryId == '_others' ? 'Others' : (cat?.name ?? 'Unknown');
                          final pct = totalExpense > 0 ? slice.amount / totalExpense : 0.0;

                          return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
                            foregroundColor: colorScheme.primary,
                            child: Icon(cat != null ? IconData(cat.iconCodePoint, fontFamily: PhosphorIconsFill.shoppingCart.fontFamily, fontPackage: 'phosphor_flutter') : Icons.category),
                          ),
                            title: Text(name),
                            subtitle: LinearProgressIndicator(
                              value: pct,
                              color: colorScheme.primary.withValues(alpha: 1.0 - (i / slices.length * 0.7)),
                              backgroundColor: colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(Formatters.currencyCompact(slice.amount), style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text('${(pct * 100).toStringAsFixed(0)}%', style: theme.textTheme.bodySmall),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Heatmap (Spending Intensity) ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Activity Map', style: theme.textTheme.titleMedium),
                        SegmentedButton<_HeatMapType>(
                          segments: const [
                            ButtonSegment(value: _HeatMapType.expense, label: Text('Expense', style: TextStyle(fontSize: 10))),
                            ButtonSegment(value: _HeatMapType.income, label: Text('Income', style: TextStyle(fontSize: 10))),
                          ],
                          selected: {_heatmapType},
                          onSelectionChanged: (val) => setState(() => _heatmapType = val.first),
                          showSelectedIcon: false,
                          style: SegmentedButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: HeatMap(
                          datasets: heatmapData,
                          colorMode: ColorMode.opacity,
                          defaultColor: colorScheme.surfaceContainerHighest,
                          textColor: colorScheme.onSurface,
                          showColorTip: false,
                          showText: false,
                          scrollable: true,
                          size: 20,
                          startDate: DateTime.now().subtract(const Duration(days: 90)),
                          endDate: DateTime.now(),
                          colorsets: {
                            1: colorScheme.primary,
                          },
                          onClick: (value) {
                            final total = dailyTotals[value] ?? 0;
                            HapticFeedback.selectionClick();
                            ScaffoldMessenger.of(context).clearSnackBars();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                behavior: SnackBarBehavior.floating,
                                width: 200,
                                content: Text(
                                  '${DateFormat('MMM d').format(value)}: ${Formatters.currencyCompact(total)}',
                                  textAlign: TextAlign.center,
                                ),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
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

class _InsightChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InsightChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      constraints: const BoxConstraints(minWidth: 110),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 12),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontSize: 9,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
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
