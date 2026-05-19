import '../api/bookings_api.dart';
import '../api/models/booking_models.dart';

class BookingsRepository {
  BookingsRepository({BookingsApi? api}) : _api = api ?? BookingsApi();

  final BookingsApi _api;

  Future<List<LocumBooking>> fetchMyBookings() async {
    late final MyBookingsResponse response;
    try {
      response = await _api.fetchMyBookings();
    } on BookingsApiException catch (e) {
      throw BookingsFailure(e.message);
    }

    if (!response.success) {
      throw BookingsFailure(
        response.message?.trim().isNotEmpty == true
            ? response.message!.trim()
            : 'Could not load bookings.',
      );
    }
    return response.bookings;
  }

  Future<String> bookShift(int shiftId) async {
    late final BookShiftResponse response;
    try {
      response = await _api.bookShift(shiftId);
    } on BookingsApiException catch (e) {
      throw BookingsFailure(e.message);
    }

    if (!response.success) {
      throw BookingsFailure(
        response.message?.trim().isNotEmpty == true
            ? response.message!.trim()
            : 'Could not book this shift.',
      );
    }
    return response.message?.trim().isNotEmpty == true
        ? response.message!.trim()
        : 'Shift booked successfully';
  }

  Future<String> cancelBooking(int bookingId) async {
    late final BookShiftResponse response;
    try {
      response = await _api.cancelBooking(bookingId);
    } on BookingsApiException catch (e) {
      throw BookingsFailure(e.message);
    }

    if (!response.success) {
      throw BookingsFailure(
        response.message?.trim().isNotEmpty == true
            ? response.message!.trim()
            : 'Could not cancel this booking.',
      );
    }
    return response.message?.trim().isNotEmpty == true
        ? response.message!.trim()
        : 'Booking cancelled';
  }
}

class BookingsFailure implements Exception {
  BookingsFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
