import 'category.dart';
import 'expense_item.dart';

class Month {
  const Month({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.year,
    required this.monthNumber,
    this.categories = const [],
  });

  final String id;
  final String name;
  final DateTime createdAt;
  final int year;
  final int monthNumber;
  final List<BudgetCategory> categories;

  double get totalBudget =>
      categories.fold(0.0, (sum, category) => sum + category.budget);

  double get totalUsed =>
      categories.fold(0.0, (sum, category) => sum + category.used);

  double get remaining => totalBudget - totalUsed;

  double get percentUsed {
    if (totalBudget <= 0) return totalUsed > 0 ? 1.0 : 0.0;
    return totalUsed / totalBudget;
  }

  bool get isOverBudget => totalUsed > totalBudget && totalBudget > 0;

  int get daysInMonth => DateTime(year, monthNumber + 1, 0).day;

  double get averageDailySpend {
    if (daysInMonth <= 0) return 0;
    return totalUsed / daysInMonth;
  }

  BudgetCategory? get highestSpendingCategory {
    if (categories.isEmpty) return null;
    return categories.reduce((a, b) => a.used >= b.used ? a : b);
  }

  BudgetCategory? get lowestSpendingCategory {
    final withSpend = categories.where((c) => c.used > 0).toList();
    if (withSpend.isEmpty) {
      if (categories.isEmpty) return null;
      return categories.reduce((a, b) => a.used <= b.used ? a : b);
    }
    return withSpend.reduce((a, b) => a.used <= b.used ? a : b);
  }

  Month copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    int? year,
    int? monthNumber,
    List<BudgetCategory>? categories,
  }) {
    return Month(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      year: year ?? this.year,
      monthNumber: monthNumber ?? this.monthNumber,
      categories: categories ?? this.categories,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'year': year,
      'monthNumber': monthNumber,
      'categories': categories.map((c) => c.toMap()).toList(),
    };
  }

  factory Month.fromMap(Map<String, dynamic> map) {
    final rawCategories = map['categories'] as List<dynamic>? ?? const [];
    return Month(
      id: map['id'] as String,
      name: map['name'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      year: map['year'] as int,
      monthNumber: map['monthNumber'] as int,
      categories: rawCategories
          .map(
            (e) => BudgetCategory.fromMap(Map<String, dynamic>.from(e as Map)),
          )
          .toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)),
    );
  }

  /// Clamps day into the destination month (handles 29–31).
  static DateTime dateForRecurring({
    required int year,
    required int monthNumber,
    required int day,
  }) {
    final lastDay = DateTime(year, monthNumber + 1, 0).day;
    return DateTime(year, monthNumber, day.clamp(1, lastDay));
  }

  static bool shouldCopyRecurringItem({
    required ExpenseItem item,
    required int targetMonthNumber,
  }) {
    if (!item.isRecurring || item.recurringDay == null) return false;
    if (item.recurrence == RecurrenceFrequency.monthly) return true;
    if (item.recurrence == RecurrenceFrequency.yearly) {
      return item.recurringMonth == targetMonthNumber;
    }
    return false;
  }
}
