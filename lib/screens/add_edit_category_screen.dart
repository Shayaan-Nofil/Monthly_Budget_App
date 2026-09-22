import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/category.dart';
import '../providers/months_provider.dart';
import '../utils/constants.dart';
import '../utils/haptics.dart';

class AddEditCategoryScreen extends StatefulWidget {
  const AddEditCategoryScreen({
    super.key,
    required this.monthId,
    this.category,
  });

  final String monthId;
  final BudgetCategory? category;

  @override
  State<AddEditCategoryScreen> createState() => _AddEditCategoryScreenState();
}

class _AddEditCategoryScreenState extends State<AddEditCategoryScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _budgetController;
  late Color _color;
  bool _saving = false;

  bool get _isEditing => widget.category != null;

  @override
  void initState() {
    super.initState();
    final category = widget.category;
    _nameController = TextEditingController(text: category?.name ?? '');
    _budgetController = TextEditingController(
      text: category == null || category.budget == 0
          ? ''
          : category.budget.round().toString(),
    );
    _color = category != null
        ? AppConstants.colorFromHex(category.colorHex)
        : AppConstants.fallbackCategoryColors.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit category' : 'Add category'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Name'),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _budgetController,
            decoration: const InputDecoration(
              labelText: 'Budget (Rs.)',
              hintText: '0',
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 20),
          Text('Color', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final color in AppConstants.fallbackCategoryColors)
                GestureDetector(
                  onTap: () {
                    AppHaptics.selection();
                    setState(() => _color = color);
                  },
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _color == color
                            ? Theme.of(context).colorScheme.onSurface
                            : Colors.transparent,
                        width: 2.5,
                      ),
                    ),
                  ),
                ),
            ],
          ),
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
    if (name.isEmpty) {
      AppHaptics.error();
      return;
    }
    final budget =
        double.tryParse(_budgetController.text.trim().replaceAll(',', '')) ??
            0;
    AppHaptics.light();
    setState(() => _saving = true);
    try {
      final provider = context.read<MonthsProvider>();
      if (_isEditing) {
        await provider.updateCategory(
          widget.category!.copyWith(
            name: name,
            budget: budget,
            colorHex: AppConstants.colorToHex(_color),
          ),
        );
      } else {
        await provider.addCategory(
          monthId: widget.monthId,
          name: name,
          budget: budget,
          colorHex: AppConstants.colorToHex(_color),
        );
      }
      AppHaptics.success();
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      AppHaptics.error();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
