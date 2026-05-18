import 'package:dio/dio.dart';

import 'api_constants.dart';
import 'api_debug_logging.dart';

/// Shared HTTP client for the Capital Locums API (JSON + multipart).
Dio createAppDio({
  Duration connectTimeout = const Duration(seconds: 20),
  Duration receiveTimeout = const Duration(seconds: 60),
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
  attachApiDebugLogging(dio);
  return dio;
}
