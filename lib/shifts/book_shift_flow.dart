import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../dashboard/bookings_repository.dart';
import '../dashboard/dashboard_providers.dart';

/// Shows confirm dialog, then POST `/bookings`. Returns `true` if booked.
Future<bool> confirmAndBookShift(
  BuildContext context,
  WidgetRef ref, {
  required int shiftId,
  String? details,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Book this shift?'),
      content: Text(
        details?.trim().isNotEmpty == true
            ? details!.trim()
            : 'Confirm you want to book this shift.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Book Now'),
        ),
      ],
    ),
  );

  if (confirmed != true || !context.mounted) return false;

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );

  try {
    final message =
        await ref.read(bookingsRepositoryProvider).bookShift(shiftId);
    if (!context.mounted) return false;
    Navigator.of(context, rootNavigator: true).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
    return true;
  } on BookingsFailure catch (e) {
    if (!context.mounted) return false;
    Navigator.of(context, rootNavigator: true).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.message)),
    );
    return false;
  } catch (e) {
    if (!context.mounted) return false;
    Navigator.of(context, rootNavigator: true).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.toString())),
    );
    return false;
  }
}
