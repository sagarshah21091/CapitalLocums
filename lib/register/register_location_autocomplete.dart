import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../env/app_env.dart';
import '../maps/google_places_service.dart';
import 'register_location_provider.dart';

/// Location field with Google Places autocomplete; coords saved to [registerLocationProvider].
class RegisterLocationAutocomplete extends ConsumerStatefulWidget {
  const RegisterLocationAutocomplete({
    super.key,
    required this.controller,
    required this.decoration,
    this.validator,
    this.textInputAction,
    this.components,
  });

  final TextEditingController controller;
  final InputDecoration decoration;
  final FormFieldValidator<String>? validator;
  final TextInputAction? textInputAction;

  /// e.g. `country:gb` — pass empty string to disable biasing.
  final String? components;

  @override
  ConsumerState<RegisterLocationAutocomplete> createState() =>
      _RegisterLocationAutocompleteState();
}

class _RegisterLocationAutocompleteState
    extends ConsumerState<RegisterLocationAutocomplete> {
  final _focusNode = FocusNode();
  final _places = GooglePlacesService();

  Timer? _debounce;
  List<PlacePrediction> _predictions = [];
  bool _loading = false;
  String? _apiError;

  static const _debounceMs = 320;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTypedAddressChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTypedAddressChanged);
    _focusNode.removeListener(_onFocusChanged);
    _debounce?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTypedAddressChanged() {
    final picked = ref.read(registerLocationProvider);
    final text = widget.controller.text;
    if (picked != null && picked.formattedAddress.trim() != text.trim()) {
      ref.read(registerLocationProvider.notifier).clear();
    }
    _scheduleFetch(text);
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus) {
      Future<void>.delayed(const Duration(milliseconds: 180), () {
        if (!mounted || _focusNode.hasFocus) return;
        setState(() {
          _predictions = [];
          _loading = false;
        });
      });
    }
  }

  void _scheduleFetch(String raw) {
    _debounce?.cancel();
    final key = AppEnv.googleMapsApiKey;
    if (key.isEmpty) {
      setState(() {
        _predictions = [];
        _loading = false;
      });
      return;
    }

    final q = raw.trim();
    if (q.length < 2) {
      setState(() {
        _predictions = [];
        _loading = false;
        _apiError = null;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: _debounceMs), () async {
      setState(() {
        _loading = true;
        _apiError = null;
      });
      try {
        final comps = widget.components ?? 'country:gb';
        final list = await _places.autocomplete(
          input: q,
          apiKey: key,
          components: comps.isEmpty ? null : comps,
        );
        if (!mounted) return;
        setState(() {
          _predictions = list;
          _loading = false;
        });
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _predictions = [];
          _loading = false;
          _apiError = e.toString();
        });
      }
    });
  }

  Future<void> _onPickPrediction(PlacePrediction p) async {
    final key = AppEnv.googleMapsApiKey;
    if (key.isEmpty) return;

    setState(() {
      _loading = true;
      _predictions = [];
    });

    try {
      final details =
          await _places.placeDetails(placeId: p.placeId, apiKey: key);
      if (!mounted || details == null) return;

      final label = details.formattedAddress.trim().isNotEmpty
          ? details.formattedAddress
          : p.description;

      widget.controller.text = label;
      widget.controller.selection = TextSelection.collapsed(
        offset: widget.controller.text.length,
      );

      ref.read(registerLocationProvider.notifier).setPick(
            PickedRegisterLocation(
              latitude: details.latitude,
              longitude: details.longitude,
              placeId: details.placeId,
              formattedAddress: label,
            ),
          );

      _focusNode.unfocus();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyMissing = AppEnv.googleMapsApiKey.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: widget.controller,
          focusNode: _focusNode,
          decoration: widget.decoration.copyWith(
            suffixIcon: _loading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : null,
          ),
          validator: widget.validator,
          textInputAction: widget.textInputAction ?? TextInputAction.next,
          onTap: () {
            if (keyMissing) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Add GOOGLE_MAPS_API_KEY to your .env file for location search.',
                  ),
                ),
              );
            }
          },
        ),
        if (_apiError != null && _focusNode.hasFocus)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              _apiError!,
              style: TextStyle(fontSize: 12, color: Colors.red.shade700),
            ),
          ),
        if (_predictions.isNotEmpty && _focusNode.hasFocus)
          Material(
            elevation: 3,
            borderRadius: BorderRadius.circular(8),
            clipBehavior: Clip.antiAlias,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: _predictions.length,
                separatorBuilder: (_, _) =>
                    Divider(height: 1, color: Colors.grey.shade300),
                itemBuilder: (context, index) {
                  final item = _predictions[index];
                  return ListTile(
                    dense: true,
                    title: Text(
                      item.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14),
                    ),
                    onTap: () => _onPickPrediction(item),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}
