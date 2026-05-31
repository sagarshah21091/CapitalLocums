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
    return response.data!;
  }

  Future<ProfileUpdateResponse> updateProfile(
    Map<String, dynamic> body,
  ) async {
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
}

class ProfileFailure implements Exception {
  ProfileFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
