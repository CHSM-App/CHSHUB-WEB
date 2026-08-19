import 'package:json_annotation/json_annotation.dart';

part 'facilities.g.dart';

@JsonSerializable()
class Facilities {
  @JsonKey(name: 'flat_no')
  final int? flatNo;

  @JsonKey(name: 'from_date')
  final String? fromDate;

  @JsonKey(name: 'Token')
  final String? token;

  @JsonKey(name: 'u_name')
  final String? userName;

  @JsonKey(name: 'from_time')
  final String? fromTime;

  final String? name;

  @JsonKey(name: 'to_date')
  final String? toDate;

  @JsonKey(name: 'to_time')
  final String? toTime;

  @JsonKey(name: 'facility_id')
  final int? facilityId;

  @JsonKey(name: 'slot_id')
  final int? slotId;

  @JsonKey(name: 'start_time')
  final String? startTime;

  @JsonKey(name: 'end_time')
  final String? endTime;

  @JsonKey(name: 'society_id')
  final String? societyId;

  final int? status;
  final int? cost;
  final String? description;
  final int? slot;
  final String? contact;
  final double? amount;

  @JsonKey(name: 'active_status')
  final int? activeStatus;
  @JsonKey(name: 'flat_id')
  final int? flatId;
  @JsonKey(name: 'book_date')
  final String? bookDate;
  @JsonKey(name: 'transaction_ref')
  final String? transactionRef;
  final String? note;

  Facilities({
    this.userName,
    this.token,
    this.amount,
    this.contact,
    this.flatNo,
    this.fromDate,
    this.fromTime,
    this.name,
    this.toDate,
    this.toTime,
    this.facilityId,
    this.slotId,
    this.endTime,
    this.startTime,
    this.societyId,
    this.status,
    this.cost,
    this.description,
    this.slot,
    this.activeStatus,
    this.bookDate,
    this.flatId,
    this.transactionRef,
    this.note,
  });

  factory Facilities.fromJson(Map<String, dynamic> json) =>
      _$FacilitiesFromJson(json);

  Map<String, dynamic> toJson() => _$FacilitiesToJson(this);
}
