import 'dart:io';

import 'package:security_app/domain/models/staff_attendance.dart';
import 'package:security_app/domain/models/staffs.dart';

abstract class StaffRepo {
  Future<List<Staffs>> getStaffList(int bId);
  Future<List<Staffs>>getStaffExit( int bId);
  Future<Staffs> updateStaff(staffid, String action, int bId, int userid);
      Future<dynamic> staffProfile(File image, int ownerId);
      Future<dynamic> updateAttendance(StaffAttendance body);
      Future<dynamic>staffEntryExit(int staffId, int statusFlag);
      Future<List<StaffAttendance>> getStaffAttendance(String society_id);
      Future<List<StaffAttendance>> getStaffAttendanceStatus(int staffId);
      Future<Map<String, dynamic>> getCurrentStaffAttendanceStatus(int staffId);
      Future<List<StaffAttendance>> getMyAttendanceHistory(int staffId);
}