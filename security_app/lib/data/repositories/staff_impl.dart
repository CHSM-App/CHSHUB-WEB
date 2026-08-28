import 'dart:io';

import 'package:security_app/data/api/api_service.dart';
import 'package:security_app/domain/models/staff_attendance.dart';
import 'package:security_app/domain/models/staffs.dart';
import 'package:security_app/domain/repository/staff_repo.dart';

class StaffRepositoryImpl implements StaffRepo {
  final ApiService apiService;

  StaffRepositoryImpl(this.apiService);
  
  @override
   Future<List<Staffs>> getStaffExit(int bId) {
  return apiService.getStaffExit(bId);
  }
  
  @override
  Future<List<Staffs>> getStaffList(int bId) {
    return apiService.getStaffList(bId);
  }
  
  @override
  Future<Staffs> updateStaff(staffid, String action, int bId, int userid) {
    return apiService.updateStaff(staffid, action, bId, userid);
  }

    @override
  Future<dynamic> staffProfile(File image, int staffId) {
    return apiService.staffProfile(image, staffId);
  }
 
 @override
Future<dynamic> staffEntryExit(int staffId, int statusFlag) {
  return apiService.staffEntryExit(staffId, statusFlag);
}
@override
Future<List<StaffAttendance>> getStaffAttendance(String society_id) {
  return  apiService.getStaffAttendance(society_id);
 
}
@override
Future<List<StaffAttendance>> getStaffAttendanceStatus(int staffId) {
  return  apiService.getStaffAttendanceStatus(staffId);
 
}

// getCurrentStaffAttendanceStatus
@override
Future<Map<String, dynamic>> getCurrentStaffAttendanceStatus(int staffId) {
  return apiService.getCurrentStaffAttendanceStatus(staffId)
      .then((v) => (v as Map).cast<String, dynamic>());
}

@override
Future<dynamic> updateAttendance(StaffAttendance body) {
  return apiService.updateAttendance(body);
}

@override
Future<List<StaffAttendance>> getMyAttendanceHistory(int staffId) async {
  final result = (await apiService.getMyAttendanceHistory(staffId)) as Map;
  final records = result['records'] as List<dynamic>? ?? [];
  return records
      .map((i) => StaffAttendance.fromJson(i as Map<String, dynamic>))
      .toList();
}

}