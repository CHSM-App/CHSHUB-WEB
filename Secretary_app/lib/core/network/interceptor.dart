import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/auth_impl.dart';
import '../../domain/models/token_response.dart';
import 'auth_event_provider.dart';
import 'token_provider.dart';

/// Attaches the access token, and on a 401 refreshes once and replays the
/// failed request.
///
/// Two things this fixes relative to the Security app's version:
///  * concurrent 401s share one refresh (`_refreshing`) instead of firing N
///    parallel refreshes that race, where the last writer wins with an
///    already-rotated token;
///  * a 401 on the *replayed* request is not retried again (`_retriedKey`), so
///    a token the server keeps rejecting cannot loop.
class TokenInterceptor extends Interceptor {
  final Dio dio;
  final Ref ref;
  final AuthImpl authRepository;

  static const _retriedKey = '__retried';

  /// Non-null while a refresh is in flight; every concurrent 401 awaits it.
  Future<bool>? _refreshing;

  TokenInterceptor({
    required this.dio,
    required this.ref,
    required this.authRepository,
  });

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = ref.read(tokenProvider).accessToken;
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // No response at all means a network fault, not a token problem.
    if (err.response == null) return handler.next(err);
    if (err.response?.statusCode != 401) return handler.next(err);

    // Already replayed once — refreshing again would just loop.
    if (err.requestOptions.extra[_retriedKey] == true) {
      return handler.next(err);
    }

    if (await _refreshOnce()) {
      return _retryRequest(err, handler);
    }

    await ref.read(tokenProvider.notifier).clearTokens();
    _emitSessionExpired();
    return handler.next(err);
  }

  /// Collapses concurrent refreshes into a single in-flight call.
  Future<bool> _refreshOnce() {
    return _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);
  }

  Future<bool> _doRefresh() async {
    final refreshToken = ref.read(tokenProvider).refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) return false;

    try {
      final res = await authRepository.refreshAccessToken(
        TokenResponse(refreshToken: refreshToken),
      );

      final access = res.accessToken;
      final refresh = res.refreshToken;
      if (access == null ||
          access.isEmpty ||
          refresh == null ||
          refresh.isEmpty) {
        return false;
      }

      await ref.read(tokenProvider.notifier).saveTokens(access, refresh);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _retryRequest(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final reqOptions = err.requestOptions;
    reqOptions.extra[_retriedKey] = true;
    reqOptions.headers['Authorization'] =
        'Bearer ${ref.read(tokenProvider).accessToken}';

    try {
      handler.resolve(await dio.fetch(reqOptions));
    } catch (_) {
      handler.next(err);
    }
  }

  /// The network layer has no BuildContext, and reaching into a global
  /// navigatorKey from here would couple it to the widget tree. Emit an event
  /// instead; the root widget listens and routes to login.
  void _emitSessionExpired() {
    ref.read(authEventProvider.notifier).state = AuthEvent.sessionExpired;
  }
}
