import 'package:society_app/domain/models/maintenance.dart';
import 'package:society_app/domain/repository/maintenance_repo.dart';

class MaintenanceUseCase {
  final MaintenanceRepository maintenanceRepository;

  MaintenanceUseCase( this.maintenanceRepository);

  Future<List<Maintenance>> getMaintenanceList(int flatId, int billId) async {
    return await maintenanceRepository.getMaintenanceList(flatId, billId);
  }
}
