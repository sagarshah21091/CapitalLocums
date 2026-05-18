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
}
