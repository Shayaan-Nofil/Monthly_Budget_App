import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/currency_formatter.dart';
import 'progress_bar.dart';

class BudgetSummaryHeader extends StatelessWidget {
  const BudgetSummaryHeader({
    super.key,
    required this.totalBudget,
    required this.totalUsed,
    required this.remaining,
    required this.percentUsed,
    this.isOverBudget = false,
  });

  final double totalBudget;
  final double totalUsed;
  final double remaining;
  final double percentUsed;
  final bool isOverBudget;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final remainingColor =
        isOverBudget ? AppTheme.overspend : theme.colorScheme.onSurface;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Overview',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _Stat(
                  label: 'Budget',
                  value: CurrencyFormatter.format(totalBudget),
                ),
              ),
              Expanded(
                child: _Stat(
                  label: 'Used',
                  value: CurrencyFormatter.format(totalUsed),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _Stat(
                  label: 'Remaining',
                  value: CurrencyFormatter.format(remaining),
                  valueColor: remainingColor,
                  icon: isOverBudget ? Icons.warning_amber_rounded : null,
                ),
              ),
              Expanded(
                child: _Stat(
                  label: 'Used %',
                  value: CurrencyFormatter.percent(percentUsed),
                  valueColor: remainingColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          BudgetProgressBar(
            percent: percentUsed,
            isOverBudget: isOverBudget,
            height: 10,
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.value,
    this.valueColor,
    this.icon,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: valueColor),
              const SizedBox(width: 4),
            ],
            Flexible(
              child: Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: valueColor,
                  letterSpacing: -0.3,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
