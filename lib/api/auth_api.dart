import 'package:dio/dio.dart';

import 'dio_factory.dart';
import 'dio_error_message.dart';
import 'models/forgot_password_models.dart';
import 'models/login_models.dart';

class AuthApi {
  AuthApi({Dio? dio, Dio? authenticatedDio})
    : _dio = dio ?? createAppDio(),
      _authenticatedDio = authenticatedDio ?? createAppDio(attachAuth: true);

  final Dio _dio;
  final Dio _authenticatedDio;

  /// POST `/auth/login`
  Future<LoginResponse> login(LoginRequest body) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: body.toJson(),
        options: Options(contentType: Headers.jsonContentType),
      );
      final data = response.data;
      if (data == null) {
        throw AuthApiException('Empty response from server.');
      }
      return LoginResponse.fromJson(data);
    } on DioException catch (e) {
      throw AuthApiException(messageFromDioException(e));
    } catch (_) {
      throw AuthApiException('Unexpected response from server.');
    }
  }

  /// POST `/auth/forgot-password`
  Future<ForgotPasswordResponse> forgotPassword(
    ForgotPasswordRequest body,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/forgot-password',
        data: body.toJson(),
        options: Options(contentType: Headers.jsonContentType),
      );
      final data = response.data;
      if (data == null) {
        throw AuthApiException('Empty response from server.');
      }
      return ForgotPasswordResponse.fromJson(data);
    } on DioException catch (e) {
      throw AuthApiException(messageFromDioException(e));
    } catch (_) {
      throw AuthApiException('Unexpected response from server.');
    }
  }

  /// DELETE `/auth/account`
  Future<void> deleteAccount() async {
    try {
      await _authenticatedDio.delete<void>('/auth/account');
    } on DioException catch (e) {
      throw AuthApiException(messageFromDioException(e));
    } catch (_) {
      throw AuthApiException('Unexpected response from server.');
    }
  }
}

class AuthApiException implements Exception {
  AuthApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
