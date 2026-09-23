import 'package:flutter/material.dart';

import '../models/month.dart';
import '../theme/app_theme.dart';
import '../utils/currency_formatter.dart';
import '../utils/haptics.dart';
import 'progress_bar.dart';

class MonthCard extends StatelessWidget {
  const MonthCard({
    super.key,
    required this.month,
    required this.onTap,
    this.onLongPress,
  });

  final Month month;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final over = month.isOverBudget;

    return Material(
      color: theme.cardTheme.color,
      elevation: 5,
      shadowColor: Colors.black.withValues(
        alpha: theme.brightness == Brightness.dark ? 0.55 : 0.16,
      ),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () {
          AppHaptics.light();
          onTap();
        },
        onLongPress: onLongPress == null
            ? null
            : () {
                AppHaptics.medium();
                onLongPress!();
              },
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      month.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (over)
                    Icon(
                      Icons.warning_amber_rounded,
                      color: AppTheme.overspend,
                      size: 20,
                    ),
                  const SizedBox(width: 4),
                  Text(
                    CurrencyFormatter.percent(month.percentUsed),
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: over
                          ? AppTheme.overspend
                          : theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                CurrencyFormatter.formatUsedBudget(
                  month.totalUsed,
                  month.totalBudget,
                ),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 18),
              BudgetProgressBar(
                percent: month.percentUsed,
                isOverBudget: over,
                height: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
