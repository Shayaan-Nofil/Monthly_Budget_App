import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/months_provider.dart';
import '../utils/constants.dart';
import '../utils/haptics.dart';

class NewMonthScreen extends StatefulWidget {
  const NewMonthScreen({super.key});

  @override
  State<NewMonthScreen> createState() => _NewMonthScreenState();
}

class _NewMonthScreenState extends State<NewMonthScreen> {
  late DateTime _selected;
  late TextEditingController _nameController;
  bool _copyFromPrevious = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selected = DateTime(now.year, now.month);
    _nameController = TextEditingController(text: _defaultName(_selected));
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String _defaultName(DateTime date) => DateFormat.yMMMM().format(date);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MonthsProvider>();
    final hasPrevious = provider.mostRecentMonth != null;

    return Scaffold(
      appBar: AppBar(title: const Text('New month')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Month name'),
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Calendar month'),
            subtitle: Text(DateFormat.yMMMM().format(_selected)),
            trailing: const Icon(Icons.calendar_month_outlined),
            onTap: () async {
              AppHaptics.light();
              final picked = await showDatePicker(
                context: context,
                initialDate: _selected,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
                helpText: 'Pick any day in the target month',
              );
              if (picked != null) {
                AppHaptics.selection();
                setState(() {
                  _selected = DateTime(picked.year, picked.month);
                  _nameController.text = _defaultName(_selected);
                });
              }
            },
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Copy categories from previous month'),
            subtitle: Text(
              hasPrevious
                  ? 'Budgets + recurring items (prices empty) from ${provider.mostRecentMonth!.name}'
                  : 'No previous month — will use default categories',
            ),
            value: _copyFromPrevious && hasPrevious,
            onChanged: hasPrevious
                ? (value) {
                    AppHaptics.selection();
                    setState(() => _copyFromPrevious = value);
                  }
                : null,
          ),
          if (!hasPrevious || !_copyFromPrevious) ...[
            const SizedBox(height: 8),
            Text(
              'Defaults: ${AppConstants.defaultCategoryNames.join(', ')}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : () => _save(context),
            child: _saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator.adaptive(strokeWidth: 2),
                  )
                : const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _save(BuildContext context) async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      AppHaptics.error();
      return;
    }
    AppHaptics.light();
    setState(() => _saving = true);
    try {
      final month = await context.read<MonthsProvider>().createMonth(
            name: name,
            year: _selected.year,
            monthNumber: _selected.month,
            copyFromPrevious: _copyFromPrevious,
          );
      AppHaptics.success();
      if (!context.mounted) return;
      Navigator.of(context).pop(month);
    } catch (_) {
      AppHaptics.error();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
