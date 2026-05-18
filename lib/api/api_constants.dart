import '../env/app_env.dart';

/// Capital Locums REST API — base URL from [.env] via [AppEnv.apiBaseUrl].
abstract final class ApiConstants {
  ApiConstants._();

  static String get baseUrl => AppEnv.apiBaseUrl;

  /// API role for locum sign-in (`/auth/login` request body).
  static const locumRole = 'locum';

  /// Base URL for uploaded document files (`document_name` is appended).
  static const documentUploadBaseUrl =
      'https://portal.capitallocums.co.uk/uploads/documents';

  static String documentUrl(String documentName) {
    final name = documentName.trim();
    if (name.isEmpty) return documentUploadBaseUrl;
    return '$documentUploadBaseUrl/$name';
  }
}
