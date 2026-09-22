import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/expense_item.dart';
import '../providers/auth_provider.dart';
import '../providers/months_provider.dart';
import '../services/receipt_scan_service.dart';

class AddEditItemScreen extends StatefulWidget {
  const AddEditItemScreen({
    super.key,
    required this.monthId,
    required this.categoryId,
    this.item,
  });

  final String monthId;
  final String categoryId;
  final ExpenseItem? item;

  @override
  State<AddEditItemScreen> createState() => _AddEditItemScreenState();
}

class _AddEditItemScreenState extends State<AddEditItemScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late DateTime _date;
  late RecurrenceFrequency _recurrence;
  int _recurringDay = DateTime.now().day;
  int _recurringMonth = DateTime.now().month;
  bool _saving = false;
  bool _scanning = false;

  String? _receiptUrl;
  String? _localReceiptPath;
  bool _removeReceipt = false;

  bool get _isEditing => widget.item != null;

  bool get _hasReceiptPreview =>
      _localReceiptPath != null ||
      (!_removeReceipt && (_receiptUrl?.isNotEmpty ?? false));

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _nameController = TextEditingController(text: item?.name ?? '');
    _priceController = TextEditingController(
      text: item?.price?.round().toString() ?? '',
    );
    _date = item?.date ?? DateTime.now();
    _recurrence = item?.recurrence ?? RecurrenceFrequency.none;
    _recurringDay = item?.recurringDay ?? _date.day;
    _recurringMonth = item?.recurringMonth ?? _date.month;
    _receiptUrl = item?.receiptImageUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  ReceiptScanService? _scannerOrNull() {
    final uid = context.read<AuthProvider>().user?.uid;
    if (uid == null) return null;
    return ReceiptScanService(userId: uid);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit item' : 'Add item'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Name'),
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _priceController,
            decoration: const InputDecoration(
              labelText: 'Price (Rs.)',
              hintText: 'Leave blank if pending',
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Date'),
            subtitle: Text(DateFormat.yMMMd().format(_date)),
            trailing: const Icon(Icons.event),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                setState(() {
                  _date = picked;
                  if (_recurrence == RecurrenceFrequency.none) {
                    _recurringDay = picked.day;
                    _recurringMonth = picked.month;
                  }
                });
              }
            },
          ),
          const SizedBox(height: 16),
          Text('Receipt', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          if (_hasReceiptPreview) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: _localReceiptPath != null
                    ? Image.file(
                        File(_localReceiptPath!),
                        fit: BoxFit.cover,
                      )
                    : CachedNetworkImage(
                        imageUrl: _receiptUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, _) => const Center(
                          child: CircularProgressIndicator.adaptive(),
                        ),
                        errorWidget: (_, _, _) => const Center(
                          child: Icon(Icons.broken_image_outlined),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _scanning || _saving ? null : _scanReceipt,
                  icon: _scanning
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator.adaptive(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.document_scanner_outlined),
                  label: Text(
                    _hasReceiptPreview ? 'Rescan receipt' : 'Scan receipt',
                  ),
                ),
              ),
              if (_hasReceiptPreview) ...[
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Remove receipt',
                  onPressed: _saving
                      ? null
                      : () {
                          setState(() {
                            _localReceiptPath = null;
                            _receiptUrl = null;
                            _removeReceipt = true;
                          });
                        },
                  icon: Icon(
                    Icons.delete_outline,
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          Text('Recurrence', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          SegmentedButton<RecurrenceFrequency>(
            segments: const [
              ButtonSegment(
                value: RecurrenceFrequency.none,
                label: Text('None'),
              ),
              ButtonSegment(
                value: RecurrenceFrequency.monthly,
                label: Text('Monthly'),
              ),
              ButtonSegment(
                value: RecurrenceFrequency.yearly,
                label: Text('Yearly'),
              ),
            ],
            selected: {_recurrence},
            onSelectionChanged: (value) {
              setState(() => _recurrence = value.first);
            },
          ),
          if (_recurrence != RecurrenceFrequency.none) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Day of month',
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
                SizedBox(
                  width: 96,
                  child: DropdownButtonFormField<int>(
                    initialValue: _recurringDay.clamp(1, 31),
                    isExpanded: true,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    items: [
                      for (var d = 1; d <= 31; d++)
                        DropdownMenuItem(value: d, child: Text('$d')),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _recurringDay = v);
                    },
                  ),
                ),
              ],
            ),
          ],
          if (_recurrence == RecurrenceFrequency.yearly) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text('Month', style: theme.textTheme.bodyLarge),
                ),
                SizedBox(
                  width: 150,
                  child: DropdownButtonFormField<int>(
                    initialValue: _recurringMonth,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    items: [
                      for (var m = 1; m <= 12; m++)
                        DropdownMenuItem(
                          value: m,
                          child: Text(
                            DateFormat.MMMM().format(DateTime(2026, m)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _recurringMonth = v);
                    },
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 28),
          FilledButton(
            onPressed: _saving || _scanning ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator.adaptive(strokeWidth: 2),
                  )
                : Text(_isEditing ? 'Save' : 'Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _scanReceipt() async {
    final scanner = _scannerOrNull();
    if (scanner == null) {
      _showMessage('Sign in required to scan receipts');
      return;
    }

    setState(() => _scanning = true);
    try {
      final paths = await scanner.scanReceipts();
      if (!mounted) return;
      if (paths.isEmpty) return;
      setState(() {
        _localReceiptPath = paths.first;
        _removeReceipt = false;
      });
    } catch (e) {
      if (!mounted) return;
      _showMessage('Could not scan receipt: $e');
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    final priceText = _priceController.text.trim();
    final price = priceText.isEmpty ? null : double.tryParse(priceText);

    setState(() => _saving = true);
    try {
      final provider = context.read<MonthsProvider>();
      final itemId = widget.item?.id ?? const Uuid().v4();
      var receiptUrl = _removeReceipt ? null : _receiptUrl;

      if (_localReceiptPath != null) {
        final scanner = _scannerOrNull();
        if (scanner == null) {
          _showMessage('Sign in required to upload receipts');
          return;
        }
        receiptUrl = await scanner.uploadReceipt(
          localPath: _localReceiptPath!,
          expenseId: itemId,
        );
      } else if (_removeReceipt && _isEditing) {
        final scanner = _scannerOrNull();
        await scanner?.deleteReceipt(itemId);
      }

      if (_isEditing) {
        await provider.updateItem(
          monthId: widget.monthId,
          item: widget.item!.copyWith(
            name: name,
            price: price,
            clearPrice: price == null,
            date: _date,
            recurrence: _recurrence,
            recurringDay: _recurrence == RecurrenceFrequency.none
                ? null
                : _recurringDay,
            clearRecurringDay: _recurrence == RecurrenceFrequency.none,
            recurringMonth: _recurrence == RecurrenceFrequency.yearly
                ? _recurringMonth
                : null,
            clearRecurringMonth: _recurrence != RecurrenceFrequency.yearly,
            receiptImageUrl: receiptUrl,
            clearReceipt: receiptUrl == null,
          ),
        );
      } else {
        await provider.addItem(
          monthId: widget.monthId,
          categoryId: widget.categoryId,
          id: itemId,
          name: name,
          price: price,
          date: _date,
          recurrence: _recurrence,
          recurringDay:
              _recurrence == RecurrenceFrequency.none ? null : _recurringDay,
          recurringMonth: _recurrence == RecurrenceFrequency.yearly
              ? _recurringMonth
              : null,
          receiptImageUrl: receiptUrl,
        );
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      _showMessage('Could not save item: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
