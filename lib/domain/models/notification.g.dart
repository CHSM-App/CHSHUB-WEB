// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SendNotification _$SendNotificationFromJson(Map<String, dynamic> json) =>
    SendNotification(
      tokens:
          (json['tokens'] as List<dynamic>).map((e) => e as String).toList(),
      status: json['status'] as String?,
      title: json['title'] as String?,
      body: json['body'] as String?,
      clickAction: json['clickAction'] as String?,
      visitorName: json['visitorName'] as String?,
      visitorId: (json['visitorId'] as num?)?.toInt(),
      purpose: json['purpose'] as String?,
      unit: json['unit'] as String?,
      id: json['id'] as String?,
      image: json['image'] as String?,
      staff_token: json['staff_token'] as String?,
      entryType: json['entryType'] as String?,
    );

Map<String, dynamic> _$SendNotificationToJson(SendNotification instance) =>
    <String, dynamic>{
      'tokens': instance.tokens,
      'title': instance.title,
      'body': instance.body,
      'clickAction': instance.clickAction,
      'visitorName': instance.visitorName,
      'visitorId': instance.visitorId,
      'purpose': instance.purpose,
      'unit': instance.unit,
      'id': instance.id,
      'image': instance.image,
      'staff_token': instance.staff_token,
      'status': instance.status,
      'entryType': instance.entryType,
    };
