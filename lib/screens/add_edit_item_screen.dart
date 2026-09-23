import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/expense_item.dart';
import '../providers/auth_provider.dart';
import '../providers/currency_preferences_provider.dart';
import '../providers/months_provider.dart';
import '../services/currency_service.dart';
import '../services/receipt_scan_service.dart';
import '../utils/currency_formatter.dart';
import '../utils/haptics.dart';
import '../utils/supported_currencies.dart';
import '../widgets/receipt_viewer.dart';

class AddEditItemScreen extends StatefulWidget {
  const AddEditItemScreen({
    super.key,
    required this.monthId,
    required this.categoryId,
    this.item,
    this.draftName,
    this.draftAmount,
    this.draftCurrency,
    this.draftDate,
    this.initialLocalReceiptPath,
  });

  final String monthId;
  final String categoryId;
  final ExpenseItem? item;

  /// Prefill from receipt import (ignored when [item] is set).
  final String? draftName;
  final double? draftAmount;
  final String? draftCurrency;
  final DateTime? draftDate;
  final String? initialLocalReceiptPath;

  @override
  State<AddEditItemScreen> createState() => _AddEditItemScreenState();
}

class _AddEditItemScreenState extends State<AddEditItemScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late DateTime _date;
  late RecurrenceFrequency _recurrence;
  late String _enteredCurrency;
  int _recurringDay = DateTime.now().day;
  int _recurringMonth = DateTime.now().month;
  bool _saving = false;
  bool _scanning = false;
  bool _didInitCurrency = false;
  String? _convertedPreview;

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
    final draftCurrency = widget.draftCurrency;
    _enteredCurrency = item?.enteredCurrency ??
        item?.priceCurrency ??
        draftCurrency ??
        SupportedCurrencies.defaultCode;
    _nameController = TextEditingController(
      text: item?.name ?? widget.draftName ?? '',
    );
    final seedAmount = item?.enteredAmount ?? item?.price ?? widget.draftAmount;
    final digits = SupportedCurrencies.decimalDigitsFor(_enteredCurrency);
    _priceController = TextEditingController(
      text: seedAmount == null
          ? ''
          : (digits == 0
              ? seedAmount.round().toString()
              : seedAmount.toStringAsFixed(digits)),
    );
    _date = item?.date ?? widget.draftDate ?? DateTime.now();
    _recurrence = item?.recurrence ?? RecurrenceFrequency.none;
    _recurringDay = item?.recurringDay ?? _date.day;
    _recurringMonth = item?.recurringMonth ?? _date.month;
    _receiptUrl = item?.receiptImageUrl;
    _localReceiptPath = widget.initialLocalReceiptPath;
    _priceController.addListener(_onPriceChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitCurrency) return;
    _didInitCurrency = true;
    final home = context.read<CurrencyPreferencesProvider>().homeCurrencyCode;
    // Only default to home when adding blank (no draft currency / not editing).
    if (!_isEditing &&
        widget.draftCurrency == null &&
        widget.initialLocalReceiptPath == null) {
      setState(() => _enteredCurrency = home);
    }
    _refreshConvertedPreview();
  }

  @override
  void dispose() {
    _priceController.removeListener(_onPriceChanged);
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _onPriceChanged() => _refreshConvertedPreview();

  ReceiptScanService? _scannerOrNull() {
    if (context.read<AuthProvider>().user == null) return null;
    return ReceiptScanService();
  }

  Future<void> _refreshConvertedPreview() async {
    if (!mounted) return;
    final home = context.read<CurrencyPreferencesProvider>().homeCurrencyCode;
    final raw = _priceController.text.trim();
    final amount = raw.isEmpty ? null : double.tryParse(raw);
    if (amount == null || _enteredCurrency == home) {
      if (mounted) setState(() => _convertedPreview = null);
      return;
    }
    final converted = await context.read<CurrencyService>().convertAmount(
          from: _enteredCurrency,
          to: home,
          amount: amount,
        );
    if (!mounted) return;
    setState(() {
      _convertedPreview = converted == null
          ? 'Conversion unavailable (check connection)'
          : '≈ ${CurrencyFormatter.format(converted)} ($home)';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final home = context.watch<CurrencyPreferencesProvider>().homeCurrencyCode;
    final digits = SupportedCurrencies.decimalDigitsFor(_enteredCurrency);

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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _priceController,
                  decoration: InputDecoration(
                    labelText:
                        'Price (${SupportedCurrencies.symbolFor(_enteredCurrency)})',
                    hintText: 'Leave blank if pending',
                  ),
                  keyboardType: TextInputType.numberWithOptions(
                    decimal: digits > 0,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      digits > 0
                          ? RegExp(r'^\d*\.?\d{0,2}')
                          : RegExp(r'^\d*'),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  key: ValueKey(_enteredCurrency),
                  initialValue: _enteredCurrency,
                  decoration: const InputDecoration(labelText: 'Currency'),
                  isExpanded: true,
                  items: [
                    for (final code in SupportedCurrencies.codes)
                      DropdownMenuItem(value: code, child: Text(code)),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    AppHaptics.selection();
                    setState(() => _enteredCurrency = value);
                    _refreshConvertedPreview();
                  },
                ),
              ),
            ],
          ),
          if (_convertedPreview != null) ...[
            const SizedBox(height: 8),
            Text(
              _convertedPreview!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
              ),
            ),
          ] else ...[
            const SizedBox(height: 8),
            Text(
              'Saved in home currency: $home',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
              ),
            ),
          ],
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Date'),
            subtitle: Text(DateFormat.yMMMd().format(_date)),
            trailing: const Icon(Icons.event),
            onTap: () async {
              AppHaptics.light();
              final picked = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                AppHaptics.selection();
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
            GestureDetector(
              onTap: () {
                AppHaptics.light();
                if (_localReceiptPath != null) {
                  ReceiptViewer.showFile(context, _localReceiptPath!);
                } else if (_receiptUrl != null) {
                  ReceiptViewer.showNetwork(context, _receiptUrl!);
                }
              },
              child: ClipRRect(
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
                          AppHaptics.medium();
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
              AppHaptics.selection();
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
                      if (v != null) {
                        AppHaptics.selection();
                        setState(() => _recurringDay = v);
                      }
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
                      if (v != null) {
                        AppHaptics.selection();
                        setState(() => _recurringMonth = v);
                      }
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
      AppHaptics.error();
      _showMessage('Sign in required to scan receipts');
      return;
    }

    AppHaptics.light();
    setState(() => _scanning = true);
    try {
      final paths = await scanner.scanReceipts();
      if (!mounted) return;
      if (paths.isEmpty) return;
      AppHaptics.success();
      setState(() {
        _localReceiptPath = paths.first;
        _removeReceipt = false;
      });
    } catch (e) {
      if (!mounted) return;
      AppHaptics.error();
      _showMessage('Could not scan receipt: $e');
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      AppHaptics.error();
      return;
    }
    final priceText = _priceController.text.trim();
    final enteredAmount =
        priceText.isEmpty ? null : double.tryParse(priceText);
    if (priceText.isNotEmpty && enteredAmount == null) {
      AppHaptics.error();
      _showMessage('Enter a valid price');
      return;
    }

    final home = context.read<CurrencyPreferencesProvider>().homeCurrencyCode;
    final currencyService = context.read<CurrencyService>();
    double? price = enteredAmount;
    double? fxRate;
    DateTime? fxFetchedAt;

    if (enteredAmount != null && _enteredCurrency != home) {
      final converted = await currencyService.convertAmount(
            from: _enteredCurrency,
            to: home,
            amount: enteredAmount,
          );
      if (!mounted) return;
      if (converted == null) {
        AppHaptics.error();
        _showMessage(
          'Could not convert $_enteredCurrency to $home. Connect once to cache a rate, then retry.',
        );
        return;
      }
      price = converted;
      fxRate = enteredAmount == 0 ? 0 : converted / enteredAmount;
      fxFetchedAt = DateTime.now();
    }

    AppHaptics.light();
    setState(() => _saving = true);
    try {
      final provider = context.read<MonthsProvider>();
      final itemId = widget.item?.id ?? const Uuid().v4();
      var receiptUrl = _removeReceipt ? null : _receiptUrl;

      if (_localReceiptPath != null) {
        final scanner = _scannerOrNull();
        if (scanner == null) {
          AppHaptics.error();
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
            enteredAmount: enteredAmount,
            clearEnteredAmount: enteredAmount == null,
            enteredCurrency: enteredAmount == null ? null : _enteredCurrency,
            clearEnteredCurrency: enteredAmount == null,
            priceCurrency: enteredAmount == null ? null : home,
            clearPriceCurrency: enteredAmount == null,
            fxRate: fxRate,
            clearFxRate: fxRate == null,
            fxFetchedAt: fxFetchedAt,
            clearFxFetchedAt: fxFetchedAt == null,
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
          enteredAmount: enteredAmount,
          enteredCurrency: enteredAmount == null ? null : _enteredCurrency,
          priceCurrency: enteredAmount == null ? null : home,
          fxRate: fxRate,
          fxFetchedAt: fxFetchedAt,
        );
      }
      AppHaptics.success();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      AppHaptics.error();
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
