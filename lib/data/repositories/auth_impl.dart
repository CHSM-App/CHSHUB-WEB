import 'dart:io';

import '../../domain/models/auth_requests.dart';
import '../../domain/models/json_utils.dart';
import '../../domain/models/token_response.dart';
import '../../domain/models/user.dart';
import '../../domain/repository/auth_repo.dart';
import '../api/api_service.dart';

class AuthImpl implements AuthRepository {
  final ApiService apiService;

  AuthImpl(this.apiService);

  @override
  Future<TokenResponse> login(String username, String password) {
    return apiService.login(
      TokenResponse(
        username: username,
        password: password,
        deviceInfo: 'secretary-app',
      ),
    );
  }

  @override
  Future<TokenResponse> refreshAccessToken(TokenResponse refreshToken) {
    return apiService.refreshAccessToken(refreshToken);
  }

  @override
  Future<void> logout(String refreshToken) {
    return apiService.logout(TokenResponse(refreshToken: refreshToken));
  }

  @override
  Future<User> me() async {
    // /auth/me answers `{ user: {...} }` while /auth/login returns the user
    // beside the tokens. Accept either, so a shape change on one route does
    // not blank the signed-in user's name and society.
    final payload = asRow(await apiService.me());
    return User.fromJson(asRow(payload['user'] ?? payload));
  }

  @override
  Future<void> forgotPassword(ForgotPasswordRequest request) {
    return apiService.forgotPassword(request);
  }

  /// Changing the password revokes every other session for this account, so
  /// the route answers with a fresh pair for *this* device — see
  /// backend/web/routes/onboarding.js. `session` is null when no refresh token
  /// was sent, meaning this device was signed out too.
  @override
  Future<TokenResponse?> changePassword(ChangePasswordRequest request) async {
    final payload = asRow(await apiService.changePassword(request));
    final session = payload['session'];
    if (session == null) return null;
    return TokenResponse.fromJson(asRow(session));
  }

  @override
  Future<String> uploadProfilePhoto(File file) async {
    final stored = asRows(
      asRow(await apiService.uploadProfilePhoto([file]))['items'],
    );
    final path = stored.isEmpty ? null : stored.first['path'];
    if (path is! String || path.isEmpty) {
      throw Exception('The photo was uploaded but no path came back.');
    }
    return path;
  }

  @override
  Future<User> updateProfile(UpdateProfileRequest request) async {
    await apiService.updateProfile(request);
    // The route answers the legacy profile modal's shape — flat name/username
    // fields, no society or user_type — which is not a User. Re-reading
    // /auth/me is what returns the whole signed-in user, so the caller can put
    // it straight into state and every screen sees the edit at once.
    return me();
  }
}
