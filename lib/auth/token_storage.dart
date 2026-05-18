import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the JWT returned by `/auth/login`.
class TokenStorage {
  TokenStorage._();

  static const _tokenKey = 'auth_token';

  static Future<void> saveToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
    } on PlatformException catch (e, st) {
      debugPrint('TokenStorage.saveToken: $e\n$st');
      throw TokenSaveException(
        'Could not save your login on this device. Try a full restart '
        '(stop the app and run again). If it persists, run '
        '`flutter clean` and rebuild.',
      );
    }
  }

  static Future<String?> readToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }
}

class TokenSaveException implements Exception {
  TokenSaveException(this.message);

  final String message;

  @override
  String toString() => message;
}
