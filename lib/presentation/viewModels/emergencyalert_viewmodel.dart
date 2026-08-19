import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:security_app/domain/models/emergency_alert.dart';
import 'package:security_app/domain/models/login_data.dart';
import 'package:security_app/domain/usecase/emergencyalert_usecase.dart';
import 'package:security_app/core/utils/error_formatter.dart';

class EmergencyState {
  final bool isLoading;
  final String? error;
  final List<EmergencyAlert>? emergencyAlerts;
    final EmergencyAlert? currentPreference; // Single preference for current alert type
  final List<EmergencyAlert>? allAlerts; 
  final List<LoginData>?buildingList;
  
  const EmergencyState({
    this.isLoading = false,
    this.error,
    this.emergencyAlerts,
    this.currentPreference,
    this.allAlerts,
    this.buildingList,
  });

  EmergencyState copyWith({
    bool? isLoading,
    String? error,
    List<EmergencyAlert>? emergencyAlerts,
    EmergencyAlert? currentPreference,
    List<EmergencyAlert>? allAlerts,
     List<LoginData>? buildingList,
  }) {
    return EmergencyState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      emergencyAlerts: emergencyAlerts ?? this.emergencyAlerts,
      currentPreference: currentPreference ?? this.currentPreference,
      allAlerts: allAlerts ?? this.allAlerts,
          buildingList: buildingList ?? this.buildingList,
    );
  }
}

class EmergencyalertViewmodel extends StateNotifier<EmergencyState> {
  final EmergencyalertUsecase usecase;
  EmergencyalertViewmodel(this.usecase) : super(const EmergencyState());

  Future<bool> addEmergencyAlert(EmergencyAlert emergencyAlert) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await usecase.AddEmergencyAlert(emergencyAlert);
      state = state.copyWith(
        isLoading: false,
        currentPreference: emergencyAlert,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: getErrorMessage(e));
      return false;
    }
  }

Future<EmergencyAlert?> fetchEmergencyAlertPreference(
  String societyId,
  String alertType,
) async {
  state = state.copyWith(isLoading: true, error: null);
  try {
    debugPrint('🔍 ViewModel: Fetching preference');
    
    final preference = await usecase.getEmergencyAlertPreference(societyId, alertType);
    
    debugPrint('📦 ViewModel: Received preference: $preference');
    debugPrint('📦 ViewModel: Alert scope: ${preference?.alertScope}'); // Add ? here
    
    state = state.copyWith(
      isLoading: false,
      currentPreference: preference,
    );
    
    debugPrint('✅ ViewModel: State updated, currentPreference: ${state.currentPreference?.alertScope}');
    return state.currentPreference;
  } catch (e, stackTrace) {
    debugPrint('❌ ViewModel Error: $e');
    debugPrint('Stack: $stackTrace');
    state = state.copyWith(isLoading: false, error: getErrorMessage(e));
    return null;
  }
}
  // Fetch all active alerts
  Future<void> fetchActiveAlerts() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final alerts = await usecase.getActiveAlerts();
      state = state.copyWith(
        allAlerts: alerts,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: getErrorMessage(e));
    }
  }

Future<void> fetchBuildingList(String societyId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final buildings = await usecase.buildingListFetch(societyId);
      state = state.copyWith(
        buildingList: buildings,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: getErrorMessage(e));
    }
  }

Future<bool> addCustomMessage(EmergencyAlert emergencyAlert) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await usecase.addCustomMessage(emergencyAlert);
      state = state.copyWith(
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: getErrorMessage(e));
      return false;
    }
  }

  // Clear current preference
  void clearCurrentPreference() {
    state = state.copyWith(currentPreference: null);
  }

}


