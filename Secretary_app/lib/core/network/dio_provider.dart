import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/api/api_service.dart';
import '../../data/repositories/auth_impl.dart';
import '../constant.dart';
import 'envelope_interceptor.dart';
import 'interceptor.dart';

/// A bare, interceptor-free client used *by* TokenInterceptor to refresh.
///
/// Deliberately separate: if the refresh call went through the interceptor's
/// own Dio, a 401 on refresh would re-enter onError and recurse.
final authRepoProvider = Provider<AuthImpl>((ref) {
  final dio = Dio(BaseOptions(baseUrl: baseUrl))
    ..interceptors.add(EnvelopeInterceptor());
  return AuthImpl(ApiService(dio));
});

/// Plain Provider, not FutureProvider — nothing in the setup is async, so a
/// FutureProvider would only buy a `.value!` force-unwrap at every call site.
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );

  // Gated: LogInterceptor prints Authorization headers and full bodies, which
  // must not ship in a release build.
  if (kDebugMode) {
    dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
  }

  // Order matters. The envelope is unwrapped first so TokenInterceptor sees a
  // normal response, and so a 401 body's message survives to the formatter.
  dio.interceptors.add(EnvelopeInterceptor());
  dio.interceptors.add(
    TokenInterceptor(
      dio: dio,
      ref: ref,
      authRepository: ref.watch(authRepoProvider),
    ),
  );

  return dio;
});

final apiServiceProvider = Provider<ApiService>(
  (ref) => ApiService(ref.watch(dioProvider)),
);
