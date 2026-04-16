// features/insights/screens/insights_screen.dart
// Spending insights with pie chart, top categories, and key metrics.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/database/models/transaction_model.dart';

import '../../../core/database/repositories/transaction_repository.dart';
import '../../../core/database/repositories/category_repository.dart';
import '../../../core/utils/formatters.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final transactions = ref.watch(transactionProvider);
    final categories = ref.watch(categoryProvider);

    final now = DateTime.now();
    final categoryMap = {for (var c in categories) c.id: c};

    // Current month expenses
    final monthExpenses = transactions.where((t) =>
        t.type == TransactionType.expense &&
        t.date.year == now.year &&
        t.date.month == now.month).toList();

    final totalExpense = monthExpenses.fold(0.0, (s, t) => s + t.amount);

    // Group by category
    final categoryTotals = <String, double>{};
    for (final t in monthExpenses) {
      categoryTotals.update(t.categoryId, (v) => v + t.amount,
          ifAbsent: () => t.amount);
    }

    // Sort descending
    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Pie chart data — top 5, rest grouped as "Others"
    final pieEntries = <_CatSlice>[];
    double othersTotal = 0;
    for (int i = 0; i < sortedCategories.length; i++) {
      if (i < 5) {
        pieEntries.add(_CatSlice(
          categoryId: sortedCategories[i].key,
          amount: sortedCategories[i].value,
        ));
      } else {
        othersTotal += sortedCategories[i].value;
      }
    }
    if (othersTotal > 0) {
      pieEntries.add(_CatSlice(categoryId: '_others', amount: othersTotal));
    }

    // Daily average

    final daysPassed = now.day;
    final dailyAvg = daysPassed > 0 ? totalExpense / daysPassed : 0.0;

    // Highest spending day
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

    // Pie chart colors
    final pieColors = [
      const Color(0xFF4CAF50),
      const Color(0xFF2196F3),
      const Color(0xFFFF9800),
      const Color(0xFFE91E63),
      const Color(0xFF9C27B0),
      const Color(0xFF607D8B), // Others
    ];

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: const Text('Insights'),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: monthExpenses.isEmpty
                  ? _EmptyState(colorScheme: colorScheme, theme: theme)
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),

                        // ── Month Label ──
                        Text(
                          Formatters.monthYear(now),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // ── Pie Chart ──
                        Center(
                          child: SizedBox(
                            height: 200,
                            child: PieChart(
                              PieChartData(
                                sectionsSpace: 3,
                                centerSpaceRadius: 50,
                                sections: pieEntries
                                    .asMap()
                                    .entries
                                    .map((entry) {
                                  final slice = entry.value;
                                  final color = pieColors[
                                      entry.key % pieColors.length];
                                  final percentage =
                                      totalExpense > 0
                                          ? (slice.amount / totalExpense * 100)
                                          : 0.0;
                                  return PieChartSectionData(
                                    value: slice.amount,
                                    color: color,
                                    radius: 36,
                                    title:
                                        '${percentage.toStringAsFixed(0)}%',
                                    titleStyle: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  );
                                }).toList(),
                              ),
                              swapAnimationDuration: const Duration(milliseconds: 400),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // ── Category Breakdown List ──
                        ...pieEntries.asMap().entries.map((entry) {
                          final slice = entry.value;
                          final color =
                              pieColors[entry.key % pieColors.length];
                          final cat = categoryMap[slice.categoryId];
                          final name = slice.categoryId == '_others'
                              ? 'Others'
                              : (cat?.name ?? 'Unknown');
                          final percentage = totalExpense > 0
                              ? (slice.amount / totalExpense * 100)
                              : 0.0;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      name,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    Formatters.currency(slice.amount),
                                    style: theme.textTheme.bodyMedium
                                        ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    width: 42,
                                    child: Text(
                                      '${percentage.toStringAsFixed(0)}%',
                                      textAlign: TextAlign.right,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                        color: colorScheme.outline,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),

                        const SizedBox(height: 24),

                        // ── Key Metrics ──
                        Text(
                          'Key Metrics',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
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
                                    ? '${highestDay}th — ${Formatters.currencyCompact(highestDayAmount)}'
                                    : '—',
                                colorScheme: colorScheme,
                                theme: theme,
                              ),
                            ),
                          ],
                        ),
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
                        ),

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

// ─── Helper types & widgets ───

class _CatSlice {
  final String categoryId;
  final double amount;
  const _CatSlice({required this.categoryId, required this.amount});
}

class _EmptyState extends StatelessWidget {
  final ColorScheme colorScheme;
  final ThemeData theme;
  const _EmptyState({required this.colorScheme, required this.theme});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 400,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(PhosphorIconsDuotone.chartPieSlice,
                size: 64, color: colorScheme.primary.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text(
              'No spending data this month',
              style: theme.textTheme.bodyLarge
                  ?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            Text(
              'Add some expenses to see insights',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: colorScheme.outline),
            ),
          ],
        ),
      ),
    );
  }
}

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
          Icon(icon, size: 22, color: colorScheme.primary),
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
