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
    this.startDate,
    this.endDate,
    this.minPay = '',
    this.maxPay = '',
    this.positionType = allPositions,
  });

  static const allPositions = 'All Positions';

  static const positionTypes = [
    allPositions,
    'Pharmacist',
    'Technician',
    'Dispenser',
  ];

  final String location;
  final double? latitude;
  final double? longitude;
  final DateTime? startDate;
  final DateTime? endDate;
  final String minPay;
  final String maxPay;
  final String positionType;

  String _formatDate(DateTime? d) {
    if (d == null) return '';
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }

  String get apiDateFrom => _formatDate(startDate);

  String get apiDateTo => _formatDate(endDate);

  String get apiLocumRole {
    if (positionType == allPositions) return 'all';
    return positionType.toLowerCase();
  }

  /// Maps profile/register `locum_role` to a filter dropdown value.
  static String positionTypeFromProfileRole(String? apiRole) {
    switch (apiRole?.trim().toLowerCase()) {
      case 'pharmacist':
        return 'Pharmacist';
      case 'technician':
        return 'Technician';
      case 'dispenser':
        return 'Dispenser';
      default:
        return allPositions;
    }
  }
}

String formatShiftFilterDate(DateTime d) {
  final day = d.day.toString().padLeft(2, '0');
  final month = d.month.toString().padLeft(2, '0');
  return '$day/$month/${d.year}';
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
  static const _border = Color(0xFFE0E0E0);
  static const _labelColor = Color(0xFF6B7280);
  static const _titleNavy = Color(0xFF1A2B3C);

  late final TextEditingController _locationController;
  late final TextEditingController _minPayController;
  late final TextEditingController _maxPayController;
  DateTime? _startDate;
  DateTime? _endDate;
  late String _positionType;

  @override
  void initState() {
    super.initState();
    _locationController = TextEditingController(text: widget.initial.location);
    _minPayController = TextEditingController(text: widget.initial.minPay);
    _maxPayController = TextEditingController(text: widget.initial.maxPay);
    _startDate = widget.initial.startDate;
    _endDate = widget.initial.endDate;
    _positionType = widget.initial.positionType;

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
    _maxPayController.dispose();
    super.dispose();
  }

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _border),
      ),
      filled: true,
      fillColor: Colors.grey.shade50,
      isDense: true,
    );
  }

  Widget _fieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          color: _labelColor,
        ),
      ),
    );
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: (isStart ? _startDate : _endDate) ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100, 12, 31),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

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
      startDate: _startDate,
      endDate: _endDate,
      minPay: _minPayController.text.trim(),
      maxPay: _maxPayController.text.trim(),
      positionType: _positionType,
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
                        color: _titleNavy,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _apply,
                    icon: const Icon(
                      Icons.search,
                      color: BrandColors.primaryBlue,
                    ),
                    tooltip: 'Search',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _fieldLabel('LOCATION'),
              RegisterLocationAutocomplete(
                controller: _locationController,
                locationProvider: shiftsSearchLocationProvider,
                decoration: _fieldDecoration('Search location'),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _fieldLabel('START DATE'),
                        _DateFilterField(
                          value: _startDate,
                          onTap: () => _pickDate(isStart: true),
                          onClear: () => setState(() => _startDate = null),
                          decoration: _fieldDecoration('dd/mm/yyyy'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _fieldLabel('END DATE'),
                        _DateFilterField(
                          value: _endDate,
                          onTap: () => _pickDate(isStart: false),
                          onClear: () => setState(() => _endDate = null),
                          decoration: _fieldDecoration('dd/mm/yyyy'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _fieldLabel('MINIMUM PAY (£)'),
                        TextField(
                          controller: _minPayController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d{0,2}'),
                            ),
                          ],
                          decoration:
                              _fieldDecoration('Enter minimum pay'),
                          onSubmitted: (_) => _apply(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _fieldLabel('MAXIMUM PAY (£)'),
                        TextField(
                          controller: _maxPayController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d{0,2}'),
                            ),
                          ],
                          decoration:
                              _fieldDecoration('Enter maximum pay'),
                          onSubmitted: (_) => _apply(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _fieldLabel('POSITION TYPE'),
              InputDecorator(
                decoration: _fieldDecoration('All Positions'),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _positionType,
                    isExpanded: true,
                    isDense: true,
                    items: ShiftsSearchFilters.positionTypes
                        .map(
                          (e) => DropdownMenuItem(
                            value: e,
                            child: Text(e, style: const TextStyle(fontSize: 15)),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => _positionType = v);
                    },
                  ),
                ),
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

class _DateFilterField extends StatelessWidget {
  const _DateFilterField({
    required this.value,
    required this.onTap,
    required this.onClear,
    required this.decoration,
  });

  final DateTime? value;
  final VoidCallback onTap;
  final VoidCallback onClear;
  final InputDecoration decoration;

  @override
  Widget build(BuildContext context) {
    final display =
        value == null ? 'dd/mm/yyyy' : formatShiftFilterDate(value!);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: decoration.copyWith(
          suffixIcon: value != null
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: onClear,
                  tooltip: 'Clear',
                )
              : const Icon(Icons.calendar_today_outlined, size: 20),
        ),
        child: Text(
          display,
          style: TextStyle(
            fontSize: 15,
            color: value == null ? Colors.grey.shade600 : Colors.black87,
          ),
        ),
      ),
    );
  }
}
