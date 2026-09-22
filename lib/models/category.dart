import 'expense_item.dart';

class BudgetCategory {
  const BudgetCategory({
    required this.id,
    required this.monthId,
    required this.name,
    required this.budget,
    required this.colorHex,
    required this.sortOrder,
    this.items = const [],
  });

  final String id;
  final String monthId;
  final String name;
  final double budget;
  final String colorHex;
  final int sortOrder;
  final List<ExpenseItem> items;

  double get used => items
      .where((item) => item.countsTowardTotals)
      .fold(0.0, (sum, item) => sum + item.price!);

  double get remaining => budget - used;

  double get percentUsed {
    if (budget <= 0) return used > 0 ? 1.0 : 0.0;
    return used / budget;
  }

  bool get isOverBudget => used > budget && budget > 0;

  BudgetCategory copyWith({
    String? id,
    String? monthId,
    String? name,
    double? budget,
    String? colorHex,
    int? sortOrder,
    List<ExpenseItem>? items,
  }) {
    return BudgetCategory(
      id: id ?? this.id,
      monthId: monthId ?? this.monthId,
      name: name ?? this.name,
      budget: budget ?? this.budget,
      colorHex: colorHex ?? this.colorHex,
      sortOrder: sortOrder ?? this.sortOrder,
      items: items ?? this.items,
    );
  }

  Map<String, dynamic> toMap({bool includeItems = true}) {
    return {
      'id': id,
      'monthId': monthId,
      'name': name,
      'budget': budget,
      'colorHex': colorHex,
      'sortOrder': sortOrder,
      if (includeItems) 'items': items.map((e) => e.toMap()).toList(),
    };
  }

  factory BudgetCategory.fromMap(Map<String, dynamic> map) {
    final rawItems = map['items'] as List<dynamic>? ?? const [];
    return BudgetCategory(
      id: map['id'] as String,
      monthId: map['monthId'] as String,
      name: map['name'] as String,
      budget: (map['budget'] as num?)?.toDouble() ?? 0,
      colorHex: map['colorHex'] as String? ?? '#0A84FF',
      sortOrder: map['sortOrder'] as int? ?? 0,
      items: rawItems
          .map((e) => ExpenseItem.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}
