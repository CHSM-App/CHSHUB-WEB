// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'login_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LoginData _$LoginDataFromJson(Map<String, dynamic> json) => LoginData(
  staffId: (json['staff_id'] as num?)?.toInt(),
  name: json['name'] as String?,
  lastName: json['last_name'] as String?,
  address: json['address'] as String?,
  contactNo: json['contact_no'] as String?,
  email: json['email'] as String?,
  dateOfJoin: json['date_of_join'] as String?,
  role: json['Role'] as String?,
  image: json['image'] as String?,
  societyId: json['society_id'] as String?,
  buildId: (json['build_id'] as num?)?.toInt(),
  buildName: json['build_name'] as String?,
  societyName: json['society_name'] as String?,
  token: json['token'] as String?,
);

Map<String, dynamic> _$LoginDataToJson(LoginData instance) => <String, dynamic>{
  'staff_id': instance.staffId,
  'name': instance.name,
  'last_name': instance.lastName,
  'address': instance.address,
  'contact_no': instance.contactNo,
  'email': instance.email,
  'date_of_join': instance.dateOfJoin,
  'Role': instance.role,
  'image': instance.image,
  'society_id': instance.societyId,
  'build_id': instance.buildId,
  'build_name': instance.buildName,
  'society_name': instance.societyName,
  'token': instance.token,
};
