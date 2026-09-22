import '../models/month.dart';

abstract class BudgetRepository {
  Future<void> init();

  String? get userId;

  Future<List<Month>> loadMonths();

  Future<void> saveMonths(List<Month> months);

  Future<void> upsertMonth(Month month);

  Future<void> deleteMonth(String monthId);

  Stream<List<Month>> watchMonths();
}
