// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'directory.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Directory _$DirectoryFromJson(Map<String, dynamic> json) => Directory(
      contactId: (json['contact_id'] as num?)?.toInt(),
      name: json['name'] as String?,
      contact: json['contact'] as String?,
      email: json['email'] as String?,
      unit: json['Unit'] as String?,
      maskPhone: (json['mask_phone'] as num?)?.toInt(),
      maskEmail: (json['mask_email'] as num?)?.toInt(),
      memId: (json['mem_id'] as num?)?.toInt(),
      token: json['token'] as String?,
      userId: (json['user_id'] as num?)?.toInt(),
      webToken: json['web_token'] as String?,
    );

Map<String, dynamic> _$DirectoryToJson(Directory instance) => <String, dynamic>{
      'contact_id': instance.contactId,
      'name': instance.name,
      'contact': instance.contact,
      'email': instance.email,
      'Unit': instance.unit,
      'mask_phone': instance.maskPhone,
      'mask_email': instance.maskEmail,
      'mem_id': instance.memId,
      'token': instance.token,
      'user_id': instance.userId,
      'web_token': instance.webToken,
    };
