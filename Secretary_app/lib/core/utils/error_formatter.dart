import 'package:dio/dio.dart';

/// Maps a thrown object to a sentence worth putting in front of a user.
///
/// Without this a DioException reaches the UI and renders as
/// "DioException [connection error]: ...". Mapping happens once, here, so every
/// ViewModel stores an already-readable string.
String formatError(Object error) {
  if (error is DioException) {
    // EnvelopeInterceptor puts the API's own message in `error` when the body
    // carried one — that beats anything we could infer from the status code.
    final apiMessage = error.error;
    if (apiMessage is String && apiMessage.isNotEmpty) return apiMessage;

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'The server took too long to respond. Please try again.';
      case DioExceptionType.connectionError:
        return 'Cannot reach the server. Check your internet connection.';
      case DioExceptionType.badResponse:
        final code = error.response?.statusCode;
        if (code == 401)
          return 'Your session has expired. Please log in again.';
        if (code == 403) return 'You do not have permission to do this.';
        if (code == 404) return 'Not found.';
        return 'Server error${code != null ? ' ($code)' : ''}.';
      case DioExceptionType.cancel:
        return 'Request cancelled.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
  return error.toString();
}
