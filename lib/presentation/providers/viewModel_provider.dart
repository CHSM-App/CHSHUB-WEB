// ignore: file_names
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:society_app/presentation/viewModels/alert_viewmodel.dart';
import 'package:society_app/presentation/viewModels/auth_model.dart';
import 'package:society_app/presentation/viewModels/due_History_viewmodal.dart';
import 'package:society_app/presentation/viewModels/facilities_viewmodel.dart';
import 'package:society_app/presentation/viewModels/helpdesk_viewmodel.dart';
import 'package:society_app/presentation/viewModels/noc_viewmodel.dart';
import 'package:society_app/presentation/viewModels/helper_view_model.dart';
import 'package:society_app/presentation/viewModels/maintenance_viewmodel.dart';
import 'package:society_app/presentation/viewModels/network_model.dart';
import 'package:society_app/presentation/viewModels/polls_viewmodel.dart';
import 'package:society_app/presentation/viewModels/product_view_model.dart';
import 'package:society_app/presentation/viewModels/profile_settings_viewmodel.dart';
import 'package:society_app/presentation/viewModels/transaction_viewmodel.dart';
import 'package:society_app/presentation/viewModels/visitor_viewmodel.dart';
import 'package:society_app/presentation/providers/usecase_provider.dart';
import '../viewModels/basic_info_viewmodel.dart';
import '../viewModels/broadcast_viewmodel.dart';
import '../viewModels/directory_viewmodel.dart';
 
final firebaseMessagingProvider = Provider<FirebaseMessaging>((ref) {
  return FirebaseMessaging.instance;
});

// Drives which tab AnimatedBottomNavScreen shows. Quick-action buttons on
// Home update this instead of pushing a new AnimatedBottomNavScreen route,
// so the already-loaded shell (and its cached basicInfoResult) stays alive
// instead of a fresh instance re-fetching user info and failing when
// there's no network.
final bottomNavIndexProvider = StateProvider<int>((ref) => 0);


final networkStateProvider =
    StateNotifierProvider<EnhancedNetworkStateNotifier, NetworkState>(
        (ref) => EnhancedNetworkStateNotifier());
final authViewModelProvider =
    StateNotifierProvider<AuthViewModel, AuthState>((ref) {
  final usecase = ref.watch(authUseCaseProvider);
 
  return AuthViewModel(ref,usecase);
});

final basicInfoViewModelProvider =
StateNotifierProvider<BasicInfoViewModel, BasicInfoState>((ref) {
  final useCases = ref.watch(BasicInfouseCaseProvider);
  return BasicInfoViewModel(useCases);
});

// ignore: non_constant_identifier_names
final HelperViewModelProvider =
StateNotifierProvider<HelperViewModel, HelperState>((ref) {
  final useCases = ref.watch(HelperuseCaseProvider);
  return HelperViewModel(useCases);
});
// ignore: non_constant_identifier_names
final TransactionViewModelProvider =
StateNotifierProvider<TransactionViewmodel, TransancationState>((ref) {
  final useCases = ref.watch(TransactionUseCaseProvider);
  return TransactionViewmodel(useCases);
});
// ignore: non_constant_identifier_names
final HelpdeskViewModelProvider =
StateNotifierProvider<HelpdeskViewModel, HelpdeskRequestState>((ref) {
  final useCases = ref.watch(HelpdeskUseCaseProvider);
  return HelpdeskViewModel(useCases);
});
// ignore: non_constant_identifier_names  
final visitorViewModelProvider = 
StateNotifierProvider<VisitorViewModel, VisitorState>((ref) {
  final usecase = ref.watch(VisitorUsecaseProvider); // replace with your DI setup
    final message=ref.watch(firebaseMessagingProvider);
  return VisitorViewModel(usecase, message);
});
final directoryViewModelProvider =
StateNotifierProvider<DirectoryViewModel, DirectoryState>((ref) {
  final usecase = ref.watch(directoryUsecaseProvider); // replace with your DI setup
  return DirectoryViewModel(usecase);
});
// Broadcast ViewModel Provider
final broadcastViewModelProvider =
StateNotifierProvider<BroadcastViewModel, BroadcastState>((ref) {
  final usecase = ref.watch(BroadcastUsecaseProvider); // replace with your DI setup
  return BroadcastViewModel(usecase);
});

// facilities ViewModel Provider

final facilitiesViewModelProvider =
StateNotifierProvider<FacilitiesViewModel, facilitiesState>((ref) {
  final usecase = ref.watch(FacilitiesUsecaseProvider); // replace with your DI setup
  return FacilitiesViewModel(usecase);
});


final dueHistoryViewModelProvider =
StateNotifierProvider<DueHistoryViewModel, DueHistoryState>((ref) {
  final usecase = ref.watch(DueHistoryUseCaseProvider); // replace with your DI setup
  return DueHistoryViewModel(usecase);
});
final productViewModelProvider  =
StateNotifierProvider<ProductViewModel, ProductState>((ref) {
  final usecase = ref.watch(productUsecaseProvider); // replace with your DI setup
  return ProductViewModel(usecase);
});
// Alert ViewModel Provider
final alertViewModelProvider =  
StateNotifierProvider<AlertViewmodel, AlertState>((ref) {
  final usecase = ref.watch(AlertUsecaseProvider);
     final message=ref.watch(firebaseMessagingProvider); // replace with your DI setup
  return AlertViewmodel(usecase,message);
});
// Maintenance ViewModel Provider
final maintenanceViewModelProvider =
StateNotifierProvider<MaintenanceViewModel, MaintenanceState>((ref) {
  final usecase = ref.watch(maintenanceUseCaseProvider); // replace with your DI setup
  return MaintenanceViewModel(usecase);
});

// Polls ViewModel Provider
final pollsViewModelProvider =
StateNotifierProvider<PollsViewmodel, PollsState>((ref) {
  final usecase = ref.watch(PollsUsecaseProvider); // replace with your DI setup
  return PollsViewmodel(usecase);
});
// Profile Settings ViewModel Provider
final profileSettingsViewModelProvider =
StateNotifierProvider<ProfileSettingsViewModel, ProfileSettingsState>((ref) {
  final usecase = ref.watch(profileSettingsUseCaseProvider); // replace with your DI setup
  return ProfileSettingsViewModel(usecase);
});


// ignore: non_constant_identifier_names
final NocViewModelProvider =
StateNotifierProvider<NocViewModel, NocState>((ref) {
  final useCases = ref.watch(NocUseCaseProvider);
  return NocViewModel(useCases);
});
