import 'package:dio/dio.dart';

import '../auth/session_expired.dart';

/// Logs the user out when an authenticated request returns 401 (expired token).
class SessionExpiredInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (isSessionExpiredResponse(err)) {
      performSessionExpiredLogout();
    }
    handler.next(err);
  }
}
