import 'package:security_app/data/api/api_service.dart';
import 'package:security_app/domain/models/emergency_alert.dart';
import 'package:security_app/domain/models/login_data.dart';
import 'package:security_app/domain/repository/emergencyalert_repo.dart';

class EmergencyalertImpl implements EmergencyalertRepo {
  final ApiService apiService;

  EmergencyalertImpl(this.apiService);

  @override
  Future<dynamic> AddEmergencyAlert(EmergencyAlert emergencyAlert) {
    return apiService.AddEmergencyAlert(emergencyAlert);
  }
  @override
  Future<Map<String, dynamic>> getEmergencyAlertPreference(String societyId, String alertType) {
    return apiService.getEmergencyAlertPreference(societyId, alertType)
        .then((v) => (v as Map).cast<String, dynamic>());
  }
    @override 
  Future<List<EmergencyAlert>> getActiveAlerts() {
    return apiService.getActiveAlerts();
  }
   @override
  Future<List<LoginData>> buildingListFetch(String societyId) {
    return apiService.buildingListFetch(societyId);
  }
  @override
  Future<dynamic> addCustomMessage(EmergencyAlert emergencyAlert) {
    return apiService.addCustomMessage(emergencyAlert);
  }
}