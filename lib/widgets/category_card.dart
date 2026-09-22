import 'package:flutter/material.dart';

import '../models/category.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';
import '../utils/currency_formatter.dart';
import '../utils/haptics.dart';
import 'item_tile.dart';
import 'progress_bar.dart';

class CategoryCard extends StatelessWidget {
  const CategoryCard({
    super.key,
    required this.category,
    required this.expanded,
    required this.onToggle,
    required this.onAddItem,
    required this.onEditCategory,
    required this.onDeleteCategory,
    required this.onEditItem,
    required this.onDeleteItem,
  });

  final BudgetCategory category;
  final bool expanded;
  final VoidCallback onToggle;
  final VoidCallback onAddItem;
  final VoidCallback onEditCategory;
  final VoidCallback onDeleteCategory;
  final void Function(String itemId) onEditItem;
  final void Function(String itemId) onDeleteItem;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = AppConstants.colorFromHex(category.colorHex);
    final over = category.isOverBudget;

    return Material(
      color: theme.cardTheme.color,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              AppHaptics.selection();
              onToggle();
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          category.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (over)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Icon(
                            Icons.warning_amber_rounded,
                            size: 18,
                            color: AppTheme.overspend,
                          ),
                        ),
                      Icon(
                        expanded
                            ? Icons.expand_less
                            : Icons.expand_more,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    CurrencyFormatter.formatUsedBudget(
                      category.used,
                      category.budget,
                    ),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: over
                          ? AppTheme.overspend
                          : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  BudgetProgressBar(
                    percent: category.percentUsed,
                    isOverBudget: over,
                  ),
                ],
              ),
            ),
          ),
          if (expanded) ...[
            const Divider(height: 1),
            ...category.items.map(
              (item) => ItemTile(
                item: item,
                onEdit: () => onEditItem(item.id),
                onDelete: () => onDeleteItem(item.id),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: () {
                      AppHaptics.light();
                      onAddItem();
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add item'),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Edit category',
                    onPressed: () {
                      AppHaptics.light();
                      onEditCategory();
                    },
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  IconButton(
                    tooltip: 'Delete category',
                    onPressed: () {
                      AppHaptics.medium();
                      onDeleteCategory();
                    },
                    icon: Icon(
                      Icons.delete_outline,
                      color: theme.colorScheme.error,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
