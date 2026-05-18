import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Selected location from Google Places (stored locally for registration flow).
@immutable
class PickedRegisterLocation {
  const PickedRegisterLocation({
    required this.latitude,
    required this.longitude,
    required this.placeId,
    required this.formattedAddress,
  });

  final double latitude;
  final double longitude;
  final String placeId;

  /// Matches [PlaceDetailsResult.formatted_address]; used for form validation.
  final String formattedAddress;
}

class RegisterLocation extends Notifier<PickedRegisterLocation?> {
  @override
  PickedRegisterLocation? build() => null;

  void setPick(PickedRegisterLocation value) => state = value;

  void clear() => state = null;
}

final registerLocationProvider =
    NotifierProvider<RegisterLocation, PickedRegisterLocation?>(
  RegisterLocation.new,
);
