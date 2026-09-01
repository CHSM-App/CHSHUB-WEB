import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:society_app/domain/usecase/alert_usecase.dart';
import 'package:society_app/domain/usecase/auth_use_case.dart';
import 'package:society_app/domain/usecase/due_history_use_case.dart';
import 'package:society_app/domain/usecase/facilities_usecase.dart';
import 'package:society_app/domain/usecase/helpdesk_usecase.dart';
import 'package:society_app/domain/usecase/noc_usecase.dart';
import 'package:society_app/domain/usecase/helper_use_case.dart';
import 'package:society_app/domain/usecase/maintenance_usecase.dart';
import 'package:society_app/domain/usecase/polls_usecase.dart';
import 'package:society_app/domain/usecase/profile_settings_usecase.dart';
import 'package:society_app/domain/usecase/transaction_use_case.dart';
import 'package:society_app/domain/usecase/visitor_usecase.dart';

import '../../domain/usecase/basic_info_use_case.dart';
import '../../domain/usecase/broadcast_usecase.dart';
import '../../domain/usecase/directory_usecase.dart';
import '../../domain/usecase/product_usecase.dart';
import 'repository_provider.dart';
final authUseCaseProvider= Provider<AuthUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthUseCase(repository);
}) ;
// ignore: non_constant_identifier_names
final BasicInfouseCaseProvider = Provider<BasicInfoUseCases>((ref) {
  final repository = ref.watch(BasicInfoRepositoryProvider);
  return BasicInfoUseCases(repository);
});
// ignore: non_constant_identifier_names
final HelperuseCaseProvider = Provider<HelperUseCases>((ref) {
  final repository = ref.watch(HelperRepositoryProvider);
  return HelperUseCases(repository);
});
// ignore: non_constant_identifier_names
final TransactionUseCaseProvider = Provider<TransactionUseCase>((ref) {
  final repository = ref.watch(TransactionRepostoryProvider);
  return TransactionUseCase(repository);
});
// ignore: non_constant_identifier_names
final HelpdeskUseCaseProvider = Provider<HelpdeskUsecase>((ref) {
  final repository = ref.watch(HelpdeskRepostoryProvider);
  return HelpdeskUsecase(repository);
});
// ignore: non_constant_identifier_names
final VisitorUsecaseProvider = Provider<VisitorUsecase>((ref) {
  final repository = ref.watch(VisitorRepositoryProvider);
  return VisitorUsecase(repository);
});
final directoryUsecaseProvider = Provider<DirectoryUsecase>((ref) {
  final repository = ref.watch(DirectoryRepositoryProvider);
  return DirectoryUsecase(repository);
});
// Broadcast Usecase Provider
final BroadcastUsecaseProvider = Provider<BroadcastUsecase>((ref) {
  final repository = ref.watch(BroadcastRepositoryProvider);
  return BroadcastUsecase(repository);
});


// Facilities Usecase Provider
final FacilitiesUsecaseProvider = Provider<FacilitiesUsecase>((ref) {
  final repository = ref.watch(FacilitiesRepositoryProvider);
  return FacilitiesUsecase(repository);
});


final DueHistoryUseCaseProvider = Provider<DueHistoryUseCase>((ref) {
  final repository = ref.watch(DueHistoryRepositoryProvider);
  return DueHistoryUseCase(repository);
});
final productUsecaseProvider = Provider<ProductUseCase>((ref) {
  final repository = ref.watch(productRepositoryProvider);
  return ProductUseCase(repository);
});

// Alert Usecase Provider
final AlertUsecaseProvider = Provider<AlertUsecase>((ref) {
  final repository = ref.watch(alertRepositoryProvider);
  return AlertUsecase(repository);
});
final maintenanceUseCaseProvider=Provider<MaintenanceUseCase>((ref) {
  final repository = ref.watch(maintenanceRepositoryProvider);
  return MaintenanceUseCase( repository);
});

// Polls Usecase Provider
final PollsUsecaseProvider=Provider<PollsUsecase>((ref) {
  final repository = ref.watch(PollsRepositoryProvider);
  return PollsUsecase(pollsRepository: repository);
});

// Profile Settings Usecase Provider
final profileSettingsUseCaseProvider=Provider<ProfileSettingsUseCase>((ref) {
  final repository = ref.watch(profileSettingsRepositoryProvider);
  return ProfileSettingsUseCase(repository);
});
// ignore: non_constant_identifier_names
final NocUseCaseProvider = Provider<NocUsecase>((ref) {
  final repository = ref.watch(NocRepositoryProvider);
  return NocUsecase(repository);
});
