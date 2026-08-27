import 'dart:io';

import '../models/auth_requests.dart';
import '../models/token_response.dart';
import '../models/user.dart';
import '../repository/auth_repo.dart';

class AuthUsecase {
  final AuthRepository repository;

  AuthUsecase(this.repository);

  /// Sign in with a username and password.
  Future<TokenResponse> login(String username, String password) {
    return repository.login(username, password);
  }

  /// End the session on the server so the refresh token cannot be reused.
  Future<void> logout(String refreshToken) => repository.logout(refreshToken);

  /// Re-read the signed-in user, picking up any role or society change.
  Future<User> me() => repository.me();

  /// Reset a forgotten password against the account's email address.
  ///
  /// Succeeds silently for an unknown address — the caller must not tell the
  /// user whether the account exists.
  Future<void> forgotPassword(String email, String newPassword) {
    return repository.forgotPassword(
      ForgotPasswordRequest(email: email, newPassword: newPassword),
    );
  }

  /// Change the password of the signed-in user.
  ///
  /// [currentRefreshToken] names this device's session so the server spares it
  /// while revoking the account's others. Answers the replacement session to
  /// store, or null if this device was signed out along with the rest.
  Future<TokenResponse?> changePassword(
    String newPassword, {
    String? currentRefreshToken,
  }) {
    return repository.changePassword(
      ChangePasswordRequest(
        newPassword: newPassword,
        refreshToken: currentRefreshToken,
      ),
    );
  }

  /// Edit the signed-in user's own account.
  ///
  /// The endpoint wants the name in two parts. Splitting at the *last* space
  /// keeps multi-word given names together — "Anna Maria Desai" becomes
  /// "Anna Maria" + "Desai" rather than "Anna" + "Maria Desai" — and a
  /// single-word name is sent as a first name alone, which the route accepts.
  Future<User> updateProfile({
    required String name,
    required String username,
    String? email,
    String? contactNo,
    String? photoPath,
  }) {
    final trimmed = name.trim();
    final cut = trimmed.lastIndexOf(' ');

    return repository.updateProfile(
      UpdateProfileRequest(
        firstName: cut == -1 ? trimmed : trimmed.substring(0, cut),
        lastName: cut == -1 ? null : trimmed.substring(cut + 1),
        username: username.trim(),
        email: email?.trim(),
        contactNo: contactNo?.trim(),
        photoPath: photoPath,
      ),
    );
  }

  /// Store a newly picked profile photo, answering the path to save with the
  /// rest of the profile.
  Future<String> uploadProfilePhoto(File file) =>
      repository.uploadProfilePhoto(file);
}
