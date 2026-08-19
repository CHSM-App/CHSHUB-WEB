import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:json_annotation/json_annotation.dart';

part 'visitors.g.dart';

@JsonSerializable()
class Visitors {
  @JsonKey(name: 'visitor_id')
  final int? visitorId;

  @JsonKey(name: 'v_name')
  final String? name;

  @JsonKey(name: 'flat_id')
  final int? flatId;

  @JsonKey(name: 'in_date')
  final String? inDate;

  @JsonKey(name: 'out_date')
  final String? outDate;

  @JsonKey(name: 'in_time')
  final String? inTime;

  @JsonKey(name: 'out_time')
  final String? outTime;

  @JsonKey(name: 'society_id')
  final String? societyId;

  @JsonKey(name: 'type')
  final String? type;

  @JsonKey(name: 'vehicle_no')
  final String? vehicleNo;

  @JsonKey(name: 'pre_date')
  final String? preDate;

  @JsonKey(name: 'contact_no')
  final String? contactNo;

  @JsonKey(name: 'image')
  final String? image;

  @JsonKey(name: 'purpose')
  final String? purpose;

  @JsonKey(name: 'unit')
  final String? unit;

  @JsonKey(name: 'UserName')
  final String? userName;

  @JsonKey(name: 'build_name')
  final String? buildName;

  @JsonKey(name: 'build_id')
  final int? buildId;

  @JsonKey(name: 'owner_type')
  final String? ownerType;

  @JsonKey(name: 'status')
  final int? status; // FIX: int, not String

  @JsonKey(name: 'company')
  final String? company;

  @JsonKey(name: 'is_rented')
  final bool? isRented;

    @JsonKey(name: 'in_user_id')
  final int? inUserId;

    @JsonKey(name: 'out_user_id')
  final int? outUserId;

  @JsonKey(name: 'gateOtp')
  final int? gateOtp;

  
  @JsonKey(name: 'w_name')
  final String? wName;

final String? details; 


  @JsonKey(name : 'user_type_id')
  final int? userTypeId;

  @JsonKey(name: 'name')
  final String? nameCommittee;

  Visitors({
    this.nameCommittee,
    this.userTypeId,
    this.inUserId,
    this.wName,
    this.outUserId,
    this.details,
    this.visitorId,
    this.name,
    this.flatId,
    this.inDate,
    this.outDate,
    this.inTime,
    this.outTime,
    this.societyId,
    this.type,
    this.vehicleNo,
    this.preDate,
    this.contactNo,
    this.image,
    this.purpose,
    this.unit,
    this.userName,
    this.buildName,
    this.buildId,
    this.ownerType,
    this.status,
    this.company,
    this.isRented,
    this.gateOtp,
  });

  factory Visitors.fromJson(Map<String, dynamic> json) =>
      _$VisitorsFromJson(json);

  Map<String, dynamic> toJson() => _$VisitorsToJson(this);
}
