import 'package:dio/dio.dart';

import 'dio_factory.dart';
import 'dio_error_message.dart';
import 'models/booking_models.dart';

class BookingsApi {
  BookingsApi({Dio? dio}) : _dio = dio ?? createAppDio(attachAuth: true);

  final Dio _dio;

  /// GET `/bookings/my`
  Future<MyBookingsResponse> fetchMyBookings() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/bookings/my');
      final data = response.data;
      if (data == null) {
        throw BookingsApiException('Empty response from server.');
      }
      return MyBookingsResponse.fromJson(data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw BookingsApiException('Session expired. Please log in again.');
      }
      throw BookingsApiException(messageFromDioException(e));
    } catch (e) {
      if (e is BookingsApiException) rethrow;
      throw BookingsApiException(e.toString());
    }
  }
}

class BookingsApiException implements Exception {
  BookingsApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
