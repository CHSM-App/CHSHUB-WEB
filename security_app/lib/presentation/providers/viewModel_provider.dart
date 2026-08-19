import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:security_app/presentation/providers/usecase_provider.dart';
import 'package:security_app/presentation/viewModels/directory_viewmodel.dart';
import 'package:security_app/presentation/viewModels/emergencyalert_viewmodel.dart';
import 'package:security_app/presentation/viewModels/login_viewmodel.dart';
import 'package:security_app/presentation/viewModels/network_model.dart';
import 'package:security_app/presentation/viewModels/staff_viewmodel.dart';
import 'package:security_app/presentation/viewModels/units_viewmodel.dart';
import 'package:security_app/presentation/viewModels/visitors_viewmodel.dart';
final firebaseMessagingProvider = Provider<FirebaseMessaging>((ref) {
  return FirebaseMessaging.instance;
});

final networkStateProvider =
    StateNotifierProvider<EnhancedNetworkStateNotifier, NetworkState>(
        (ref) => EnhancedNetworkStateNotifier());


final securitymodelProvider = StateNotifierProvider<SecurityModelViewModel, SecurityState>((ref) {
  final usecase = ref.watch(loginUsercaseProvider);
  return SecurityModelViewModel(usecase);
});

final unitsmodelProvider = StateNotifierProvider<UnitsViewModel, UnitState>((ref) {
  final usecase = ref.watch(unitsUsecaseProvider);
  return UnitsViewModel(usecase);
});

final directorymodelProvider = StateNotifierProvider<DirectoryViewModel, DirectoryState>((ref) {
  final usecase = ref.watch(directoryUsecaseProvider);
  return DirectoryViewModel(usecase);
});

final staffmodelProvider = StateNotifierProvider<StaffViewModel, StaffState>((ref) {
  final usecase = ref.watch(staffUsecaseProvider);
  return StaffViewModel(usecase);
});

final visitormodelProvider = StateNotifierProvider<VisitorsViewModel, VisitorState>((ref) {
  final usecase = ref.watch(visitorsUsecaseProvider);
  final message=ref.watch(firebaseMessagingProvider);
  return VisitorsViewModel(usecase, message);
});

final emergencymodelProvider = StateNotifierProvider<EmergencyalertViewmodel, EmergencyState>((ref) {
  final usecase = ref.watch(emergencyalertUsecaseProvider);
  return EmergencyalertViewmodel(usecase);
});



