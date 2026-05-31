import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'dio_factory.dart';
import 'dio_error_message.dart';
import 'models/shift_models.dart';

class ShiftsQuery {
  const ShiftsQuery({
    this.location = '',
    this.latitude,
    this.longitude,
    this.date = '',
    this.payRate = '',
    this.page = 1,
    this.limit = 6,
  });

  final String location;
  final double? latitude;
  final double? longitude;
  final String date;
  final String payRate;
  final int page;
  final int limit;

  Map<String, dynamic> toQueryParameters() {
    return {
      'location': location,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      'date': date,
      'pay_rate': payRate,
      'page': page,
      'limit': limit,
    };
  }
}

class ShiftsApi {
  ShiftsApi({Dio? dio}) : _dio = dio ?? createAppDio(attachAuth: true);

  final Dio _dio;

  /// GET `/shifts`
  Future<ShiftsListResponse> fetchShifts(ShiftsQuery query) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/shifts',
        queryParameters: query.toQueryParameters(),
      );
      final data = response.data;
      if (data == null) {
        throw ShiftsApiException('Empty response from server.');
      }
      return ShiftsListResponse.fromJson(data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw ShiftsApiException('Session expired. Please log in again.');
      }
      throw ShiftsApiException(messageFromDioException(e));
    } catch (e) {
      if (e is ShiftsApiException) rethrow;
      throw ShiftsApiException(e.toString());
    }
  }

  /// GET `/shifts/:id` — Bearer auth only (matches portal API).
  Future<ShiftDetailResponse> fetchShiftDetail(int shiftId) async {
    try {
      if (kDebugMode) {
        developer.log(
          'Fetching shift detail for id: $shiftId',
          name: 'CapitalLocums.Shifts',
        );
      }
      final response = await _dio.get<Map<String, dynamic>>('/shifts/$shiftId');
      final data = response.data;
      if (data == null) {
        throw ShiftsApiException('Empty response from server.');
      }
      if (kDebugMode) {
        final shift = data['shift'];
        if (shift is Map) {
          developer.log(
            'Shift response: id=${shift['id']}, location=${shift['location']}, '
            'locum_role=${shift['locum_role']}, start_time=${shift['start_time']}',
            name: 'CapitalLocums.Shifts',
          );
        }
      }
      return ShiftDetailResponse.fromJson(data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw ShiftsApiException('Session expired. Please log in again.');
      }
      if (e.response?.statusCode == 404) {
        throw ShiftsApiException('Shift not found.');
      }
      throw ShiftsApiException(messageFromDioException(e));
    } catch (e) {
      if (e is ShiftsApiException) rethrow;
      throw ShiftsApiException(e.toString());
    }
  }
}

class ShiftsApiException implements Exception {
  ShiftsApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
