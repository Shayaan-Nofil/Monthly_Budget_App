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
    this.enteredAmount,
    this.enteredCurrency,
    this.priceCurrency,
    this.fxRate,
    this.fxFetchedAt,
  });

  final String id;
  final String categoryId;
  final String name;

  /// Canonical amount used for totals (in [priceCurrency] / home at save time).
  /// Null price means the item is listed but excluded from totals/analytics.
  final double? price;
  final DateTime date;
  final RecurrenceFrequency recurrence;
  final int? recurringDay;
  final int? recurringMonth;
  final String? receiptImageUrl;
  final String? receiptLocalPath;

  /// What the user typed before conversion.
  final double? enteredAmount;

  /// Currency of [enteredAmount].
  final String? enteredCurrency;

  /// Currency [price] is denominated in (home currency when saved).
  final String? priceCurrency;

  /// `price / enteredAmount` when currencies differed.
  final double? fxRate;
  final DateTime? fxFetchedAt;

  bool get isRecurring => recurrence != RecurrenceFrequency.none;

  bool get countsTowardTotals => price != null;

  bool get wasEnteredInForeignCurrency {
    final entered = enteredCurrency?.toUpperCase();
    final home = priceCurrency?.toUpperCase();
    if (entered == null || home == null) return false;
    return entered != home;
  }

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
    double? enteredAmount,
    bool clearEnteredAmount = false,
    String? enteredCurrency,
    bool clearEnteredCurrency = false,
    String? priceCurrency,
    bool clearPriceCurrency = false,
    double? fxRate,
    bool clearFxRate = false,
    DateTime? fxFetchedAt,
    bool clearFxFetchedAt = false,
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
      enteredAmount: clearEnteredAmount
          ? null
          : (enteredAmount ?? this.enteredAmount),
      enteredCurrency: clearEnteredCurrency
          ? null
          : (enteredCurrency ?? this.enteredCurrency),
      priceCurrency: clearPriceCurrency
          ? null
          : (priceCurrency ?? this.priceCurrency),
      fxRate: clearFxRate ? null : (fxRate ?? this.fxRate),
      fxFetchedAt:
          clearFxFetchedAt ? null : (fxFetchedAt ?? this.fxFetchedAt),
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
      'enteredAmount': enteredAmount,
      'enteredCurrency': enteredCurrency,
      'priceCurrency': priceCurrency,
      'fxRate': fxRate,
      'fxFetchedAt': fxFetchedAt?.toIso8601String(),
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
      enteredAmount: (map['enteredAmount'] as num?)?.toDouble(),
      enteredCurrency: map['enteredCurrency'] as String?,
      priceCurrency: map['priceCurrency'] as String?,
      fxRate: (map['fxRate'] as num?)?.toDouble(),
      fxFetchedAt: map['fxFetchedAt'] == null
          ? null
          : DateTime.tryParse(map['fxFetchedAt'] as String),
    );
  }
}
