import 'dart:math' as math;
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
          final results = data['results'] as List<dynamic>;

          // Helper function to score how specific a result's location components are
          // Higher score = more specific location (e.g., sublocality_level_2 is better than locality)
          int _getLocationSpecificityScore(Map<String, dynamic> result) {
            final addressComponents =
                result['address_components'] as List<dynamic>?;
            if (addressComponents == null) return 0;

            int score = 0;
            for (var component in addressComponents) {
              final types = component['types'] as List<dynamic>?;
              if (types != null) {
                if (types.contains('sublocality_level_2')) {
                  score = 5; // Most specific
                  break;
                } else if (types.contains('sublocality_level_1')) {
                  score = math.max(score, 4);
                } else if (types.contains('neighborhood')) {
                  score = math.max(score, 3);
                } else if (types.contains('sublocality')) {
                  score = math.max(score, 2);
                } else if (types.contains('locality')) {
                  score = math.max(score, 1);
                }
              }
            }
            return score;
          }

          // Find the result with the most specific location component
          Map<String, dynamic>? bestResult;
          int bestScore = -1;
          String? bestLocationType;

          for (var result in results) {
            final resultMap = result as Map<String, dynamic>;
            final specificityScore = _getLocationSpecificityScore(resultMap);
            final locationType =
                resultMap['geometry']?['location_type'] as String?;

            // Prioritize results with higher specificity score
            // If scores are equal, prefer ROOFTOP > RANGE_INTERPOLATED > others
            bool shouldUseThis = false;

            if (specificityScore > bestScore) {
              // This result has a more specific location component
              shouldUseThis = true;
            } else if (specificityScore == bestScore && bestResult != null) {
              // Same specificity, check location type accuracy
              if (bestLocationType != 'ROOFTOP' && locationType == 'ROOFTOP') {
                shouldUseThis = true;
              } else if (bestLocationType != 'RANGE_INTERPOLATED' &&
                  bestLocationType != 'ROOFTOP' &&
                  locationType == 'RANGE_INTERPOLATED') {
                shouldUseThis = true;
              }
            } else if (bestResult == null) {
              // First result, use it as fallback
              shouldUseThis = true;
            }

            if (shouldUseThis) {
              bestResult = resultMap;
              bestScore = specificityScore;
              bestLocationType = locationType;
            }
          }

          // Use the best result found, or first result as fallback
          final result = bestResult ?? results[0] as Map<String, dynamic>;

          // Try to extract structured components (Place, District, State)
          final addressComponents =
              result['address_components'] as List<dynamic>?;

          if (addressComponents != null) {
            String? locality; // Place
            String? sublocality; // Sub-place (more specific)
            String? sublocalityLevel1; // Even more specific sub-place
            String? sublocalityLevel2; // Most specific sub-place
            String? neighborhood; // Neighborhood
            String? subAdministrativeArea; // District
            String? administrativeArea; // State

            for (var component in addressComponents) {
              final types = component['types'] as List<dynamic>?;
              final longName = component['long_name'] as String?;

              if (types != null && longName != null) {
                // Check for most specific location first
                if (types.contains('sublocality_level_2')) {
                  sublocalityLevel2 = longName;
                } else if (types.contains('sublocality_level_1')) {
                  sublocalityLevel1 = longName;
                } else if (types.contains('neighborhood')) {
                  neighborhood = longName;
                } else if (types.contains('sublocality')) {
                  sublocality = longName;
                } else if (types.contains('locality')) {
                  locality = longName;
                } else if (types.contains('administrative_area_level_2')) {
                  subAdministrativeArea = longName;
                } else if (types.contains('administrative_area_level_1')) {
                  administrativeArea = longName;
                }
              }
            }

            // Build address in format: Place, District, State
            // Prioritize most specific location components
            final addressParts = <String>[];

            // Add place - prioritize most specific location
            if (sublocalityLevel2?.isNotEmpty == true) {
              addressParts.add(sublocalityLevel2!);
            } else if (sublocalityLevel1?.isNotEmpty == true) {
              addressParts.add(sublocalityLevel1!);
            } else if (neighborhood?.isNotEmpty == true) {
              addressParts.add(neighborhood!);
            } else if (sublocality?.isNotEmpty == true) {
              addressParts.add(sublocality!);
            } else if (locality?.isNotEmpty == true) {
              addressParts.add(locality!);
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
              print(
                  '📍 Extracted location: ${addressParts.join(", ")} (specificity_score: $bestScore, location_type: $bestLocationType)');
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
