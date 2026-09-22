import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/expense_item.dart';
import '../providers/months_provider.dart';

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

  bool get _isEditing => widget.item != null;

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
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          const SizedBox(height: 8),
          Text('Recurrence', style: Theme.of(context).textTheme.titleSmall),
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
                    style: Theme.of(context).textTheme.bodyLarge,
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
                  child: Text(
                    'Month',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
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
            onPressed: _saving ? null : _save,
            child: Text(_isEditing ? 'Save' : 'Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    final priceText = _priceController.text.trim();
    final price = priceText.isEmpty ? null : double.tryParse(priceText);

    setState(() => _saving = true);
    try {
      final provider = context.read<MonthsProvider>();
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
          ),
        );
      } else {
        await provider.addItem(
          monthId: widget.monthId,
          categoryId: widget.categoryId,
          name: name,
          price: price,
          date: _date,
          recurrence: _recurrence,
          recurringDay:
              _recurrence == RecurrenceFrequency.none ? null : _recurringDay,
          recurringMonth: _recurrence == RecurrenceFrequency.yearly
              ? _recurringMonth
              : null,
        );
      }
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
