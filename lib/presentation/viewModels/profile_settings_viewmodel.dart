import 'package:society_app/core/network/error_message_mapper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:society_app/domain/models/basicinfo.dart';
import 'package:society_app/domain/models/helper.dart';
import 'package:society_app/domain/models/vehicle.dart';
import 'package:society_app/domain/models/visitor.dart';
import 'package:society_app/domain/usecase/profile_settings_usecase.dart';

class ProfileSettingsState {
  // Add properties and methods relevant to profile settings here
  final AsyncValue<List<Vehicle>> vehicleResult;
  final AsyncValue<List<BasicInfo>> familyMemberResult;
  final AsyncValue<List<Helper>> familyMemberHelper;
  final AsyncValue<List<Visitor>> frequentEntriesResult;
  final AsyncValue<List<Helper>> personListResult;
  final AsyncValue<Helper>? addHelperResult;
  final Map<String, dynamic>? data;
  final String? errorMessage;
  final bool isLoading;

  const ProfileSettingsState({
    this.personListResult = const AsyncValue.data([]),
    this.addHelperResult,
    this.frequentEntriesResult = const AsyncValue.data([]),
    this.vehicleResult = const AsyncValue.data([]),
    this.familyMemberResult = const AsyncValue.data([]),
    this.familyMemberHelper = const AsyncValue.data([]),
    this.data,
    this.errorMessage,
    this.isLoading = false,
  });

  ProfileSettingsState copyWith({
    AsyncValue<List<Helper>>? personListResult,
    AsyncValue<List<Visitor>>? frequentEntriesResult,
    AsyncValue<List<Vehicle>>? vehicleResult,
    AsyncValue<List<Helper>>? familyMemberHelper,
    AsyncValue<Helper>? addHelperResult,
    AsyncValue<List<BasicInfo>>? familyMemberResult,
    Map<String, dynamic>? data,
    String? errorMessage,
    bool? isLoading,
  }) {
    return ProfileSettingsState(
      frequentEntriesResult:
          frequentEntriesResult ?? this.frequentEntriesResult,
      vehicleResult: vehicleResult ?? this.vehicleResult,
      familyMemberResult: familyMemberResult ?? this.familyMemberResult,
      personListResult: personListResult ?? this.personListResult,
      familyMemberHelper: familyMemberHelper ?? this.familyMemberHelper,
      data: data ?? this.data,
      errorMessage: errorMessage ?? this.errorMessage,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class ProfileSettingsViewModel extends StateNotifier<ProfileSettingsState> {
  final ProfileSettingsUseCase useCase;

  ProfileSettingsViewModel(this.useCase) : super(const ProfileSettingsState());

  Future<void> getFamilyMembers(
    int flatID,
    int ownerID,
    String loginType,
  ) async {
    state = state.copyWith(familyMemberResult: AsyncValue.loading());
    try {
      final result = await useCase.getFamilyMembers(flatID);
      result.removeWhere(
        (member) => member.ownerId == ownerID && member.login == loginType,
      );
      state = state.copyWith(familyMemberResult: AsyncValue.data(result));
    } catch (e, st) {
      state = state.copyWith(familyMemberResult: AsyncValue.error(e, st));
    }
  }

  Future<void> getVehicleList(int flatID, String societyID) async {
    state = state.copyWith(vehicleResult: const AsyncValue.loading());
    try {
      final result = await useCase.getVehicleList(flatID, societyID);
      state = state.copyWith(vehicleResult: AsyncValue.data(result));
    } catch (e, st) {
      state = state.copyWith(vehicleResult: AsyncValue.error(e, st));
    }
  }

  Future<void> addFamilyMember(
    int oId,
    String fName,
    String contact,
    String relation,
    String societyID,
  ) async {
    state = state.copyWith(isLoading: true);
    try {
      final result = await useCase.addFamilyMember(
        oId,
        fName,
        contact,
        relation,
        societyID,
      );
      state = state.copyWith(isLoading: false, data: result);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: ErrorMessageMapper.map(e));
    }
  }

  Future<void> deleteFamilyMember(int oExId) async {
    state = state.copyWith(isLoading: true);
    try {
      final result = await useCase.deleteFamilyMember(oExId);
      state = state.copyWith(isLoading: false, data: result);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: ErrorMessageMapper.map(e));
    }
  }

  Future<void> deleteFamilyVehicle(int vehicleId) async {
    state = state.copyWith(isLoading: true);
    try {
      final result = await useCase.deleteFamilyVehicle(vehicleId);
      state = state.copyWith(isLoading: false, data: result);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: ErrorMessageMapper.map(e));
    }
  }

  Future<void> addFamilyVehicle(Vehicle vehicle) async {
    state = state.copyWith(isLoading: true);
    try {
      final result = await useCase.addFamilyVehicle(vehicle);
      state = state.copyWith(isLoading: false, data: result);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: ErrorMessageMapper.map(e));
    }
  }

  Future<void> getFamilyMemberHelper(int flatID) async {
    state = state.copyWith(familyMemberHelper: AsyncValue.loading());
    try {
      final result = await useCase.getFamilyMemberHelper(flatID);
      state = state.copyWith(familyMemberHelper: AsyncValue.data(result));
    } catch (e, st) {
      state = state.copyWith(familyMemberHelper: AsyncValue.error(e, st));
    }
  }

  Future<void> getFrequentEntries(int flatID) async {
    state = state.copyWith(frequentEntriesResult: AsyncValue.loading());
    try {
      final result = await useCase.getFrequentEntries(flatID);
      state = state.copyWith(frequentEntriesResult: AsyncValue.data(result));
    } catch (e, st) {
      state = state.copyWith(frequentEntriesResult: AsyncValue.error(e, st));
    }
  }

  Future<void> getPersonList() async {
    state = state.copyWith(personListResult: AsyncValue.loading());
    try {
      final result = await useCase.getPersonList();
      state = state.copyWith(personListResult: AsyncValue.data(result));
    } catch (e, st) {
      state = state.copyWith(personListResult: AsyncValue.error(e, st));
    }
  }

  Future<void> addFamilyHelper(Helper helper) async {
    state = state.copyWith(addHelperResult: AsyncValue.loading());
    try {
      final result = await useCase.addFamilyHelper(helper);
      state = state.copyWith(addHelperResult: AsyncValue.data(result));
    } catch (e, st) {
      state = state.copyWith(addHelperResult: AsyncValue.error(e, st));
    }
  }

  Future<void> deleteFamilyHelper(int helperId) async {
    state = state.copyWith(isLoading: true);
    try {
      final result = await useCase.deleteFamilyHelper(helperId);
      state = state.copyWith(isLoading: false, data: result);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: ErrorMessageMapper.map(e));
    }
  }
}
