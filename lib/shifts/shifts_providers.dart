import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../register/register_location_provider.dart';
import 'shifts_repository.dart';

final shiftsRepositoryProvider = Provider<ShiftsRepository>((ref) {
  return ShiftsRepository();
});

/// Google Places pick for Find Shifts filter (separate from registration).
final shiftsSearchLocationProvider =
    NotifierProvider<RegisterLocation, PickedRegisterLocation?>(
  RegisterLocation.new,
);

class ShiftsFilterOpenTrigger extends Notifier<int> {
  @override
  int build() => 0;

  void open() => state++;
}

/// Incremented by shell filter button; [FindShiftsScreen] opens the filter sheet.
final shiftsFilterOpenTriggerProvider =
    NotifierProvider<ShiftsFilterOpenTrigger, int>(
  ShiftsFilterOpenTrigger.new,
);
