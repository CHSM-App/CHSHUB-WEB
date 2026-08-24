import 'package:json_annotation/json_annotation.dart';

part 'community_requests.g.dart';

/// Body of POST/PUT /api/web/community/notices.
///
/// `recipientsId` selects the audience group; the server pushes a notification
/// to it *after* the notice is saved, so a failed push can never lose the
/// notice. GET /community/notices/recipients lists the valid groups.
@JsonSerializable(includeIfNull: false)
class NoticeRequest {
  @JsonKey(name: 'title')
  final String title;

  @JsonKey(name: 'description')
  final String? description;

  /// ISO yyyy-MM-dd — the notice stops showing after this.
  @JsonKey(name: 'validTo')
  final String? validTo;

  @JsonKey(name: 'recipientsId')
  final int? recipientsId;

  /// Accepted on update only.
  @JsonKey(name: 'date')
  final String? date;

  const NoticeRequest({
    required this.title,
    this.description,
    this.validTo,
    this.recipientsId,
    this.date,
  });

  factory NoticeRequest.fromJson(Map<String, dynamic> json) =>
      _$NoticeRequestFromJson(json);

  Map<String, dynamic> toJson() => _$NoticeRequestToJson(this);
}

/// Body of POST /api/web/community/facility-bookings.
@JsonSerializable(includeIfNull: false)
class FacilityBookingRequest {
  @JsonKey(name: 'facilityId')
  final int facilityId;

  @JsonKey(name: 'name')
  final String name;

  /// ISO yyyy-MM-dd. Required by the server.
  @JsonKey(name: 'fromDate')
  final String fromDate;

  @JsonKey(name: 'toDate')
  final String? toDate;

  /// The date the booking is made for, distinct from the from/to range.
  @JsonKey(name: 'bookDate')
  final String? bookDate;

  @JsonKey(name: 'flatId')
  final int? flatId;

  @JsonKey(name: 'address')
  final String? address;

  @JsonKey(name: 'contact')
  final String? contact;

  /// HH:mm clock times.
  @JsonKey(name: 'fromTime')
  final String? fromTime;

  @JsonKey(name: 'toTime')
  final String? toTime;

  @JsonKey(name: 'amount')
  final double? amount;

  @JsonKey(name: 'note')
  final String? note;

  /// Whether the booker is from within the society (affects the charge).
  @JsonKey(name: 'societyIn')
  final bool? societyIn;

  const FacilityBookingRequest({
    required this.facilityId,
    required this.name,
    required this.fromDate,
    this.toDate,
    this.bookDate,
    this.flatId,
    this.address,
    this.contact,
    this.fromTime,
    this.toTime,
    this.amount,
    this.note,
    this.societyIn,
  });

  factory FacilityBookingRequest.fromJson(Map<String, dynamic> json) =>
      _$FacilityBookingRequestFromJson(json);

  Map<String, dynamic> toJson() => _$FacilityBookingRequestToJson(this);
}

/// Body of PUT /api/web/community/helpdesk/:id/status.
@JsonSerializable(includeIfNull: false)
class HelpdeskStatusRequest {
  @JsonKey(name: 'status')
  final int status;

  const HelpdeskStatusRequest({required this.status});

  factory HelpdeskStatusRequest.fromJson(Map<String, dynamic> json) =>
      _$HelpdeskStatusRequestFromJson(json);

  Map<String, dynamic> toJson() => _$HelpdeskStatusRequestToJson(this);
}

/// Body of POST /api/web/community/helpdesk/:id/comments.
///
/// The commenter is taken from the access token, not the body — a secretary
/// cannot post as someone else.
@JsonSerializable(includeIfNull: false)
class HelpdeskCommentRequest {
  @JsonKey(name: 'comment')
  final String comment;

  @JsonKey(name: 'flatId')
  final int? flatId;

  /// Defaults to 'Admin' server-side.
  @JsonKey(name: 'type')
  final String? type;

  const HelpdeskCommentRequest({required this.comment, this.flatId, this.type});

  factory HelpdeskCommentRequest.fromJson(Map<String, dynamic> json) =>
      _$HelpdeskCommentRequestFromJson(json);

  Map<String, dynamic> toJson() => _$HelpdeskCommentRequestToJson(this);
}
