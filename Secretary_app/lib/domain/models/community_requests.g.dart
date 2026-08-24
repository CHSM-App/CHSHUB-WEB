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
