import '../../domain/models/dashboard.dart';
import '../../domain/models/paged_rows.dart';
import '../../domain/repository/dashboard_repo.dart';
import '../api/api_service.dart';

class DashboardImpl implements DashboardRepository {
  final ApiService api;

  DashboardImpl(this.api);

  @override
  Future<DashboardSummary> getDashboard() => api.getDashboard();

  @override
  Future<RowList> getIncomeSplit({String? to}) => api.getIncomeSplit(to);

  @override
  Future<RowList> getExpenseChart({int? type}) => api.getExpenseChart(type);

  @override
  Future<RowList> getRecentActivity() => api.getRecentActivity();
}
