import 'package:json_annotation/json_annotation.dart';

part 'visitor.g.dart';

@JsonSerializable()
class Visitor {
  @JsonKey(name: 'build_id')
  final int? buildId;

  @JsonKey(name: 'flat_id')
  final int? flatId;

  @JsonKey(name: 'in_date')
  final String? inDate;

  @JsonKey(name: 'in_time')
  final String? inTime;

  @JsonKey(name: 'out_date')
  final String? outDate;

  @JsonKey(name: 'out_time')
  final String? outTime;

  @JsonKey(name: 'society_id')
  final String? societyId;

  @JsonKey(name: 'visitor_id')
  final int? visitorId;

  @JsonKey(name: 'v_name')
  final String? vName;

  @JsonKey(name: 'pre_date')
  final String? preDate;

  @JsonKey(name: 'vehicle_no')
  final String? vehicleNo;

  @JsonKey(name: 'contact_no')
  final String? contactNo;

  final String? type;
  @JsonKey(name: 'preference')
  final String? preference;

  @JsonKey(name: 'UserName')
  final String? userName;

  final String? image;

  final int? status;

  @JsonKey(name: 'Approver_Name')
  final String? approverName;

  @JsonKey(name: 'gateOtp')
  final int? gateOtp;

  @JsonKey(name: 'company')
  final String? company;

  @JsonKey(name: 'purpose')
  final String? purpose;

  @JsonKey(name: 'owner_id')
  final int? ownerId;

  Visitor({

    this.buildId,
    this.flatId,
    this.inDate,
    this.inTime,
    this.outDate,
    this.outTime,
    this.societyId,
    this.visitorId,
    this.vName,
    this.preDate,
    this.vehicleNo,
    this.contactNo,
    this.type,
    this.preference,
    this.userName,
    this.image,
    this.status,
    this.approverName,
    this.gateOtp,
    this.company,
    this.purpose,
    this.ownerId,
  });

  factory Visitor.fromJson(Map<String, dynamic> json) =>
      _$VisitorFromJson(json);

  Map<String, dynamic> toJson() => _$VisitorToJson(this);
}
