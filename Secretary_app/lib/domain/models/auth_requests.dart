import 'package:json_annotation/json_annotation.dart';

part 'auth_requests.g.dart';

/// Body of POST /api/web/onboarding/forgot-password.
///
/// The account is identified by email, and the new password is sent with it —
/// there is no separate "send a code, then reset" pair on this API. Identity is
/// proved out of band: the legacy flow verifies the resident over SMS via the
/// mobile API's /login/send-sms before this call, and that step is unchanged.
///
/// The response is `{ submitted: true }` whether or not the address exists, so
/// the endpoint cannot be used to discover which addresses have accounts. The
/// UI must not claim the reset definitely happened.
@JsonSerializable(includeIfNull: false)
class ForgotPasswordRequest {
  @JsonKey(name: 'email')
  final String email;

  /// Minimum 8 characters — enforced server-side too.
  @JsonKey(name: 'newPassword')
  final String newPassword;

  const ForgotPasswordRequest({required this.email, required this.newPassword});

  factory ForgotPasswordRequest.fromJson(Map<String, dynamic> json) =>
      _$ForgotPasswordRequestFromJson(json);

  Map<String, dynamic> toJson() => _$ForgotPasswordRequestToJson(this);
}

/// Body of POST /api/web/onboarding/change-password, for a signed-in user.
///
/// Only the new password is sent. The endpoint does not ask for the current
/// one: a valid access token is already proof of possession, and demanding the
/// old password locked out anyone who had forgotten it. The other fields are
/// optional because sp_UserLogin's UpdateProfile branch writes the whole row —
/// omitting them is what leaves them unchanged.
@JsonSerializable(includeIfNull: false)
class ChangePasswordRequest {
  @JsonKey(name: 'newPassword')
  final String newPassword;

  @JsonKey(name: 'username')
  final String? username;

  @JsonKey(name: 'email')
  final String? email;

  @JsonKey(name: 'contactNo')
  final String? contactNo;

  const ChangePasswordRequest({
    required this.newPassword,
    this.username,
    this.email,
    this.contactNo,
  });

  factory ChangePasswordRequest.fromJson(Map<String, dynamic> json) =>
      _$ChangePasswordRequestFromJson(json);

  Map<String, dynamic> toJson() => _$ChangePasswordRequestToJson(this);
}
