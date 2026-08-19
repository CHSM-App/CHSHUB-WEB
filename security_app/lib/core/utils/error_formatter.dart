import 'package:dio/dio.dart';

/// Converts any caught error into a short, user-friendly message.
/// Never surfaces raw exception text (stack traces, DioException dumps,
/// server-generated HTML/JSON bodies) to the UI.
String getErrorMessage(Object error) {
  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return "The server is taking too long to respond. Please try again.";
      case DioExceptionType.connectionError:
        return "Unable to connect. Please check your internet connection.";
      case DioExceptionType.cancel:
        return "Request was cancelled.";
      case DioExceptionType.badCertificate:
        return "Couldn't establish a secure connection.";
      case DioExceptionType.badResponse:
        return _messageForStatusCode(error.response?.statusCode);
      case DioExceptionType.unknown:
        return "Something went wrong. Please try again.";
    }
  }
  return "Something went wrong. Please try again.";
}

String _messageForStatusCode(int? statusCode) {
  if (statusCode == null) return "Something went wrong. Please try again.";
  if (statusCode == 400) return "That request couldn't be processed. Please check your input.";
  if (statusCode == 401) return "Your session has expired. Please log in again.";
  if (statusCode == 403) return "You don't have permission to do that.";
  if (statusCode == 404) return "The requested information couldn't be found.";
  if (statusCode == 409) return "This action conflicts with existing data.";
  if (statusCode >= 500) return "The server is having trouble right now. Please try again later.";
  return "Something went wrong. Please try again.";
}
