import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'token_storage.dart';

enum AuthSessionStatus {
  /// Not yet read from device storage.
  unknown,

  /// Valid token stored.
  authenticated,

  /// No token (logged out or never signed in).
  unauthenticated,
}

/// Whether the user should be treated as signed in for routing and API calls.
class AuthSession extends Notifier<AuthSessionStatus> {
  @override
  AuthSessionStatus build() => AuthSessionStatus.unknown;

  /// Loads persisted JWT from [TokenStorage] (call once at startup).
  Future<void> hydrate() async {
    try {
      final token = await TokenStorage.readToken();
      state = token != null && token.trim().isNotEmpty
          ? AuthSessionStatus.authenticated
          : AuthSessionStatus.unauthenticated;
    } catch (e, st) {
      debugPrint('AuthSession.hydrate failed: $e\n$st');
      state = AuthSessionStatus.unauthenticated;
    }
  }

  void markAuthenticated() => state = AuthSessionStatus.authenticated;

  Future<void> logout() async {
    await TokenStorage.clearToken();
    state = AuthSessionStatus.unauthenticated;
  }
}

final authSessionProvider =
    NotifierProvider<AuthSession, AuthSessionStatus>(AuthSession.new);
