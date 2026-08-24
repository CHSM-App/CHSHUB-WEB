import '../models/dashboard.dart';
import '../models/paged_rows.dart';
import '../repository/dashboard_repo.dart';

class DashboardUsecase {
  final DashboardRepository repository;

  DashboardUsecase(this.repository);

  /// Headline figures for the landing page.
  Future<DashboardSummary> getDashboard() => repository.getDashboard();

  /// Income tracker donut for a period ending at [to].
  Future<RowList> getIncomeSplit({String? to}) =>
      repository.getIncomeSplit(to: to);

  /// Expense breakdown; [type] 2 means every bill type.
  Future<RowList> getExpenseChart({int? type}) =>
      repository.getExpenseChart(type: type);

  /// The full activity feed, beyond the 20 the dashboard carries.
  Future<RowList> getRecentActivity() => repository.getRecentActivity();
}
