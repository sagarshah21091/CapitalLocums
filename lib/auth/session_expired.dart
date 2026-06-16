import 'package:dio/dio.dart';

import 'token_storage.dart';

typedef SessionExpiredLogoutCallback = Future<void> Function();

SessionExpiredLogoutCallback? sessionExpiredLogoutCallback;

bool _logoutInProgress = false;

/// True when the API returns 401 with a token/session expiry message.
bool isSessionExpiredResponse(DioException error) {
  if (error.response?.statusCode != 401) return false;

  final message = _responseMessage(error)?.toLowerCase() ?? '';
  if (message.contains('expired')) return true;

  final auth = error.requestOptions.headers['Authorization'];
  return auth != null && auth.toString().trim().isNotEmpty;
}

String? _responseMessage(DioException error) {
  final data = error.response?.data;
  if (data is Map) {
    final message = data['message'];
    if (message is String && message.trim().isNotEmpty) {
      return message.trim();
    }
    if (message is List && message.isNotEmpty) {
      final first = message.first;
      if (first != null && first.toString().trim().isNotEmpty) {
        return first.toString().trim();
      }
    }
    final err = data['error'];
    if (err is String && err.trim().isNotEmpty) {
      return err.trim();
    }
  }
  if (data is String && data.trim().isNotEmpty) {
    return data.trim();
  }
  return null;
}

/// Clears the session when the API reports an expired token.
Future<void> performSessionExpiredLogout() async {
  if (_logoutInProgress) return;
  _logoutInProgress = true;
  try {
    final callback = sessionExpiredLogoutCallback;
    if (callback != null) {
      await callback();
      return;
    }
    await TokenStorage.clearToken();
  } finally {
    _logoutInProgress = false;
  }
}
