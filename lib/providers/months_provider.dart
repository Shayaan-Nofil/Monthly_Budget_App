import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/category.dart';
import '../models/expense_item.dart';
import '../models/month.dart';
import '../repositories/budget_repository.dart';
import '../utils/constants.dart';

class MonthsProvider extends ChangeNotifier {
  MonthsProvider(this._repository);

  final BudgetRepository _repository;
  final _uuid = const Uuid();

  List<Month> _months = [];
  bool _loading = true;
  String? _error;
  bool _initialized = false;
  StreamSubscription<List<Month>>? _watchSub;

  List<Month> get months => List.unmodifiable(_months);
  bool get isLoading => _loading;
  String? get error => _error;
  bool get isEmpty => _months.isEmpty;
  bool get isInitialized => _initialized;

  Month? get mostRecentMonth => _months.isEmpty ? null : _months.first;

  Month? getMonth(String id) {
    try {
      return _months.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> init() async {
    if (_initialized) return;

    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _repository.init();
      _months = await _repository.loadMonths();
      await _watchSub?.cancel();
      _watchSub = _repository.watchMonths().listen((months) {
        _months = months;
        notifyListeners();
      });
      _initialized = true;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> reset() async {
    await _watchSub?.cancel();
    _watchSub = null;
    await _repository.clearSession();
    _months = [];
    _loading = true;
    _error = null;
    _initialized = false;
    notifyListeners();
  }

  Future<Month> createMonth({
    required String name,
    required int year,
    required int monthNumber,
    bool copyFromPrevious = true,
  }) async {
    final previous = mostRecentMonth;
    final monthId = _uuid.v4();
    List<BudgetCategory> categories;

    if (copyFromPrevious && previous != null) {
      categories = previous.categories.map((source) {
        final categoryId = _uuid.v4();
        final recurringItems = <ExpenseItem>[];
        for (final item in source.items) {
          if (!Month.shouldCopyRecurringItem(
            item: item,
            targetMonthNumber: monthNumber,
          )) {
            continue;
          }
          final day = item.recurringDay!;
          recurringItems.add(
            ExpenseItem(
              id: _uuid.v4(),
              categoryId: categoryId,
              name: item.name,
              price: null,
              date: Month.dateForRecurring(
                year: year,
                monthNumber: monthNumber,
                day: day,
              ),
              recurrence: item.recurrence,
              recurringDay: item.recurringDay,
              recurringMonth: item.recurringMonth,
            ),
          );
        }
        return BudgetCategory(
          id: categoryId,
          monthId: monthId,
          name: source.name,
          budget: source.budget,
          colorHex: source.colorHex,
          sortOrder: source.sortOrder,
          items: recurringItems,
        );
      }).toList();
    } else {
      categories = _defaultCategories(monthId);
    }

    final month = Month(
      id: monthId,
      name: name,
      createdAt: DateTime.now(),
      year: year,
      monthNumber: monthNumber,
      categories: categories,
    );
    await _repository.upsertMonth(month);
    _months = await _repository.loadMonths();
    notifyListeners();
    return month;
  }

  Future<void> renameMonth(String id, String name) async {
    final month = getMonth(id);
    if (month == null) return;
    await _repository.upsertMonth(month.copyWith(name: name));
    _months = await _repository.loadMonths();
    notifyListeners();
  }

  Future<void> deleteMonth(String id) async {
    await _repository.deleteMonth(id);
    _months = await _repository.loadMonths();
    notifyListeners();
  }

  Future<void> addCategory({
    required String monthId,
    required String name,
    required double budget,
    required String colorHex,
  }) async {
    final month = getMonth(monthId);
    if (month == null) return;
    final category = BudgetCategory(
      id: _uuid.v4(),
      monthId: monthId,
      name: name,
      budget: budget,
      colorHex: colorHex,
      sortOrder: month.categories.length,
    );
    final updated = month.copyWith(
      categories: [...month.categories, category],
    );
    await _repository.upsertMonth(updated);
    _months = await _repository.loadMonths();
    notifyListeners();
  }

  Future<void> updateCategory(BudgetCategory category) async {
    final month = getMonth(category.monthId);
    if (month == null) return;
    final categories = month.categories
        .map((c) => c.id == category.id ? category : c)
        .toList();
    await _repository.upsertMonth(month.copyWith(categories: categories));
    _months = await _repository.loadMonths();
    notifyListeners();
  }

  Future<void> deleteCategory(String monthId, String categoryId) async {
    final month = getMonth(monthId);
    if (month == null) return;
    final categories =
        month.categories.where((c) => c.id != categoryId).toList();
    await _repository.upsertMonth(month.copyWith(categories: categories));
    _months = await _repository.loadMonths();
    notifyListeners();
  }

  Future<void> addItem({
    required String monthId,
    required String categoryId,
    required String name,
    double? price,
    DateTime? date,
    RecurrenceFrequency recurrence = RecurrenceFrequency.none,
    int? recurringDay,
    int? recurringMonth,
    String? id,
    String? receiptImageUrl,
    double? enteredAmount,
    String? enteredCurrency,
    String? priceCurrency,
    double? fxRate,
    DateTime? fxFetchedAt,
  }) async {
    final month = getMonth(monthId);
    if (month == null) return;
    final categories = month.categories.map((category) {
      if (category.id != categoryId) return category;
      final item = ExpenseItem(
        id: id ?? _uuid.v4(),
        categoryId: categoryId,
        name: name,
        price: price,
        date: date ?? DateTime.now(),
        recurrence: recurrence,
        recurringDay: recurringDay,
        recurringMonth: recurringMonth,
        receiptImageUrl: receiptImageUrl,
        enteredAmount: enteredAmount,
        enteredCurrency: enteredCurrency,
        priceCurrency: priceCurrency,
        fxRate: fxRate,
        fxFetchedAt: fxFetchedAt,
      );
      return category.copyWith(items: [...category.items, item]);
    }).toList();
    await _repository.upsertMonth(month.copyWith(categories: categories));
    _months = await _repository.loadMonths();
    notifyListeners();
  }

  Future<void> updateItem({
    required String monthId,
    required ExpenseItem item,
  }) async {
    final month = getMonth(monthId);
    if (month == null) return;
    // Remove from any category, then place on the item's categoryId (supports moves).
    final categories = month.categories.map((category) {
      final without = category.items.where((e) => e.id != item.id).toList();
      if (category.id == item.categoryId) {
        return category.copyWith(items: [...without, item]);
      }
      return category.copyWith(items: without);
    }).toList();
    await _repository.upsertMonth(month.copyWith(categories: categories));
    _months = await _repository.loadMonths();
    notifyListeners();
  }

  Future<void> deleteItem({
    required String monthId,
    required String categoryId,
    required String itemId,
  }) async {
    final month = getMonth(monthId);
    if (month == null) return;
    final categories = month.categories.map((category) {
      if (category.id != categoryId) return category;
      return category.copyWith(
        items: category.items.where((e) => e.id != itemId).toList(),
      );
    }).toList();
    await _repository.upsertMonth(month.copyWith(categories: categories));
    _months = await _repository.loadMonths();
    notifyListeners();
  }

  List<BudgetCategory> _defaultCategories(String monthId) {
    return [
      for (var i = 0; i < AppConstants.defaultCategoryNames.length; i++)
        BudgetCategory(
          id: _uuid.v4(),
          monthId: monthId,
          name: AppConstants.defaultCategoryNames[i],
          budget: 0,
          colorHex: AppConstants.colorToHex(
            AppConstants.colorForCategory(
              AppConstants.defaultCategoryNames[i],
              i,
            ),
          ),
          sortOrder: i,
        ),
    ];
  }
}
