import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import '../models/category.dart';
import '../models/expense_item.dart';
import '../models/month.dart';
import '../providers/months_provider.dart';
import '../utils/constants.dart';

class SeedService {
  SeedService._();

  static Future<void> seedSeptemberIfEmpty(MonthsProvider provider) async {
    if (provider.months.isNotEmpty) return;

    final raw = await rootBundle.loadString('assets/seed/september_2026.json');
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final uuid = const Uuid();
    final monthId = uuid.v4();
    final year = data['year'] as int;
    final monthNumber = data['month'] as int;

    final categoriesJson = data['categories'] as List<dynamic>;
    final categories = <BudgetCategory>[];

    for (var i = 0; i < categoriesJson.length; i++) {
      final catMap = Map<String, dynamic>.from(categoriesJson[i] as Map);
      final categoryId = uuid.v4();
      final itemsJson = catMap['items'] as List<dynamic>? ?? const [];
      final items = itemsJson.map((rawItem) {
        final item = Map<String, dynamic>.from(rawItem as Map);
        final recurrence = RecurrenceFrequency.fromString(
          item['recurrence'] as String?,
        );
        return ExpenseItem(
          id: uuid.v4(),
          categoryId: categoryId,
          name: item['name'] as String,
          price: (item['price'] as num?)?.toDouble(),
          date: item['date'] != null
              ? DateTime.parse(item['date'] as String)
              : DateTime(year, monthNumber, 1),
          recurrence: recurrence,
          recurringDay: item['recurringDay'] as int?,
          recurringMonth: item['recurringMonth'] as int?,
        );
      }).toList();

      final name = catMap['name'] as String;
      categories.add(
        BudgetCategory(
          id: categoryId,
          monthId: monthId,
          name: name,
          budget: (catMap['budget'] as num?)?.toDouble() ?? 0,
          colorHex: AppConstants.colorToHex(
            AppConstants.colorForCategory(name, i),
          ),
          sortOrder: i,
          items: items,
        ),
      );
    }

    final month = Month(
      id: monthId,
      name: data['name'] as String,
      createdAt: DateTime(year, monthNumber, 1),
      year: year,
      monthNumber: monthNumber,
      categories: categories,
    );

    await provider.replaceAll([month]);
  }
}
