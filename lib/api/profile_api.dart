import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:dio/dio.dart';

import 'dio_factory.dart';
import 'dio_error_message.dart';
import 'models/profile_models.dart';
import 'register_attachment_prepare.dart';

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
        throw ProfileApiException('Session expired. Please log in again.');
      }
      throw ProfileApiException(messageFromDioException(e));
    } catch (e) {
      if (e is ProfileApiException) rethrow;
      throw ProfileApiException(e.toString());
    }
  }

  /// PUT `/profile` (requires Bearer token).
  Future<ProfileUpdateResponse> updateProfile(Map<String, dynamic> body) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '/profile',
        data: body,
        options: Options(contentType: Headers.jsonContentType),
      );
      final data = response.data;
      if (data == null) {
        throw ProfileApiException('Empty response from server.');
      }
      return ProfileUpdateResponse.fromJson(data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw ProfileApiException('Session expired. Please log in again.');
      }
      throw ProfileApiException(messageFromDioException(e));
    } catch (e) {
      if (e is ProfileApiException) rethrow;
      throw ProfileApiException(e.toString());
    }
  }

  /// DELETE `/profile/documents/{id}` (requires Bearer token).
  Future<ProfileDocumentsResponse> deleteDocument(int id) async {
    try {
      final response = await _dio.delete<Map<String, dynamic>>(
        '/profile/documents/$id',
      );
      return _parseDocumentsResponse(response.data);
    } on DioException catch (e) {
      throw ProfileApiException(messageFromDioException(e));
    } catch (e) {
      if (e is ProfileApiException) rethrow;
      throw ProfileApiException(e.toString());
    }
  }

  /// POST `/profile/documents` multipart upload (requires Bearer token).
  Future<ProfileDocumentsResponse> uploadDocument({
    required String documentType,
    required XFile file,
  }) async {
    try {
      final prepared = await prepareRegisterAttachmentForUpload(file);
      final name = await resolveRegisterMultipartFilename(prepared);
      final path = prepared.path.trim();
      final multipart = path.isNotEmpty
          ? await MultipartFile.fromFile(path, filename: name)
          : MultipartFile.fromBytes(
              await prepared.readAsBytes(),
              filename: name,
            );
      final formData = FormData.fromMap({
        'doc_type': documentType,
        'document': multipart,
      });
      final response = await _dio.post<Map<String, dynamic>>(
        '/profile/documents',
        data: formData,
      );
      return _parseDocumentsResponse(response.data);
    } on DioException catch (e) {
      throw ProfileApiException(messageFromDioException(e));
    } catch (e) {
      if (e is ProfileApiException) rethrow;
      throw ProfileApiException(e.toString());
    }
  }

  /// Downloads a document using the authenticated HTTP client.
  Future<Uint8List> downloadDocument(String url) async {
    try {
      final response = await _dio.get<List<int>>(
        url,
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes = response.data;
      if (bytes == null || bytes.isEmpty) {
        throw ProfileApiException('The downloaded document was empty.');
      }
      return Uint8List.fromList(bytes);
    } on DioException catch (e) {
      throw ProfileApiException(messageFromDioException(e));
    } catch (e) {
      if (e is ProfileApiException) rethrow;
      throw ProfileApiException(e.toString());
    }
  }

  ProfileDocumentsResponse _parseDocumentsResponse(Map<String, dynamic>? data) {
    if (data == null) {
      throw ProfileApiException('Empty response from server.');
    }
    return ProfileDocumentsResponse.fromJson(data);
  }
}

class ProfileApiException implements Exception {
  ProfileApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
