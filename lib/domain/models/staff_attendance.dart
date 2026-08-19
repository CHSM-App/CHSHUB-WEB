import 'package:json_annotation/json_annotation.dart';

part 'staff_attendance.g.dart';

@JsonSerializable()
class StaffAttendance {
  @JsonKey(name: 'attendance_id')
  final int? attendanceId;

  @JsonKey(name: 'Action')
  final String? action;

  @JsonKey(name: 'staff_id')
  final int staffId;

  @JsonKey(name: 'in_date')
  final String? inDate;

  @JsonKey(name: 'in_time')
  final String? inTime;

  @JsonKey(name: 'out_date')
  final String? outDate;

  @JsonKey(name: 'name')
  final String? name;

  @JsonKey(name: 'out_time')
  final String? outTime;

  final int? status;

  @JsonKey(name: 'working_hours')
  final double? workingHours;

  StaffAttendance({
    this.attendanceId,
    this.action,
    required this.staffId,
    this.inDate,
    this.inTime,
    this.outDate,
    this.outTime,
    this.status,
    this.workingHours,
    this.name,
  });

  StaffAttendance copyWith({
    int? staffId,
    String? name,
    String? inDate,
    int? status,
    String? inTime,
  }) {
    return StaffAttendance(
      staffId: staffId ?? this.staffId,
      name: name ?? this.name,
      inDate: inDate ?? this.inDate,
      status: status ?? this.status,
      inTime: inTime ?? this.inTime,
    );
  }

  factory StaffAttendance.fromJson(Map<String, dynamic> json) =>
      _$StaffAttendanceFromJson(json);

  Map<String, dynamic> toJson() => _$StaffAttendanceToJson(this);
}
