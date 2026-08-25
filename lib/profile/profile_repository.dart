import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';

import '../api/api_constants.dart';
import '../api/models/profile_models.dart';
import '../api/profile_api.dart';

class ProfileRepository {
  ProfileRepository({ProfileApi? api}) : _api = api ?? ProfileApi();

  final ProfileApi _api;

  Future<ProfilePayload> fetchProfile() async {
    late final ProfileResponse response;
    try {
      response = await _api.getProfile();
    } on ProfileApiException catch (e) {
      throw ProfileFailure(e.message);
    }

    if (!response.success || response.data == null) {
      throw ProfileFailure(
        response.message?.trim().isNotEmpty == true
            ? response.message!.trim()
            : 'Could not load profile.',
      );
    }
    final data = response.data!;
    return data.withMessage(response.message ?? data.message);
  }

  Future<ProfileUpdateResponse> updateProfile(Map<String, dynamic> body) async {
    late final ProfileUpdateResponse response;
    try {
      response = await _api.updateProfile(body);
    } on ProfileApiException catch (e) {
      throw ProfileFailure(e.message);
    }

    if (!response.success) {
      throw ProfileFailure(
        response.message?.trim().isNotEmpty == true
            ? response.message!.trim()
            : 'Could not update profile.',
      );
    }

    if (response.data == null) {
      throw ProfileFailure('Profile updated but response data was missing.');
    }
    return response;
  }

  Future<ProfileDocumentsResponse> deleteDocument(int id) async {
    late final ProfileDocumentsResponse response;
    try {
      response = await _api.deleteDocument(id);
    } on ProfileApiException catch (e) {
      throw ProfileFailure(e.message);
    }
    return _validatedDocumentsResponse(
      response,
      fallbackMessage: 'Could not delete document.',
    );
  }

  Future<ProfileDocumentsResponse> uploadDocument({
    required String documentType,
    required XFile file,
  }) async {
    late final ProfileDocumentsResponse response;
    try {
      response = await _api.uploadDocument(
        documentType: documentType,
        file: file,
      );
    } on ProfileApiException catch (e) {
      throw ProfileFailure(e.message);
    }
    return _validatedDocumentsResponse(
      response,
      fallbackMessage: 'Could not upload document.',
    );
  }

  Future<Uint8List> downloadDocument(ProfileDocument document) async {
    try {
      return await _api.downloadDocument(
        ApiConstants.documentUrl(document.documentName),
      );
    } on ProfileApiException catch (e) {
      throw ProfileFailure(e.message);
    }
  }

  ProfileDocumentsResponse _validatedDocumentsResponse(
    ProfileDocumentsResponse response, {
    required String fallbackMessage,
  }) {
    if (!response.success) {
      throw ProfileFailure(
        response.message?.trim().isNotEmpty == true
            ? response.message!.trim()
            : fallbackMessage,
      );
    }
    return response;
  }
}

class ProfileFailure implements Exception {
  ProfileFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
