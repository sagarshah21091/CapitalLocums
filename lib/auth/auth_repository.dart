import '../api/api_constants.dart';
import '../api/auth_api.dart';
import '../api/models/forgot_password_models.dart';
import '../api/models/login_models.dart';
import 'token_storage.dart';

class AuthRepository {
  AuthRepository({AuthApi? api}) : _api = api ?? AuthApi();

  final AuthApi _api;

  /// Validates with the server, then stores the JWT on success.
  Future<LoginUser> login({
    required String email,
    required String password,
  }) async {
    final trimmedEmail = email.trim();
    late final LoginResponse response;
    try {
      response = await _api.login(
        LoginRequest(
          email: trimmedEmail,
          password: password,
          role: ApiConstants.locumRole,
        ),
      );
    } on AuthApiException catch (e) {
      throw AuthFailure(e.message);
    }

    if (!response.success || response.token == null || response.token!.isEmpty) {
      throw AuthFailure(
        response.message?.trim().isNotEmpty == true
            ? response.message!.trim()
            : 'Login failed. Please check your email and password.',
      );
    }

    final user = response.user;
    if (user == null) {
      throw AuthFailure('Login succeeded but user data was missing.');
    }
    if (!user.isActive) {
      throw AuthFailure('This account is not active. Please contact support.');
    }

    try {
      await TokenStorage.saveToken(response.token!);
    } on TokenSaveException catch (e) {
      throw AuthFailure(e.message);
    }
    return user;
  }

  /// POST `/auth/forgot-password`
  Future<String> forgotPassword({required String email}) async {
    late final ForgotPasswordResponse response;
    try {
      response = await _api.forgotPassword(
        ForgotPasswordRequest(email: email.trim()),
      );
    } on AuthApiException catch (e) {
      throw AuthFailure(e.message);
    }

    if (!response.success) {
      throw AuthFailure(
        response.message?.trim().isNotEmpty == true
            ? response.message!.trim()
            : 'Could not send reset link. Please try again.',
      );
    }

    final msg = response.message?.trim();
    return msg != null && msg.isNotEmpty
        ? msg
        : 'If email exists, reset link sent';
  }
}

class AuthFailure implements Exception {
  AuthFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
