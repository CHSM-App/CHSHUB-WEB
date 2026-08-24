import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure storage is the source of truth on disk; TokenState (token_provider)
/// is the synchronous read cache the interceptor uses.
class TokenStorage {
  static const _accessTokenKey = 'ACCESS_TOKEN';
  static const _refreshTokenKey = 'REFRESH_TOKEN';

  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static Future<void> saveTokens(
    String accessToken,
    String refreshToken,
  ) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  static Future<Map<String, String>?> getTokens() async {
    final access = await _storage.read(key: _accessTokenKey);
    final refresh = await _storage.read(key: _refreshTokenKey);

    if (access != null && refresh != null) {
      return {'accessToken': access, 'refreshToken': refresh};
    }
    return null;
  }

  /// Generic values: name, username, society_id, society_name, user_type, ...
  static Future<void> saveValue(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  static Future<String?> getValue(String key) async {
    return await _storage.read(key: key);
  }

  static Future<void> deleteValue(String key) async {
    await _storage.delete(key: key);
  }

  static Future<void> clear() async {
    await _storage.deleteAll();
  }
}
