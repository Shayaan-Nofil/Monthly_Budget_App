import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/analytics_provider.dart';
import '../providers/months_provider.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';
import '../utils/currency_formatter.dart';
import 'month_detail_screen.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MonthsProvider>();
    final months = provider.months;
    final selected = provider.mostRecentMonth;
    final mom = AnalyticsHelper.monthOverMonth(months);
    final slices = AnalyticsHelper.categoryBreakdown(selected);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator.adaptive())
          : months.isEmpty
              ? const Center(child: Text('Add a month to see analytics'))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  children: [
                    if (selected != null) ...[
                      _QuickStats(monthName: selected.name, stats: [
                        _StatData(
                          'Highest',
                          selected.highestSpendingCategory?.name ?? '—',
                        ),
                        _StatData(
                          'Lowest',
                          selected.lowestSpendingCategory?.name ?? '—',
                        ),
                        _StatData(
                          'Avg / day',
                          CurrencyFormatter.format(selected.averageDailySpend),
                        ),
                        _StatData(
                          'Budget used',
                          CurrencyFormatter.percent(selected.percentUsed),
                        ),
                      ]),
                      const SizedBox(height: 16),
                    ],
                    _SectionCard(
                      title: 'Month over month',
                      child: SizedBox(
                        height: 220,
                        child: mom.every((p) => p.used == 0) && mom.length <= 1
                            ? Center(
                                child: Text(
                                  'Spend will appear here as you log expenses',
                                  style: theme.textTheme.bodyMedium,
                                  textAlign: TextAlign.center,
                                ),
                              )
                            : BarChart(
                                BarChartData(
                                  alignment: BarChartAlignment.spaceAround,
                                  maxY: (mom
                                              .map((e) => e.used)
                                              .fold<double>(0, (a, b) => a > b ? a : b) *
                                          1.2)
                                      .clamp(1000, double.infinity),
                                  barTouchData: BarTouchData(
                                    touchCallback: (event, response) {
                                      if (!event.isInterestedForInteractions ||
                                          response?.spot == null) {
                                        return;
                                      }
                                      final index =
                                          response!.spot!.touchedBarGroupIndex;
                                      if (index < 0 || index >= mom.length) {
                                        return;
                                      }
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => MonthDetailScreen(
                                            monthId: mom[index].month.id,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  titlesData: FlTitlesData(
                                    topTitles: const AxisTitles(),
                                    rightTitles: const AxisTitles(),
                                    leftTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: (value, meta) {
                                          final i = value.toInt();
                                          if (i < 0 || i >= mom.length) {
                                            return const SizedBox.shrink();
                                          }
                                          final label = mom[i]
                                              .month
                                              .name
                                              .split(' ')
                                              .first;
                                          return Padding(
                                            padding:
                                                const EdgeInsets.only(top: 8),
                                            child: Text(
                                              label.substring(
                                                0,
                                                label.length.clamp(0, 3),
                                              ),
                                              style: theme.textTheme.labelSmall,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  borderData: FlBorderData(show: false),
                                  gridData: const FlGridData(show: false),
                                  barGroups: [
                                    for (var i = 0; i < mom.length; i++)
                                      BarChartGroupData(
                                        x: i,
                                        barRods: [
                                          BarChartRodData(
                                            toY: mom[i].used,
                                            color: AppTheme.accent,
                                            width: 18,
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: selected == null
                          ? 'Category breakdown'
                          : '${selected.name} by category',
                      child: SizedBox(
                        height: 240,
                        child: slices.isEmpty
                            ? Center(
                                child: Text(
                                  'No priced expenses yet',
                                  style: theme.textTheme.bodyMedium,
                                ),
                              )
                            : Row(
                                children: [
                                  Expanded(
                                    child: PieChart(
                                      PieChartData(
                                        sectionsSpace: 2,
                                        centerSpaceRadius: 40,
                                        sections: [
                                          for (final slice in slices)
                                            PieChartSectionData(
                                              value: slice.used,
                                              color: AppConstants.colorFromHex(
                                                slice.category.colorHex,
                                              ),
                                              title: '',
                                              radius: 48,
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        for (final slice in slices.take(5))
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 4,
                                            ),
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 10,
                                                  height: 10,
                                                  decoration: BoxDecoration(
                                                    color: AppConstants
                                                        .colorFromHex(
                                                      slice.category.colorHex,
                                                    ),
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    slice.category.name,
                                                    style: theme
                                                        .textTheme.bodySmall,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                Text(
                                                  CurrencyFormatter.format(
                                                    slice.used,
                                                  ),
                                                  style: theme
                                                      .textTheme.labelMedium
                                                      ?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Months',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...months.map(
                      (month) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(month.name),
                        subtitle: Text(
                          CurrencyFormatter.formatUsedBudget(
                            month.totalUsed,
                            month.totalBudget,
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  MonthDetailScreen(monthId: month.id),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _QuickStats extends StatelessWidget {
  const _QuickStats({required this.monthName, required this.stats});

  final String monthName;
  final List<_StatData> stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick stats · $monthName',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final stat in stats)
                SizedBox(
                  width: (MediaQuery.sizeOf(context).width - 56) / 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stat.label,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.55),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        stat.value,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatData {
  const _StatData(this.label, this.value);
  final String label;
  final String value;
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
