import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../router/app_router.dart';
import 'book_shift_flow.dart';

import '../api/models/shift_models.dart';
import '../api/shifts_api.dart';
import '../profile/profile_providers.dart';
import '../register/register_location_provider.dart';
import 'shift_card.dart';
import 'shifts_filter_sheet.dart';
import 'shifts_providers.dart';
import 'shifts_repository.dart';

/// Find Shifts tab — GET `/shifts` with filters in bottom sheet (AppBar icon).
class FindShiftsScreen extends ConsumerStatefulWidget {
  const FindShiftsScreen({super.key});

  @override
  ConsumerState<FindShiftsScreen> createState() => _FindShiftsScreenState();
}

class _FindShiftsScreenState extends ConsumerState<FindShiftsScreen> {
  static const _pageBg = Color(0xFFF8F9FA);
  static const _pageLimit = 6;

  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  List<ShiftListing> _shifts = [];
  int _page = 1;
  int _totalPages = 1;
  ShiftsSearchFilters _filters = const ShiftsSearchFilters();
  bool _seededProfileLocation = false;

  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    await _seedLocationFromProfile();
    await _loadShifts(refresh: true);
  }

  Future<void> _seedLocationFromProfile() async {
    if (_seededProfileLocation) return;
    _seededProfileLocation = true;
    try {
      final payload =
          await ref.read(profileRepositoryProvider).fetchProfile();
      final profile = payload.profile;
      if (profile == null) return;

      final location = profile.location.trim();
      final lat =
          double.tryParse(profile.latitude ?? '') ?? profile.coordinates?.y;
      final lng =
          double.tryParse(profile.longitude ?? '') ?? profile.coordinates?.x;
      if (location.isEmpty || lat == null || lng == null) return;

      if (!mounted) return;
      ref.read(shiftsSearchLocationProvider.notifier).setPick(
            PickedRegisterLocation(
              latitude: lat,
              longitude: lng,
              placeId: '',
              formattedAddress: location,
            ),
          );
      setState(() {
        _filters = ShiftsSearchFilters(
          location: location,
          latitude: lat,
          longitude: lng,
        );
      });
    } catch (_) {
      // Optional default; user can set filters manually.
    }
  }

  void _onScroll() {
    if (_loading || _loadingMore || _page >= _totalPages) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      _loadShifts(refresh: false);
    }
  }

  ShiftsQuery _buildQuery({required int page}) {
    return ShiftsQuery(
      location: _filters.location,
      latitude: _filters.latitude,
      longitude: _filters.longitude,
      dateFrom: _filters.apiDateFrom,
      dateTo: _filters.apiDateTo,
      minPayRate: _filters.minPay,
      maxPayRate: _filters.maxPay,
      locumRole: _filters.apiLocumRole,
      page: page,
      limit: _pageLimit,
    );
  }

  Future<void> _loadShifts({required bool refresh}) async {
    if (refresh) {
      setState(() {
        _loading = true;
        _error = null;
        _page = 1;
      });
    } else {
      if (_loadingMore) return;
      setState(() => _loadingMore = true);
    }

    final nextPage = refresh ? 1 : _page + 1;

    try {
      final response = await ref.read(shiftsRepositoryProvider).fetchShifts(
            _buildQuery(page: nextPage),
          );
      if (!mounted) return;
      setState(() {
        if (refresh) {
          _shifts = response.shifts;
        } else {
          _shifts = [..._shifts, ...response.shifts];
        }
        _page = response.page;
        _totalPages = response.totalPages;
        _loading = false;
        _loadingMore = false;
        _error = null;
      });
    } on ShiftsFailure catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
        _loadingMore = false;
      });
    }
  }

  Future<void> _openFilterSheet() async {
    final result = await showShiftsFilterSheet(
      context,
      initial: _filters,
    );
    if (result == null || !mounted) return;
    setState(() => _filters = result);
    await _loadShifts(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(shiftsFilterOpenTriggerProvider, (prev, next) {
      if (next == (prev ?? 0)) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _openFilterSheet();
      });
    });

    return ColoredBox(
      color: _pageBg,
      child: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading && _shifts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _shifts.isEmpty) {
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
                onPressed: () => _loadShifts(refresh: true),
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadShifts(refresh: true),
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _shifts.isEmpty ? 1 : _shifts.length + (_loadingMore ? 1 : 0),
        separatorBuilder: (_, index) {
          if (_shifts.isEmpty) return const SizedBox.shrink();
          return const SizedBox(height: 12);
        },
        itemBuilder: (context, index) {
          if (_shifts.isEmpty) {
            return Padding(
              padding: const EdgeInsets.only(top: 48),
              child: Column(
                children: [
                  Icon(Icons.search_off, size: 56, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text(
                    'No shifts found',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Try adjusting your filters.',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _openFilterSheet,
                    icon: const Icon(Icons.tune),
                    label: const Text('Open filters'),
                  ),
                ],
              ),
            );
          }

          if (index >= _shifts.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final shift = _shifts[index];
          return ShiftCard(
            shift: shift,
            onViewDetails: () {
              context.push(
                AppRoute.shiftDetailPath(
                  shift.id,
                  isBooked: shift.alreadyBooked,
                ),
              );
            },
            onBookShift: () async {
              final details =
                  '${shift.formattedDate}\n${shift.formattedTimeRange}\n${shift.location}';
              final booked = await confirmAndBookShift(
                context,
                ref,
                shiftId: shift.id,
                details: details,
              );
              if (booked && mounted) {
                await _loadShifts(refresh: true);
              }
            },
          );
        },
      ),
    );
  }
}
