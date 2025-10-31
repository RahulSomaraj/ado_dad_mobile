import 'package:dio/dio.dart';

class GooglePlacesService {
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/place';
  final Dio _dio = Dio();
  final String _apiKey;

  GooglePlacesService({required String apiKey}) : _apiKey = apiKey {
    _dio.options.headers = {
      'Content-Type': 'application/json',
    };
  }

  /// Get place predictions based on input text
  /// This will show suggestions for places starting with the input text
  Future<List<PlacePrediction>> getPlacePredictions({
    required String input,
    String? location, // Optional: bias results to a specific location
    double? radius, // Optional: radius in meters
    String? language = 'en',
    String? region = 'in', // Default to India
  }) async {
    try {
      final queryParams = {
        'input': input,
        'key': _apiKey,
        'language': language,
        'region': region,
        'types': 'geocode', // Only return geocoding results (places)
      };

      // Add location bias if provided
      if (location != null) {
        queryParams['location'] = location;
        if (radius != null) {
          queryParams['radius'] = radius.toString();
        }
      }

      final response = await _dio.get(
        '$_baseUrl/autocomplete/json',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['status'] == 'OK') {
          final predictions = data['predictions'] as List;
          return predictions
              .map((prediction) => PlacePrediction.fromJson(prediction))
              .toList();
        } else {
          throw Exception('Google Places API error: ${data['status']}');
        }
      } else {
        throw Exception('HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting place predictions: $e');
      return [];
    }
  }

  /// Get place details by place ID
  Future<PlaceDetails?> getPlaceDetails(String placeId) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/details/json',
        queryParameters: {
          'place_id': placeId,
          'key': _apiKey,
          'fields': 'formatted_address,geometry,name,place_id',
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['status'] == 'OK') {
          return PlaceDetails.fromJson(data['result']);
        }
      }
      return null;
    } catch (e) {
      print('Error getting place details: $e');
      return null;
    }
  }

  /// Get nearby places based on location
  Future<List<PlaceDetails>> getNearbyPlaces({
    required double latitude,
    required double longitude,
    double radius = 5000, // 5km default
    String type = 'establishment',
  }) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/nearbysearch/json',
        queryParameters: {
          'location': '$latitude,$longitude',
          'radius': radius.toString(),
          'type': type,
          'key': _apiKey,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['status'] == 'OK') {
          final results = data['results'] as List;
          return results
              .map((result) => PlaceDetails.fromJson(result))
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('Error getting nearby places: $e');
      return [];
    }
  }

  /// Reverse geocoding - get address from coordinates using Google Geocoding API
  Future<String?> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await _dio.get(
        'https://maps.googleapis.com/maps/api/geocode/json',
        queryParameters: {
          'latlng': '$latitude,$longitude',
          'key': _apiKey,
          'language': 'en',
          'region': 'in',
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          final result = data['results'][0];

          // Try to extract structured components (Place, District, State)
          final addressComponents =
              result['address_components'] as List<dynamic>?;

          if (addressComponents != null) {
            String? locality; // Place
            String? sublocality; // Sub-place
            String? subAdministrativeArea; // District
            String? administrativeArea; // State

            for (var component in addressComponents) {
              final types = component['types'] as List<dynamic>?;
              final longName = component['long_name'] as String?;

              if (types != null && longName != null) {
                if (types.contains('locality')) {
                  locality = longName;
                } else if (types.contains('sublocality') ||
                    types.contains('sublocality_level_1')) {
                  sublocality = longName;
                } else if (types.contains('administrative_area_level_2')) {
                  subAdministrativeArea = longName;
                } else if (types.contains('administrative_area_level_1')) {
                  administrativeArea = longName;
                }
              }
            }

            // Build address in format: Place, District, State
            final addressParts = <String>[];

            // Add place (locality or sublocality)
            if (locality?.isNotEmpty == true) {
              addressParts.add(locality!);
            } else if (sublocality?.isNotEmpty == true) {
              addressParts.add(sublocality!);
            }

            // Add district (subAdministrativeArea)
            if (subAdministrativeArea?.isNotEmpty == true) {
              addressParts.add(subAdministrativeArea!);
            }

            // Add state (administrativeArea)
            if (administrativeArea?.isNotEmpty == true) {
              addressParts.add(administrativeArea!);
            }

            if (addressParts.isNotEmpty) {
              return addressParts.join(', ');
            }
          }

          // Fallback to formatted_address if components parsing fails
          return result['formatted_address'];
        }
      }
      return null;
    } catch (e) {
      print('Error in reverse geocoding: $e');
      return null;
    }
  }
}

class PlacePrediction {
  final String description;
  final String placeId;
  final List<String> types;
  final List<MatchedSubstring> matchedSubstrings;

  PlacePrediction({
    required this.description,
    required this.placeId,
    required this.types,
    required this.matchedSubstrings,
  });

  factory PlacePrediction.fromJson(Map<String, dynamic> json) {
    return PlacePrediction(
      description: json['description'] ?? '',
      placeId: json['place_id'] ?? '',
      types: List<String>.from(json['types'] ?? []),
      matchedSubstrings: (json['matched_substrings'] as List?)
              ?.map((substring) => MatchedSubstring.fromJson(substring))
              .toList() ??
          [],
    );
  }
}

class MatchedSubstring {
  final int length;
  final int offset;

  MatchedSubstring({required this.length, required this.offset});

  factory MatchedSubstring.fromJson(Map<String, dynamic> json) {
    return MatchedSubstring(
      length: json['length'] ?? 0,
      offset: json['offset'] ?? 0,
    );
  }
}

class PlaceDetails {
  final String name;
  final String formattedAddress;
  final String placeId;
  final PlaceGeometry? geometry;

  PlaceDetails({
    required this.name,
    required this.formattedAddress,
    required this.placeId,
    this.geometry,
  });

  factory PlaceDetails.fromJson(Map<String, dynamic> json) {
    return PlaceDetails(
      name: json['name'] ?? '',
      formattedAddress: json['formatted_address'] ?? '',
      placeId: json['place_id'] ?? '',
      geometry: json['geometry'] != null
          ? PlaceGeometry.fromJson(json['geometry'])
          : null,
    );
  }
}

class PlaceGeometry {
  final PlaceLocation location;

  PlaceGeometry({required this.location});

  factory PlaceGeometry.fromJson(Map<String, dynamic> json) {
    return PlaceGeometry(
      location: PlaceLocation.fromJson(json['location']),
    );
  }
}

class PlaceLocation {
  final double lat;
  final double lng;

  PlaceLocation({required this.lat, required this.lng});

  factory PlaceLocation.fromJson(Map<String, dynamic> json) {
    return PlaceLocation(
      lat: (json['lat'] ?? 0.0).toDouble(),
      lng: (json['lng'] ?? 0.0).toDouble(),
    );
  }
}
