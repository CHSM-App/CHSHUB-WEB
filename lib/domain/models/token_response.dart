import 'package:json_annotation/json_annotation.dart';

import 'json_utils.dart';
import 'user.dart';

part 'token_response.g.dart';

/// Body and response of /api/web/auth/login, /refresh and /logout.
///
/// One class serves all three because the website API answers login and
/// refresh with the identical shape, and logout takes only `refreshToken` —
/// every field being nullable is what lets it double as the request body.
@JsonSerializable(explicitToJson: true)
class TokenResponse {
  // ===== SENT ON LOGIN =====
  @JsonKey(name: 'username', includeIfNull: false)
  final String? username;

  @JsonKey(name: 'password', includeIfNull: false)
  final String? password;

  @JsonKey(name: 'deviceInfo', includeIfNull: false)
  final String? deviceInfo;

  // ===== RETURNED =====
  @JsonKey(name: 'accessToken', includeIfNull: false)
  final String? accessToken;

  @JsonKey(name: 'refreshToken', includeIfNull: false)
  final String? refreshToken;

  @JsonKey(name: 'expiresAt', includeToJson: false)
  final String? expiresAt;

  @JsonKey(name: 'user', includeToJson: false)
  final User? user;

  @JsonKey(name: 'loggedOut', includeToJson: false, fromJson: asBool)
  final bool loggedOut;

  const TokenResponse({
    this.username,
    this.password,
    this.deviceInfo,
    this.accessToken,
    this.refreshToken,
    this.expiresAt,
    this.user,
    this.loggedOut = false,
  });

  factory TokenResponse.fromJson(Map<String, dynamic> json) =>
      _$TokenResponseFromJson(json);

  Map<String, dynamic> toJson() => _$TokenResponseToJson(this);

  TokenResponse copyWith({
    String? username,
    String? password,
    String? deviceInfo,
    String? accessToken,
    String? refreshToken,
    String? expiresAt,
    User? user,
    bool? loggedOut,
  }) {
    return TokenResponse(
      username: username ?? this.username,
      password: password ?? this.password,
      deviceInfo: deviceInfo ?? this.deviceInfo,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      expiresAt: expiresAt ?? this.expiresAt,
      user: user ?? this.user,
      loggedOut: loggedOut ?? this.loggedOut,
    );
  }
}
