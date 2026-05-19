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
    final raw = json['shift'];
    return ShiftDetailResponse(
      success: json['success'] as bool? ?? false,
      shift: raw is Map<String, dynamic> ? ShiftDetail.fromJson(raw) : null,
      message: json['message'] as String?,
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
  final String? createdAt;
  final String? updatedAt;

  factory ShiftDetail.fromJson(Map<String, dynamic> json) {
    return ShiftDetail(
      id: (json['id'] as num).toInt(),
      pharmacyId: (json['pharmacy_id'] as num?)?.toInt() ?? 0,
      date: DateTime.parse(json['date'] as String).toLocal(),
      startTime: json['start_time'] as String? ?? '',
      endTime: json['end_time'] as String? ?? '',
      location: json['location'] as String? ?? '',
      address: json['address'] as String? ?? '',
      latitude: json['latitude'] as String? ?? '',
      longitude: json['longitude'] as String? ?? '',
      payRate: json['pay_rate'] as String? ?? '',
      requiredLocums: (json['required_locums'] as num?)?.toInt() ?? 0,
      bookedLocumsCount: (json['booked_locums_count'] as num?)?.toInt() ?? 0,
      status: (json['status'] as String? ?? '').toLowerCase(),
      summary: json['summary'] as String? ?? '',
      locumRole: json['locum_role'] as String? ?? '',
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
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

  String get statusLabel => status.trim().toUpperCase();

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

  String get formattedTimeRange {
    String format(String t) {
      final parts = t.split(':');
      if (parts.length >= 3) {
        return '${parts[0]}:${parts[1]}:${parts[2]}';
      }
      if (parts.length >= 2) return '${parts[0]}:${parts[1]}:00';
      return t;
    }

    return '${format(startTime)} - ${format(endTime)}';
  }

  String get formattedPayRate => '$payRate / hour';
}
