import '../models/auth_requests.dart';
import '../models/token_response.dart';
import '../models/user.dart';

abstract class AuthRepository {
  Future<TokenResponse> login(String username, String password);
  Future<TokenResponse> refreshAccessToken(TokenResponse refreshToken);
  Future<void> logout(String refreshToken);
  Future<User> me();
  Future<void> forgotPassword(ForgotPasswordRequest request);
  Future<void> changePassword(ChangePasswordRequest request);
}
