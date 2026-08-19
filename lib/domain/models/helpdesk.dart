import 'package:json_annotation/json_annotation.dart';

part 'helpdesk.g.dart';

@JsonSerializable()
class HelpdeskRequest {
  final int? category;

  final String? documents;

  @JsonKey(name: 'flat_id')
  final int? flatId;

  @JsonKey(name: 'helpdesk_id')
  final int? helpdeskId;

  final String? query;

  @JsonKey(name: 'req_service_date')
  final String? reqServiceDate;

  final int? urgency;

  final int? status;

  @JsonKey(name: 'category_type')
  final String? categoryType;

  @JsonKey(name: 'flat_no')
  final String? flatNo;

  @JsonKey(name: 'Unit')
  final String? unit;

  final String? name;

  final String? date;

  final String? image;

  final String? categoryName;

  @JsonKey(name: 'p_type_name')
  final String? pTypeName;
  
  @JsonKey(name: 'owner_id')
  final int? ownerId;

  
  @JsonKey(name: 'seen_status')
  final int? seenStatus;
  
  @JsonKey(name: 'notification_id')
  final int? notificationId;
    @JsonKey(name: 'notify_status_id')
  final int? notifyStatusId;

  @JsonKey(name: 'logintype')
  final String? loginType;
  HelpdeskRequest({
    this.category,
    this.documents,
    this.flatId,
    required this.helpdeskId,
    this.query,
    this.reqServiceDate,
    required this.urgency,
    this.status,
    this.categoryType,
    this.flatNo,
    this.unit,
    this.name,
    required this.date,
    this.image,
    this.categoryName,
    this.ownerId,
    this.pTypeName,
    this.seenStatus,
    this.notificationId,
    this.notifyStatusId,
    this.loginType,

  });

  factory HelpdeskRequest.fromJson(Map<String, dynamic> json) =>
      _$HelpdeskRequestFromJson(json);

  Map<String, dynamic> toJson() => _$HelpdeskRequestToJson(this);
}
