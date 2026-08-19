// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'alert_notification.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AlertNotification _$AlertNotificationFromJson(Map<String, dynamic> json) =>
    AlertNotification(
      society_id: json['society_id'] as String,
      buildings: (json['buildings'] as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList(),
      staff_id: (json['staff_id'] as num).toInt(),
      notification_type: json['notification_type'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
    );

Map<String, dynamic> _$AlertNotificationToJson(AlertNotification instance) =>
    <String, dynamic>{
      'society_id': instance.society_id,
      'buildings': instance.buildings,
      'staff_id': instance.staff_id,
      'notification_type': instance.notification_type,
      'title': instance.title,
      'body': instance.body,
    };
