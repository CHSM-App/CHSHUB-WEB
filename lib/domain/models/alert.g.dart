// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'alert.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Alert _$AlertFromJson(Map<String, dynamic> json) => Alert(
      RId: (json['r_id'] as num?)?.toInt(),
      flatId: (json['flat_id'] as num?)?.toInt(),
      Message: json['message'] as String?,
      Type: json['type'] as String?,
      SocietyId: json['society_id'] as String?,
      Messagesub: json['message_sub'] as String?,
      OwnerId: (json['owner_id'] as num?)?.toInt(),
      Ownertype: (json['owner_type'] as num?)?.toInt(),
      securityId: (json['security_id'] as num?)?.toInt(),
    );

Map<String, dynamic> _$AlertToJson(Alert instance) => <String, dynamic>{
      'r_id': instance.RId,
      'flat_id': instance.flatId,
      'message': instance.Message,
      'type': instance.Type,
      'society_id': instance.SocietyId,
      'message_sub': instance.Messagesub,
      'owner_id': instance.OwnerId,
      'owner_type': instance.Ownertype,
      'security_id': instance.securityId,
    };
