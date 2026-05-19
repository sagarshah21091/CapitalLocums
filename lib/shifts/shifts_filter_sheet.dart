import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../brand_colors.dart';
import '../env/app_env.dart';
import '../register/register_location_autocomplete.dart';
import '../register/register_location_provider.dart';
import 'shifts_providers.dart';

/// Applied filters for GET `/shifts`.
class ShiftsSearchFilters {
  const ShiftsSearchFilters({
    this.location = '',
    this.latitude,
    this.longitude,
    this.date,
    this.minPay = '',
  });

  final String location;
  final double? latitude;
  final double? longitude;
  final DateTime? date;
  final String minPay;

  String get apiDate {
    if (date == null) return '';
    final d = date!;
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }
}

String _formatFilterDate(DateTime d) {
  const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${weekdays[d.weekday - 1]}, ${d.day} ${months[d.month - 1]} ${d.year}';
}

Future<ShiftsSearchFilters?> showShiftsFilterSheet(
  BuildContext context, {
  required ShiftsSearchFilters initial,
}) {
  return showModalBottomSheet<ShiftsSearchFilters>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => _ShiftsFilterSheet(initial: initial),
  );
}

class _ShiftsFilterSheet extends ConsumerStatefulWidget {
  const _ShiftsFilterSheet({required this.initial});

  final ShiftsSearchFilters initial;

  @override
  ConsumerState<_ShiftsFilterSheet> createState() => _ShiftsFilterSheetState();
}

class _ShiftsFilterSheetState extends ConsumerState<_ShiftsFilterSheet> {
  late final TextEditingController _locationController;
  late final TextEditingController _minPayController;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _locationController = TextEditingController(text: widget.initial.location);
    _minPayController = TextEditingController(text: widget.initial.minPay);
    _selectedDate = widget.initial.date;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final lat = widget.initial.latitude;
      final lng = widget.initial.longitude;
      final loc = widget.initial.location.trim();
      if (lat != null && lng != null && loc.isNotEmpty) {
        ref.read(shiftsSearchLocationProvider.notifier).setPick(
              PickedRegisterLocation(
                latitude: lat,
                longitude: lng,
                placeId: '',
                formattedAddress: loc,
              ),
            );
      }
    });
  }

  @override
  void dispose() {
    _locationController.dispose();
    _minPayController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _clearDate() => setState(() => _selectedDate = null);

  ShiftsSearchFilters? _buildFilters() {
    final locationText = _locationController.text.trim();
    final picked = ref.read(shiftsSearchLocationProvider);

    if (AppEnv.googleMapsApiKey.isNotEmpty &&
        locationText.isNotEmpty &&
        (picked == null || picked.formattedAddress.trim() != locationText)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Choose a location from the suggestions.'),
        ),
      );
      return null;
    }

    return ShiftsSearchFilters(
      location: locationText,
      latitude: picked?.latitude,
      longitude: picked?.longitude,
      date: _selectedDate,
      minPay: _minPayController.text.trim(),
    );
  }

  void _apply() {
    final filters = _buildFilters();
    if (filters == null) return;
    Navigator.pop(context, filters);
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final maxHeight = MediaQuery.sizeOf(context).height * 0.9;
    final dateLabel =
        _selectedDate == null ? 'Any date' : _formatFilterDate(_selectedDate!);

    return AnimatedPadding(
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Filter shifts',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                onPressed: _apply,
                icon: const Icon(Icons.search, color: BrandColors.primaryBlue),
                tooltip: 'Search',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'LOCATION',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 6),
          RegisterLocationAutocomplete(
            controller: _locationController,
            locationProvider: shiftsSearchLocationProvider,
            decoration: InputDecoration(
              hintText: 'Search by city or area',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'DATE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: _pickDate,
            borderRadius: BorderRadius.circular(8),
            child: InputDecorator(
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                filled: true,
                fillColor: Colors.grey.shade50,
                suffixIcon: _selectedDate != null
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: _clearDate,
                        tooltip: 'Clear date',
                      )
                    : const Icon(Icons.calendar_today_outlined, size: 20),
              ),
              child: Text(
                dateLabel,
                style: TextStyle(
                  fontSize: 15,
                  color: _selectedDate == null
                      ? Colors.grey.shade600
                      : Colors.black87,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'MIN PAY (£/hr)',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _minPayController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
            decoration: InputDecoration(
              hintText: 'e.g. 25',
              prefixText: '£ ',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
            onSubmitted: (_) => _apply(),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _apply,
            icon: const Icon(Icons.search),
            label: const Text('Search shifts'),
            style: FilledButton.styleFrom(
              backgroundColor: BrandColors.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
            ],
          ),
        ),
      ),
    );
  }
}
