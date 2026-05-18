import 'package:dio/dio.dart';
import 'package:cross_file/cross_file.dart';

import 'dio_factory.dart';
import 'dio_error_message.dart';
import 'models/register_models.dart';
import 'register_attachment_prepare.dart';

/// POST `/auth/register` — `multipart/form-data` per API schema.
class RegisterApi {
  RegisterApi({Dio? dio})
      : _dio = dio ??
            createAppDio(receiveTimeout: const Duration(seconds: 120));

  final Dio _dio;

  Future<RegisterResponse> register({
    required String name,
    required String email,
    required String password,
    required String location,
    required double latitude,
    required double longitude,
    required String phone,
    required String qualifications,
    required int experienceYears,
    required String locumRole,
    required double travelDistanceKm,
    required XFile passport,
    required XFile nationalInsurance,
    required XFile qualificationCert,
    required XFile professionalReference1,
    required XFile professionalReference2,
    XFile? visaWorkPermit,
  }) async {
    final formData = FormData();

    void addField(String key, String value) {
      formData.fields.add(MapEntry(key, value));
    }

    addField('name', name.trim());
    addField('email', email.trim());
    addField('password', password);
    addField('role', 'locum');
    addField('location', location.trim());
    addField('latitude', '$latitude');
    addField('longitude', '$longitude');
    addField('phone', phone.trim());
    addField('qualifications', qualifications.trim());
    addField('experience_years', '$experienceYears');
    addField('locum_role', locumRole.trim().toLowerCase());
    addField('travel_distance', '$travelDistanceKm');

    Future<void> addFile(String field, XFile file) async {
      final prepared = await prepareRegisterAttachmentForUpload(file);
      formData.files.add(MapEntry(field, await _multipartFromXFile(prepared)));
    }

    try {
      await addFile('passport', passport);
      if (visaWorkPermit != null) {
        await addFile('visa_work_permit', visaWorkPermit);
      }
      await addFile('national_insurance', nationalInsurance);
      await addFile('qualification_certificates', qualificationCert);
      await addFile('professional_reference_1', professionalReference1);
      await addFile('professional_reference_2', professionalReference2);

      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/register',
        data: formData,
      );

      final data = response.data;
      if (data == null) {
        throw RegisterApiException('Empty response from server.');
      }

      final parsed = RegisterResponse.fromJson(data);
      if (!parsed.success) {
        throw RegisterApiException(
          (parsed.message?.trim().isNotEmpty ?? false)
              ? parsed.message!.trim()
              : 'Registration failed.',
        );
      }
      return parsed;
    } on DioException catch (e) {
      throw RegisterApiException(messageFromDioException(e));
    } catch (e) {
      if (e is RegisterApiException) rethrow;
      throw RegisterApiException(e.toString());
    }
  }
}

Future<MultipartFile> _multipartFromXFile(XFile file) async {
  final rawPath = file.path;
  final name =
      file.name.trim().isNotEmpty ? file.name.trim() : 'upload.bin';
  final path = rawPath.trim();
  if (path.isNotEmpty) {
    return MultipartFile.fromFile(path, filename: name);
  }
  final bytes = await file.readAsBytes();
  return MultipartFile.fromBytes(bytes, filename: name);
}

class RegisterApiException implements Exception {
  RegisterApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
