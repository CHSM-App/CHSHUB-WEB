import 'package:society_app/domain/models/token_response.dart';
import 'package:society_app/domain/repository/auth_repository.dart';

class AuthUseCase {
  final AuthRepository authRepository;
  AuthUseCase(this.authRepository);

  Future<void> requestOtp(String mobile) {
    return authRepository.requestOtp(mobile);
  }
  Future<TokenResponse> login(TokenResponse token) {
    return authRepository.createLogin(token);
  }
  Future<TokenResponse> refreshAccessToken(TokenResponse refreshToken) {
    return authRepository.refreshAccessToken(refreshToken);
  }
    Future<TokenResponse> logout(TokenResponse refreshToken) {
      return authRepository.logout(refreshToken);
    }
}