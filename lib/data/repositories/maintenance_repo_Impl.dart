import 'package:society_app/data/api/api_service.dart';
import 'package:society_app/domain/models/maintenance.dart';
import 'package:society_app/domain/repository/maintenance_repo.dart';

class MaintenanceRepositoryImpl implements MaintenanceRepository {
  final ApiService apiService;

  MaintenanceRepositoryImpl( this.apiService);

  @override
  Future<List<Maintenance>> getMaintenanceList(int flatId, int billId) async {
    return await apiService.maintenanceList(flatId, billId);
  }
}
