import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'bookings_repository.dart';

final bookingsRepositoryProvider = Provider<BookingsRepository>((ref) {
  return BookingsRepository();
});
