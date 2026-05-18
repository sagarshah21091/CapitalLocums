import 'package:dio/dio.dart';

import '../auth/token_storage.dart';

/// Adds `Authorization: Bearer <token>` from [TokenStorage] when present.
class AuthInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await TokenStorage.readToken();
    if (token != null && token.trim().isNotEmpty) {
      options.headers['Authorization'] = 'Bearer ${token.trim()}';
    }
    handler.next(options);
  }
}
