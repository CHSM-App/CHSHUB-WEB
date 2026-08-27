import 'dart:io';

import '../models/auth_requests.dart';
import '../models/token_response.dart';
import '../models/user.dart';

abstract class AuthRepository {
  Future<TokenResponse> login(String username, String password);
  Future<TokenResponse> refreshAccessToken(TokenResponse refreshToken);
  Future<void> logout(String refreshToken);
  Future<User> me();
  Future<void> forgotPassword(ForgotPasswordRequest request);
  /// Answers the re-armed session for this device, or null when the server
  /// signed this device out along with the others.
  Future<TokenResponse?> changePassword(ChangePasswordRequest request);

  /// Edit the signed-in user's own account, and answer the user as the server
  /// now holds them.
  Future<User> updateProfile(UpdateProfileRequest request);

  /// Store a profile photo, answering the path to save against the account.
  Future<String> uploadProfilePhoto(File file);
}
