import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class BudgetProgressBar extends StatelessWidget {
  const BudgetProgressBar({
    super.key,
    required this.percent,
    this.isOverBudget = false,
    this.height = 8,
  });

  final double percent;
  final bool isOverBudget;
  final double height;

  @override
  Widget build(BuildContext context) {
    final clamped = percent.clamp(0.0, 1.0);
    final color = isOverBudget ? AppTheme.overspend : AppTheme.accent;
    return Semantics(
      label: isOverBudget ? 'Over budget' : 'Within budget',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(height),
        child: LinearProgressIndicator(
          value: clamped,
          minHeight: height,
          backgroundColor: color.withValues(alpha: 0.15),
          color: color,
        ),
      ),
    );
  }
}
