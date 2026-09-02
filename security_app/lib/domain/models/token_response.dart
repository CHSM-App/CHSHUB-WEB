import 'package:json_annotation/json_annotation.dart';

part 'token_response.g.dart';

@JsonSerializable()
class TokenResponse {
  final String? accessToken;
  final String? refreshToken;
  final String? mobile;
  final String? deviceDetails;
  // The verification code the server checks in POST /login/Createlogin.
  // Only sent on login; never returned, so it stays null on responses.
  final String? otp;

  TokenResponse({
     this.accessToken,
     this.refreshToken,
    this.mobile,
    this.deviceDetails,
    this.otp

  });

  factory TokenResponse.fromJson(Map<String, dynamic> json) =>
   _$TokenResponseFromJson(json);
  

  Map<String, dynamic> toJson() => _$TokenResponseToJson(this);
}
