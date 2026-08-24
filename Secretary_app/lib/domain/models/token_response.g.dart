// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'token_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TokenResponse _$TokenResponseFromJson(Map<String, dynamic> json) =>
    TokenResponse(
      username: json['username'] as String?,
      password: json['password'] as String?,
      deviceInfo: json['deviceInfo'] as String?,
      accessToken: json['accessToken'] as String?,
      refreshToken: json['refreshToken'] as String?,
      expiresAt: json['expiresAt'] as String?,
      user: json['user'] == null
          ? null
          : User.fromJson(json['user'] as Map<String, dynamic>),
      loggedOut: json['loggedOut'] == null ? false : asBool(json['loggedOut']),
    );

Map<String, dynamic> _$TokenResponseToJson(TokenResponse instance) =>
    <String, dynamic>{
      'username': ?instance.username,
      'password': ?instance.password,
      'deviceInfo': ?instance.deviceInfo,
      'accessToken': ?instance.accessToken,
      'refreshToken': ?instance.refreshToken,
    };
