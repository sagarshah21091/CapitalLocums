import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

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
      final trimmed = token.trim();
      options.headers['Authorization'] = 'Bearer $trimmed';
      if (kDebugMode) {
        developer.log(
          'Authorization: Bearer $trimmed',
          name: 'CapitalLocums.Auth',
        );
      }
    }
    handler.next(options);
  }
}
