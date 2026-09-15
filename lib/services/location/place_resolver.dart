import 'dart:async';
import 'dart:collection';

import 'package:ado_dad_user/common/google_places_service.dart';
import 'package:geocoding/geocoding.dart' as geo;

class PlaceSuggestion {
  const PlaceSuggestion({required this.placeId, required this.description});
  final String placeId;
  final String description;
}

class ForwardResult {
  const ForwardResult({
    required this.lat,
    required this.lng,
    required this.label,
  });
  final double lat;
  final double lng;
  final String label;
}

/// Turns coordinates into names and names into coordinates.
///
/// Every method is bounded and never throws: a null / empty result means
/// "could not resolve", which callers present as a normal state.
abstract class PlaceResolver {
  Future<String?> reverse(double lat, double lng);
  Future<ForwardResult?> forward({String? placeId, required String text});
  Future<List<PlaceSuggestion>> suggest(String input);
}

/// Google first, the platform geocoder second.
///
/// Google's results have the "Place, District, State" shape the chip is built
/// around but need a live API key; `geocoding` goes through the OS and needs
/// none — coarser, but it keeps the feature working when the key lapses.
class DefaultPlaceResolver implements PlaceResolver {
  DefaultPlaceResolver(
    this._google, {
    this.timeout = const Duration(seconds: 5),
  });

  final GooglePlacesService _google;
  final Duration timeout;

  static const int _cacheSize = 32;
  final LinkedHashMap<String, String> _reverseCache =
      LinkedHashMap<String, String>();

  @override
  Future<String?> reverse(double lat, double lng) async {
    // ~1 km buckets: a resume in the same town costs no network call.
    final key = '${lat.toStringAsFixed(2)},${lng.toStringAsFixed(2)}';
    final cached = _reverseCache[key];
    if (cached != null) return cached;

    String? label;
    try {
      final g = await _google
          .reverseGeocode(latitude: lat, longitude: lng)
          .timeout(timeout);
      if (g != null && g.trim().isNotEmpty) {
        label = formatIndianAddress(g);
      }
    } catch (_) {}

    if (label == null) {
      try {
        final marks =
            await geo.placemarkFromCoordinates(lat, lng).timeout(timeout);
        if (marks.isNotEmpty) label = _formatPlacemark(marks.first);
      } catch (_) {}
    }

    if (label != null && label.isNotEmpty) {
      _reverseCache[key] = label;
      if (_reverseCache.length > _cacheSize) {
        _reverseCache.remove(_reverseCache.keys.first);
      }
      return label;
    }
    return null;
  }

  @override
  Future<ForwardResult?> forward({
    String? placeId,
    required String text,
  }) async {
    final query = text.trim();
    if (query.isEmpty) return null;

    // 1. A picked suggestion carries its id — one details call, exact point.
    if (placeId != null && placeId.isNotEmpty) {
      final r = await _details(placeId, query);
      if (r != null) return r;
    }

    // 2. Free text through Places: best match on Indian village/town names.
    if (placeId == null || placeId.isEmpty) {
      try {
        final predictions = await _google
            .getPlacePredictions(input: query, region: 'in', language: 'en')
            .timeout(timeout);
        if (predictions.isNotEmpty) {
          final lower = query.toLowerCase();
          final best = predictions.firstWhere(
            (p) => p.description.toLowerCase() == lower,
            orElse: () => predictions.first,
          );
          final r = await _details(best.placeId, query);
          if (r != null) return r;
        }
      } catch (_) {}
    }

    // 3. Platform geocoder — keyless, works when Google is unavailable.
    try {
      final locations = await geo.locationFromAddress(query).timeout(timeout);
      for (final l in locations) {
        if (_valid(l.latitude, l.longitude)) {
          return ForwardResult(lat: l.latitude, lng: l.longitude, label: query);
        }
      }
    } catch (_) {}

    return null;
  }

  @override
  Future<List<PlaceSuggestion>> suggest(String input) async {
    final q = input.trim();
    if (q.length < 2) return const [];
    try {
      final predictions = await _google
          .getPlacePredictions(input: q, region: 'in', language: 'en')
          .timeout(timeout);
      return predictions
          .where((p) => p.placeId.isNotEmpty && p.description.isNotEmpty)
          .take(5)
          .map((p) =>
              PlaceSuggestion(placeId: p.placeId, description: p.description))
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  Future<ForwardResult?> _details(String placeId, String label) async {
    try {
      final d = await _google.getPlaceDetails(placeId).timeout(timeout);
      final loc = d?.geometry?.location;
      if (loc != null && _valid(loc.lat, loc.lng)) {
        return ForwardResult(lat: loc.lat, lng: loc.lng, label: label);
      }
    } catch (_) {}
    return null;
  }

  static bool _valid(double lat, double lng) =>
      lat.isFinite &&
      lng.isFinite &&
      lat.abs() <= 90 &&
      lng.abs() <= 180 &&
      !(lat == 0 && lng == 0);

  static String? _formatPlacemark(geo.Placemark place) {
    final parts = <String>[];
    if (place.locality?.isNotEmpty == true) parts.add(place.locality!);
    if (place.subAdministrativeArea?.isNotEmpty == true &&
        place.subAdministrativeArea != place.locality) {
      parts.add(place.subAdministrativeArea!);
    }
    if (place.administrativeArea?.isNotEmpty == true) {
      parts.add(place.administrativeArea!);
    }
    return parts.isEmpty ? null : parts.join(', ');
  }

  /// "Street, Area, Place, District, State, 686001, India" → "Place, District,
  /// State". Moved from home_page.
  static String formatIndianAddress(String formattedAddress) {
    final parts = formattedAddress.split(',').map((e) => e.trim()).toList();

    bool isPincode(String str) {
      final cleaned = str.replaceAll(RegExp(r'[^0-9]'), '');
      return cleaned.length == 6 && RegExp(r'^\d{6}$').hasMatch(cleaned);
    }

    // The old filter used contains('pin'), which also dropped real place names
    // such as "Pinarayi"; only whole-word postal markers are removed now.
    final postal = RegExp(r'\b(pin|pincode|postal)\b');
    final filtered = parts.where((part) {
      final lower = part.toLowerCase();
      return part.isNotEmpty &&
          lower != 'india' &&
          !postal.hasMatch(lower) &&
          !isPincode(part);
    }).toList();

    if (filtered.length >= 3) {
      return filtered.sublist(filtered.length - 3).join(', ');
    }
    if (filtered.isNotEmpty) return filtered.join(', ');
    return formattedAddress;
  }
}
