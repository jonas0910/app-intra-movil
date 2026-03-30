import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../errors/failures.dart';

/// Global navigator key for unauthorized redirects
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Centralized Dio HTTP client with interceptors for auth, error handling.
class DioClient {
  static Dio? _dio;

  static Future<Dio> getInstance() async {
    if (_dio != null) return _dio!;
    _dio = await _createDio();
    return _dio!;
  }

  /// Force recreating the Dio instance (useful after server URL change)
  static Future<Dio> recreateInstance() async {
    _dio = await _createDio();
    return _dio!;
  }

  static Future<Dio> _createDio() async {
    final serverUrl = await AppConfig.getServerUrl();

    final dio = Dio(BaseOptions(
      baseUrl: serverUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ));

    dio.interceptors.add(_AuthInterceptor());
    dio.interceptors.add(_ErrorInterceptor());

    return dio;
  }
}

/// Injects the Bearer token into each request
class _AuthInterceptor extends Interceptor {
  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await AppConfig.getToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}

/// Catches API errors and maps to app failures
class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // Clear session and redirect to login
      await AppConfig.clearSession();
      handler.reject(DioException(
        requestOptions: err.requestOptions,
        error: UnauthorizedFailure(),
        type: DioExceptionType.badResponse,
        response: err.response,
      ));
      return;
    }

    if (err.response?.statusCode == 422) {
      final data = err.response?.data;
      final message = data is Map ? (data['message'] ?? 'Error de validación') : 'Error de validación';
      handler.reject(DioException(
        requestOptions: err.requestOptions,
        error: ValidationFailure(message.toString(), errors: data is Map ? data.cast<String, dynamic>() : null),
        type: DioExceptionType.badResponse,
        response: err.response,
      ));
      return;
    }

    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError) {
      handler.reject(DioException(
        requestOptions: err.requestOptions,
        error: NetworkFailure(),
        type: err.type,
      ));
      return;
    }

    handler.next(err);
  }
}
