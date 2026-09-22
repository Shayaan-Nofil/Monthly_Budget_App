import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/expense_item.dart';
import '../utils/currency_formatter.dart';
import '../utils/haptics.dart';
import 'receipt_viewer.dart';

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
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      child: Material(
        color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: isDark ? 0.5 : 0.12),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            AppHaptics.light();
            onEdit();
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
            child: Row(
              children: [
                if (hasReceipt) ...[
                  GestureDetector(
                    onTap: () {
                      AppHaptics.light();
                      ReceiptViewer.showNetwork(context, item.receiptImageUrl!);
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        width: 48,
                        height: 48,
                        child: CachedNetworkImage(
                          imageUrl: item.receiptImageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, _) => ColoredBox(
                            color: theme.colorScheme.surfaceContainerHighest,
                            child: const Icon(Icons.receipt_long, size: 20),
                          ),
                          errorWidget: (_, _, _) => ColoredBox(
                            color: theme.colorScheme.surfaceContainerHighest,
                            child: const Icon(
                              Icons.broken_image_outlined,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        [
                          dateLabel,
                          ?recurrenceLabel,
                          if (item.price == null) 'Price pending',
                          if (hasReceipt) 'Receipt',
                        ].join(' · '),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.55,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  CurrencyFormatter.format(item.price),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: item.price == null
                        ? theme.colorScheme.onSurface.withValues(alpha: 0.35)
                        : null,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_horiz),
                  tooltip: 'Item actions',
                  onPressed: () async {
                    AppHaptics.light();
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
                              onTap: () {
                                AppHaptics.selection();
                                Navigator.pop(context, 'edit');
                              },
                            ),
                            if (hasReceipt)
                              ListTile(
                                leading:
                                    const Icon(Icons.receipt_long_outlined),
                                title: const Text('View receipt'),
                                onTap: () {
                                  AppHaptics.selection();
                                  Navigator.pop(context, 'receipt');
                                },
                              ),
                            ListTile(
                              leading: Icon(
                                Icons.delete_outline,
                                color: theme.colorScheme.error,
                              ),
                              title: Text(
                                'Delete',
                                style: TextStyle(
                                  color: theme.colorScheme.error,
                                ),
                              ),
                              onTap: () {
                                AppHaptics.medium();
                                Navigator.pop(context, 'delete');
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                    if (!context.mounted) return;
                    if (action == 'edit') onEdit();
                    if (action == 'delete') onDelete();
                    if (action == 'receipt' && hasReceipt) {
                      ReceiptViewer.showNetwork(
                        context,
                        item.receiptImageUrl!,
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
