import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../api/models/shift_models.dart';
import '../brand_colors.dart';
import 'book_shift_flow.dart';
import 'shifts_providers.dart';
import 'shifts_repository.dart';

/// Shift details — GET `/shifts/:id`.
class ShiftDetailScreen extends ConsumerStatefulWidget {
  const ShiftDetailScreen({
    super.key,
    required this.shiftId,
    this.initialIsBooked = false,
  });

  final int shiftId;

  /// From list API `is_booked` when navigating from [FindShiftsScreen].
  final bool initialIsBooked;

  @override
  ConsumerState<ShiftDetailScreen> createState() => _ShiftDetailScreenState();
}

class _ShiftDetailScreenState extends ConsumerState<ShiftDetailScreen> {
  static const _pageBg = Color(0xFFF8F9FA);
  static const _titleNavy = Color(0xFF1A2B3C);
  static const _openGreen = Color(0xFF2E9E4A);
  static const _openGreenBg = Color(0xFFE8F5E9);
  static const _cardBorder = Color(0xFFE8EAED);
  static const _labelGray = Color(0xFF6B7280);
  static const _noteBlueBg = Color(0xFFE3F2FD);

  late bool _isBooked;

  @override
  void initState() {
    super.initState();
    _isBooked = widget.initialIsBooked;
    if (kDebugMode) {
      developer.log(
        'ShiftDetailScreen initState: shiftId=${widget.shiftId}',
        name: 'CapitalLocums.Shifts',
      );
    }
  }

  @override
  void didUpdateWidget(ShiftDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.shiftId != widget.shiftId ||
        oldWidget.initialIsBooked != widget.initialIsBooked) {
      _isBooked = widget.initialIsBooked;
    }
  }

  bool _canBookNow(ShiftDetail shift) => shift.isOpen && !_isBooked;

  void _reloadShift() {
    ref.invalidate(shiftDetailProvider(widget.shiftId));
  }

  Future<void> _onBookNow(ShiftDetail shift) async {
    final details =
        '${shift.formattedHeaderDate}\n${shift.formattedDisplayTimeRange}\n${ShiftDetail.displayText(shift.location)}';
    final booked = await confirmAndBookShift(
      context,
      ref,
      shiftId: shift.id,
      details: details,
    );
    if (booked && mounted) {
      setState(() => _isBooked = true);
      _reloadShift();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        title: Text(
          kDebugMode ? 'Shift #${widget.shiftId}' : 'Shift Details',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: _titleNavy,
          ),
        ),
        centerTitle: false,
        backgroundColor: _pageBg,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final shiftAsync = ref.watch(shiftDetailProvider(widget.shiftId));

    return shiftAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.grey.shade600),
              const SizedBox(height: 16),
              Text(
                error is ShiftsFailure ? error.message : error.toString(),
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade800, fontSize: 15),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _reloadShift,
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      ),
      data: (shift) {
        if (kDebugMode) {
          developer.log(
            'Rendering shift: id=${shift.id}, location=${shift.location}, '
            'role=${shift.locumRole}, startTime=${shift.startTime}',
            name: 'CapitalLocums.Shifts',
          );
        }
        return _buildShiftContent(shift);
      },
    );
  }

  Widget _buildShiftContent(ShiftDetail shift) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(shift),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Shift Information',
            compact: true,
            child: _InfoWrap(
              spacing: 10,
              runSpacing: 12,
              items: [
                _InfoGridItem(
                  label: 'DATE',
                  value: shift.formattedCalendarDate,
                  icon: Icons.calendar_today_outlined,
                  iconColor: BrandColors.primaryBlue,
                ),
                _InfoGridItem(
                  label: 'TIME',
                  value: shift.formattedDisplayTimeRange,
                  icon: Icons.access_time,
                  iconColor: BrandColors.primaryBlue,
                ),
                _InfoGridItem(
                  label: 'LOCATION',
                  value: ShiftDetail.displayText(shift.location),
                  icon: Icons.location_on_outlined,
                  iconColor: const Color(0xFFE53935),
                ),
                _InfoGridItem(
                  label: 'POSITION',
                  value: ShiftDetail.displayText(shift.locumRole),
                  icon: Icons.person_outline,
                  iconColor: _openGreen,
                ),
                _InfoGridItem(
                  label: 'PAY RATE',
                  value: shift.formattedPayRate,
                  icon: Icons.currency_pound,
                  iconColor: const Color(0xFFFF9800),
                ),
                _InfoGridItem(
                  label: 'LUNCH BREAK',
                  value: shift.apiLunchBreakText,
                  icon: Icons.free_breakfast_outlined,
                  iconColor: const Color(0xFF37474F),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'About This Shift',
            compact: true,
            child: Text(
              ShiftDetail.displayText(shift.summary),
              style: TextStyle(
                fontSize: 14,
                height: 1.45,
                color: Colors.grey.shade800,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Pharmacy Information',
            titleIcon: Icons.store_outlined,
            titleIconColor: BrandColors.primaryBlue,
            compact: true,
            child: _CompactPharmacyInfo(shift: shift),
          ),
          const SizedBox(height: 12),
          _BookNowCard(
            canBook: _canBookNow(shift),
            isBooked: _isBooked,
            onBook: () => _onBookNow(shift),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ShiftDetail shift) {
    final distance = shift.apiDistanceLabel;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'SHIFT DETAILS',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: _labelGray,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    shift.formattedHeaderDate,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: _titleNavy,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ShiftDetail.displayText(shift.location),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade800,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ShiftDetail.displayText(shift.locumRole),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                      height: 1.35,
                    ),
                  ),
                  if (distance != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.directions_car_outlined,
                          size: 17,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          distance,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            _StatusBadge(label: shift.statusLabel, isOpen: shift.isOpen),
          ],
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.isOpen});

  final String label;
  final bool isOpen;

  @override
  Widget build(BuildContext context) {
    final color =
        isOpen ? _ShiftDetailScreenState._openGreen : Colors.grey.shade600;
    final bg =
        isOpen ? _ShiftDetailScreenState._openGreenBg : Colors.grey.shade100;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
          color: color,
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    this.titleIcon,
    this.titleIconColor,
    this.compact = false,
  });

  final String title;
  final Widget child;
  final IconData? titleIcon;
  final Color? titleIconColor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final pad = compact ? 14.0 : 18.0;
    final titleGap = compact ? 10.0 : 16.0;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(pad),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _ShiftDetailScreenState._cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (titleIcon != null) ...[
                Icon(
                  titleIcon,
                  size: compact ? 20 : 22,
                  color: titleIconColor ?? _ShiftDetailScreenState._titleNavy,
                ),
                const SizedBox(width: 8),
              ],
              Text(
                title,
                style: TextStyle(
                  fontSize: compact ? 16 : 17,
                  fontWeight: FontWeight.w700,
                  color: _ShiftDetailScreenState._titleNavy,
                ),
              ),
            ],
          ),
          SizedBox(height: titleGap),
          child,
        ],
      ),
    );
  }
}

class _InfoGridItem {
  const _InfoGridItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
}

/// Two-column wrap layout — cell height follows content.
class _InfoWrap extends StatelessWidget {
  const _InfoWrap({
    required this.items,
    this.spacing = 12,
    this.runSpacing = 14,
  });

  final List<_InfoGridItem> items;
  final double spacing;
  final double runSpacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cellWidth = (constraints.maxWidth - spacing) / 2;
        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: [
            for (final item in items)
              SizedBox(
                width: cellWidth,
                child: _InfoGridCell(item: item, compact: true),
              ),
          ],
        );
      },
    );
  }
}

class _InfoGridCell extends StatelessWidget {
  const _InfoGridCell({
    required this.item,
    this.compact = false,
  });

  final _InfoGridItem item;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final labelSize = compact ? 9.5 : 10.0;
    final valueSize = compact ? 13.0 : 14.0;
    final gap = compact ? 4.0 : 6.0;
    final iconSize = compact ? 18.0 : 20.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(item.icon, size: iconSize, color: item.iconColor),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                item.label,
                style: TextStyle(
                  fontSize: labelSize,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: _ShiftDetailScreenState._labelGray,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: gap),
        Text(
          item.value,
          style: TextStyle(
            fontSize: valueSize,
            fontWeight: FontWeight.w600,
            color: _ShiftDetailScreenState._titleNavy,
            height: 1.25,
          ),
        ),
      ],
    );
  }
}

class _CompactPharmacyInfo extends StatelessWidget {
  const _CompactPharmacyInfo({required this.shift});

  final ShiftDetail shift;

  @override
  Widget build(BuildContext context) {
    final rows = <_CompactRow>[
      _CompactRow(
        label: 'PHARMACY NAME',
        value: shift.displayPharmacyName,
        icon: Icons.business_outlined,
        iconColor: BrandColors.primaryBlue,
      ),
      _CompactRow(
        label: 'CONTACT PERSON',
        value: shift.displayContactPerson,
        icon: Icons.person_outline,
        iconColor: _ShiftDetailScreenState._openGreen,
      ),
      _CompactRow(
        label: 'PHONE NUMBER',
        value: shift.displayPhoneNumber,
        icon: Icons.phone_outlined,
        iconColor: BrandColors.primaryBlue,
      ),
      _CompactRow(
        label: 'ADDRESS',
        value: shift.displayPharmacyAddress,
        icon: Icons.location_on_outlined,
        iconColor: const Color(0xFFE53935),
      ),
      _CompactRow(
        label: 'LICENSE NUMBER',
        value: shift.displayLicenseNumber,
        icon: Icons.badge_outlined,
        iconColor: const Color(0xFF37474F),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          _CompactPharmacyRow(row: rows[i]),
        ],
      ],
    );
  }
}

class _CompactRow {
  const _CompactRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
}

class _CompactPharmacyRow extends StatelessWidget {
  const _CompactPharmacyRow({required this.row});

  final _CompactRow row;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(row.icon, size: 17, color: row.iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                row.label,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                  color: _ShiftDetailScreenState._labelGray,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                row.value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _ShiftDetailScreenState._titleNavy,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BookNowCard extends StatelessWidget {
  const _BookNowCard({
    required this.canBook,
    required this.isBooked,
    required this.onBook,
  });

  final bool canBook;
  final bool isBooked;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _ShiftDetailScreenState._cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'READY TO WORK?',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: _ShiftDetailScreenState._titleNavy,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isBooked
                ? 'You have already booked this shift.'
                : 'Book this shift now to secure your position at the pharmacy.',
            style: TextStyle(
              fontSize: 14,
              height: 1.45,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: canBook ? onBook : null,
              icon: const Icon(Icons.calendar_month_outlined, size: 20),
              label: Text(
                isBooked ? 'Booked' : 'Book Now',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: canBook
                    ? BrandColors.primaryBlue
                    : Colors.grey.shade400,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          if (!isBooked) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _ShiftDetailScreenState._noteBlueBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.description_outlined,
                    size: 20,
                    color: BrandColors.primaryBlue.withValues(alpha: 0.9),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Note: Once booked, you'll be notified with pharmacy "
                      'details and further instructions.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: Colors.blue.shade900.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
