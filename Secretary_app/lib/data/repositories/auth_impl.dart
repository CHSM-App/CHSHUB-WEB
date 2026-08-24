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

  @override
  Future<void> changePassword(ChangePasswordRequest request) {
    return apiService.changePassword(request);
  }
}
