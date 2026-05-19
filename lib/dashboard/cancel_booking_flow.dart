import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'bookings_repository.dart';
import 'dashboard_providers.dart';

/// Confirm dialog, then PATCH `/bookings/:id/cancel`. Returns `true` if cancelled.
Future<bool> confirmAndCancelBooking(
  BuildContext context,
  WidgetRef ref, {
  required int bookingId,
  String? details,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Cancel this shift?'),
      content: Text(
        details?.trim().isNotEmpty == true
            ? details!.trim()
            : 'Are you sure you want to cancel this booking?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Keep booking'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFE53935),
          ),
          child: const Text('Cancel shift'),
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
        await ref.read(bookingsRepositoryProvider).cancelBooking(bookingId);
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
