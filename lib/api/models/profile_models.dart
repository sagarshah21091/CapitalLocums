int _jsonInt(dynamic value, {int fallback = 0}) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim()) ?? fallback;
  return fallback;
}

num _jsonNum(dynamic value, {num fallback = 0}) {
  if (value == null) return fallback;
  if (value is num) return value;
  if (value is String) return num.tryParse(value.trim()) ?? fallback;
  return fallback;
}

double _jsonDouble(dynamic value, {double fallback = 0}) {
  if (value == null) return fallback;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value.trim()) ?? fallback;
  return fallback;
}

ProfileCoordinates? _parseCoordinates(dynamic raw) {
  if (raw is! Map<String, dynamic>) return null;
  final x = raw['x'];
  final y = raw['y'];
  if (x == null || y == null) return null;
  return ProfileCoordinates(x: _jsonDouble(x), y: _jsonDouble(y));
}

class ProfileResponse {
  const ProfileResponse({required this.success, this.data, this.message});

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
  const ProfilePayload({this.user, this.profile, this.documents = const []});

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
    this.lastName = '',
    required this.email,
    required this.role,
    this.address = '',
    this.city = '',
    this.zipCode = '',
    this.dob = '',
    this.gender = '',
    this.qualificationDate = '',
    this.independentPrescriber = '',
    this.refName1 = '',
    this.refPhoneNumber1 = '',
    this.refDetails1 = '',
    this.refName2 = '',
    this.refPhoneNumber2 = '',
    this.refDetails2 = '',
  });

  final int id;
  final String name;
  final String lastName;
  final String email;
  final String role;
  final String address;
  final String city;
  final String zipCode;
  final String dob;
  final String gender;
  final String qualificationDate;
  final String independentPrescriber;
  final String refName1;
  final String refPhoneNumber1;
  final String refDetails1;
  final String refName2;
  final String refPhoneNumber2;
  final String refDetails2;

  String get fullName {
    final parts = [name.trim(), lastName.trim()].where((p) => p.isNotEmpty);
    return parts.join(' ');
  }

  factory ProfileUser.fromJson(Map<String, dynamic> json) {
    return ProfileUser(
      id: _jsonInt(json['id']),
      name: json['name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? '',
      address: json['address'] as String? ?? '',
      city: json['city'] as String? ?? '',
      zipCode: json['zip_code'] as String? ?? '',
      dob: json['dob'] as String? ?? json['date_of_birth'] as String? ?? '',
      gender: json['gender'] as String? ?? '',
      qualificationDate: json['qualification_date'] as String? ?? '',
      independentPrescriber: json['independent_prescriber']?.toString() ?? '',
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
      x: _jsonDouble(json['x']),
      y: _jsonDouble(json['y']),
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
    this.address = '',
    this.city = '',
    this.zipCode = '',
    this.dob = '',
    this.gender = '',
    this.qualificationDate = '',
    this.independentPrescriber = '',
    this.approvalStatus = '',
    this.approvalReason,
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
  final String address;
  final String city;
  final String zipCode;
  final String dob;
  final String gender;
  final String qualificationDate;
  final String independentPrescriber;
  final String approvalStatus;
  final String? approvalReason;
  final String? createdAt;
  final String? updatedAt;
  final ProfileCoordinates? coordinates;

  static String formatIndependentPrescriber(String raw) {
    final s = raw.trim().toLowerCase();
    if (s == '1' || s == 'yes' || s == 'true') return 'Yes';
    if (s == '0' || s == 'no' || s == 'false') return 'No';
    if (raw.isEmpty) return '';
    return raw;
  }

  static String formatGender(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';
    final g = trimmed.toLowerCase();
    if (g == 'male') return 'Male';
    if (g == 'female') return 'Female';
    if (g == 'other') return 'Other';
    return trimmed[0].toUpperCase() +
        (trimmed.length > 1 ? trimmed.substring(1) : '');
  }

  /// Converts `dd/mm/yyyy` to `yyyy-MM-dd` for API; passes through ISO dates.
  static String dateToApi(String displayOrIso) {
    final t = displayOrIso.trim();
    if (t.isEmpty) return '';
    if (t.contains('/')) {
      final parts = t.split('/');
      if (parts.length == 3) {
        final day = parts[0].padLeft(2, '0');
        final month = parts[1].padLeft(2, '0');
        final year = parts[2];
        return '$year-$month-$day';
      }
    }
    try {
      final dt = DateTime.parse(t);
      final m = dt.month.toString().padLeft(2, '0');
      final day = dt.day.toString().padLeft(2, '0');
      return '${dt.year}-$m-$day';
    } catch (_) {
      return t.split('T').first;
    }
  }

  /// Supports `yyyy-MM-dd`, ISO datetimes, and `dd/mm/yyyy`.
  static String formatDobForDisplay(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return '';
    if (t.contains('/') && !t.contains('T')) return t;

    try {
      final dt = DateTime.parse(t);
      final day = dt.day.toString().padLeft(2, '0');
      final month = dt.month.toString().padLeft(2, '0');
      return '$day/$month/${dt.year}';
    } catch (_) {
      // Fall through to date-only parsing.
    }

    final dateOnly = t.split('T').first;
    final parts = dateOnly.split('-');
    if (parts.length == 3) {
      return '${parts[2]}/${parts[1]}/${parts[0]}';
    }
    return t;
  }

  factory ProfileDetails.fromJson(Map<String, dynamic> json) {
    return ProfileDetails(
      id: _jsonInt(json['id']),
      userId: _jsonInt(json['user_id']),
      phone: json['phone'] as String? ?? '',
      qualifications: json['qualifications'] as String? ?? '',
      experienceYears: _jsonInt(json['experience_years']),
      location: json['location'] as String? ?? '',
      latitude: json['latitude']?.toString(),
      longitude: json['longitude']?.toString(),
      travelDistance: _jsonNum(json['travel_distance']),
      locumRole: json['locum_role'] as String?,
      gphcNumber: json['gphc_number'] as String? ?? '',
      address: json['address'] as String? ?? '',
      city: json['city'] as String? ?? '',
      zipCode: json['zip_code'] as String? ?? '',
      dob: json['dob']?.toString() ?? json['date_of_birth']?.toString() ?? '',
      gender: json['gender'] as String? ?? '',
      qualificationDate: json['qualification_date']?.toString() ?? '',
      independentPrescriber: json['independent_prescriber']?.toString() ?? '',
      approvalStatus: json['approval_status']?.toString() ?? '',
      approvalReason: json['approval_reason']?.toString(),
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      coordinates: _parseCoordinates(json['coordinates']),
    );
  }

  /// PUT `/profile` responses may omit fields; keep existing values when missing.
  ProfileDetails mergeWith(ProfileDetails base) {
    String pick(String updated, String fallback) =>
        updated.trim().isNotEmpty ? updated.trim() : fallback;

    return ProfileDetails(
      id: id != 0 ? id : base.id,
      userId: userId != 0 ? userId : base.userId,
      phone: pick(phone, base.phone),
      qualifications: pick(qualifications, base.qualifications),
      experienceYears: experienceYears != 0
          ? experienceYears
          : base.experienceYears,
      location: pick(location, base.location),
      latitude: latitude ?? base.latitude,
      longitude: longitude ?? base.longitude,
      travelDistance: travelDistance != 0
          ? travelDistance
          : base.travelDistance,
      locumRole: locumRole ?? base.locumRole,
      gphcNumber: pick(gphcNumber, base.gphcNumber),
      address: pick(address, base.address),
      city: pick(city, base.city),
      zipCode: pick(zipCode, base.zipCode),
      dob: pick(dob, base.dob),
      gender: pick(gender, base.gender),
      qualificationDate: pick(qualificationDate, base.qualificationDate),
      independentPrescriber: pick(
        independentPrescriber,
        base.independentPrescriber,
      ),
      approvalStatus: pick(approvalStatus, base.approvalStatus),
      approvalReason: approvalReason ?? base.approvalReason,
      createdAt: createdAt ?? base.createdAt,
      updatedAt: updatedAt ?? base.updatedAt,
      coordinates: coordinates ?? base.coordinates,
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
      if (address.trim().isNotEmpty) 'address': address.trim(),
      if (city.trim().isNotEmpty) 'city': city.trim(),
      if (zipCode.trim().isNotEmpty) 'zip_code': zipCode.trim(),
      if (dob.trim().isNotEmpty) 'dob': dob.trim(),
      if (gender.trim().isNotEmpty) 'gender': gender.trim(),
      if (qualificationDate.trim().isNotEmpty)
        'qualification_date': qualificationDate.trim(),
      if (independentPrescriber.trim().isNotEmpty)
        'independent_prescriber': independentPrescriber.trim(),
      if (coords != null) 'coordinates': coords.toJson(),
    };
  }
}

class ProfileUpdateResponse {
  const ProfileUpdateResponse({required this.success, this.message, this.data});

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
      id: _jsonInt(json['id']),
      userId: _jsonInt(json['userId'] ?? json['user_id']),
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
      case 'dbs_check':
        return 'DBS Check';
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
