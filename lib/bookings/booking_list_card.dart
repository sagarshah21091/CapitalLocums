import 'package:flutter/material.dart';

import '../api/models/booking_models.dart';

enum BookingCardVariant { confirmed, completed, cancelled }

/// Booking row card (dashboard, my bookings).
class BookingListCard extends StatelessWidget {
  const BookingListCard({
    super.key,
    required this.booking,
    required this.variant,
    this.onCancel,
  });

  final LocumBooking booking;
  final BookingCardVariant variant;
  final VoidCallback? onCancel;

  static const _titleNavy = Color(0xFF1A2B3C);
  static const _cardBorder = Color(0xFFE8EAED);
  static const _confirmedGreen = Color(0xFF2E9E4A);
  static const _completedBlue = Color(0xFF1E88E5);
  static const _cancelledRed = Color(0xFFE53935);

  Color get _accent {
    switch (variant) {
      case BookingCardVariant.confirmed:
        return _confirmedGreen;
      case BookingCardVariant.completed:
        return _completedBlue;
      case BookingCardVariant.cancelled:
        return _cancelledRed;
    }
  }

  String get _statusLabel {
    switch (variant) {
      case BookingCardVariant.confirmed:
        return 'CONFIRMED';
      case BookingCardVariant.completed:
        return 'COMPLETED';
      case BookingCardVariant.cancelled:
        return 'CANCELLED';
    }
  }

  String get _footerLabel {
    switch (variant) {
      case BookingCardVariant.confirmed:
        return 'Upcoming shift';
      case BookingCardVariant.completed:
        return 'Shift Completed';
      case BookingCardVariant.cancelled:
        return 'Cancelled';
    }
  }

  static BookingCardVariant variantFor(LocumBooking booking) {
    if (booking.isCancelled) return BookingCardVariant.cancelled;
    if (booking.isCompleted) return BookingCardVariant.completed;
    return BookingCardVariant.confirmed;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.formattedDate,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _titleNavy,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      booking.displayRole,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              _BookingStatusBadge(label: _statusLabel, color: _accent),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.schedule, size: 18, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Text(
                booking.formattedTimeRange,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
              ),
              const Spacer(),
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.location_on_outlined,
                        size: 18, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        booking.location,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade800,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                booking.formattedPayRate,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: _accent,
                ),
              ),
              const Spacer(),
              if (variant == BookingCardVariant.confirmed && onCancel != null)
                TextButton(
                  onPressed: onCancel,
                  style: TextButton.styleFrom(
                    foregroundColor: _cancelledRed,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              else
                Text(
                  _footerLabel,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BookingStatusBadge extends StatelessWidget {
  const _BookingStatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            label == 'CANCELLED' ? Icons.close : Icons.check,
            size: 14,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
