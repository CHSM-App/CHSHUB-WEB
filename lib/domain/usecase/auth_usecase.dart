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
  Future<void> changePassword(String newPassword) {
    return repository.changePassword(
      ChangePasswordRequest(newPassword: newPassword),
    );
  }
}
