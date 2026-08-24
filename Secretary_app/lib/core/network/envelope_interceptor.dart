import 'package:dio/dio.dart';

/// Unwraps the website API envelope.
///
/// backend/web/lib/http.js answers every call as either
///   `{ ok: true,  data: <payload> }`  or
///   `{ ok: false, error: { message, code, details } }`
/// while the mobile API (routes/) returns bare arrays. Retrofit's generated
/// code deserialises `response.data` directly, so without this the models would
/// all have to be written against the envelope instead of the payload.
///
/// Unwrapping here keeps `data/api/api_service.dart` declaring real types
/// (`Future<List<Bill>>`) and keeps the envelope out of every model.
class EnvelopeInterceptor extends Interceptor {
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final body = response.data;

    if (body is Map && body.containsKey('ok')) {
      if (body['ok'] == true) {
        response.data = body['data'];
      } else {
        // A failure that arrived with a 2xx status. Convert it to a DioException
        // so it lands in the same catch block as a 4xx/5xx.
        return handler.reject(
          DioException(
            requestOptions: response.requestOptions,
            response: response,
            type: DioExceptionType.badResponse,
            error: _messageFrom(body),
          ),
          true,
        );
      }
    }

    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Surface the API's own message rather than Dio's generic status text, so
    // `error_formatter` has something worth showing the user.
    final body = err.response?.data;
    if (body is Map && body['ok'] == false) {
      return handler.next(err.copyWith(error: _messageFrom(body)));
    }
    handler.next(err);
  }

  static String _messageFrom(Map body) {
    final error = body['error'];
    if (error is Map && error['message'] is String) {
      return error['message'] as String;
    }
    return 'Something went wrong';
  }
}
