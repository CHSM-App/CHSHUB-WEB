import 'package:security_app/domain/models/emergency_alert.dart';
import 'package:security_app/domain/models/login_data.dart';
import 'package:security_app/domain/repository/emergencyalert_repo.dart';
import 'package:flutter/material.dart';
class EmergencyalertUsecase {
  final EmergencyalertRepo emergencyalertRepo;
  EmergencyalertUsecase(this.emergencyalertRepo);

  Future<dynamic> AddEmergencyAlert(EmergencyAlert emergencyAlert) {
    return emergencyalertRepo.AddEmergencyAlert(emergencyAlert);
  }

   Future<EmergencyAlert?> getEmergencyAlertPreference(String societyId,String alertType,) async {
  try {
    final response = await emergencyalertRepo.getEmergencyAlertPreference(societyId, alertType);
    
    // Check if response is successful and has data
    if (response['success'] == true && response['data'] != null) {
      final data = response['data'] as Map<String, dynamic>;
      
      final alert = EmergencyAlert.fromJson(data);
      return alert;
    } else {
      debugPrint('❌ UseCase: No data in response or success=false');
      return null;
    }
  } catch (e, stackTrace) {
    debugPrint('❌ UseCase Error: $e');
    debugPrint('❌ Stack: $stackTrace');
    rethrow;
  }
}
    Future<List<EmergencyAlert>> getActiveAlerts() {
    return emergencyalertRepo.getActiveAlerts();
  }
      Future<List<LoginData>> buildingListFetch(String societyId) {
      return emergencyalertRepo.buildingListFetch(societyId);
    }


      Future<dynamic> addCustomMessage(EmergencyAlert emergencyAlert) {
      return emergencyalertRepo.addCustomMessage(emergencyAlert);
      }
}
  