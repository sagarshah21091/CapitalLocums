import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../api/models/shift_models.dart';
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
  static const _cardBorder = Color(0xFFE8EAED);

  bool _loading = true;
  String? _error;
  ShiftDetail? _shift;
  late bool _isBooked;

  @override
  void initState() {
    super.initState();
    _isBooked = widget.initialIsBooked;
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  bool _canBookNow(ShiftDetail shift) => shift.isOpen && !_isBooked;

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final shift = await ref
          .read(shiftsRepositoryProvider)
          .fetchShiftDetail(widget.shiftId);
      if (!mounted) return;
      setState(() {
        _shift = shift;
        _loading = false;
      });
    } on ShiftsFailure catch (e) {
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

  Future<void> _onBookNow(ShiftDetail shift) async {
    final details =
        '${shift.formattedHeaderDate}\n${shift.formattedTimeRange}\n${shift.location}';
    final booked = await confirmAndBookShift(
      context,
      ref,
      shiftId: shift.id,
      details: details,
    );
    if (booked && mounted) {
      setState(() => _isBooked = true);
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        title: const Text(
          'Shift Details',
          style: TextStyle(
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
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
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
                style: TextStyle(color: Colors.grey.shade800, fontSize: 15),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _load,
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }

    final shift = _shift!;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
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
                        shift.formattedHeaderDate,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: _titleNavy,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        shift.displayRole,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusBadge(label: shift.statusLabel, isOpen: shift.isOpen),
              ],
            ),
            const SizedBox(height: 20),
            _DetailRow(
              icon: Icons.access_time,
              text: shift.formattedTimeRange,
            ),
            const SizedBox(height: 12),
            _DetailRow(
              icon: Icons.location_on_outlined,
              text: shift.location,
            ),
            const SizedBox(height: 12),
            _DetailRow(
              icon: Icons.person_outline,
              text: shift.displayRole,
            ),
            const SizedBox(height: 12),
            _DetailRow(
              icon: Icons.currency_pound,
              text: shift.formattedPayRate,
            ),
            const SizedBox(height: 24),
            const Text(
              'Shift Description',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _titleNavy,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              shift.summary.trim().isEmpty ? '—' : shift.summary.trim(),
              style: TextStyle(
                fontSize: 14,
                height: 1.45,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed:
                    _canBookNow(shift) ? () => _onBookNow(shift) : null,
                style: TextButton.styleFrom(
                  foregroundColor: _titleNavy,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
                child: Text(
                  _isBooked ? 'Booked' : 'Book Now',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.isOpen});

  final String label;
  final bool isOpen;

  @override
  Widget build(BuildContext context) {
    final color = isOpen ? _ShiftDetailScreenState._openGreen : Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 1.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
          color: color,
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 22, color: Colors.grey.shade700),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade800,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}
