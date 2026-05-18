import '../env/app_env.dart';

/// Capital Locums REST API — base URL from [.env] via [AppEnv.apiBaseUrl].
abstract final class ApiConstants {
  ApiConstants._();

  static String get baseUrl => AppEnv.apiBaseUrl;

  /// API role for locum sign-in (`/auth/login` request body).
  static const locumRole = 'locum';
}
