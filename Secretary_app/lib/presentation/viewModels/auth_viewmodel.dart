import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/token_provider.dart';
import '../../core/storage/token_storage.dart';
import '../../core/utils/error_formatter.dart';
import '../../domain/models/user.dart';
import '../../domain/usecase/auth_usecase.dart';

class AuthState {
  final bool isLoading;
  final String? error;

  /// Set after a successful password change or reset.
  final bool passwordChanged;

  final User? user;

  const AuthState({
    this.isLoading = false,
    this.error,
    this.passwordChanged = false,
    this.user,
  });

  AuthState copyWith({
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool? passwordChanged,
    User? user,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      // Hand-written copyWith cannot tell "not passed" from "passed null", so
      // clearing is opt-in rather than something a null accidentally does.
      error: clearError ? null : (error ?? this.error),
      passwordChanged: passwordChanged ?? this.passwordChanged,
      user: user ?? this.user,
    );
  }
}

class AuthViewModel extends StateNotifier<AuthState> {
  final AuthUsecase usecase;
  final Ref ref;

  /// Guards against a double tap on Sign in firing two logins.
  bool _isSubmitting = false;

  AuthViewModel(this.usecase, this.ref) : super(const AuthState());

  /// Sign in, persist the tokens and the session values the screens read.
  Future<bool> login(String username, String password) async {
    if (_isSubmitting || state.isLoading) return false;
    _isSubmitting = true;
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final res = await usecase.login(username, password);

      final access = res.accessToken;
      final refresh = res.refreshToken;
      if (access == null || refresh == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'The server did not return a session. Please try again.',
        );
        return false;
      }

      await ref.read(tokenProvider.notifier).saveTokens(access, refresh);

      // State before cache, for the same reason loadMe does it: the tree
      // swaps to the app on these tokens, and it should not wait on storage.
      state = state.copyWith(isLoading: false, user: res.user);
      await _persistSession(res.user);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: formatError(e));
      return false;
    } finally {
      _isSubmitting = false;
    }
  }

  /// Revoke the refresh token server-side, then drop everything local.
  ///
  /// A failed revoke does not stop the local sign-out: leaving the user
  /// apparently signed in because the network was down would be worse than a
  /// token that expires on its own.
  Future<void> logout() async {
    final refresh = ref.read(tokenProvider).refreshToken;
    try {
      if (refresh != null && refresh.isNotEmpty) {
        await usecase.logout(refresh);
      }
    } catch (_) {
      // Intentionally ignored — see above.
    } finally {
      await ref.read(tokenProvider.notifier).clearTokens();
      state = const AuthState();
    }
  }

  /// Re-read the signed-in user; picks up a role or society change.
  Future<void> loadMe() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await usecase.me();
      // State first, cache second: the screens want the name now, and the
      // cache only matters on the next cold start.
      state = state.copyWith(isLoading: false, user: user);
      await _persistSession(user);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: formatError(e));
    }
  }

  /// Reset a forgotten password against the account's email address.
  ///
  /// Returning true means the request was accepted, *not* that the account
  /// exists — the server answers identically either way so the endpoint cannot
  /// be used to discover which addresses are registered. The UI must word its
  /// confirmation accordingly.
  Future<bool> forgotPassword(String email, String newPassword) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      passwordChanged: false,
    );
    try {
      await usecase.forgotPassword(email, newPassword);
      state = state.copyWith(isLoading: false, passwordChanged: true);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: formatError(e));
      return false;
    }
  }

  /// Change the password of the signed-in user.
  ///
  /// The API asks only for the new password — a valid access token is already
  /// proof of possession, and requiring the old one locked out anyone who had
  /// forgotten it.
  Future<bool> changePassword(String newPassword) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      passwordChanged: false,
    );
    try {
      await usecase.changePassword(newPassword);
      state = state.copyWith(isLoading: false, passwordChanged: true);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: formatError(e));
      return false;
    }
  }

  /// Load the cached session so the app bar can show the society name before
  /// any request completes.
  Future<void> loadFromStorage() async {
    final name = await TokenStorage.getValue(SessionKeys.name);
    final societyName = await TokenStorage.getValue(SessionKeys.societyName);
    final societyId = await TokenStorage.getValue(SessionKeys.societyId);
    final username = await TokenStorage.getValue(SessionKeys.username);

    if (name == null && societyName == null) return;

    state = state.copyWith(
      user: User(
        name: name,
        username: username,
        societyId: societyId,
        societyName: societyName,
      ),
    );
  }

  /// Caches the session values screens read before a request completes.
  ///
  /// Never allowed to fail the caller. Secure storage is a platform channel,
  /// and on a host without one — a widget test, or a browser where the plugin
  /// is unavailable — a write can throw or simply never complete. Awaiting it
  /// on the path that also sets `state.user` meant a storage problem left the
  /// app bar showing "Hello, there" with the real name already in hand.
  ///
  /// The cache is an optimisation: losing it costs a flash of defaults on the
  /// next cold start, not correctness.
  Future<void> _persistSession(User? user) async {
    if (user == null) return;

    final values = <String, String?>{
      SessionKeys.userId: user.userId?.toString(),
      SessionKeys.name: user.name,
      SessionKeys.username: user.username,
      SessionKeys.userTypeId: user.userTypeId?.toString(),
      SessionKeys.userType: user.userType,
      SessionKeys.societyId: user.societyId,
      SessionKeys.societyName: user.societyName,
      SessionKeys.email: user.email,
      SessionKeys.contactNo: user.contactNo,
    };

    try {
      await Future.wait([
        for (final entry in values.entries)
          if (entry.value != null)
            TokenStorage.saveValue(entry.key, entry.value!),
      ]).timeout(const Duration(seconds: 5));
    } catch (_) {
      // Intentionally swallowed — see above.
    }
  }

  void clearError() => state = state.copyWith(clearError: true);
}
