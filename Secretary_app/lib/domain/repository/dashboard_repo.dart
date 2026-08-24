import '../models/dashboard.dart';
import '../models/paged_rows.dart';

abstract class DashboardRepository {
  Future<DashboardSummary> getDashboard();
  Future<RowList> getIncomeSplit({String? to});
  Future<RowList> getExpenseChart({int? type});
  Future<RowList> getRecentActivity();
}
