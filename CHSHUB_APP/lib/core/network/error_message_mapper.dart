import 'package:dio/dio.dart';

/// Converts any exception (DioException, server error responses, etc.)
/// into a short, user-friendly message safe to show in the UI.
class ErrorMessageMapper {
  static String map(Object error) {
    if (error is DioException) {
      return _fromDioException(error);
    }
    return 'Something went wrong. Please try again.';
  }

  /// Whether this error represents a lack of internet/connectivity
  /// (as opposed to a server-side or validation error).
  static bool isConnectivityError(Object error) {
    if (error is! DioException) return false;
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return true;
    }
    if (error.type == DioExceptionType.unknown) {
      final msg = error.message?.toLowerCase() ?? '';
      return msg.contains('socket') ||
          msg.contains('network') ||
          msg.contains('failed host lookup');
    }
    return false;
  }

  static String _fromDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionError:
        return 'No internet connection. Please check your network and try again.';
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'The connection timed out. Please try again.';
      case DioExceptionType.badCertificate:
        return 'Couldn\'t establish a secure connection. Please try again.';
      case DioExceptionType.cancel:
        return 'Request was cancelled.';
      case DioExceptionType.badResponse:
        return _fromStatusCode(error.response?.statusCode);
      case DioExceptionType.unknown:
        final msg = error.message?.toLowerCase() ?? '';
        if (msg.contains('socket') ||
            msg.contains('network') ||
            msg.contains('failed host lookup')) {
          return 'No internet connection. Please check your network and try again.';
        }
        return 'Something went wrong. Please try again.';
    }
  }

  static String _fromStatusCode(int? statusCode) {
    if (statusCode == null) {
      return 'Something went wrong. Please try again.';
    }
    if (statusCode == 400) {
      return 'That request could not be processed. Please check your input and try again.';
    }
    if (statusCode == 401) {
      return 'Your session has expired. Please log in again.';
    }
    if (statusCode == 403) {
      return 'You don\'t have permission to perform this action.';
    }
    if (statusCode == 404) {
      return 'The requested information could not be found.';
    }
    if (statusCode == 409) {
      return 'This action could not be completed due to a conflict. Please refresh and try again.';
    }
    if (statusCode >= 500) {
      return 'Our servers are having trouble right now. Please try again later.';
    }
    return 'Something went wrong. Please try again.';
  }
}
