import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:society_app/data/repositories/alert_impl.dart';
import 'package:society_app/data/repositories/auth_impl.dart';
import 'package:society_app/data/repositories/due_history_impl.dart';
import 'package:society_app/data/repositories/facilities_impl.dart';
import 'package:society_app/data/repositories/helpdesk_impl.dart';
import 'package:society_app/data/repositories/helper_impl.dart';
import 'package:society_app/data/repositories/maintenance_repo_Impl.dart';
import 'package:society_app/data/repositories/polls_impl.dart';
import 'package:society_app/data/repositories/profile_settings_impl.dart';
import 'package:society_app/data/repositories/transaction_impl.dart';
import 'package:society_app/data/repositories/visitor_impl.dart';
import 'package:society_app/domain/repository/alert_repository.dart';
import 'package:society_app/domain/repository/auth_repository.dart';
import 'package:society_app/domain/repository/due_History_repository.dart';
import 'package:society_app/domain/repository/facilities_repository.dart';
import 'package:society_app/domain/repository/helpdesk_repository.dart';
import 'package:society_app/domain/repository/helper_repository.dart';
import 'package:society_app/domain/repository/maintenance_repo.dart';
import 'package:society_app/domain/repository/polls_repository.dart';
import 'package:society_app/domain/repository/profile_settings_repository.dart';
import 'package:society_app/domain/repository/transaction_repository.dart';
import 'package:society_app/domain/repository/visitor_repository.dart';
import '../../core/network/dio_provider.dart';
import '../../data/api/api_service.dart';
import '../../data/repositories/basic_info_impl.dart';
import '../../data/repositories/broadcast_impl.dart';
import '../../data/repositories/directory_impl.dart';
import '../../data/repositories/product_impl.dart';
import '../../domain/repository/basic_info_repository.dart';
import '../../domain/repository/broadcast_repository.dart';
import '../../domain/repository/directory_repository.dart';
import '../../domain/repository/product_repository.dart';

// Basic Info Repository Provider
// ignore: non_constant_identifier_names
final BasicInfoRepositoryProvider = Provider<BasicInfoRepository>((ref) {
  final dio = ref.watch(dioProvider).value!;
  final api = ApiService(dio);
  return BasicInfoRepositoryImpl(api);
});
// Helper Repository Provider
// ignore: non_constant_identifier_names
final HelperRepositoryProvider = Provider<HelperRepository>((ref) {
  final dio = ref.watch(dioProvider).value!;
  final api = ApiService(dio);
  return HelperRepositoryImpl (api);
});
// Helpdesk Repository Provider
// ignore: non_constant_identifier_names
final TransactionRepostoryProvider = Provider<TransactionRepository>((ref) {
   final dio = ref.watch(dioProvider).value!;
  final api = ApiService(dio);
  return TransactionImpl (api);
});
// Helpdesk Repository Provider
// ignore: non_constant_identifier_names
final HelpdeskRepostoryProvider = Provider<HelpdeskRepository>((ref) {
   final dio = ref.watch(dioProvider).value!;
  final api = ApiService(dio);
  return HelpdeskRepositoryImpl (api);
});
// Visitor Repository Provider
// ignore: non_constant_identifier_names
final VisitorRepositoryProvider = Provider<VisitorRepository>((ref) {
   final dio = ref.watch(dioProvider).value!;
  final api = ApiService(dio);
  return VisitorImpl(api);
});
// ignore: non_constant_identifier_names
final DirectoryRepositoryProvider = Provider<DirectoryRepository>((ref) {
   final dio = ref.watch(dioProvider).value!;
  final api = ApiService(dio);
  return DirectoryRepositoryImpl(api);
});
// Broadcast Repository Provider
// ignore: non_constant_identifier_names  
final BroadcastRepositoryProvider = Provider<BroadcastRepository>((ref) {
   final dio = ref.watch(dioProvider).value!;
  final api = ApiService(dio);
  return BroadcastRepositoryImpl(api);
});


//facilities Repository Provider

final FacilitiesRepositoryProvider = Provider<FacilitiesRepository>((ref) {
   final dio = ref.watch(dioProvider).value!;
  final api = ApiService(dio);
  return FacilitiesImpl(api);
});

final DueHistoryRepositoryProvider = Provider<DueHistoryRepository>((ref) {
   final dio = ref.watch(dioProvider).value!;
  final api = ApiService(dio);
  return DueHistoryImpl(api);
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
   final dio = ref.watch(dioProvider).value!;
  final api = ApiService(dio);
  return AuthImpl(api);
});

final productRepositoryProvider=Provider<ProductRepository>((ref) {
   final dio = ref.watch(dioProvider).value!;
  final api = ApiService(dio);
  return ProductRepositoryImpl(api);
});
final alertRepositoryProvider=Provider<AlertRepository>((ref) {
   final dio = ref.watch(dioProvider).value!;
  final api = ApiService(dio);
  return AlertImpl(api);
});
final maintenanceRepositoryProvider=Provider<MaintenanceRepository>((ref) {
   final dio = ref.watch(dioProvider).value!;
  final api = ApiService(dio);
  return MaintenanceRepositoryImpl(api);
});

// Polls Repository Provider
final PollsRepositoryProvider=Provider<PollsRepository>((ref) {
   final dio = ref.watch(dioProvider).value!;
  final api = ApiService(dio);
  return PollsImpl(api);
});
// Profile Settings Repository Provider
final profileSettingsRepositoryProvider = Provider<ProfileSettingsRepository>((ref) {
   final dio = ref.watch(dioProvider).value!;
  final api = ApiService(dio);
  return ProfileSettingsImpl(api);
});
