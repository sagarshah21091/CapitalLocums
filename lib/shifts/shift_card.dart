import 'package:flutter/material.dart';

import '../api/models/shift_models.dart';
import '../brand_colors.dart';

/// Shift list card matching Find Shifts reference design.
class ShiftCard extends StatelessWidget {
  const ShiftCard({
    super.key,
    required this.shift,
    this.onViewDetails,
    this.onBookShift,
  });

  final ShiftListing shift;
  final VoidCallback? onViewDetails;
  final VoidCallback? onBookShift;

  static const _titleNavy = Color(0xFF1A2B3C);
  static const _slotsGreen = Color(0xFF2E9E4A);
  static const _cardBorder = Color(0xFFE8EAED);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
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
                      if (shift.pharmacyName.trim().isNotEmpty) ...[
                        Text(
                          shift.pharmacyName.trim(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: _titleNavy,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                      Text(
                        shift.location,
                        style: TextStyle(
                          fontSize: shift.pharmacyName.trim().isNotEmpty
                              ? 14
                              : 16,
                          fontWeight: shift.pharmacyName.trim().isNotEmpty
                              ? FontWeight.w500
                              : FontWeight.w800,
                          color: shift.pharmacyName.trim().isNotEmpty
                              ? Colors.grey.shade700
                              : _titleNavy,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _slotsGreen,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    shift.slotsLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _RoleBadge(label: shift.displayRole),
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.calendar_today_outlined,
              iconColor: Colors.grey.shade600,
              text: shift.formattedDate,
              textColor: Colors.grey.shade700,
            ),
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.access_time,
              iconColor: BrandColors.primaryBlue,
              text: shift.formattedTimeRange,
              textColor: _titleNavy,
              fontWeight: FontWeight.w600,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  '£ ${shift.formattedPayRate}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _slotsGreen,
                  ),
                ),
                const Spacer(),
                Icon(Icons.people_outline, size: 18, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  shift.capacityLabel,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Divider(height: 1, color: Colors.grey.shade200),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: onViewDetails,
                    style: FilledButton.styleFrom(
                      backgroundColor: _titleNavy,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'View Details',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: shift.alreadyBooked ? null : onBookShift,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: BrandColors.primaryBlue,
                      side: BorderSide(color: Colors.grey.shade400),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      shift.alreadyBooked ? 'Booked' : 'Book Shift',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: BrandColors.primaryBlue,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person_outline, size: 14, color: Colors.white),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.iconColor,
    required this.text,
    required this.textColor,
    this.fontWeight,
  });

  final IconData icon;
  final Color iconColor;
  final String text;
  final Color textColor;
  final FontWeight? fontWeight;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: textColor,
              fontWeight: fontWeight,
            ),
          ),
        ),
      ],
    );
  }
}
