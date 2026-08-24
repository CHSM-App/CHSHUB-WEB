import 'package:json_annotation/json_annotation.dart';

part 'visitor_request.g.dart';

/// Body of POST/PUT /api/web/community/visitors.
///
/// One canonical shape for every visitor type. The legacy page showed a
/// different panel per type — guest, cab, delivery, service — but all four
/// wrote the same columns, so `type` drives which labels the UI shows rather
/// than which fields exist.
@JsonSerializable(includeIfNull: false)
class VisitorRequest {
  @JsonKey(name: 'name')
  final String name;

  /// 'Guest' | 'Cab' | 'Delivery' | 'Service'.
  @JsonKey(name: 'type')
  final String type;

  @JsonKey(name: 'contactNo')
  final String? contactNo;

  @JsonKey(name: 'flatId')
  final int? flatId;

  @JsonKey(name: 'buildId')
  final int? buildId;

  @JsonKey(name: 'vehicleNo')
  final String? vehicleNo;

  @JsonKey(name: 'company')
  final String? company;

  @JsonKey(name: 'location')
  final String? location;

  @JsonKey(name: 'purpose')
  final String? purpose;

  @JsonKey(name: 'preference')
  final String? preference;

  @JsonKey(name: 'image')
  final String? image;

  // ===== ISO yyyy-MM-dd =====
  @JsonKey(name: 'inDate')
  final String? inDate;

  @JsonKey(name: 'outDate')
  final String? outDate;

  @JsonKey(name: 'expectedDate')
  final String? expectedDate;

  // ===== HH:mm =====
  @JsonKey(name: 'inTime')
  final String? inTime;

  @JsonKey(name: 'outTime')
  final String? outTime;

  @JsonKey(name: 'status')
  final int? status;

  @JsonKey(name: 'ownerId')
  final int? ownerId;

  const VisitorRequest({
    required this.name,
    required this.type,
    this.contactNo,
    this.flatId,
    this.buildId,
    this.vehicleNo,
    this.company,
    this.location,
    this.purpose,
    this.preference,
    this.image,
    this.inDate,
    this.outDate,
    this.expectedDate,
    this.inTime,
    this.outTime,
    this.status,
    this.ownerId,
  });

  factory VisitorRequest.fromJson(Map<String, dynamic> json) =>
      _$VisitorRequestFromJson(json);

  Map<String, dynamic> toJson() => _$VisitorRequestToJson(this);
}
