import 'package:cached_network_image/cached_network_image.dart';
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
    final hasReceipt = item.receiptImageUrl?.isNotEmpty ?? false;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      leading: hasReceipt
          ? GestureDetector(
              onTap: () => _showReceipt(context, item.receiptImageUrl!),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: CachedNetworkImage(
                    imageUrl: item.receiptImageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (_, _) => ColoredBox(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: const Icon(Icons.receipt_long, size: 20),
                    ),
                    errorWidget: (_, _, _) => ColoredBox(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: const Icon(Icons.broken_image_outlined, size: 20),
                    ),
                  ),
                ),
              ),
            )
          : null,
      title: Text(item.name),
      subtitle: Text(
        [
          dateLabel,
          ?recurrenceLabel,
          if (item.price == null) 'Price pending',
          if (hasReceipt) 'Receipt',
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
                      if (hasReceipt)
                        ListTile(
                          leading: const Icon(Icons.receipt_long_outlined),
                          title: const Text('View receipt'),
                          onTap: () => Navigator.pop(context, 'receipt'),
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
              if (!context.mounted) return;
              if (action == 'edit') onEdit();
              if (action == 'delete') onDelete();
              if (action == 'receipt' && hasReceipt) {
                _showReceipt(context, item.receiptImageUrl!);
              }
            },
          ),
        ],
      ),
    );
  }

  void _showReceipt(BuildContext context, String url) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                tooltip: 'Close',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.7,
                maxWidth: MediaQuery.sizeOf(context).width,
              ),
              child: InteractiveViewer(
                child: CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.contain,
                  placeholder: (_, _) => const Padding(
                    padding: EdgeInsets.all(48),
                    child: CircularProgressIndicator.adaptive(),
                  ),
                  errorWidget: (_, _, _) => const Padding(
                    padding: EdgeInsets.all(48),
                    child: Icon(Icons.broken_image_outlined, size: 48),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
