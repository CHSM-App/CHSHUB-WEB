import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:security_app/core/network/dio_provider.dart';
import 'package:security_app/data/api/api_service.dart';
import 'package:security_app/data/repositories/all_units_impl.dart';
import 'package:security_app/data/repositories/auth_impl.dart';
import 'package:security_app/data/repositories/directory_impl.dart';
import 'package:security_app/data/repositories/emergencyalert_impl.dart';
import 'package:security_app/data/repositories/logindata_impl.dart';
import 'package:security_app/data/repositories/staff_impl.dart';
import 'package:security_app/data/repositories/visitors_impl.dart';
import 'package:security_app/domain/repository/AllUnits_repo.dart';
import 'package:security_app/domain/repository/auth_repo.dart';
import 'package:security_app/domain/repository/directory_repo.dart';
import 'package:security_app/domain/repository/emergencyalert_repo.dart';
import 'package:security_app/domain/repository/logindata_repo.dart';
import 'package:security_app/domain/repository/staff_repo.dart';
import 'package:security_app/domain/repository/visitors_repo.dart';


final loginRepositoryProvider = Provider<LoginRepo>((ref) {
  final dio = ref.watch(dioProvider).value!;
  final api = ApiService(dio);
  return LoginImpl(api);
});

// You can add more repository providers here as needed.
final allUnitsRepositoryProvider = Provider<AllUnitsRepo>((ref) {
  final dio = ref.watch(dioProvider).value!;
  final api = ApiService(dio);
  return AllUnitsImpl(api);
});

// Add other repository providers similarly
final directoryRepositoryProvider = Provider<DirectoryRepo>((ref) {
  final dio = ref.watch(dioProvider).value!;
  final api = ApiService(dio);
  return DirectoryImpl(api);
});

final staffRepositoryProvider = Provider<StaffRepo>((ref) {
  final dio = ref.watch(dioProvider).value!;
  final api = ApiService(dio);
  return StaffRepositoryImpl(api);
});

final visitorrepositoryProvider = Provider<VisitorsRepo>((ref) {
  final dio = ref.watch(dioProvider).value!;
  final api = ApiService(dio);
  return VisitorsImpl(api);
});
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dio = ref.watch(dioProvider).value!;
  final api = ApiService(dio);
  return AuthImpl(api);
});
final emergencyalertRepositoryProvider = Provider<EmergencyalertRepo>((ref) {
  final dio = ref.watch(dioProvider).value!;
  final api = ApiService(dio);
  return EmergencyalertImpl(api);
});




