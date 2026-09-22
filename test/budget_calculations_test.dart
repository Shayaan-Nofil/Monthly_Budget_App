import 'package:flutter_test/flutter_test.dart';
import 'package:monthly_budget_tracker/models/category.dart';
import 'package:monthly_budget_tracker/models/expense_item.dart';
import 'package:monthly_budget_tracker/models/month.dart';
import 'package:monthly_budget_tracker/providers/analytics_provider.dart';
import 'package:monthly_budget_tracker/utils/currency_formatter.dart';

void main() {
  group('ExpenseItem totals', () {
    test('null price is excluded from category used', () {
      final cat = BudgetCategory(
        id: 'c1',
        monthId: 'm1',
        name: 'Subscriptions',
        budget: 12000,
        colorHex: '#BF5AF2',
        sortOrder: 0,
        items: [
          ExpenseItem(
            id: 'i1',
            categoryId: 'c1',
            name: 'Netflix',
            price: 1100,
            date: DateTime(2026, 9, 20),
          ),
          ExpenseItem(
            id: 'i2',
            categoryId: 'c1',
            name: 'Cursor',
            price: null,
            date: DateTime(2026, 9, 27),
            recurrence: RecurrenceFrequency.monthly,
            recurringDay: 27,
          ),
        ],
      );
      expect(cat.used, 1100);
      expect(cat.percentUsed, closeTo(1100 / 12000, 0.0001));
    });

    test('month totals sum only priced items', () {
      final month = Month(
        id: 'm1',
        name: 'September 2026',
        createdAt: DateTime(2026, 9, 1),
        year: 2026,
        monthNumber: 9,
        categories: [
          BudgetCategory(
            id: 'c1',
            monthId: 'm1',
            name: 'Food',
            budget: 25000,
            colorHex: '#FF9F0A',
            sortOrder: 0,
            items: [
              ExpenseItem(
                id: 'i1',
                categoryId: 'c1',
                name: "McDonald's",
                price: 3046,
                date: DateTime(2026, 9, 1),
              ),
            ],
          ),
          BudgetCategory(
            id: 'c2',
            monthId: 'm1',
            name: 'Subscriptions',
            budget: 12000,
            colorHex: '#BF5AF2',
            sortOrder: 1,
            items: [
              ExpenseItem(
                id: 'i2',
                categoryId: 'c2',
                name: 'Cursor',
                date: DateTime(2026, 9, 27),
              ),
            ],
          ),
        ],
      );

      expect(month.totalBudget, 37000);
      expect(month.totalUsed, 3046);
      expect(month.remaining, 37000 - 3046);
      expect(month.isOverBudget, isFalse);
      expect(month.averageDailySpend, closeTo(3046 / 30, 0.01));
    });
  });

  group('Recurring copy rules', () {
    test('monthly recurring always copies', () {
      final item = ExpenseItem(
        id: 'i1',
        categoryId: 'c1',
        name: 'Spotify',
        date: DateTime(2026, 9, 12),
        recurrence: RecurrenceFrequency.monthly,
        recurringDay: 12,
      );
      expect(
        Month.shouldCopyRecurringItem(item: item, targetMonthNumber: 10),
        isTrue,
      );
    });

    test('yearly recurring copies only matching month', () {
      final item = ExpenseItem(
        id: 'i1',
        categoryId: 'c1',
        name: 'Domain',
        date: DateTime(2026, 3, 5),
        recurrence: RecurrenceFrequency.yearly,
        recurringDay: 5,
        recurringMonth: 3,
      );
      expect(
        Month.shouldCopyRecurringItem(item: item, targetMonthNumber: 3),
        isTrue,
      );
      expect(
        Month.shouldCopyRecurringItem(item: item, targetMonthNumber: 10),
        isFalse,
      );
    });

    test('dateForRecurring clamps day 31 in shorter months', () {
      final date = Month.dateForRecurring(
        year: 2026,
        monthNumber: 2,
        day: 31,
      );
      expect(date.day, 28);
      expect(date.month, 2);
    });
  });

  group('CurrencyFormatter', () {
    test('formats without decimals', () {
      expect(CurrencyFormatter.format(16363), contains('16,363'));
      expect(CurrencyFormatter.format(null), '—');
      expect(CurrencyFormatter.percent(0.3366), '34%');
    });
  });

  group('AnalyticsHelper', () {
    test('builds chronological month-over-month points', () {
      final older = Month(
        id: 'a',
        name: 'August 2026',
        createdAt: DateTime(2026, 8, 1),
        year: 2026,
        monthNumber: 8,
      );
      final newer = Month(
        id: 'b',
        name: 'September 2026',
        createdAt: DateTime(2026, 9, 1),
        year: 2026,
        monthNumber: 9,
        categories: [
          BudgetCategory(
            id: 'c',
            monthId: 'b',
            name: 'Food',
            budget: 100,
            colorHex: '#FF9F0A',
            sortOrder: 0,
            items: [
              ExpenseItem(
                id: 'i',
                categoryId: 'c',
                name: 'X',
                price: 50,
                date: DateTime(2026, 9, 1),
              ),
            ],
          ),
        ],
      );
      final points = AnalyticsHelper.monthOverMonth([newer, older]);
      expect(points.first.month.id, 'a');
      expect(points.last.used, 50);
    });
  });
}
