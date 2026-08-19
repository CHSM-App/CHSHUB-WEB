import 'package:society_app/core/network/error_message_mapper.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:society_app/SocietyApp/screens/login.dart';
import 'package:society_app/domain/models/vehicle.dart';
import 'package:society_app/main.dart';
import 'package:society_app/presentation/providers/viewmodel_provider.dart';
import '../../../domain/models/basicinfo.dart';
import '../../core/storage/token_storage.dart';
import '../../domain/usecase/basic_info_use_case.dart';

@immutable
class BasicInfoState {
  final AsyncValue<List<BasicInfo>> phoneCheckResult;
  final AsyncValue<List<BasicInfo>> userCheckResult;
  final AsyncValue<List<BasicInfo>> basicInfoResult;
  final AsyncValue<List<BasicInfo>> transactionResult;
   final  AsyncValue<List<BasicInfo>>? ownerDocumentResult;
  final Map<String, dynamic>? data;
  final String? errorMessage;
  final AsyncValue<String?> loginResult;
  final bool isLoading;
  final String? mobile;
  final int? ownerId;
  final int? flatId;
  final String? societyID;
  final String? name;
  final String? loginType;
  final String? email;
  final String? unit;
  final String? societyName;

  // NEW

  const BasicInfoState({
    this.isLoading = false,
    this.data,
    this.errorMessage,
    this.phoneCheckResult = const AsyncValue.data([]),
    this.userCheckResult = const AsyncValue.data([]),
    this.basicInfoResult = const AsyncValue.data([]),
    this.transactionResult = const AsyncValue.data([]),
    this.loginResult = const AsyncValue.data(null),
      this.ownerDocumentResult = const AsyncValue.data([]),
    // this.vehicleResult = const AsyncValue.data([]),
    // this.familyMemberResult = const AsyncValue.data([]),
    // this.data,
    // this.errorMessage,
    // this.isLoading = false,
    this.mobile,
    this.ownerId,
    this.flatId,
    this.societyID,
    this.email,
    this.loginType,
    this.name,
    this.unit,
    this.societyName,
  });

  BasicInfoState copyWith({
    AsyncValue<List<BasicInfo>>? phoneCheckResult,
    AsyncValue<List<BasicInfo>>? basicInfoResult,
    AsyncValue<List<BasicInfo>>? transactionResult,
    AsyncValue<List<BasicInfo>>? userCheckResult,
    AsyncValue<List<Vehicle>>? vehicleResult,
    AsyncValue<List<BasicInfo>>? familyMemberResult,
     AsyncValue<List<BasicInfo>>? ownerDocumentResult,
    AsyncValue<String>? loginResult,
    Map<String, dynamic>? data,
    String? errorMessage,
    bool? isLoading,
    String? mobile,
    int? ownerId,
    int? flatId,
    String? societyID,
    String? name,
    String? email,
    String? loginType,
    String? unit,
    String? societyName,
  }) {
    return BasicInfoState(
      phoneCheckResult: phoneCheckResult ?? this.phoneCheckResult,
      basicInfoResult: basicInfoResult ?? this.basicInfoResult,
      transactionResult: transactionResult ?? this.transactionResult,
      loginResult: loginResult ?? this.loginResult,
      userCheckResult: userCheckResult ?? this.userCheckResult,
      ownerDocumentResult: ownerDocumentResult ?? this.ownerDocumentResult,
      mobile: mobile ?? this.mobile,
      ownerId: ownerId ?? this.ownerId, // ✅ safe fallback
      flatId: flatId ?? this.flatId, // ✅ safe fallback
      societyID: societyID ?? this.societyID,
      loginType: loginType ?? this.loginType,
      email: email ?? this.email,
      name: name ?? this.name,
      unit: unit ?? this.unit,
      societyName: societyName ?? this.societyName,
      data: data ?? this.data,
      errorMessage: errorMessage ?? this.errorMessage,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class BasicInfoViewModel extends StateNotifier<BasicInfoState> {
  final BasicInfoUseCases useCases;

  BasicInfoViewModel(this.useCases) : super(const BasicInfoState()) {
    _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    final mobile = await TokenStorage.getValue('owner_mobile');
    final ownerId = await TokenStorage.getValue('owner_id');
    final flatId = await TokenStorage.getValue('flat_id');
    final societyID = await TokenStorage.getValue('society_id');
    final loginType = await TokenStorage.getValue('login_type');
    final name = await TokenStorage.getValue('owner_name');
    final email = await TokenStorage.getValue('owner_email');
    final societyName = await TokenStorage.getValue('SocietyName');
    final unit = await TokenStorage.getValue('Unit');
    final int? ownerID = int.tryParse(ownerId ?? ''); // Load society ID
    final int? flatID = int.tryParse(flatId ?? ''); // Load society ID
    state = state.copyWith(
      mobile: mobile,
      ownerId: ownerID,
      flatId: flatID,
      societyID: societyID,
      loginType: loginType,
      name: name,
      email: email,
      unit: unit,
    );
  }

  Future<void> clearAll() async {
    await TokenStorage.saveValue('owner_mobile', '');
    await TokenStorage.saveValue('owner_id', '');
    await TokenStorage.saveValue('flat_id', '');
    await TokenStorage.saveValue('society_id', '');
    state = state.copyWith(
      mobile: null,
      ownerId: null,
      flatId: null,
      societyID: null,
      societyName: null,
    );
  }

  // ✅ Check phone number is valid
  Future<void> checkPhoneNumber(String preMob) async {
    state = state.copyWith(phoneCheckResult: const AsyncValue.loading());
    try {
      final result = await useCases.checkPhoneNumber(preMob);
      state = state.copyWith(phoneCheckResult: AsyncValue.data(result));
    } catch (e, st) {
      state = state.copyWith(phoneCheckResult: AsyncValue.error(e, st));
    }
  }

  // ✅ Check user exists
  Future<List<BasicInfo>?> checkUser(String preMob) async {
    state = state.copyWith(userCheckResult: const AsyncValue.loading());
    try {
      final result = await useCases.checkUser(preMob);
            debugPrint("MY list wd");
      // if (result.isEmpty) {
      //   state = state.copyWith(userCheckResult: const AsyncValue.data([]));
      //   return [];
      // }
      
      // state = state.copyWith(flatId: flatId);
      // await useCases.getBasicInfo(preMob, result.first.flatId ?? 0, result.first.ownerId ?? 0);
      state = state.copyWith(userCheckResult: AsyncValue.data(result));
      return result;
    } catch (e, st) {
      state = state.copyWith(userCheckResult: AsyncValue.error(e, st));
      return null;
    }
  }

  Future<void> getBasicInfo() async {
    if (state.mobile == null || state.flatId == null || state.ownerId == null) {
      await _loadFromStorage();
    }

    final mobile = state.mobile;
    final flatId = state.flatId;
    final ownerId = state.ownerId;

    if (mobile == null || mobile.isEmpty || flatId == null || ownerId == null) {
      // Profile identifiers missing from storage — session can't be trusted, force re-login
      // instead of calling the API with placeholder 0 values.
      state = state.copyWith(
        basicInfoResult: AsyncValue.error(
          StateError('Missing profile identifiers, re-login required'),
          StackTrace.current,
        ),
      );
      if (navigatorKey.currentContext != null) {
        Navigator.of(navigatorKey.currentContext!).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => LoginPage()),
          (route) => false,
        );
      }
      return;
    }

    state = state.copyWith(basicInfoResult: const AsyncValue.loading());
    try {
      final result = await useCases.getBasicInfo(mobile, flatId, ownerId);

      state = state.copyWith(basicInfoResult: AsyncValue.data(result));
    } catch (e, st) {
      state = state.copyWith(basicInfoResult: AsyncValue.error(e, st));
    }
  }

  Future<void> selectFlat(
    String mobile,
    int? flat,
    int? OwnerId,
    WidgetRef ref,
    String loc,
  ) async {
    // Ref ref = ProviderScope.containerOf(navigatorKey.currentContext!) as Ref<Object?>;
    await TokenStorage.saveValue('flat_id', flat.toString());
    await TokenStorage.saveValue("OwnerId", OwnerId.toString());
    state = state.copyWith(flatId: flat);
    final result = await useCases.getBasicInfo(
      mobile,
      flat ?? 0,
      OwnerId ?? 0,
    );
    state = state.copyWith(flatId: result.first.flatId);
    state = state.copyWith(mobile: result.first.preMob);
    state = state.copyWith(ownerId: result.first.ownerId);
    _loadFromStorage();
    debugPrint(mobile);
    if (loc == "nav") {
      if ( navigatorKey.currentContext != null) {
      Navigator.of(navigatorKey.currentContext!).pop(); 
      

        await refreshNotifier(ref);
      }
    }
    // ref.notifyListeners();
  }

  Future<void> updateProfile(BasicInfo basicInfo) async {
    state = state.copyWith(isLoading: true);
    try {
      final result = await useCases.updateProfile(basicInfo);
      state = state.copyWith(isLoading: false, data: result);
      state = state.copyWith(mobile: basicInfo.preMob);
      await getBasicInfo();
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<void> addProfileImage(File image, String ownerId) async {
    state = state.copyWith(isLoading: true);
    try {
      final result = await useCases.addProfileImage(
        image,
        ownerId,
        state.loginType ?? "",
      );
      state = state.copyWith(isLoading: false, data: result);
      await getBasicInfo();
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
  Future<void> deleteProfileImage(String ownerId) async {
    state = state.copyWith(isLoading: true);
    try {
      final result = await useCases.deleteProfileImage(
        ownerId,
        state.loginType ?? "",
      );
      state = state.copyWith(isLoading: false, data: result);
      await getBasicInfo();
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
  Future<void> addOwnerDocuments(File documents,int flatId, String documentName) async {
    state = state.copyWith(isLoading: true);
    try {
      final result = await useCases.addOwnerDocuments(
        documents,
        flatId,
        documentName,
      );
      state = state.copyWith(isLoading: false, data: result);
      await getBasicInfo();
    } catch (e) {
      throw Exception('Error: $e');
    }
  }


   Future<void> ownerDocumentsList( int fId) async {
    state = state.copyWith(ownerDocumentResult: const AsyncValue.loading());
    try {
      final result = await useCases.ownerDocumentsList(fId);
      state = state.copyWith(ownerDocumentResult: AsyncValue.data(result));
    } catch (e, st) {
      state = state.copyWith(ownerDocumentResult: AsyncValue.error(e, st));
    }
  }
 Future<void> deleteDocuments(int documentId)async {
    state = state.copyWith(isLoading: true);
    try {
      final result = await useCases.deleteDocuments(documentId);
      state = state.copyWith(isLoading: false, data: result);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: ErrorMessageMapper.map(e));
    }
  }
  Future<void> refreshNotifier(WidgetRef ref) async {
    // await ref.refresh(basicInfoViewModelProvider.notifier);
      getBasicInfo();

    ref.refresh(authViewModelProvider);
    ref.refresh(HelperViewModelProvider);
    await ref.refresh(TransactionViewModelProvider.notifier).getTransactionDue(state.flatId ?? 0);
    await ref.refresh(dueHistoryViewModelProvider.notifier).loadDueHistory(state.ownerId ?? 0);
    await ref.refresh(facilitiesViewModelProvider.notifier).loadFacilities(state.societyID ?? "");
    await ref.refresh(productViewModelProvider.notifier).fetchOwnerProductList(state.societyID ?? "", state.ownerId ?? 0);
    await ref.refresh(alertViewModelProvider.notifier).loadData();
    await ref.refresh(pollsViewModelProvider.notifier).getSocietyPolls(state.ownerId ?? 0, state.societyID ?? "",1);
    await ref.refresh(profileSettingsViewModelProvider.notifier).getFamilyMembers(state.flatId ?? 0, state.ownerId ?? 0, state.loginType ?? "");
    await ref.refresh(profileSettingsViewModelProvider.notifier).getVehicleList(state.flatId ?? 0, state.societyID ?? "");
    await ref.refresh(broadcastViewModelProvider.notifier).getBroadcast(state.societyID ?? "", state.ownerId ?? 0);
  }
}
