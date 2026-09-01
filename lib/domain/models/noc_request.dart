import 'package:json_annotation/json_annotation.dart';

part 'noc_request.g.dart';

/// A no-objection certificate a member has asked the society for.
///
/// The same class carries both directions: the few fields a member fills in
/// when raising a request, and everything the society writes onto it
/// afterwards — the wording, the serial number, and the appointment to come
/// and collect the signed letter. The write fields are the only ones the
/// member's form sets; the rest arrive filled in from GET
/// /community/noc-request/{flat_id}.
@JsonSerializable(includeIfNull: false)
class NocRequest {
  @JsonKey(name: 'request_id')
  final int? requestId;

  @JsonKey(name: 'society_id')
  final String? societyId;

  @JsonKey(name: 'flat_id')
  final int? flatId;

  /// The member raising it, from their login.
  @JsonKey(name: 'user_id')
  final int? userId;

  @JsonKey(name: 'member_name')
  final String? memberName;

  @JsonKey(name: 'flat_no')
  final String? flatNo;

  @JsonKey(name: 'building_name')
  final String? buildingName;

  /// One of NoDues, SaleTransfer, Renovation, Mortgage, General, Other.
  @JsonKey(name: 'noc_type')
  final String? nocType;

  /// What an `Other` request calls itself; null for the built-in types.
  @JsonKey(name: 'custom_title')
  final String? customTitle;

  /// Why the member needs it, in their own words.
  final String? purpose;

  /// 1 Pending, 2 Approved, 4 Rejected, 5 Ready to collect, 6 Collected.
  final int? status;

  /// The certificate's running number, once the society has issued it.
  @JsonKey(name: 'serial_no')
  final String? serialNo;

  /// Completes "The society has no objection …". Written by the society, so
  /// it is null until the request has been reviewed.
  final String? clause;

  final String? remarks;

  @JsonKey(name: 'requested_on')
  final String? requestedOn;

  @JsonKey(name: 'approved_on')
  final String? approvedOn;

  /// Why it was refused, shown to the member. Null unless [status] is 4.
  @JsonKey(name: 'reject_reason')
  final String? rejectReason;

  /// The day the society has asked the member to come for the signed letter.
  @JsonKey(name: 'collection_date')
  final String? collectionDate;

  /// Office hours in words, e.g. "10 AM – 1 PM".
  @JsonKey(name: 'collection_time')
  final String? collectionTime;

  /// Anything to bring, e.g. "Carry your Aadhaar card".
  @JsonKey(name: 'collection_note')
  final String? collectionNote;

  @JsonKey(name: 'collected_on')
  final String? collectedOn;

  @JsonKey(name: 'collected_by')
  final String? collectedBy;

  @JsonKey(name: 'valid_till')
  final String? validTill;

  const NocRequest({
    this.requestId,
    this.societyId,
    this.flatId,
    this.userId,
    this.memberName,
    this.flatNo,
    this.buildingName,
    this.nocType,
    this.customTitle,
    this.purpose,
    this.status,
    this.serialNo,
    this.clause,
    this.remarks,
    this.requestedOn,
    this.approvedOn,
    this.rejectReason,
    this.collectionDate,
    this.collectionTime,
    this.collectionNote,
    this.collectedOn,
    this.collectedBy,
    this.validTill,
  });

  factory NocRequest.fromJson(Map<String, dynamic> json) =>
      _$NocRequestFromJson(json);

  Map<String, dynamic> toJson() => _$NocRequestToJson(this);
}
