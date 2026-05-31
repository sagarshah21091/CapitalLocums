import '../api/models/shift_models.dart';
import '../api/shifts_api.dart';

class ShiftsRepository {
  ShiftsRepository({ShiftsApi? api}) : _api = api ?? ShiftsApi();

  final ShiftsApi _api;

  Future<ShiftsListResponse> fetchShifts(ShiftsQuery query) async {
    late final ShiftsListResponse response;
    try {
      response = await _api.fetchShifts(query);
    } on ShiftsApiException catch (e) {
      throw ShiftsFailure(e.message);
    }

    if (!response.success) {
      throw ShiftsFailure(
        response.message?.trim().isNotEmpty == true
            ? response.message!.trim()
            : 'Could not load shifts.',
      );
    }
    return response;
  }

  Future<ShiftDetail> fetchShiftDetail(int shiftId) async {
    late final ShiftDetailResponse response;
    try {
      response = await _api.fetchShiftDetail(shiftId);
    } on ShiftsApiException catch (e) {
      throw ShiftsFailure(e.message);
    }

    if (!response.success || response.shift == null) {
      throw ShiftsFailure(
        response.message?.trim().isNotEmpty == true
            ? response.message!.trim()
            : 'Could not load shift details.',
      );
    }
    final shift = response.shift!;
    if (shift.id != shiftId) {
      throw ShiftsFailure(
        'Shift data mismatch (expected id $shiftId, received ${shift.id}).',
      );
    }
    return shift;
  }
}

class ShiftsFailure implements Exception {
  ShiftsFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
