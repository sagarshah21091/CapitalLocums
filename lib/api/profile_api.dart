import 'package:dio/dio.dart';

import 'dio_factory.dart';
import 'dio_error_message.dart';
import 'models/profile_models.dart';

class ProfileApi {
  ProfileApi({Dio? dio}) : _dio = dio ?? createAppDio(attachAuth: true);

  final Dio _dio;

  /// GET `/profile` (requires Bearer token).
  Future<ProfileResponse> getProfile() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/profile');
      final data = response.data;
      if (data == null) {
        throw ProfileApiException('Empty response from server.');
      }
      return ProfileResponse.fromJson(data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw ProfileApiException(
          'Session expired. Please log in again.',
        );
      }
      throw ProfileApiException(messageFromDioException(e));
    } catch (e) {
      if (e is ProfileApiException) rethrow;
      throw ProfileApiException(e.toString());
    }
  }

  /// PUT `/profile` (requires Bearer token).
  Future<ProfileUpdateResponse> updateProfile(
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '/profile',
        data: body,
        options: Options(
          contentType: Headers.jsonContentType,
        ),
      );
      final data = response.data;
      if (data == null) {
        throw ProfileApiException('Empty response from server.');
      }
      return ProfileUpdateResponse.fromJson(data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw ProfileApiException(
          'Session expired. Please log in again.',
        );
      }
      throw ProfileApiException(messageFromDioException(e));
    } catch (e) {
      if (e is ProfileApiException) rethrow;
      throw ProfileApiException(e.toString());
    }
  }
}

class ProfileApiException implements Exception {
  ProfileApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
