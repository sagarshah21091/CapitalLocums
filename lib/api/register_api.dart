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
    required String lastName,
    required String email,
    required String password,
    String? location,
    double? latitude,
    double? longitude,
    String? phone,
    required String qualifications,
    required int experienceYears,
    required String locumRole,
    required double travelDistanceMiles,
    String? gphcNumber,
    String? address,
    String? city,
    String? zipCode,
    required String dateOfBirth,
    required String gender,
    required String qualificationDate,
    String? independentPrescriber,
    required bool agreedPharmacistTerms,
    required bool agreedPrivacyPolicy,
    XFile? passport,
    XFile? nationalInsurance,
    List<XFile> qualificationCertificates = const [],
    required String professionalReference1Name,
    required String professionalReference1Phone,
    required String professionalReference1Details,
    required String professionalReference2Name,
    required String professionalReference2Phone,
    required String professionalReference2Details,
    XFile? visaWorkPermit,
    XFile? dbsCheck,
  }) async {
    final formData = FormData();

    void addField(String key, String value) {
      formData.fields.add(MapEntry(key, value));
    }

    void addOptionalField(String key, String? value) {
      final trimmed = value?.trim() ?? '';
      if (trimmed.isNotEmpty) addField(key, trimmed);
    }

    addField('name', name.trim());
    addField('last_name', lastName.trim());
    addField('email', email.trim());
    addField('password', password);
    addField('role', 'locum');
    addOptionalField('location', location);
    if (location?.trim().isNotEmpty == true &&
        latitude != null &&
        longitude != null) {
      addField('latitude', '$latitude');
      addField('longitude', '$longitude');
    }
    addOptionalField('phone', phone);
    addField('qualifications', qualifications.trim());
    addField('experience_years', '$experienceYears');
    addField('locum_role', locumRole.trim().toLowerCase());
    addField('travel_distance', '$travelDistanceMiles');
    final gphc = gphcNumber?.trim() ?? '';
    if (gphc.isNotEmpty) {
      addField('gphc_number', gphc);
    }
    addOptionalField('address', address);
    addOptionalField('city', city);
    addOptionalField('zip_code', zipCode);
    addField('dob', dateOfBirth.trim());
    addField('gender', gender.trim().toLowerCase());
    addField('qualification_date', qualificationDate.trim());
    if (independentPrescriber != null && independentPrescriber.trim().isNotEmpty) {
      addField('independent_prescriber', independentPrescriber.trim());
    }
    // addField('agreed_pharmacist_terms', agreedPharmacistTerms ? 'true' : 'false');
    // addField('agreed_privacy_policy', agreedPrivacyPolicy ? 'true' : 'false');
    addField('ref_Name_1', professionalReference1Name.trim());
    addField('ref_PhoneNumber_1', professionalReference1Phone.trim());
    addField(
      'ref_Details_1',
      professionalReference1Details.trim(),
    );
    addField('ref_Name_2', professionalReference2Name.trim());
    addField('ref_PhoneNumber_2', professionalReference2Phone.trim());
    addField(
      'ref_Details_2',
      professionalReference2Details.trim(),
    );

    Future<void> addFile(String field, XFile file) async {
      final prepared = await prepareRegisterAttachmentForUpload(file);
      formData.files.add(MapEntry(field, await _multipartFromXFile(prepared)));
    }

    try {
      if (passport != null) {
        await addFile('passport', passport);
      }
      if (visaWorkPermit != null) {
        await addFile('visa_work_permit', visaWorkPermit);
      }
      if (nationalInsurance != null) {
        await addFile('national_insurance', nationalInsurance);
      }
      for (final cert in qualificationCertificates) {
        await addFile('qualification_certificates', cert);
      }
      if (dbsCheck != null) {
        await addFile('dbs_check', dbsCheck);
      }

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
  final name = await resolveRegisterMultipartFilename(file);
  final rawPath = file.path;
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
