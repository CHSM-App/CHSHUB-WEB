import 'dart:io';

import 'package:security_app/domain/models/staff_attendance.dart';
import 'package:security_app/domain/models/staffs.dart';
import 'package:security_app/domain/repository/staff_repo.dart';

class StaffUsercase {
  final StaffRepo repo;
  StaffUsercase(this.repo);
  Future<List<Staffs>> getStaffList(int bId) {
    return repo.getStaffList(bId);
  }
   Future<List<Staffs>> getStaffExit(int bId) {
    return repo.getStaffExit(bId);
  }
  Future<Staffs> updateStaff(int staffid, String action, int bId, int userid) {
    return repo.updateStaff(staffid, action, bId, userid);
  }
 Future<dynamic> staffProfile(File image, int staffId) {
    return repo.staffProfile(image, staffId);
  }
  Future<dynamic> staffEntryExit(int staffId, int statusFlag) {
      return repo.staffEntryExit(staffId, statusFlag);
    }
    Future<List<StaffAttendance>> getStaffAttendance(String society_id) {
      return repo.getStaffAttendance(society_id);
    }
    Future<List<StaffAttendance>> getStaffAttendanceStatus(int staffId) {
      return repo.getStaffAttendanceStatus(staffId);
    }

    Future<Map<String, dynamic>> getCurrentStaffAttendanceStatus(int staffId) {
      return repo.getCurrentStaffAttendanceStatus(staffId);
    }
    Future<dynamic> updateAttendance(StaffAttendance body) {
      return repo.updateAttendance(body);
    }
    Future<List<StaffAttendance>> getMyAttendanceHistory(int staffId) {
      return repo.getMyAttendanceHistory(staffId);
    }
}