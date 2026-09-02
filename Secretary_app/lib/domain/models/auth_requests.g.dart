// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_requests.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ForgotPasswordRequest _$ForgotPasswordRequestFromJson(
  Map<String, dynamic> json,
) => ForgotPasswordRequest(
  email: json['email'] as String,
  newPassword: json['newPassword'] as String,
);

Map<String, dynamic> _$ForgotPasswordRequestToJson(
  ForgotPasswordRequest instance,
) => <String, dynamic>{
  'email': instance.email,
  'newPassword': instance.newPassword,
};

UpdateProfileRequest _$UpdateProfileRequestFromJson(
  Map<String, dynamic> json,
) => UpdateProfileRequest(
  firstName: json['firstName'] as String,
  username: json['username'] as String,
  lastName: json['lastName'] as String?,
  email: json['email'] as String?,
  contactNo: json['contactNo'] as String?,
  photoPath: json['photoPath'] as String?,
);

Map<String, dynamic> _$UpdateProfileRequestToJson(
  UpdateProfileRequest instance,
) => <String, dynamic>{
  'firstName': instance.firstName,
  'lastName': ?instance.lastName,
  'username': instance.username,
  'email': ?instance.email,
  'contactNo': ?instance.contactNo,
  'photoPath': ?instance.photoPath,
};

ChangePasswordRequest _$ChangePasswordRequestFromJson(
  Map<String, dynamic> json,
) => ChangePasswordRequest(
  newPassword: json['newPassword'] as String,
  username: json['username'] as String?,
  email: json['email'] as String?,
  contactNo: json['contactNo'] as String?,
  refreshToken: json['refreshToken'] as String?,
);

Map<String, dynamic> _$ChangePasswordRequestToJson(
  ChangePasswordRequest instance,
) => <String, dynamic>{
  'newPassword': instance.newPassword,
  'username': ?instance.username,
  'email': ?instance.email,
  'contactNo': ?instance.contactNo,
  'refreshToken': ?instance.refreshToken,
};
