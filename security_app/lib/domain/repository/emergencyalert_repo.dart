import 'package:security_app/domain/models/emergency_alert.dart';
import 'package:security_app/domain/models/login_data.dart';

abstract class EmergencyalertRepo {
 
  Future<dynamic> AddEmergencyAlert(EmergencyAlert emergencyAlert);
  Future<Map<String, dynamic>> getEmergencyAlertPreference(String societyId, String alertType);
  Future<List<EmergencyAlert>> getActiveAlerts();
  Future<List<LoginData>> buildingListFetch(String societyId);
  Future<dynamic> addCustomMessage(EmergencyAlert emergencyAlert);
}