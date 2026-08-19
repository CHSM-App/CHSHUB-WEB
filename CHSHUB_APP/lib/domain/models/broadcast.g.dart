// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'broadcast.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Broadcast _$BroadcastFromJson(Map<String, dynamic> json) => Broadcast(
      fromDate: json['from_date'] as String?,
      toDate: json['to_date'] as String?,
      description: json['description'] as String?,
      name: json['name'] as String?,
      societyId: json['society_id'] as String?,
      userId: (json['user_id'] as num?)?.toInt(),
      userType: json['user_type'] as String?,
      notificationId: (json['notification_id'] as num?)?.toInt(),
      notificationType: json['notification_type'] as String?,
      notifyStatusId: (json['notify_status_id'] as num?)?.toInt(),
      title: json['title'] as String?,
      body: json['body'] as String?,
      timestamp: json['timestamp'] as String?,
      seenStatus: (json['seen_status'] as num?)?.toInt(),
      ownerId: (json['owner_id'] as num?)?.toInt(),
      record: (json['record'] as num?)?.toInt(),
    );

Map<String, dynamic> _$BroadcastToJson(Broadcast instance) => <String, dynamic>{
      'from_date': instance.fromDate,
      'to_date': instance.toDate,
      'description': instance.description,
      'name': instance.name,
      'society_id': instance.societyId,
      'user_id': instance.userId,
      'user_type': instance.userType,
      'notification_id': instance.notificationId,
      'notification_type': instance.notificationType,
      'notify_status_id': instance.notifyStatusId,
      'title': instance.title,
      'body': instance.body,
      'timestamp': instance.timestamp,
      'seen_status': instance.seenStatus,
      'owner_id': instance.ownerId,
      'record': instance.record,
    };
