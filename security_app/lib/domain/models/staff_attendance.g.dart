// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'staff_attendance.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StaffAttendance _$StaffAttendanceFromJson(Map<String, dynamic> json) =>
    StaffAttendance(
      attendanceId: (json['attendance_id'] as num?)?.toInt(),
      action: json['Action'] as String?,
      staffId: (json['staff_id'] as num).toInt(),
      inDate: json['in_date'] as String?,
      inTime: json['in_time'] as String?,
      outDate: json['out_date'] as String?,
      outTime: json['out_time'] as String?,
      status: (json['status'] as num?)?.toInt(),
      workingHours: (json['working_hours'] as num?)?.toDouble(),
      name: json['name'] as String?,
    );

Map<String, dynamic> _$StaffAttendanceToJson(StaffAttendance instance) =>
    <String, dynamic>{
      'attendance_id': instance.attendanceId,
      'Action': instance.action,
      'staff_id': instance.staffId,
      'in_date': instance.inDate,
      'in_time': instance.inTime,
      'out_date': instance.outDate,
      'name': instance.name,
      'out_time': instance.outTime,
      'status': instance.status,
      'working_hours': instance.workingHours,
    };
