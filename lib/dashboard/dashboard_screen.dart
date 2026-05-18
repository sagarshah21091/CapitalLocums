import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/models/booking_models.dart';
import 'bookings_repository.dart';
import 'dashboard_providers.dart';

/// Locum workspace dashboard — GET `/bookings/my`.
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  static const _pageBg = Color(0xFFF8F9FA);
  static const _cardBorder = Color(0xFFE8EAED);
  static const _titleNavy = Color(0xFF1A2B3C);
  static const _confirmedGreen = Color(0xFF2E9E4A);
  static const _completedBlue = Color(0xFF1E88E5);
  static const _cancelledRed = Color(0xFFE53935);

  bool _loading = true;
  String? _error;
  List<LocumBooking> _bookings = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await ref.read(bookingsRepositoryProvider).fetchMyBookings();
      if (!mounted) return;
      setState(() {
        _bookings = list;
        _loading = false;
      });
    } on BookingsFailure catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  DateTime get _today {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  List<LocumBooking> get _upcoming {
    final end = _today.add(const Duration(days: 7));
    return _bookings.where((b) {
      if (!b.isConfirmed) return false;
      final d = b.shiftDay;
      return !d.isBefore(_today) && !d.isAfter(end);
    }).toList()
      ..sort((a, b) => a.shiftDay.compareTo(b.shiftDay));
  }

  List<LocumBooking> get _history {
    return _bookings
        .where((b) => b.isCompleted || b.isCancelled)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  int get _confirmedCount => _bookings.where((b) => b.isConfirmed).length;
  int get _completedCount => _bookings.where((b) => b.isCompleted).length;
  int get _cancelledCount => _bookings.where((b) => b.isCancelled).length;

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const ColoredBox(
        color: _pageBg,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return ColoredBox(
        color: _pageBg,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.grey.shade600),
                const SizedBox(height: 16),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade800),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _load,
                  child: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ColoredBox(
      color: _pageBg,
      child: RefreshIndicator(
        onRefresh: _load,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 720;
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                _header(),
                const SizedBox(height: 20),
                _statsRow(wide),
                const SizedBox(height: 20),
                if (wide)
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: _upcomingPanel()),
                        const SizedBox(width: 16),
                        Expanded(child: _historyPanel()),
                      ],
                    ),
                  )
                else ...[
                  _upcomingPanel(),
                  const SizedBox(height: 16),
                  _historyPanel(),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _header() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'LOCUM WORKSPACE',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Dashboard',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: _titleNavy,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Manage and track your upcoming shifts and booking history.',
          style: TextStyle(fontSize: 14, height: 1.4, color: Colors.grey.shade700),
        ),
      ],
    );
  }

  Widget _statsRow(bool wide) {
    final cards = [
      _StatCard(
        label: 'CONFIRMED',
        count: _confirmedCount,
        color: _confirmedGreen,
        icon: Icons.check_circle_outline,
      ),
      _StatCard(
        label: 'COMPLETED',
        count: _completedCount,
        color: _completedBlue,
        icon: Icons.event_available_outlined,
      ),
      _StatCard(
        label: 'CANCELLED',
        count: _cancelledCount,
        color: _cancelledRed,
        icon: Icons.cancel_outlined,
      ),
      _StatCard(
        label: 'TOTAL BOOKINGS',
        count: _bookings.length,
        color: _titleNavy,
        icon: Icons.assignment_outlined,
      ),
    ];

    if (wide) {
      return Row(
        children: [
          for (var i = 0; i < cards.length; i++) ...[
            if (i > 0) const SizedBox(width: 12),
            Expanded(child: cards[i]),
          ],
        ],
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: cards[0]),
            const SizedBox(width: 12),
            Expanded(child: cards[1]),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: cards[2]),
            const SizedBox(width: 12),
            Expanded(child: cards[3]),
          ],
        ),
      ],
    );
  }

  Widget _upcomingPanel() {
    final upcoming = _upcoming;
    return _Panel(
      icon: Icons.calendar_month_outlined,
      title: 'Upcoming Shifts (Next 7 Days)',
      badge: upcoming.length,
      badgeColor: _confirmedGreen,
      child: upcoming.isEmpty
          ? _emptyState(
              icon: Icons.calendar_today_outlined,
              message: 'No upcoming shifts in the next 7 days',
            )
          : Column(
              children: [
                for (var i = 0; i < upcoming.length; i++) ...[
                  if (i > 0) const SizedBox(height: 12),
                  _BookingCard(booking: upcoming[i], variant: _BookingVariant.confirmed),
                ],
              ],
            ),
    );
  }

  Widget _historyPanel() {
    final history = _history;
    return _Panel(
      icon: Icons.history,
      title: 'Booking History',
      badge: history.length,
      badgeColor: Colors.grey.shade700,
      child: history.isEmpty
          ? _emptyState(
              icon: Icons.history,
              message: 'No booking history yet',
            )
          : Column(
              children: [
                for (var i = 0; i < history.length; i++) ...[
                  if (i > 0) const SizedBox(height: 12),
                  _BookingCard(
                    booking: history[i],
                    variant: history[i].isCancelled
                        ? _BookingVariant.cancelled
                        : _BookingVariant.completed,
                  ),
                ],
              ],
            ),
    );
  }

  Widget _emptyState({required IconData icon, required String message}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(icon, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });

  final String label;
  final int count;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _DashboardScreenState._cardBorder),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            right: 0,
            child: Icon(icon, color: color.withValues(alpha: 0.85), size: 22),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: color,
                  height: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.icon,
    required this.title,
    required this.badge,
    required this.badgeColor,
    required this.child,
  });

  final IconData icon;
  final String title;
  final int badge;
  final Color badgeColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _DashboardScreenState._cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 22, color: _DashboardScreenState._titleNavy),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _DashboardScreenState._titleNavy,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$badge',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

enum _BookingVariant { confirmed, completed, cancelled }

class _BookingCard extends StatelessWidget {
  const _BookingCard({required this.booking, required this.variant});

  final LocumBooking booking;
  final _BookingVariant variant;

  Color get _accent {
    switch (variant) {
      case _BookingVariant.confirmed:
        return _DashboardScreenState._confirmedGreen;
      case _BookingVariant.completed:
        return _DashboardScreenState._completedBlue;
      case _BookingVariant.cancelled:
        return _DashboardScreenState._cancelledRed;
    }
  }

  String get _statusLabel {
    switch (variant) {
      case _BookingVariant.confirmed:
        return 'CONFIRMED';
      case _BookingVariant.completed:
        return 'COMPLETED';
      case _BookingVariant.cancelled:
        return 'CANCELLED';
    }
  }

  String get _footerLabel {
    switch (variant) {
      case _BookingVariant.confirmed:
        return 'Upcoming shift';
      case _BookingVariant.completed:
        return 'Shift Completed';
      case _BookingVariant.cancelled:
        return 'Cancelled';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _DashboardScreenState._cardBorder),
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
                        color: _DashboardScreenState._titleNavy,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      booking.locumRole,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusBadge(label: _statusLabel, color: _accent),
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

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});

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
