// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'helpdesk.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HelpdeskRequest _$HelpdeskRequestFromJson(Map<String, dynamic> json) =>
    HelpdeskRequest(
      category: (json['category'] as num?)?.toInt(),
      documents: json['documents'] as String?,
      flatId: (json['flat_id'] as num?)?.toInt(),
      helpdeskId: (json['helpdesk_id'] as num?)?.toInt(),
      query: json['query'] as String?,
      reqServiceDate: json['req_service_date'] as String?,
      urgency: (json['urgency'] as num?)?.toInt(),
      status: (json['status'] as num?)?.toInt(),
      categoryType: json['category_type'] as String?,
      flatNo: json['flat_no'] as String?,
      unit: json['Unit'] as String?,
      name: json['name'] as String?,
      date: json['date'] as String?,
      image: json['image'] as String?,
      categoryName: json['categoryName'] as String?,
      ownerId: (json['owner_id'] as num?)?.toInt(),
      pTypeName: json['p_type_name'] as String?,
      seenStatus: (json['seen_status'] as num?)?.toInt(),
      notificationId: (json['notification_id'] as num?)?.toInt(),
      notifyStatusId: (json['notify_status_id'] as num?)?.toInt(),
      loginType: json['logintype'] as String?,
    );

Map<String, dynamic> _$HelpdeskRequestToJson(HelpdeskRequest instance) =>
    <String, dynamic>{
      'category': instance.category,
      'documents': instance.documents,
      'flat_id': instance.flatId,
      'helpdesk_id': instance.helpdeskId,
      'query': instance.query,
      'req_service_date': instance.reqServiceDate,
      'urgency': instance.urgency,
      'status': instance.status,
      'category_type': instance.categoryType,
      'flat_no': instance.flatNo,
      'Unit': instance.unit,
      'name': instance.name,
      'date': instance.date,
      'image': instance.image,
      'categoryName': instance.categoryName,
      'p_type_name': instance.pTypeName,
      'owner_id': instance.ownerId,
      'seen_status': instance.seenStatus,
      'notification_id': instance.notificationId,
      'notify_status_id': instance.notifyStatusId,
      'logintype': instance.loginType,
    };
