import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:security_app/core/network/dio_provider.dart';
import 'package:security_app/core/network/token_provider.dart';
import 'package:security_app/data/api/api_service.dart';
import 'package:security_app/data/repositories/auth_impl.dart';
import 'package:security_app/domain/models/token_response.dart';


/// Provider for AuthViewModel
final authViewModelProvider =
    StateNotifierProvider<AuthViewModel, AsyncValue<void>>((ref) {
  final dio = ref.watch(dioProvider).value!;
  final authRepo = AuthImpl(ApiService(dio));
  return AuthViewModel(ref, authRepo);
});

class AuthViewModel extends StateNotifier<AsyncValue<void>> {
  final Ref ref;
  final AuthImpl authRepository;

  AuthViewModel(this.ref, this.authRepository)
      : super(const AsyncValue.data(null));

  /// Login function
  Future<String?> login(TokenResponse token) async {
    state = const AsyncValue.loading();

    try {
      // 🔹 Call API
      final result = await authRepository.createLogin(token); 
      // result should be TokenResponse

      // ✅ Save tokens to Riverpod + SecureStorage
      await ref
          .read(tokenProvider.notifier)
          .saveTokens(result.accessToken??"", result.refreshToken??"");

      state = const AsyncValue.data(null);
      return "sucesss"; // Return TokenResponse for UI navigation
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  

}

