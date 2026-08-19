// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'helpdesk_comment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HelpdeskComment _$HelpdeskCommentFromJson(Map<String, dynamic> json) =>
    HelpdeskComment(
      ownerId: (json['owner_id'] as num?)?.toInt(),
      oExId: (json['oExId'] as num?)?.toInt(),
      name: json['name'] as String?,
      unit: json['unit'] as String?,
      description: json['description'] as String?,
      dateTime: json['dateTime'] as String?,
      image: json['image'] as String?,
      helpdeskId: (json['helpdesk_id'] as num).toInt(),
      comment_id: (json['comment_id'] as num?)?.toInt(),
      flatId: (json['flat_id'] as num?)?.toInt(),
      ownerType: json['ownerType'] as String?,
      type: json['type'] as String?,
    );

Map<String, dynamic> _$HelpdeskCommentToJson(HelpdeskComment instance) =>
    <String, dynamic>{
      'ownerType': instance.ownerType,
      'flat_id': instance.flatId,
      'owner_id': instance.ownerId,
      'oExId': instance.oExId,
      'comment_id': instance.comment_id,
      'name': instance.name,
      'unit': instance.unit,
      'description': instance.description,
      'dateTime': instance.dateTime,
      'image': instance.image,
      'helpdesk_id': instance.helpdeskId,
      'type': instance.type,
    };
