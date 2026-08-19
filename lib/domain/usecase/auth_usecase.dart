import 'package:security_app/domain/models/token_response.dart';
import 'package:security_app/domain/repository/auth_repo.dart';

class AuthUsecase {
  final AuthRepository authRepository;

  AuthUsecase(this.authRepository);

  Future<TokenResponse> createLogin(TokenResponse token) {
    return authRepository.createLogin(token);
  }
  Future<TokenResponse> refreshAccessToken(TokenResponse refreshToken) {
    return authRepository.refreshAccessToken(refreshToken);
  }
  
}