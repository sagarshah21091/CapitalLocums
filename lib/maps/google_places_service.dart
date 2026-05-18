import 'package:dio/dio.dart';

/// Minimal Google Places (legacy REST) client for autocomplete + details.
class GooglePlacesService {
  GooglePlacesService({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 15),
              ),
            );

  final Dio _dio;

  static const _autocompleteUrl =
      'https://maps.googleapis.com/maps/api/place/autocomplete/json';
  static const _detailsUrl =
      'https://maps.googleapis.com/maps/api/place/details/json';

  /// Biases results toward GB (Capital Locums). Pass `null` to disable.
  Future<List<PlacePrediction>> autocomplete({
    required String input,
    required String apiKey,
    String? components,
  }) async {
    final q = input.trim();
    if (q.length < 2 || apiKey.isEmpty) return [];

    final params = <String, dynamic>{
      'input': q,
      'key': apiKey,
    };
    if (components != null && components.isNotEmpty) {
      params['components'] = components;
    }

    final response = await _dio.get<Map<String, dynamic>>(
      _autocompleteUrl,
      queryParameters: params,
    );

    final data = response.data;
    if (data == null) return [];

    final status = data['status'] as String? ?? '';
    if (status != 'OK' && status != 'ZERO_RESULTS') {
      throw PlacesApiException(_statusMessage(status, data));
    }

    final preds = data['predictions'];
    if (preds is! List) return [];

    final out = <PlacePrediction>[];
    for (final p in preds) {
      if (p is! Map<String, dynamic>) continue;
      final desc = p['description'] as String?;
      final id = p['place_id'] as String?;
      if (desc != null && id != null) {
        out.add(PlacePrediction(description: desc, placeId: id));
      }
    }
    return out;
  }

  Future<PlaceDetailsResult?> placeDetails({
    required String placeId,
    required String apiKey,
  }) async {
    if (apiKey.isEmpty) return null;

    final response = await _dio.get<Map<String, dynamic>>(
      _detailsUrl,
      queryParameters: {
        'place_id': placeId,
        'fields': 'formatted_address,geometry/location',
        'key': apiKey,
      },
    );

    final data = response.data;
    if (data == null) return null;

    final status = data['status'] as String? ?? '';
    if (status != 'OK') {
      throw PlacesApiException(_statusMessage(status, data));
    }

    final result = data['result'];
    if (result is! Map<String, dynamic>) return null;

    final formatted = result['formatted_address'] as String? ?? '';
    final geom = result['geometry'];
    if (geom is! Map<String, dynamic>) return null;
    final loc = geom['location'];
    if (loc is! Map<String, dynamic>) return null;

    final lat = (loc['lat'] as num?)?.toDouble();
    final lng = (loc['lng'] as num?)?.toDouble();
    if (lat == null || lng == null) return null;

    return PlaceDetailsResult(
      formattedAddress: formatted,
      latitude: lat,
      longitude: lng,
      placeId: placeId,
    );
  }

  static String _statusMessage(String status, Map<String, dynamic> data) {
    final err = data['error_message'] as String?;
    switch (status) {
      case 'REQUEST_DENIED':
        return err ??
            'Places request denied. Check GOOGLE_MAPS_API_KEY and enabled APIs.';
      case 'OVER_QUERY_LIMIT':
        return 'Places quota exceeded. Try again later.';
      case 'INVALID_REQUEST':
        return err ?? 'Invalid Places request.';
      default:
        return err ?? 'Places error: $status';
    }
  }
}

class PlacePrediction {
  const PlacePrediction({
    required this.description,
    required this.placeId,
  });

  final String description;
  final String placeId;
}

class PlaceDetailsResult {
  const PlaceDetailsResult({
    required this.formattedAddress,
    required this.latitude,
    required this.longitude,
    required this.placeId,
  });

  final String formattedAddress;
  final double latitude;
  final double longitude;
  final String placeId;
}

class PlacesApiException implements Exception {
  PlacesApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
