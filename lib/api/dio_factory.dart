import 'package:dio/dio.dart';

import 'api_constants.dart';
import 'api_debug_logging.dart';
import 'auth_interceptor.dart';
import 'session_expired_interceptor.dart';

/// Shared HTTP client for the Capital Locums API (JSON + multipart).
Dio createAppDio({
  Duration connectTimeout = const Duration(seconds: 20),
  Duration receiveTimeout = const Duration(seconds: 60),
  bool attachAuth = false,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: connectTimeout,
      receiveTimeout: receiveTimeout,
      headers: const {
        Headers.acceptHeader: Headers.jsonContentType,
      },
    ),
  );
  if (attachAuth) {
    dio.interceptors.add(AuthInterceptor());
    dio.interceptors.add(SessionExpiredInterceptor());
  }
  attachApiDebugLogging(dio);
  return dio;
}
