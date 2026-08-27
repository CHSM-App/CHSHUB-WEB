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

/// Body of POST /api/web/community/helpdesk.
///
/// The secretary raising it is taken from the access token; [flatId] says who
/// it is being raised *for*.
@JsonSerializable(includeIfNull: false)
class HelpdeskCreateRequest {
  /// The flat the complaint is about.
  ///
  /// Null on a community complaint — a lift or the parking belongs to the
  /// society rather than to any one flat, and the form does not ask for one.
  /// `includeIfNull: false` keeps the key out of the body entirely then.
  @JsonKey(name: 'flatId')
  final int? flatId;

  /// The complaint category — a `p_type_id` from the lookups.
  @JsonKey(name: 'category')
  final int category;

  /// The resident's own words.
  @JsonKey(name: 'query')
  final String query;

  /// 'personal' or 'community'.
  @JsonKey(name: 'categoryType')
  final String categoryType;

  /// A flag, not a scale: anything non-zero reads as Urgent.
  @JsonKey(name: 'urgency')
  final int urgency;

  const HelpdeskCreateRequest({
    required this.flatId,
    required this.category,
    required this.query,
    this.categoryType = 'personal',
    this.urgency = 0,
  });

  factory HelpdeskCreateRequest.fromJson(Map<String, dynamic> json) =>
      _$HelpdeskCreateRequestFromJson(json);

  Map<String, dynamic> toJson() => _$HelpdeskCreateRequestToJson(this);
}

/// Body of POST /api/web/uploads/record/helpdesk-image.
///
/// Sent after the file itself is uploaded, to attach the stored path to a
/// ticket.
@JsonSerializable(includeIfNull: false)
class HelpdeskImageRequest {
  @JsonKey(name: 'helpdeskId')
  final int helpdeskId;

  /// The `path` the uploader returned — `helpdesk/<file>`, not a full URL.
  @JsonKey(name: 'docPath')
  final String docPath;

  const HelpdeskImageRequest({required this.helpdeskId, required this.docPath});

  factory HelpdeskImageRequest.fromJson(Map<String, dynamic> json) =>
      _$HelpdeskImageRequestFromJson(json);

  Map<String, dynamic> toJson() => _$HelpdeskImageRequestToJson(this);
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

/// Body of POST/PUT /api/web/community/events.
///
/// `sp_event_master` stores a span rather than a single day, so both dates are
/// required — a one-day event passes the same date twice. Like a notice, the
/// server pushes to residents after the save, so a failed push cannot lose the
/// event.
@JsonSerializable(includeIfNull: false)
class EventRequest {
  @JsonKey(name: 'name')
  final String name;

  @JsonKey(name: 'description')
  final String? description;

  /// ISO yyyy-MM-dd.
  @JsonKey(name: 'fromDate')
  final String fromDate;

  /// ISO yyyy-MM-dd.
  @JsonKey(name: 'toDate')
  final String toDate;

  const EventRequest({
    required this.name,
    required this.fromDate,
    required this.toDate,
    this.description,
  });

  factory EventRequest.fromJson(Map<String, dynamic> json) =>
      _$EventRequestFromJson(json);

  Map<String, dynamic> toJson() => _$EventRequestToJson(this);
}

/// Body of POST/PUT /api/web/community/meetings.
///
/// The time is optional because `sp_meeting_master` accepts a null one, and
/// meeting_search.aspx has no recipient picker — the server notifies the whole
/// society, so this carries no audience field.
@JsonSerializable(includeIfNull: false)
class MeetingRequest {
  @JsonKey(name: 'subject')
  final String subject;

  @JsonKey(name: 'details')
  final String? details;

  /// ISO yyyy-MM-dd.
  @JsonKey(name: 'meetingDate')
  final String meetingDate;

  /// HH:mm, 24-hour. Omitted when the time is not settled yet.
  @JsonKey(name: 'meetingTime')
  final String? meetingTime;

  const MeetingRequest({
    required this.subject,
    required this.meetingDate,
    this.details,
    this.meetingTime,
  });

  factory MeetingRequest.fromJson(Map<String, dynamic> json) =>
      _$MeetingRequestFromJson(json);

  Map<String, dynamic> toJson() => _$MeetingRequestToJson(this);
}

/// Body of POST /api/web/community/polls.
///
/// The audience values are Vote.aspx's own — 1 all members, 2 committee,
/// 3 owners, 4 tenants — which the route translates into recipient groups
/// itself, so they are passed through as the website sends them rather than
/// converted here.
///
/// [options] must hold at least two entries and none may contain a comma:
/// sp_PollOptions splits the joined string with STRING_SPLIT, so a comma
/// inside one option would silently become two.
@JsonSerializable(includeIfNull: false)
class PollRequest {
  @JsonKey(name: 'topic')
  final String topic;

  @JsonKey(name: 'description')
  final String? description;

  /// ISO yyyy-MM-dd — voting closes after this.
  @JsonKey(name: 'expiryDate')
  final String expiryDate;

  @JsonKey(name: 'options')
  final List<String> options;

  /// '1' all members · '2' committee · '3' owners · '4' tenants.
  @JsonKey(name: 'audience')
  final String audience;

  @JsonKey(name: 'allowMultipleVotes')
  final bool allowMultipleVotes;

  /// One vote per flat rather than per resident.
  @JsonKey(name: 'oneVotePerUnit')
  final bool oneVotePerUnit;

  const PollRequest({
    required this.topic,
    required this.expiryDate,
    required this.options,
    this.description,
    this.audience = '1',
    this.allowMultipleVotes = false,
    this.oneVotePerUnit = false,
  });

  factory PollRequest.fromJson(Map<String, dynamic> json) =>
      _$PollRequestFromJson(json);

  Map<String, dynamic> toJson() => _$PollRequestToJson(this);
}

/// Body of POST/PUT /api/web/community/noc.
///
/// `clause` is sent for every type, not derived from `nocType` on the server:
/// a certificate is a legal statement fixed when it was signed, so rewording
/// the society's standard clause later must not change what an already-issued
/// certificate reads.
@JsonSerializable(includeIfNull: false)
class NocRequest {
  /// One of NoDues, SaleTransfer, Renovation, Mortgage, General, Other.
  @JsonKey(name: 'nocType')
  final String nocType;

  /// What an `Other` certificate calls itself; ignored for the built-in types.
  @JsonKey(name: 'customTitle')
  final String? customTitle;

  /// Completes "The society has no objection …".
  @JsonKey(name: 'clause')
  final String clause;

  @JsonKey(name: 'memberName')
  final String memberName;

  @JsonKey(name: 'flatNo')
  final String flatNo;

  @JsonKey(name: 'buildingName')
  final String? buildingName;

  @JsonKey(name: 'purpose')
  final String? purpose;

  /// Printed as a further paragraph on the letter.
  @JsonKey(name: 'remarks')
  final String? remarks;

  /// ISO yyyy-MM-dd.
  @JsonKey(name: 'issuedOn')
  final String? issuedOn;

  /// ISO yyyy-MM-dd. Absent means the certificate does not lapse.
  @JsonKey(name: 'validTill')
  final String? validTill;

  const NocRequest({
    required this.nocType,
    required this.clause,
    required this.memberName,
    required this.flatNo,
    this.customTitle,
    this.buildingName,
    this.purpose,
    this.remarks,
    this.issuedOn,
    this.validTill,
  });

  factory NocRequest.fromJson(Map<String, dynamic> json) =>
      _$NocRequestFromJson(json);

  Map<String, dynamic> toJson() => _$NocRequestToJson(this);
}

/// Body of POST and PUT /api/web/community/suggestions.
///
/// The two fields suggestion_request.aspx's modal carried — txt_sub and
/// txt_details — and nothing more. The society comes off the access token,
/// so a suggestion can only ever be filed against the caller's own society.
@JsonSerializable(includeIfNull: false)
class SuggestionRequest {
  @JsonKey(name: 'subject')
  final String subject;

  @JsonKey(name: 'details')
  final String details;

  const SuggestionRequest({required this.subject, required this.details});

  factory SuggestionRequest.fromJson(Map<String, dynamic> json) =>
      _$SuggestionRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SuggestionRequestToJson(this);
}
