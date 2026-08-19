import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:society_app/core/network/dio_provider.dart';
import 'package:society_app/presentation/providers/viewmodel_provider.dart';


class NetworkInterceptor extends Interceptor {
  final Ref ref;
  
  NetworkInterceptor(this.ref);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final networkState = ref.read(networkStateProvider);
    
   
    
    // Only block requests if we're sure there's no network
    if (networkState.isInitialized && !networkState.isConnected) {
      return handler.reject(
        DioException(
          requestOptions: options,
          message: 'No internet connection available',
          type: DioExceptionType.connectionError,
        ),
      );
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
   
    
    // Trigger network check on connection-related errors
    if (_isNetworkError(err)) {
      ref.read(networkStateProvider.notifier).checkConnection();
    } 
    // Trigger API health check on server errors
    else if (_isServerError(err)) {
      ref.read(apiStateProvider.notifier).checkApiHealth();
    }

    handler.next(err);
  }
  
  bool _isNetworkError(DioException err) {
    return err.type == DioExceptionType.connectionError ||
           err.type == DioExceptionType.connectionTimeout ||
           err.type == DioExceptionType.receiveTimeout ||
           err.type == DioExceptionType.sendTimeout ||
           (err.type == DioExceptionType.unknown && 
            err.message?.toLowerCase().contains('network') == true);
  }
  
  bool _isServerError(DioException err) {
    return err.response?.statusCode != null && 
           err.response!.statusCode! >= 500;
  }
}