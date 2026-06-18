import 'package:dio/dio.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:gold_taxi/features/search/data/models/place_model.dart';

class PlacesRepository {
  final Dio _dio;

  // Rate limiting properties
  static int _dailyRequestCount = 0;
  static DateTime? _lastRequestDate;

  PlacesRepository({Dio? dio}) : _dio = dio ?? Dio() {
    _dio.options.baseUrl = 'https://maps.googleapis.com/maps/api/place';
  }

  bool _isSpam(String query) {
    // Reject SQL wildcards or excessive emojis
    final RegExp spamRegex = RegExp(
      r'[%;_]|[\u{1F600}-\u{1F64F}]',
      unicode: true,
    );
    return spamRegex.hasMatch(query);
  }

  bool _checkRateLimit() {
    final now = DateTime.now();
    if (_lastRequestDate == null || _lastRequestDate!.day != now.day) {
      _lastRequestDate = now;
      _dailyRequestCount = 0;
    }

    if (_dailyRequestCount >= 500) {
      return false; // Rate limit exceeded (simulated 500/day IP limit)
    }
    _dailyRequestCount++;
    return true;
  }

  Future<List<PlaceModel>> autocomplete(
    String query,
    LatLng? currentLocation,
  ) async {
    if (query.trim().isEmpty || _isSpam(query)) {
      return [];
    }

    if (!_checkRateLimit()) {
      throw Exception('Rate limit exceeded (500 requests/24h)');
    }

    const apiKey = String.fromEnvironment('GOOGLE_MAPS_API_KEY');
    if (apiKey.isEmpty) {
      throw Exception('GOOGLE_MAPS_API_KEY is not configured');
    }

    try {
      final queryParams = {
        'input': query,
        'key': apiKey,
        'language': 'sk',
        'components': 'country:sk', // Bias results to Slovakia
      };

      if (currentLocation != null) {
        queryParams['location'] =
            '${currentLocation.latitude},${currentLocation.longitude}';
        queryParams['radius'] = '50000'; // 50km bias
      }

      final response = await _dio.get(
        '/autocomplete/json',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['status'] == 'OK') {
          final predictions = data['predictions'] as List;
          return predictions.map((json) => PlaceModel.fromJson(json)).toList();
        } else if (data['status'] == 'ZERO_RESULTS') {
          return [];
        } else {
          throw Exception('Places API error: ${data['status']}');
        }
      } else {
        throw Exception('Failed to fetch places');
      }
    } catch (e) {
      throw Exception('Network error during autocomplete: $e');
    }
  }

  Future<PlaceModel> getPlaceDetails(
    String placeId,
    LatLng? currentLocation,
  ) async {
    const apiKey = String.fromEnvironment('GOOGLE_MAPS_API_KEY');
    if (apiKey.isEmpty) {
      throw Exception('GOOGLE_MAPS_API_KEY is not configured');
    }

    try {
      final response = await _dio.get(
        '/details/json',
        queryParameters: {
          'place_id': placeId,
          'key': apiKey,
          'language': 'sk',
          'fields': 'geometry,name,formatted_address',
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['status'] == 'OK') {
          final result = data['result'];
          final lat = result['geometry']['location']['lat'];
          final lng = result['geometry']['location']['lng'];

          double? distance;
          if (currentLocation != null && lat != null && lng != null) {
            distance = Geolocator.distanceBetween(
              currentLocation.latitude,
              currentLocation.longitude,
              lat,
              lng,
            );
          }

          return PlaceModel(
            placeId: placeId,
            primaryText: result['name'] ?? '',
            secondaryText: result['formatted_address'] ?? '',
            lat: lat,
            lng: lng,
            distanceInMeters: distance,
          );
        } else {
          throw Exception('Places Details API error: ${data['status']}');
        }
      } else {
        throw Exception('Failed to fetch place details');
      }
    } catch (e) {
      throw Exception('Network error during getPlaceDetails: $e');
    }
  }
}
