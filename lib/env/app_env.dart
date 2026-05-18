import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Local configuration from [.env] (gitignored — same file is kept when you switch branches).
///
/// First-time setup: `dart run tool/bootstrap_env.dart` or `cp .env.example .env`
/// Tracked template: [.env.example] (safe to commit).
abstract final class AppEnv {
  AppEnv._();

  static const _defaultApiBase = 'https://portal.capitallocums.co.uk/api';

  static Future<void> load() async {
    await dotenv.load(fileName: '.env', isOptional: true);
  }

  /// API origin (no trailing slash). Override with `API_BASE_URL` in `.env`.
  static String get apiBaseUrl {
    final v = dotenv.env['API_BASE_URL']?.trim();
    if (v != null && v.isNotEmpty) {
      return v.endsWith('/') ? v.substring(0, v.length - 1) : v;
    }
    return _defaultApiBase;
  }

  /// Google Maps / Places key for location autocomplete (optional until wired in UI).
  static String get googleMapsApiKey =>
      dotenv.env['GOOGLE_MAPS_API_KEY']?.trim() ?? '';

}
