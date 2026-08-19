import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:security_app/domain/usecase/auth_usecase.dart';
import 'package:security_app/domain/usecase/directory_usecase.dart';
import 'package:security_app/domain/usecase/emergencyalert_usecase.dart';
import 'package:security_app/domain/usecase/login_usercase.dart';
import 'package:security_app/domain/usecase/staff_usercase.dart';
import 'package:security_app/domain/usecase/units_usecase.dart';
import 'package:security_app/domain/usecase/visitors_usercase.dart';
import 'package:security_app/presentation/providers/repository_provider.dart';

final directoryUsecaseProvider = Provider<DirectoryUsecase>((ref) {
  final directoryRepo = ref.watch(directoryRepositoryProvider);
  return DirectoryUsecase(directoryRepo);
});

final staffUsecaseProvider = Provider<StaffUsercase>((ref) {
  final staffRepo = ref.watch(staffRepositoryProvider);
  return StaffUsercase(staffRepo);
});

final loginUsercaseProvider = Provider<LoginUsercase>((ref) {
  final loginRepo = ref.watch(loginRepositoryProvider);
  return LoginUsercase(loginRepo);
});

final unitsUsecaseProvider = Provider<UnitsUsecase>((ref) {
  final unitsRepo = ref.watch(allUnitsRepositoryProvider);
  return UnitsUsecase(unitsRepo);
});

final visitorsUsecaseProvider = Provider<VisitorsUsercase>((ref) {
  final visitorsRepo = ref.watch(visitorrepositoryProvider);
  return VisitorsUsercase(visitorsRepo);
});
final authUsecaseProvider = Provider<AuthUsecase>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return AuthUsecase(authRepo);
});

final emergencyalertUsecaseProvider = Provider<EmergencyalertUsecase>((ref) {
  final emergencyalertRepo = ref.watch(emergencyalertRepositoryProvider);
  return EmergencyalertUsecase(emergencyalertRepo);
});