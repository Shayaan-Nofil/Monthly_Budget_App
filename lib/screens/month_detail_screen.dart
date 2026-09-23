import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/months_provider.dart';
import '../services/receipt_import_flow.dart';
import '../utils/haptics.dart';
import '../widgets/budget_summary_header.dart';
import '../widgets/category_card.dart';
import 'add_edit_category_screen.dart';
import 'add_edit_item_screen.dart';

class MonthDetailScreen extends StatefulWidget {
  const MonthDetailScreen({super.key, required this.monthId});

  final String monthId;

  @override
  State<MonthDetailScreen> createState() => _MonthDetailScreenState();
}

class _MonthDetailScreenState extends State<MonthDetailScreen> {
  final Set<String> _expanded = {};

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MonthsProvider>();
    final month = provider.getMonth(widget.monthId);

    if (month == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Month not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(month.name),
        actions: [
          IconButton(
            tooltip: 'Scan receipt',
            icon: const Icon(Icons.document_scanner_outlined),
            onPressed: () {
              ReceiptImportFlow.start(context: context, month: month);
            },
          ),
          IconButton(
            tooltip: 'Add category',
            icon: const Icon(Icons.create_new_folder_outlined),
            onPressed: () async {
              AppHaptics.light();
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AddEditCategoryScreen(monthId: month.id),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          BudgetSummaryHeader(
            totalBudget: month.totalBudget,
            totalUsed: month.totalUsed,
            remaining: month.remaining,
            percentUsed: month.percentUsed,
            isOverBudget: month.isOverBudget,
          ),
          const SizedBox(height: 16),
          ...month.categories.map((category) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: CategoryCard(
                category: category,
                expanded: _expanded.contains(category.id),
                onToggle: () {
                  setState(() {
                    if (_expanded.contains(category.id)) {
                      _expanded.remove(category.id);
                    } else {
                      _expanded.add(category.id);
                    }
                  });
                },
                onAddItem: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AddEditItemScreen(
                        monthId: month.id,
                        categoryId: category.id,
                      ),
                    ),
                  );
                },
                onEditCategory: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AddEditCategoryScreen(
                        monthId: month.id,
                        category: category,
                      ),
                    ),
                  );
                },
                onDeleteCategory: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete category?'),
                      content: Text(
                        'Delete "${category.name}" and all its items?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            AppHaptics.light();
                            Navigator.pop(context, false);
                          },
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            AppHaptics.medium();
                            Navigator.pop(context, true);
                          },
                          style: TextButton.styleFrom(
                            foregroundColor:
                                Theme.of(context).colorScheme.error,
                          ),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                  if (ok == true && context.mounted) {
                    await context.read<MonthsProvider>().deleteCategory(
                          month.id,
                          category.id,
                        );
                  }
                },
                onEditItem: (itemId) async {
                  final item =
                      category.items.firstWhere((e) => e.id == itemId);
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AddEditItemScreen(
                        monthId: month.id,
                        categoryId: category.id,
                        item: item,
                      ),
                    ),
                  );
                },
                onDeleteItem: (itemId) async {
                  final item =
                      category.items.firstWhere((e) => e.id == itemId);
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete item?'),
                      content: Text('Delete "${item.name}"?'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            AppHaptics.light();
                            Navigator.pop(context, false);
                          },
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            AppHaptics.medium();
                            Navigator.pop(context, true);
                          },
                          style: TextButton.styleFrom(
                            foregroundColor:
                                Theme.of(context).colorScheme.error,
                          ),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                  if (ok == true && context.mounted) {
                    await context.read<MonthsProvider>().deleteItem(
                          monthId: month.id,
                          categoryId: category.id,
                          itemId: itemId,
                        );
                  }
                },
              ),
            );
          }),
        ],
      ),
    );
  }
}
