class ProfileResponse {
  const ProfileResponse({
    required this.success,
    this.data,
    this.message,
  });

  final bool success;
  final ProfilePayload? data;
  final String? message;

  factory ProfileResponse.fromJson(Map<String, dynamic> json) {
    final dataRaw = json['data'];
    return ProfileResponse(
      success: json['success'] as bool? ?? false,
      data: dataRaw is Map<String, dynamic>
          ? ProfilePayload.fromJson(dataRaw)
          : null,
      message: json['message'] as String?,
    );
  }
}

class ProfilePayload {
  const ProfilePayload({
    this.user,
    this.profile,
    this.documents = const [],
  });

  final ProfileUser? user;
  final ProfileDetails? profile;
  final List<ProfileDocument> documents;

  factory ProfilePayload.fromJson(Map<String, dynamic> json) {
    final docs = json['documents'];
    return ProfilePayload(
      user: json['user'] is Map<String, dynamic>
          ? ProfileUser.fromJson(json['user'] as Map<String, dynamic>)
          : null,
      profile: json['profile'] is Map<String, dynamic>
          ? ProfileDetails.fromJson(json['profile'] as Map<String, dynamic>)
          : null,
      documents: docs is List
          ? docs
              .whereType<Map<String, dynamic>>()
              .map(ProfileDocument.fromJson)
              .toList()
          : const [],
    );
  }
}

class ProfileUser {
  const ProfileUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.refName1 = '',
    this.refPhoneNumber1 = '',
    this.refDetails1 = '',
    this.refName2 = '',
    this.refPhoneNumber2 = '',
    this.refDetails2 = '',
  });

  final int id;
  final String name;
  final String email;
  final String role;
  final String refName1;
  final String refPhoneNumber1;
  final String refDetails1;
  final String refName2;
  final String refPhoneNumber2;
  final String refDetails2;

  factory ProfileUser.fromJson(Map<String, dynamic> json) {
    return ProfileUser(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? '',
      refName1: json['ref_Name_1'] as String? ?? '',
      refPhoneNumber1: json['ref_PhoneNumber_1'] as String? ?? '',
      refDetails1: json['ref_Details_1'] as String? ?? '',
      refName2: json['ref_Name_2'] as String? ?? '',
      refPhoneNumber2: json['ref_PhoneNumber_2'] as String? ?? '',
      refDetails2: json['ref_Details_2'] as String? ?? '',
    );
  }
}

class ProfileCoordinates {
  const ProfileCoordinates({required this.x, required this.y});

  /// Longitude.
  final double x;

  /// Latitude.
  final double y;

  factory ProfileCoordinates.fromJson(Map<String, dynamic> json) {
    return ProfileCoordinates(
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {'x': x, 'y': y};
}

class ProfileDetails {
  const ProfileDetails({
    required this.id,
    required this.userId,
    required this.phone,
    required this.qualifications,
    required this.experienceYears,
    required this.location,
    this.latitude,
    this.longitude,
    required this.travelDistance,
    this.locumRole,
    this.gphcNumber = '',
    this.createdAt,
    this.updatedAt,
    this.coordinates,
  });

  final int id;
  final int userId;
  final String phone;
  final String qualifications;
  final int experienceYears;
  final String location;
  final String? latitude;
  final String? longitude;
  final num travelDistance;
  final String? locumRole;
  final String gphcNumber;
  final String? createdAt;
  final String? updatedAt;
  final ProfileCoordinates? coordinates;

  factory ProfileDetails.fromJson(Map<String, dynamic> json) {
    final coordsRaw = json['coordinates'];
    return ProfileDetails(
      id: (json['id'] as num).toInt(),
      userId: (json['user_id'] as num).toInt(),
      phone: json['phone'] as String? ?? '',
      qualifications: json['qualifications'] as String? ?? '',
      experienceYears: (json['experience_years'] as num?)?.toInt() ?? 0,
      location: json['location'] as String? ?? '',
      latitude: json['latitude']?.toString(),
      longitude: json['longitude']?.toString(),
      travelDistance: json['travel_distance'] as num? ?? 0,
      locumRole: json['locum_role'] as String?,
      gphcNumber: json['gphc_number'] as String? ?? '',
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      coordinates: coordsRaw is Map<String, dynamic>
          ? ProfileCoordinates.fromJson(coordsRaw)
          : null,
    );
  }

  /// Body for `PUT /profile`.
  Map<String, dynamic> toJson() {
    final coords = coordinates;
    return {
      'id': id,
      'user_id': userId,
      'phone': phone,
      'qualifications': qualifications,
      'experience_years': experienceYears,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'travel_distance': travelDistance is int
          ? travelDistance
          : travelDistance.toDouble(),
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      'locum_role': locumRole,
      'gphc_number': gphcNumber,
      if (coords != null) 'coordinates': coords.toJson(),
    };
  }
}

class ProfileUpdateResponse {
  const ProfileUpdateResponse({
    required this.success,
    this.message,
    this.data,
  });

  final bool success;
  final String? message;
  final ProfileDetails? data;

  factory ProfileUpdateResponse.fromJson(Map<String, dynamic> json) {
    final dataRaw = json['data'];
    return ProfileUpdateResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String?,
      data: dataRaw is Map<String, dynamic>
          ? ProfileDetails.fromJson(dataRaw)
          : null,
    );
  }
}

class ProfileDocument {
  const ProfileDocument({
    required this.id,
    required this.userId,
    required this.docType,
    required this.documentName,
  });

  final int id;
  final int userId;
  final String docType;
  final String documentName;

  factory ProfileDocument.fromJson(Map<String, dynamic> json) {
    return ProfileDocument(
      id: (json['id'] as num).toInt(),
      userId: (json['userId'] as num?)?.toInt() ??
          (json['user_id'] as num?)?.toInt() ??
          0,
      docType: json['doc_type'] as String? ?? '',
      documentName: json['document_name'] as String? ?? '',
    );
  }

  String get displayTitle => titleForDocType(docType);

  static String titleForDocType(String docType) {
    switch (docType) {
      case 'passport':
        return 'Passport';
      case 'visa_work_permit':
        return 'Visa/Work permit';
      case 'national_insurance':
        return 'National insurance';
      case 'qualification_certificates':
        return 'Qualification certificates';
      case 'qualification_cert':
        return 'Qualification certificates';
      case 'professional_reference_1':
        return 'Professional reference 1';
      case 'professional_reference_2':
        return 'Professional reference 2';
      case 'professional_reference':
        return 'Professional reference';
      default:
        return docType.replaceAll('_', ' ');
    }
  }
}
