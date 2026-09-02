// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'community_requests.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NoticeRequest _$NoticeRequestFromJson(Map<String, dynamic> json) =>
    NoticeRequest(
      title: json['title'] as String,
      description: json['description'] as String?,
      validTo: json['validTo'] as String?,
      recipientsId: (json['recipientsId'] as num?)?.toInt(),
      date: json['date'] as String?,
    );

Map<String, dynamic> _$NoticeRequestToJson(NoticeRequest instance) =>
    <String, dynamic>{
      'title': instance.title,
      'description': ?instance.description,
      'validTo': ?instance.validTo,
      'recipientsId': ?instance.recipientsId,
      'date': ?instance.date,
    };

FacilityBookingRequest _$FacilityBookingRequestFromJson(
  Map<String, dynamic> json,
) => FacilityBookingRequest(
  facilityId: (json['facilityId'] as num).toInt(),
  name: json['name'] as String,
  fromDate: json['fromDate'] as String,
  toDate: json['toDate'] as String?,
  bookDate: json['bookDate'] as String?,
  flatId: (json['flatId'] as num?)?.toInt(),
  address: json['address'] as String?,
  contact: json['contact'] as String?,
  fromTime: json['fromTime'] as String?,
  toTime: json['toTime'] as String?,
  amount: (json['amount'] as num?)?.toDouble(),
  note: json['note'] as String?,
  societyIn: json['societyIn'] as bool?,
);

Map<String, dynamic> _$FacilityBookingRequestToJson(
  FacilityBookingRequest instance,
) => <String, dynamic>{
  'facilityId': instance.facilityId,
  'name': instance.name,
  'fromDate': instance.fromDate,
  'toDate': ?instance.toDate,
  'bookDate': ?instance.bookDate,
  'flatId': ?instance.flatId,
  'address': ?instance.address,
  'contact': ?instance.contact,
  'fromTime': ?instance.fromTime,
  'toTime': ?instance.toTime,
  'amount': ?instance.amount,
  'note': ?instance.note,
  'societyIn': ?instance.societyIn,
};

HelpdeskStatusRequest _$HelpdeskStatusRequestFromJson(
  Map<String, dynamic> json,
) => HelpdeskStatusRequest(status: (json['status'] as num).toInt());

Map<String, dynamic> _$HelpdeskStatusRequestToJson(
  HelpdeskStatusRequest instance,
) => <String, dynamic>{'status': instance.status};

HelpdeskCreateRequest _$HelpdeskCreateRequestFromJson(
  Map<String, dynamic> json,
) => HelpdeskCreateRequest(
  flatId: (json['flatId'] as num?)?.toInt(),
  category: (json['category'] as num).toInt(),
  query: json['query'] as String,
  categoryType: json['categoryType'] as String? ?? 'personal',
  urgency: (json['urgency'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$HelpdeskCreateRequestToJson(
  HelpdeskCreateRequest instance,
) => <String, dynamic>{
  'flatId': ?instance.flatId,
  'category': instance.category,
  'query': instance.query,
  'categoryType': instance.categoryType,
  'urgency': instance.urgency,
};

HelpdeskImageRequest _$HelpdeskImageRequestFromJson(
  Map<String, dynamic> json,
) => HelpdeskImageRequest(
  helpdeskId: (json['helpdeskId'] as num).toInt(),
  docPath: json['docPath'] as String,
);

Map<String, dynamic> _$HelpdeskImageRequestToJson(
  HelpdeskImageRequest instance,
) => <String, dynamic>{
  'helpdeskId': instance.helpdeskId,
  'docPath': instance.docPath,
};

HelpdeskCommentRequest _$HelpdeskCommentRequestFromJson(
  Map<String, dynamic> json,
) => HelpdeskCommentRequest(
  comment: json['comment'] as String,
  flatId: (json['flatId'] as num?)?.toInt(),
  type: json['type'] as String?,
);

Map<String, dynamic> _$HelpdeskCommentRequestToJson(
  HelpdeskCommentRequest instance,
) => <String, dynamic>{
  'comment': instance.comment,
  'flatId': ?instance.flatId,
  'type': ?instance.type,
};

EventRequest _$EventRequestFromJson(Map<String, dynamic> json) => EventRequest(
  name: json['name'] as String,
  fromDate: json['fromDate'] as String,
  toDate: json['toDate'] as String,
  description: json['description'] as String?,
);

Map<String, dynamic> _$EventRequestToJson(EventRequest instance) =>
    <String, dynamic>{
      'name': instance.name,
      'description': ?instance.description,
      'fromDate': instance.fromDate,
      'toDate': instance.toDate,
    };

MeetingRequest _$MeetingRequestFromJson(Map<String, dynamic> json) =>
    MeetingRequest(
      subject: json['subject'] as String,
      meetingDate: json['meetingDate'] as String,
      details: json['details'] as String?,
      meetingTime: json['meetingTime'] as String?,
    );

Map<String, dynamic> _$MeetingRequestToJson(MeetingRequest instance) =>
    <String, dynamic>{
      'subject': instance.subject,
      'details': ?instance.details,
      'meetingDate': instance.meetingDate,
      'meetingTime': ?instance.meetingTime,
    };

PollRequest _$PollRequestFromJson(Map<String, dynamic> json) => PollRequest(
  topic: json['topic'] as String,
  expiryDate: json['expiryDate'] as String,
  options: (json['options'] as List<dynamic>).map((e) => e as String).toList(),
  description: json['description'] as String?,
  audience: json['audience'] as String? ?? '1',
  allowMultipleVotes: json['allowMultipleVotes'] as bool? ?? false,
  oneVotePerUnit: json['oneVotePerUnit'] as bool? ?? false,
);

Map<String, dynamic> _$PollRequestToJson(PollRequest instance) =>
    <String, dynamic>{
      'topic': instance.topic,
      'description': ?instance.description,
      'expiryDate': instance.expiryDate,
      'options': instance.options,
      'audience': instance.audience,
      'allowMultipleVotes': instance.allowMultipleVotes,
      'oneVotePerUnit': instance.oneVotePerUnit,
    };

NocRequest _$NocRequestFromJson(Map<String, dynamic> json) => NocRequest(
  nocType: json['nocType'] as String,
  clause: json['clause'] as String,
  memberName: json['memberName'] as String,
  flatNo: json['flatNo'] as String,
  customTitle: json['customTitle'] as String?,
  buildingName: json['buildingName'] as String?,
  purpose: json['purpose'] as String?,
  remarks: json['remarks'] as String?,
  issuedOn: json['issuedOn'] as String?,
  validTill: json['validTill'] as String?,
);

Map<String, dynamic> _$NocRequestToJson(NocRequest instance) =>
    <String, dynamic>{
      'nocType': instance.nocType,
      'customTitle': ?instance.customTitle,
      'clause': instance.clause,
      'memberName': instance.memberName,
      'flatNo': instance.flatNo,
      'buildingName': ?instance.buildingName,
      'purpose': ?instance.purpose,
      'remarks': ?instance.remarks,
      'issuedOn': ?instance.issuedOn,
      'validTill': ?instance.validTill,
    };

NocDraftRequest _$NocDraftRequestFromJson(Map<String, dynamic> json) =>
    NocDraftRequest(
      nocType: json['nocType'] as String,
      customTitle: json['customTitle'] as String?,
      clause: json['clause'] as String?,
      purpose: json['purpose'] as String?,
      remarks: json['remarks'] as String?,
      validTill: json['validTill'] as String?,
    );

Map<String, dynamic> _$NocDraftRequestToJson(NocDraftRequest instance) =>
    <String, dynamic>{
      'nocType': instance.nocType,
      'customTitle': ?instance.customTitle,
      'clause': ?instance.clause,
      'purpose': ?instance.purpose,
      'remarks': ?instance.remarks,
      'validTill': ?instance.validTill,
    };

NocApproversRequest _$NocApproversRequestFromJson(Map<String, dynamic> json) =>
    NocApproversRequest(
      userIds: (json['userIds'] as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList(),
    );

Map<String, dynamic> _$NocApproversRequestToJson(
  NocApproversRequest instance,
) => <String, dynamic>{'userIds': instance.userIds};

NocDecisionRequest _$NocDecisionRequestFromJson(Map<String, dynamic> json) =>
    NocDecisionRequest(
      decision: json['decision'] as String,
      remarks: json['remarks'] as String?,
    );

Map<String, dynamic> _$NocDecisionRequestToJson(NocDecisionRequest instance) =>
    <String, dynamic>{
      'decision': instance.decision,
      'remarks': ?instance.remarks,
    };

NocReadyRequest _$NocReadyRequestFromJson(Map<String, dynamic> json) =>
    NocReadyRequest(
      collectionDate: json['collectionDate'] as String,
      collectionTime: json['collectionTime'] as String?,
      collectionNote: json['collectionNote'] as String?,
    );

Map<String, dynamic> _$NocReadyRequestToJson(NocReadyRequest instance) =>
    <String, dynamic>{
      'collectionDate': instance.collectionDate,
      'collectionTime': ?instance.collectionTime,
      'collectionNote': ?instance.collectionNote,
    };

NocCollectedRequest _$NocCollectedRequestFromJson(Map<String, dynamic> json) =>
    NocCollectedRequest(collectedBy: json['collectedBy'] as String?);

Map<String, dynamic> _$NocCollectedRequestToJson(
  NocCollectedRequest instance,
) => <String, dynamic>{'collectedBy': ?instance.collectedBy};

SuggestionRequest _$SuggestionRequestFromJson(Map<String, dynamic> json) =>
    SuggestionRequest(
      subject: json['subject'] as String,
      details: json['details'] as String,
    );

Map<String, dynamic> _$SuggestionRequestToJson(SuggestionRequest instance) =>
    <String, dynamic>{'subject': instance.subject, 'details': instance.details};
