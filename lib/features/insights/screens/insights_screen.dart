// features/insights/screens/insights_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
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

class _InsightsScreenState extends ConsumerState<InsightsScreen> {
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  int? _hoveredIndex;

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

    // Pie colors
    final fallbackColors = [Colors.blue, Colors.orange, Colors.purple, Colors.teal, Colors.pink, Colors.amber];
    List<Color> pieColors = slices.asMap().entries.map((e) {
      final cat = categoryMap[e.value.categoryId];
      if (cat != null) return Color(int.parse('FF${cat.colorHex}', radix: 16));
      return fallbackColors[e.key % fallbackColors.length];
    }).toList();

    // Key metrics
    final daysPassed = isCurrentMonth ? now.day : DateUtils.getDaysInMonth(_selectedMonth.year, _selectedMonth.month);
    final dailyAvg = daysPassed > 0 ? totalExpense / daysPassed : 0.0;
    final dayTotals = <int, double>{};
    for (final t in monthExpenses) {
      dayTotals.update(t.date.day, (v) => v + t.amount, ifAbsent: () => t.amount);
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
      appBar: AppBar(
        title: const Text('Insights'),
      ),
      body: CustomScrollView(
        slivers: [
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
                        icon: const Icon(Icons.chevron_left),
                      ),
                      Text(
                        DateFormat('MMMM yyyy').format(_selectedMonth),
                        style: theme.textTheme.titleMedium,
                      ),
                      IconButton(
                        onPressed: isCurrentMonth ? null : () => _changeMonth(1),
                        icon: const Icon(Icons.chevron_right),
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
                                      Text('Expenses', style: theme.textTheme.bodySmall),
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
                                      Text('Income', style: theme.textTheme.bodySmall),
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
                    const SizedBox(height: 24),

                    // ── Pie Chart ──
                    SizedBox(
                      height: 200,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 50,
                          pieTouchData: PieTouchData(
                            touchCallback: (event, response) {
                              setState(() {
                                if (!event.isInterestedForInteractions || response == null || response.touchedSection == null) {
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
                            final pct = totalExpense > 0 ? (slice.amount / totalExpense * 100) : 0.0;
                            final isTouched = _hoveredIndex == i;

                            return PieChartSectionData(
                              value: slice.amount,
                              color: color,
                              radius: isTouched ? 50 : 40,
                              title: isTouched ? Formatters.currencyCompact(slice.amount) : (pct >= 5 ? '${pct.toStringAsFixed(0)}%' : ''),
                              titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                            );
                          }).toList(),
                        ),
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
                          final color = pieColors[i];
                          final cat = categoryMap[slice.categoryId];
                          final name = slice.categoryId == '_others' ? 'Others' : (cat?.name ?? 'Unknown');
                          final pct = totalExpense > 0 ? slice.amount / totalExpense : 0.0;

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: color.withValues(alpha: 0.2),
                              foregroundColor: color,
                              child: Icon(cat != null ? IconData(cat.iconCodePoint, fontFamily: 'Phosphor', fontPackage: 'phosphor_flutter') : Icons.category),
                            ),
                            title: Text(name),
                            subtitle: LinearProgressIndicator(
                              value: pct,
                              color: color,
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

                    // ── Key Metrics ──
                    Text('Key Metrics', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.bar_chart, color: colorScheme.primary),
                                  const SizedBox(height: 8),
                                  Text('Daily Average', style: theme.textTheme.bodySmall),
                                  Text(Formatters.currencyCompact(dailyAvg), style: theme.textTheme.titleMedium),
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
                                  Icon(Icons.local_fire_department, color: colorScheme.primary),
                                  const SizedBox(height: 8),
                                  Text('Highest Day ($highestDay)', style: theme.textTheme.bodySmall),
                                  Text(highestDay != null ? Formatters.currencyCompact(highestDayAmount) : '—', style: theme.textTheme.titleMedium),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
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

class _Slice {
  final String categoryId;
  final double amount;
  const _Slice({required this.categoryId, required this.amount});
}
