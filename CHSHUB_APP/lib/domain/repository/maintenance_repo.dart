import 'package:society_app/domain/models/maintenance.dart';

abstract class MaintenanceRepository {

  Future<List<Maintenance>> getMaintenanceList(int flatId, int billId); 
    
}
  