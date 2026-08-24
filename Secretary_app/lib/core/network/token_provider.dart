import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/token_storage.dart';

/// Keys for the non-token session data the website API hands back in
/// `data.user` at login. Persisted alongside the tokens so screens can read
/// the society name / user type without a network round trip.
class SessionKeys {
  static const userId = 'USER_ID';
  static const name = 'NAME';
  static const username = 'USERNAME';
  static const userTypeId = 'USER_TYPE_ID';
  static const userType = 'USER_TYPE';
  static const societyId = 'SOCIETY_ID';
  static const societyName = 'SOCIETY_NAME';
  static const email = 'EMAIL';
  static const contactNo = 'CONTACT_NO';
}

class TokenState {
  final String? accessToken;
  final String? refreshToken;
  final bool isLoading;

  const TokenState({
    this.accessToken,
    this.refreshToken,
    this.isLoading = true,
  });

  bool get isLoggedIn =>
      (accessToken?.isNotEmpty ?? false) && (refreshToken?.isNotEmpty ?? false);

  TokenState copyWith({
    String? accessToken,
    String? refreshToken,
    bool? isLoading,
  }) {
    return TokenState(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class TokenNotifier extends StateNotifier<TokenState> {
  TokenNotifier() : super(const TokenState());

  /// Hydrate from secure storage at boot.
  Future<void> loadTokens() async {
    final tokens = await TokenStorage.getTokens();
    state = TokenState(
      accessToken: tokens?['accessToken'],
      refreshToken: tokens?['refreshToken'],
      isLoading: false,
    );
  }

  Future<void> saveTokens(String accessToken, String refreshToken) async {
    state = TokenState(
      accessToken: accessToken,
      refreshToken: refreshToken,
      isLoading: false,
    );
    await TokenStorage.saveTokens(accessToken, refreshToken);
  }

  /// Clears tokens and every persisted session value — used on logout and on
  /// an unrecoverable 401.
  Future<void> clearTokens() async {
    state = const TokenState(isLoading: false);
    await TokenStorage.clear();
  }
}

final tokenProvider = StateNotifierProvider<TokenNotifier, TokenState>(
  (ref) => TokenNotifier(),
);
