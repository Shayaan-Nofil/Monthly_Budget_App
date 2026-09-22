enum RecurrenceFrequency {
  none,
  monthly,
  yearly;

  static RecurrenceFrequency fromString(String? value) {
    return RecurrenceFrequency.values.firstWhere(
      (e) => e.name == value,
      orElse: () => RecurrenceFrequency.none,
    );
  }
}

class ExpenseItem {
  const ExpenseItem({
    required this.id,
    required this.categoryId,
    required this.name,
    this.price,
    required this.date,
    this.recurrence = RecurrenceFrequency.none,
    this.recurringDay,
    this.recurringMonth,
    this.receiptImageUrl,
    this.receiptLocalPath,
  });

  final String id;
  final String categoryId;
  final String name;

  /// Null price means the item is listed but excluded from totals/analytics.
  final double? price;
  final DateTime date;
  final RecurrenceFrequency recurrence;
  final int? recurringDay;
  final int? recurringMonth;
  final String? receiptImageUrl;
  final String? receiptLocalPath;

  bool get isRecurring => recurrence != RecurrenceFrequency.none;

  bool get countsTowardTotals => price != null;

  ExpenseItem copyWith({
    String? id,
    String? categoryId,
    String? name,
    double? price,
    bool clearPrice = false,
    DateTime? date,
    RecurrenceFrequency? recurrence,
    int? recurringDay,
    bool clearRecurringDay = false,
    int? recurringMonth,
    bool clearRecurringMonth = false,
    String? receiptImageUrl,
    String? receiptLocalPath,
    bool clearReceipt = false,
  }) {
    return ExpenseItem(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      price: clearPrice ? null : (price ?? this.price),
      date: date ?? this.date,
      recurrence: recurrence ?? this.recurrence,
      recurringDay:
          clearRecurringDay ? null : (recurringDay ?? this.recurringDay),
      recurringMonth: clearRecurringMonth
          ? null
          : (recurringMonth ?? this.recurringMonth),
      receiptImageUrl:
          clearReceipt ? null : (receiptImageUrl ?? this.receiptImageUrl),
      receiptLocalPath:
          clearReceipt ? null : (receiptLocalPath ?? this.receiptLocalPath),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'categoryId': categoryId,
      'name': name,
      'price': price,
      'date': date.toIso8601String(),
      'recurrence': recurrence.name,
      'recurringDay': recurringDay,
      'recurringMonth': recurringMonth,
      'receiptImageUrl': receiptImageUrl,
      'receiptLocalPath': receiptLocalPath,
    };
  }

  factory ExpenseItem.fromMap(Map<String, dynamic> map) {
    return ExpenseItem(
      id: map['id'] as String,
      categoryId: map['categoryId'] as String,
      name: map['name'] as String,
      price: (map['price'] as num?)?.toDouble(),
      date: DateTime.parse(map['date'] as String),
      recurrence: RecurrenceFrequency.fromString(map['recurrence'] as String?),
      recurringDay: map['recurringDay'] as int?,
      recurringMonth: map['recurringMonth'] as int?,
      receiptImageUrl: map['receiptImageUrl'] as String?,
      receiptLocalPath: map['receiptLocalPath'] as String?,
    );
  }
}
