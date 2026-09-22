import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/expense_item.dart';
import '../utils/currency_formatter.dart';

class ItemTile extends StatelessWidget {
  const ItemTile({
    super.key,
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  final ExpenseItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateLabel = DateFormat.MMMd().format(item.date);
    final recurrenceLabel = switch (item.recurrence) {
      RecurrenceFrequency.monthly => 'Monthly · day ${item.recurringDay}',
      RecurrenceFrequency.yearly =>
        'Yearly · ${item.recurringMonth}/${item.recurringDay}',
      RecurrenceFrequency.none => null,
    };

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      title: Text(item.name),
      subtitle: Text(
        [
          dateLabel,
          ?recurrenceLabel,
          if (item.price == null) 'Price pending',
        ].join(' · '),
        style: theme.textTheme.bodySmall,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            CurrencyFormatter.format(item.price),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: item.price == null
                  ? theme.colorScheme.onSurface.withValues(alpha: 0.4)
                  : null,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_horiz),
            tooltip: 'Item actions',
            onPressed: () async {
              final action = await showModalBottomSheet<String>(
                context: context,
                showDragHandle: true,
                builder: (context) => SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.edit_outlined),
                        title: const Text('Edit'),
                        onTap: () => Navigator.pop(context, 'edit'),
                      ),
                      ListTile(
                        leading: Icon(
                          Icons.delete_outline,
                          color: theme.colorScheme.error,
                        ),
                        title: Text(
                          'Delete',
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                        onTap: () => Navigator.pop(context, 'delete'),
                      ),
                    ],
                  ),
                ),
              );
              if (action == 'edit') onEdit();
              if (action == 'delete') onDelete();
            },
          ),
        ],
      ),
    );
  }
}
