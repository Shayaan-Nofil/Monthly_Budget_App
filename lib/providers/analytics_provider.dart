import '../models/category.dart';
import '../models/month.dart';

class MonthSpendPoint {
  const MonthSpendPoint({required this.month, required this.used});

  final Month month;
  final double used;
}

class CategorySpendSlice {
  const CategorySpendSlice({required this.category, required this.used});

  final BudgetCategory category;
  final double used;
}

/// Pure helpers for analytics — unit-testable without widgets.
class AnalyticsHelper {
  AnalyticsHelper._();

  static List<MonthSpendPoint> monthOverMonth(List<Month> months) {
    final chronological = [...months]
      ..sort((a, b) {
        final byYear = a.year.compareTo(b.year);
        if (byYear != 0) return byYear;
        return a.monthNumber.compareTo(b.monthNumber);
      });
    return chronological
        .map((m) => MonthSpendPoint(month: m, used: m.totalUsed))
        .toList();
  }

  static List<CategorySpendSlice> categoryBreakdown(Month? month) {
    if (month == null) return const [];
    return month.categories
        .map((c) => CategorySpendSlice(category: c, used: c.used))
        .where((s) => s.used > 0)
        .toList()
      ..sort((a, b) => b.used.compareTo(a.used));
  }
}
