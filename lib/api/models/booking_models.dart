class BookShiftResponse {
  const BookShiftResponse({
    required this.success,
    this.message,
  });

  final bool success;
  final String? message;

  factory BookShiftResponse.fromJson(Map<String, dynamic> json) {
    return BookShiftResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String?,
    );
  }
}

class MyBookingsResponse {
  const MyBookingsResponse({
    required this.success,
    this.bookings = const [],
    this.message,
  });

  final bool success;
  final List<LocumBooking> bookings;
  final String? message;

  factory MyBookingsResponse.fromJson(Map<String, dynamic> json) {
    final raw = json['bookings'];
    return MyBookingsResponse(
      success: json['success'] as bool? ?? false,
      bookings: raw is List
          ? raw
              .whereType<Map<String, dynamic>>()
              .map(LocumBooking.fromJson)
              .toList()
          : const [],
      message: json['message'] as String?,
    );
  }
}

String _bookingJsonString(dynamic value) {
  if (value == null) return '';
  if (value is String) return value;
  if (value is num) return value.toString();
  return value.toString();
}

num? _bookingJsonNumNullable(dynamic value) {
  if (value == null) return null;
  if (value is num) return value;
  if (value is String) return num.tryParse(value.trim());
  return null;
}

class LocumBooking {
  const LocumBooking({
    required this.bookingId,
    required this.status,
    this.bookedAt,
    required this.shiftId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.location,
    required this.payRate,
    required this.locumRole,
    this.pharmacyName,
    this.travelDistance,
  });

  final int bookingId;
  final String status;
  final String? bookedAt;
  final int shiftId;
  final DateTime date;
  final String startTime;
  final String endTime;
  final String location;
  final String payRate;
  final String locumRole;
  final String? pharmacyName;
  final num? travelDistance;

  factory LocumBooking.fromJson(Map<String, dynamic> json) {
    return LocumBooking(
      bookingId: (json['booking_id'] as num).toInt(),
      status: (json['status'] as String? ?? '').toLowerCase(),
      bookedAt: json['booked_at'] as String?,
      shiftId: (json['shift_id'] as num).toInt(),
      date: DateTime.parse(json['date'] as String).toLocal(),
      startTime: json['start_time'] as String? ?? '',
      endTime: json['end_time'] as String? ?? '',
      location: json['location'] as String? ?? '',
      payRate: json['pay_rate'] as String? ?? '',
      locumRole: json['locum_role'] as String? ?? '',
      pharmacyName: _bookingJsonString(json['pharmacy_name']).isEmpty
          ? null
          : _bookingJsonString(json['pharmacy_name']),
      travelDistance: _bookingJsonNumNullable(json['travel_distance']),
    );
  }

  /// Local calendar day of the shift (ignores time-of-day for range filters).
  DateTime get shiftDay =>
      DateTime(date.year, date.month, date.day);

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
    return '${weekdays[d.weekday - 1]} ${d.day} ${months[d.month - 1]}';
  }

  String get formattedTimeRange {
    String trim(String t) {
      final parts = t.split(':');
      if (parts.length >= 2) {
        return '${parts[0]}:${parts[1]}';
      }
      return t;
    }

    return '${trim(startTime)} - ${trim(endTime)}';
  }

  String get formattedPayRate => '£ $payRate/hr';

  bool get isConfirmed => status == 'confirmed';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';

  String get displayRole {
    final r = locumRole.trim().toLowerCase();
    if (r.isEmpty) return '—';
    if (r == 'pharmacist') return 'Pharmacist';
    if (r == 'dispenser') return 'Dispenser';
    if (r == 'technician') return 'Technician';
    return r[0].toUpperCase() + r.substring(1);
  }

  String get displayPharmacyName {
    final name = pharmacyName?.trim() ?? '';
    return name.isEmpty ? '' : name;
  }

  /// API `travel_distance` (miles).
  String? get formattedTravelDistance {
    final miles = travelDistance;
    if (miles == null) return null;
    if (miles == 0) return 'Same location';
    return '$miles miles';
  }
}
