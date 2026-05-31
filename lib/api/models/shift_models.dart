String _shiftJsonString(dynamic value) {
  if (value == null) return '';
  if (value is String) return value;
  if (value is num) return value.toString();
  return value.toString();
}

int _shiftJsonInt(dynamic value, {int fallback = 0}) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim()) ?? fallback;
  return fallback;
}

num? _shiftJsonNumNullable(dynamic value) {
  if (value == null) return null;
  if (value is num) return value;
  if (value is String) return num.tryParse(value.trim());
  return null;
}

Map<String, dynamic>? _extractShiftPayload(Map<String, dynamic> json) {
  final shift = json['shift'];
  if (shift is Map<String, dynamic>) return shift;

  final data = json['data'];
  if (data is Map<String, dynamic>) {
    final nested = data['shift'];
    if (nested is Map<String, dynamic>) return nested;
    if (data['id'] != null) return data;
  }
  return null;
}

class ShiftsListResponse {
  const ShiftsListResponse({
    required this.success,
    this.shifts = const [],
    this.total = 0,
    this.page = 1,
    this.totalPages = 1,
    this.message,
  });

  final bool success;
  final List<ShiftListing> shifts;
  final int total;
  final int page;
  final int totalPages;
  final String? message;

  factory ShiftsListResponse.fromJson(Map<String, dynamic> json) {
    final raw = json['shifts'];
    return ShiftsListResponse(
      success: json['success'] as bool? ?? false,
      shifts: raw is List
          ? raw
              .whereType<Map<String, dynamic>>()
              .map(ShiftListing.fromJson)
              .toList()
          : const [],
      total: (json['total'] as num?)?.toInt() ?? 0,
      page: (json['page'] as num?)?.toInt() ?? 1,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 1,
      message: json['message'] as String?,
    );
  }
}

class ShiftListing {
  const ShiftListing({
    required this.id,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.location,
    required this.address,
    required this.payRate,
    required this.requiredLocums,
    required this.bookedLocumsCount,
    required this.availableSlots,
    required this.locumRole,
    required this.isBooked,
    required this.distanceKm,
    required this.distanceMiles,
  });

  final int id;
  final DateTime date;
  final String startTime;
  final String endTime;
  final String location;
  final String address;
  final String payRate;
  final int requiredLocums;
  final int bookedLocumsCount;
  final int availableSlots;
  final String locumRole;
  final int isBooked;
  final num distanceKm;
  final num distanceMiles;

  factory ShiftListing.fromJson(Map<String, dynamic> json) {
    return ShiftListing(
      id: (json['id'] as num).toInt(),
      date: DateTime.parse(json['date'] as String).toLocal(),
      startTime: json['start_time'] as String? ?? '',
      endTime: json['end_time'] as String? ?? '',
      location: json['location'] as String? ?? '',
      address: json['address'] as String? ?? '',
      payRate: json['pay_rate'] as String? ?? '',
      requiredLocums: (json['required_locums'] as num?)?.toInt() ?? 0,
      bookedLocumsCount: (json['booked_locums_count'] as num?)?.toInt() ?? 0,
      availableSlots: (json['available_slots'] as num?)?.toInt() ?? 0,
      locumRole: json['locum_role'] as String? ?? '',
      isBooked: (json['is_booked'] as num?)?.toInt() ?? 0,
      distanceKm: json['distance_km'] as num? ?? 0,
      distanceMiles: json['distance_miles'] as num? ?? 0,
    );
  }

  bool get alreadyBooked => isBooked == 1;

  String get displayRole {
    final r = locumRole.trim().toLowerCase();
    if (r.isEmpty) return '—';
    if (r == 'pharmacist') return 'Pharmacist';
    if (r == 'dispenser') return 'Dispenser';
    if (r == 'technician') return 'Technician';
    return r[0].toUpperCase() + r.substring(1);
  }

  String get formattedDate {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final d = date.toLocal();
    return '${weekdays[d.weekday - 1]}, ${d.day} ${months[d.month - 1]} ${d.year}';
  }

  String get formattedTimeRange {
    String trimTime(String t) {
      final parts = t.split(':');
      if (parts.length >= 2) return '${parts[0]}:${parts[1]}';
      return t;
    }

    return '${trimTime(startTime)} - ${trimTime(endTime)}';
  }

  String get formattedPayRate => payRate;

  String get capacityLabel => '$bookedLocumsCount/$requiredLocums';

  String get slotsLabel {
    final n = availableSlots;
    return n == 1 ? '1 Slot' : '$n Slots';
  }
}

class ShiftDetailResponse {
  const ShiftDetailResponse({
    required this.success,
    this.shift,
    this.message,
  });

  final bool success;
  final ShiftDetail? shift;
  final String? message;

  factory ShiftDetailResponse.fromJson(Map<String, dynamic> json) {
    final raw = _extractShiftPayload(json);
    return ShiftDetailResponse(
      success: json['success'] as bool? ?? false,
      shift: raw != null ? ShiftDetail.fromJson(raw) : null,
      message: _shiftJsonString(json['message']).isEmpty
          ? null
          : _shiftJsonString(json['message']),
    );
  }
}

class ShiftDetail {
  const ShiftDetail({
    required this.id,
    required this.pharmacyId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.location,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.payRate,
    required this.requiredLocums,
    required this.bookedLocumsCount,
    required this.status,
    required this.summary,
    required this.locumRole,
    this.lunchBreakMinutes,
    this.pharmacyName,
    this.contactPerson,
    this.phoneNumber,
    this.pharmacyAddress,
    this.pharmacyLocation,
    this.licenseNumber,
    this.distanceMiles,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final int pharmacyId;
  final DateTime date;
  final String startTime;
  final String endTime;
  final String location;
  final String address;
  final String latitude;
  final String longitude;
  final String payRate;
  final int requiredLocums;
  final int bookedLocumsCount;
  final String status;
  final String summary;
  final String locumRole;
  final int? lunchBreakMinutes;
  final String? pharmacyName;
  final String? contactPerson;
  final String? phoneNumber;
  final String? pharmacyAddress;
  final String? pharmacyLocation;
  final String? licenseNumber;
  final num? distanceMiles;
  final String? createdAt;
  final String? updatedAt;

  factory ShiftDetail.fromJson(Map<String, dynamic> json) {
    final pharmacy = json['pharmacy'];
    final pharmacyMap =
        pharmacy is Map<String, dynamic> ? pharmacy : null;

    String field(String snake, [String? camel, String? nestedKey]) {
      final top = _shiftJsonString(json[snake] ?? json[camel]);
      if (top.isNotEmpty) return top;
      if (pharmacyMap == null) return '';
      final fromPharmacy = _shiftJsonString(
        pharmacyMap[snake] ??
            pharmacyMap[camel] ??
            (nestedKey != null ? pharmacyMap[nestedKey] : null),
      );
      return fromPharmacy;
    }

    String? optionalField(String snake, [String? camel, String? nestedKey]) {
      final v = field(snake, camel, nestedKey);
      return v.isEmpty ? null : v;
    }

    final dateRaw = _shiftJsonString(json['date']);
    return ShiftDetail(
      id: _shiftJsonInt(json['id']),
      pharmacyId: _shiftJsonInt(json['pharmacy_id']),
      date: dateRaw.isNotEmpty
          ? DateTime.parse(dateRaw).toLocal()
          : DateTime.now(),
      startTime: _shiftJsonString(json['start_time'] ?? json['startTime']),
      endTime: _shiftJsonString(json['end_time'] ?? json['endTime']),
      location: _shiftJsonString(json['location']),
      address: _shiftJsonString(json['address']),
      latitude: _shiftJsonString(json['latitude']),
      longitude: _shiftJsonString(json['longitude']),
      payRate: _shiftJsonString(json['pay_rate'] ?? json['payRate']),
      requiredLocums: _shiftJsonInt(json['required_locums']),
      bookedLocumsCount: _shiftJsonInt(json['booked_locums_count']),
      status: _shiftJsonString(json['status']).toLowerCase(),
      summary: _shiftJsonString(json['summary']),
      locumRole: _shiftJsonString(json['locum_role'] ?? json['locumRole']),
      lunchBreakMinutes: _shiftJsonNumNullable(json['lunch_break_minutes'])
          ?.toInt(),
      pharmacyName: optionalField('pharmacy_name', 'pharmacyName', 'name'),
      contactPerson:
          optionalField('contact_person', 'contactPerson', 'contact_person'),
      phoneNumber: optionalField('phone_number', 'phoneNumber', 'phone'),
      pharmacyAddress:
          optionalField('pharmacy_address', 'pharmacyAddress', 'address'),
      pharmacyLocation:
          optionalField('pharmacy_location', 'pharmacyLocation'),
      licenseNumber:
          optionalField('license_number', 'licenseNumber', 'license_number'),
      distanceMiles: _shiftJsonNumNullable(
        json['distance_miles'] ?? json['distanceMiles'],
      ),
      createdAt: _shiftJsonString(json['created_at']).isEmpty
          ? null
          : _shiftJsonString(json['created_at']),
      updatedAt: _shiftJsonString(json['updated_at']).isEmpty
          ? null
          : _shiftJsonString(json['updated_at']),
    );
  }

  /// Non-empty API text or em dash.
  static String displayText(String value) {
    final v = value.trim();
    return v.isEmpty ? '—' : v;
  }

  /// API `start_time` and `end_time` as HH:mm (e.g. 15:12 - 19:12).
  String get formattedDisplayTimeRange {
    final start = _trimTimeToHm(startTime);
    final end = _trimTimeToHm(endTime);
    if (start.isEmpty && end.isEmpty) return '—';
    if (start.isEmpty) return end;
    if (end.isEmpty) return start;
    return '$start - $end';
  }

  static String _trimTimeToHm(String t) {
    final parts = t.trim().split(':');
    if (parts.length >= 2) return '${parts[0]}:${parts[1]}';
    return t.trim();
  }

  /// API `start_time` and `end_time` joined exactly as returned.
  String get apiTimeRange {
    if (startTime.isEmpty && endTime.isEmpty) return '—';
    if (startTime.isEmpty) return endTime;
    if (endTime.isEmpty) return startTime;
    return '$startTime - $endTime';
  }

  /// Header distance line from API `distance_miles`.
  String? get apiDistanceLabel {
    final miles = distanceMiles;
    if (miles == null) return null;
    if (miles == 0) return 'Same location';
    return '$miles miles away';
  }

  /// API `lunch_break_minutes` (e.g. 10 minutes, 32 minutes).
  String get apiLunchBreakText {
    final mins = lunchBreakMinutes;
    if (mins == null) return '—';
    return mins == 1 ? '1 minute' : '$mins minutes';
  }

  String get displayRole {
    final r = locumRole.trim().toLowerCase();
    if (r.isEmpty) return '—';
    return r;
  }

  String get displayRoleLabel {
    final r = displayRole;
    if (r == '—') return r;
    if (r == 'pharmacist') return 'Pharmacist';
    if (r == 'dispenser') return 'Dispenser';
    if (r == 'technician') return 'Technician';
    return r[0].toUpperCase() + r.substring(1);
  }

  String get statusLabel {
    if (status == 'open') return 'AVAILABLE';
    return status.trim().toUpperCase();
  }

  bool get isOpen => status == 'open';

  String get formattedHeaderDate {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final d = date.toLocal();
    return '${weekdays[d.weekday - 1]} ${d.day} ${months[d.month - 1]}';
  }

  String get formattedTimeRange => formattedDisplayTimeRange;

  String get formattedCalendarDate {
    final d = date.toLocal();
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    return '$day/$month/${d.year}';
  }

  String get formattedPayRate {
    final rate = payRate.trim();
    if (rate.isEmpty) return '—';
    final parsed = double.tryParse(rate);
    final display = parsed != null ? parsed.toStringAsFixed(2) : rate;
    return '£$display /hour';
  }

  String get displayPharmacyName => displayText(pharmacyName ?? '');
  String get displayContactPerson => displayText(contactPerson ?? '');
  String get displayPhoneNumber => displayText(phoneNumber ?? '');
  String get displayPharmacyAddress => displayText(pharmacyAddress ?? '');
  String get displayLicenseNumber => displayText(licenseNumber ?? '');
}
