
import '../models/token_response.dart';

abstract class AuthRepository {

  Future<void> requestOtp(String mobile);
  Future<TokenResponse> createLogin(TokenResponse token);
  Future<TokenResponse> refreshAccessToken(TokenResponse refreshToken);
   Future<TokenResponse> logout(TokenResponse refreshToken);
}
