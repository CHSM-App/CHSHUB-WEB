import 'package:json_annotation/json_annotation.dart';

part 'staffs.g.dart';

@JsonSerializable()
class Staffs {
  @JsonKey(name: 'staff_id')
  final int staffId;

  final String name;
  final String address;

  @JsonKey(name: 'contact_no')
  final String contactNo;

  final String email;

  @JsonKey(name: 'date_of_join')
  final String dateOfJoin;

  @JsonKey(name: 'b_id')
  final int bId;

  @JsonKey(name: 'build_name')
  final String buildName;

  @JsonKey(name: 'Role')
  final String role;

  @JsonKey(name: 'society_id')
  final String societyId;

  @JsonKey(name: 'in_date')
  final String inDate;

  @JsonKey(name: 'in_time')
  final String inTime;

  @JsonKey(name: 'out_date')
  final String outDate;

  @JsonKey(name: 'out_time')
  final String outTime;

  final String image;
  final int id;



  Staffs({
    required this.staffId,
    required this.name,
    required this.address,
    required this.contactNo,
    required this.email,
    required this.dateOfJoin,
    required this.bId,
    required this.buildName,
    required this.role,
    required this.societyId,
    required this.inDate,
    required this.inTime,
    required this.outDate,
    required this.outTime,
    required this.image,
    required this.id,
  });

  factory Staffs.fromJson(Map<String, dynamic> json) => _$StaffsFromJson(json);
  Map<String, dynamic> toJson() => _$StaffsToJson(this);
}
