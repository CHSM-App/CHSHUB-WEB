import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:security_app/domain/models/staff_attendance.dart';
import 'package:security_app/domain/models/staffs.dart';
import 'package:security_app/domain/usecase/staff_usercase.dart';
import 'package:security_app/core/utils/error_formatter.dart';

class StaffState {
  final AsyncValue<List<Staffs>> staffList;
  final AsyncValue<List<StaffAttendance>> staffAttendanceList;
  final AsyncValue<List<StaffAttendance>> myAttendanceHistory;
  final Map<String, dynamic> data;
  final bool isLoading;
  final String? error;
  final bool isCheckedIn;

  const StaffState({
    this.staffList = const AsyncValue.loading(),
    this.staffAttendanceList = const AsyncValue.loading(),
    this.myAttendanceHistory = const AsyncValue.loading(),
    this.data = const {},
    this.isLoading = false,
    this.error,
    this.isCheckedIn = false,
  });

  StaffState copyWith({
    AsyncValue<List<Staffs>>? staffList,
    AsyncValue<List<StaffAttendance>>? staffAttendanceList,
    AsyncValue<List<StaffAttendance>>? myAttendanceHistory,
    Map<String, dynamic>? data,
    bool? isLoading,
    String? error,
    bool? isCheckedIn,
  }) {
    return StaffState(
      staffList: staffList ?? this.staffList,
      staffAttendanceList: staffAttendanceList ?? this.staffAttendanceList,
      myAttendanceHistory: myAttendanceHistory ?? this.myAttendanceHistory,
        data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isCheckedIn: isCheckedIn ?? this.isCheckedIn,
    );
  }
}

class StaffViewModel extends StateNotifier<StaffState> {
  final StaffUsercase usercase;
  StaffViewModel(this.usercase) : super(const StaffState());

  Future<void> fetchStaffs(int bId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final staffs = await usercase.getStaffList(bId);
      state = state.copyWith(
        staffList: AsyncValue.data(staffs),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: getErrorMessage(e));
    }
  }

  Future<void> addStaff(int staffid, String action, int bId, int userid) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final newStaff = await usercase.updateStaff(staffid, action, bId, userid);
      final currentStaffs = state.staffList.value ?? [];
      final updatedStaffs = List<Staffs>.from(currentStaffs)..add(newStaff);
      state = state.copyWith(
        staffList: AsyncValue.data(updatedStaffs),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: getErrorMessage(e));
    }
  }

  Future<dynamic> addProfileImage(File image, int staffId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await usercase.staffProfile(image, staffId);

      // Don't update state with data here, just return the result
      // This prevents premature state updates
      state = state.copyWith(isLoading: false);

      return result; // Return result so it can be used in UI
    } catch (e) {
      state = state.copyWith(isLoading: false, error: getErrorMessage(e));
      throw Exception('Error uploading profile image: $e');
    }
  }

  Future<void> staffEntryExit(int staffId, int statusFlag) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
       await usercase.staffEntryExit(staffId, statusFlag);

      state = state.copyWith(isLoading: false,);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: getErrorMessage(e));
      debugPrint("Error in staffEntryExit: $e");
    }
  }


Future<bool> updateAttendance(StaffAttendance body) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await usercase.updateAttendance(body);
      bool success = result['message'] == "Successfully";
      state = state.copyWith(isLoading: false);
      return success;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: getErrorMessage(e));
      return false;
    }
  }

  Future<void> fetchStaffAttendanceStatus(int staffId) async {
    state = state.copyWith(isLoading: true, error: null, isCheckedIn: !state.isCheckedIn);
    debugPrint("Fetching attendance status for staffId: $staffId");
    try {
      final statusData = await usercase.getCurrentStaffAttendanceStatus(staffId, );
      final isCheckedIn = statusData['isCheckedIn'] == true;
      state = state.copyWith(isLoading: false, isCheckedIn: isCheckedIn);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: getErrorMessage(e));
    }
  }

// getStaffAttendance
  Future<void> fetchStaffAttendance(String society_id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final attendanceList = await usercase.getStaffAttendance(society_id);
      state = state.copyWith(staffAttendanceList: AsyncValue.data(attendanceList), isLoading: false,);  
    } catch (e) {
      state = state.copyWith(isLoading: false, error: getErrorMessage(e));
    }
}

  Future<void> fetchMyAttendanceHistory(int staffId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final history = await usercase.getMyAttendanceHistory(staffId);
      state = state.copyWith(
        myAttendanceHistory: AsyncValue.data(history),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: getErrorMessage(e));
    }
  }

  void updateLocalStatus(int staffId, int statusCode) {
  state = state.copyWith(
    staffAttendanceList: AsyncData([
        for (final s in state.staffAttendanceList.value!)
        s.staffId == staffId? s.copyWith(status: statusCode) : s
    ]),
  );
}


}
