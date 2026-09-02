import 'package:society_app/data/api/api_service.dart';

import 'package:society_app/domain/models/token_response.dart';
import '../../domain/repository/auth_repository.dart';

class AuthImpl implements AuthRepository {
  final ApiService apiService;

  AuthImpl(this.apiService);

  @override
  Future<void> requestOtp(String mobile) {
    return apiService.requestOtp({"mobile": mobile});
  }

  @override
  Future<TokenResponse> createLogin(TokenResponse token) {
    return apiService.createLogin(token);
  }

  @override
  Future<TokenResponse>refreshAccessToken(TokenResponse refreshToken) {
    return apiService.refreshAccessToken(refreshToken);
  }
  
  @override
  Future<TokenResponse> logout(TokenResponse refreshToken) {
   return apiService.logout(refreshToken);
  }


  
}