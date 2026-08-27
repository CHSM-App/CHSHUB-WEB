// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
  userId: asInt(json['user_id']),
  name: json['name'] as String?,
  username: json['username'] as String?,
  userTypeId: asInt(json['user_type_id']),
  userType: json['user_type'] as String?,
  societyId: asString(json['society_id']),
  societyName: json['society_name'] as String?,
  villageId: asString(json['village_id']),
  villageName: json['village_name'] as String?,
  tenantType: json['tenant_type'] as String?,
  ownerId: asInt(json['owner_id']),
  email: json['email'] as String?,
  contactNo: asString(json['contact_no']),
  photoPath: json['photo_path'] as String?,
);

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
  'user_id': instance.userId,
  'name': instance.name,
  'username': instance.username,
  'user_type_id': instance.userTypeId,
  'user_type': instance.userType,
  'society_id': instance.societyId,
  'society_name': instance.societyName,
  'village_id': instance.villageId,
  'village_name': instance.villageName,
  'tenant_type': instance.tenantType,
  'owner_id': instance.ownerId,
  'email': instance.email,
  'contact_no': instance.contactNo,
  'photo_path': instance.photoPath,
};
