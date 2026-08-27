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

/// Body of PUT /api/web/onboarding/profile — a signed-in user editing their
/// own account.
///
/// The name is sent split, because that is the shape the endpoint takes: the
/// legacy profile modal had separate first/last boxes and the route rejoins
/// them. Our editor shows one "Full name" field and splits it at the last
/// space, so a single-word name arrives as a first name with no last name,
/// which the route accepts.
///
/// `newPassword` is deliberately absent: password changes go through
/// [ChangePasswordRequest] so that saving a profile can never touch the login.
@JsonSerializable(includeIfNull: false)
class UpdateProfileRequest {
  @JsonKey(name: 'firstName')
  final String firstName;

  @JsonKey(name: 'lastName')
  final String? lastName;

  /// Required by the route — it checks the name is not already taken by
  /// another account before writing.
  @JsonKey(name: 'username')
  final String username;

  @JsonKey(name: 'email')
  final String? email;

  @JsonKey(name: 'contactNo')
  final String? contactNo;

  /// Profile photo, as the path /uploads returned for it.
  ///
  /// Three states, and the route reads all three: omitted (null, and dropped
  /// from the body by includeIfNull) leaves the stored photo alone; a path
  /// replaces it; the empty string removes it. Null therefore cannot be used
  /// to mean "remove" — that is what [photoRemoved] produces.
  @JsonKey(name: 'photoPath')
  final String? photoPath;

  const UpdateProfileRequest({
    required this.firstName,
    required this.username,
    this.lastName,
    this.email,
    this.contactNo,
    this.photoPath,
  });

  /// The value of [photoPath] that clears the stored photo.
  static const String photoRemoved = '';

  factory UpdateProfileRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateProfileRequestFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateProfileRequestToJson(this);
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

  /// This device's refresh token, so the server can spare this session while
  /// it revokes the others.
  ///
  /// Changing a password ends every session the account has, on the website
  /// and in the mobile apps — that is the point of changing it. Naming our own
  /// token is what keeps the person doing the changing from being signed out
  /// of the device they are typing on; the server revokes it and answers with
  /// a fresh pair. Omitting it is safe but signs this device out too.
  @JsonKey(name: 'refreshToken')
  final String? refreshToken;

  const ChangePasswordRequest({
    required this.newPassword,
    this.username,
    this.email,
    this.contactNo,
    this.refreshToken,
  });

  factory ChangePasswordRequest.fromJson(Map<String, dynamic> json) =>
      _$ChangePasswordRequestFromJson(json);

  Map<String, dynamic> toJson() => _$ChangePasswordRequestToJson(this);
}
