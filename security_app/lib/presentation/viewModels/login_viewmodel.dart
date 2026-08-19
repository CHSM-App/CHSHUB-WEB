import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:security_app/core/storage/token_storage.dart';
import 'package:security_app/core/utils/error_formatter.dart';
import 'package:security_app/domain/models/alert_notification.dart';
import 'package:security_app/domain/models/login_data.dart';
import 'package:security_app/domain/models/notification.dart';
import 'package:security_app/domain/models/visitors.dart';
import 'package:security_app/domain/usecase/login_usercase.dart';

class SecurityState {
  final AsyncValue<List<LoginData>> loginDetails;
  final AsyncValue<List<LoginData>> checkUserdata;
  final AsyncValue<List<LoginData>> getAllTokensdata;
  final Map<String, dynamic> data;
  final String? mobileNumber;
  final String? name;
  final String? email;
  final String? address;
  final String? societyName;
  final bool isLoading;
  final String? error;
  final String? SocietyId;
  final String? userId;
  final String? token;
  // final bool isCheckedIn;

  const SecurityState({
    this.loginDetails = const AsyncValue.data([]),
    this.checkUserdata = const AsyncValue.data([]),
    this.getAllTokensdata = const AsyncValue.data([]),
    this.data = const {},
    this.isLoading = false,
    this.error,
    this.mobileNumber,
    this.name,
    this.email,
    this.address,
    this.SocietyId,
    this.societyName,
    this.userId,
    this.token,
    // this.isCheckedIn = false,
  });
  SecurityState copyWith({
    AsyncValue<List<LoginData>>? loginDetails,
    AsyncValue<List<LoginData>>? checkUserdata,
    AsyncValue<List<LoginData>>? getAllTokensdata,
    Map<String, dynamic>? data,
    bool? isLoading,
    String? error,
    String? mobileNumber,
    String? name,
    String? email,
    String? address,
    String? SocietyId,
    String? societyName,
    String? userId,
    String? token,
    // bool? isCheckedIn,
  }) {
    return SecurityState(
      loginDetails: loginDetails ?? this.loginDetails,
      checkUserdata: checkUserdata ?? this.checkUserdata,
      getAllTokensdata: getAllTokensdata ?? this.getAllTokensdata,
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      SocietyId: SocietyId ?? this.SocietyId,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      name: name ?? this.name,
      societyName: societyName ?? this.societyName,
      email: email ?? this.email,
      userId: userId ?? this.userId,
      token: token ?? this.token,
      // isCheckedIn: isCheckedIn ?? this.isCheckedIn,
    );
  }
}

class SecurityModelViewModel extends StateNotifier<SecurityState> {
  final LoginUsercase usercase;
  SecurityModelViewModel(this.usercase) : super(const SecurityState()) {
    // Initial fetch or setup can be done here if needed
    _loadStorage();
  }

  Future<void> loadDataFromStorage() async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      loginDetails: const AsyncValue.loading(),
    );
    if (state.mobileNumber == null) {
      await _loadStorage();
    }
    try {
      final login = await usercase.getLoginDetails(state.mobileNumber ?? "");
      state = state.copyWith(
        loginDetails: AsyncValue.data(login),
        isLoading: false,
      );
      _loadStorage();
    } catch (e, st) {
      state = state.copyWith(
        isLoading: false,
        error: getErrorMessage(e),
        loginDetails: AsyncError(e, st),
      );
    }
  }

  // Future<void> fetchLogin(String contact) async {
  //   state = state.copyWith(isLoading: true, error: null);
  //   try {
  //     final login = await usercase.getLoginDetails(contact);
  //     state = state.copyWith(
  //       loginDetails: AsyncValue.data(login),
  //       isLoading: false,
  //     );
  //     debugPrint("Login fetched: ${login[0].contactNo}");
  //     _loadStorage();
  //   } catch (e, st) {
  //     state = state.copyWith(
  //       isLoading: false,
  //       error: getErrorMessage(e),
  //       checkUserdata: AsyncError(e, st),
  //     );
  //   }
  // }
  Future<void> fetchLogin(String contact) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final login = await usercase.getLoginDetails(contact);
      final user = login.first;

      // ✅ ONLY PLACE where storage is written
      await TokenStorage.saveValue("mobile", user.contactNo ?? "");
      await TokenStorage.saveValue("name", user.name ?? "");
      await TokenStorage.saveValue("email", user.email ?? "");
      await TokenStorage.saveValue("address", user.address ?? "");
      await TokenStorage.saveValue(
        "societyId",
        user.societyId?.toString() ?? "",
      );
      await TokenStorage.saveValue("societyName", user.societyName ?? "");
      await TokenStorage.saveValue("userId", user.staffId?.toString() ?? "");
      await TokenStorage.saveValue("token", user.token ?? "");

      state = state.copyWith(
        loginDetails: AsyncValue.data(login),
        mobileNumber: user.contactNo,
        name: user.name,
        email: user.email,
        address: user.address,
        SocietyId: user.societyId?.toString(),
        societyName: user.societyName,
        userId: user.staffId?.toString(),
        token: user.token,
        isLoading: false,
      );
    } catch (e, st) {
      state = state.copyWith(
        isLoading: false,
        error: getErrorMessage(e),
        loginDetails: AsyncError(e, st),
      );
    }
  }

  Future<void> clearLogin() async {
    state = state.copyWith(
      loginDetails: AsyncValue.data([]),
      mobileNumber: null,
      name: null,
      email: null,
      address: null,
      SocietyId: null,
      societyName: null,
      userId: null,
      token: null,
    );
    debugPrint("Cleared login state ${state.loginDetails.value}");
    await TokenStorage.clear();
  }

  Future<void> checkUser(String contact) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final login = await usercase.checkUser(contact);
      state = state.copyWith(
        checkUserdata: AsyncValue.data(login),
        isLoading: false,
      );
    } catch (e, st) {
      state = state.copyWith(
        isLoading: false,
        error: getErrorMessage(e),
        checkUserdata: AsyncError(e, st),
      );
    }
  }

  Future<void> updateGateKeeper1(
    int id,
    String contactNo,
    String name,
    String email,
    String address,
    String image,
  ) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await usercase.updateGateKeeper1(
        id,
        contactNo,
        name,
        email,
        address,
        image,
      );
      state = state.copyWith(isLoading: false, data: {"update": result});
    } catch (e) {
      state = state.copyWith(isLoading: false, error: getErrorMessage(e));
    }
  }

  Future<void> _loadStorage() async {
    state = state.copyWith(
      mobileNumber: await TokenStorage.getValue("mobile"),
      name: await TokenStorage.getValue("name"),
      email: await TokenStorage.getValue("email"),
      address: await TokenStorage.getValue("address"),
      SocietyId: await TokenStorage.getValue("societyId"),
      societyName: await TokenStorage.getValue("societyName"),
      userId: await TokenStorage.getValue("userId"),
      token: await TokenStorage.getValue("token"),
    );
    debugPrint("Loaded mobile number: ${state.mobileNumber}");
  }

  Future<void> updateGateKeeper(LoginData loginData) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await usercase.updateGateKeeper(loginData);

      // Update state with success data
      state = state.copyWith(isLoading: false, data: {"update": result});

      // Optionally refresh the login details after update
      await fetchLogin(loginData.contactNo ?? "");
    } catch (e) {
      state = state.copyWith(isLoading: false, error: getErrorMessage(e));
    }
  }

  Future<void> updateToken(int staffId, String token) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await usercase.updateToken(staffId, token);
      state = state.copyWith(isLoading: false, data: {"updateToken": result});
    } catch (e) {
      state = state.copyWith(isLoading: false, error: getErrorMessage(e));
    }
  }

  Future<void> sendMessage(SendNotification body) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await usercase.sendMessage(body);
      state = state.copyWith(isLoading: false, data: {"sendMessage": result});
    } catch (e) {
      state = state.copyWith(isLoading: false, error: getErrorMessage(e));
    }
  }

  Future<void> getAllTokens(String society, String type) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await usercase.getAllTokens(society, type);
      state = state.copyWith(
        isLoading: false,
        getAllTokensdata: AsyncValue.data(result),
      );
    } catch (e, st) {
      state = state.copyWith(
        isLoading: false,
        error: getErrorMessage(e),
        getAllTokensdata: AsyncError(e, st),
      );
    }
  }

  Future<void> sendDataMessage(SendNotification body) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await usercase.sendDataMessage(body);
      state = state.copyWith(
        isLoading: false,
        data: {"sendDataMessage": result},
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: getErrorMessage(e));
    }
  }

  Future<void> deleteStaffImage(String staffId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await usercase.deleteStaffImage(staffId);
      state = state.copyWith(
        isLoading: false,
        data: {"deleteStaffImage": result},
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: getErrorMessage(e));
    }
  }

  Future<void> sendAlertNotifications(AlertNotification body) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await usercase.sendAlertNotifications(body);
      state = state.copyWith(
        isLoading: false,
        data: {"sendAlertNotifications": result},
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: getErrorMessage(e));
    }
  }

  Future<List<Visitors>> getCommitteeContacts(String society_id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await usercase.getCommitteeContacts(society_id);
      state = state.copyWith(isLoading: false);

      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: getErrorMessage(e));
      return [];
    }
  }
}
