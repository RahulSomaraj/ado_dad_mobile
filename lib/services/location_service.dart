import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The app's single owner of device position.
///
/// Three screens used to ask the platform for a fix independently — Home,
/// the category list and the detail page's "similar near you" section — each
/// paying up to 5–6 s and a GPS wake. This holds one fix, shares one in-flight
/// request between all callers, and persists the last one so the *next* cold
/// start has something to seed a radius query with even before the platform's
/// own cache is warm.
///
/// Two levels, deliberately separate:
/// * [seedPosition] — instant (persisted value, else `getLastKnownPosition`).
///   Never wakes the hardware. This is what paint-critical paths use.
/// * [freshPosition] — a real fix, deduped across callers. Background work only.
class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  static const String _kLat = 'last_lat';
  static const String _kLng = 'last_lng';
  static const String _kFixAt = 'last_fix_at';

  /// Distance (metres) a fresh fix must differ from the seed before it is worth
  /// re-issuing a feed request.
  static const double movedThresholdMeters = 2000;

  /// How long a fix is trusted before [isStale] asks for a new one.
  ///
  /// The persisted fix exists to make a cold start instant, not to stand in for
  /// the device's real position indefinitely. Without an age check, an app
  /// resumed days later — in another city — kept querying the radius around
  /// wherever it was last opened.
  static const Duration staleAfter = Duration(minutes: 30);

  Position? _cached;
  DateTime? _fixedAt;
  Future<Position?>? _inFlight;
  bool _seedLoaded = false;

  /// The best fix known without any await. Null until [seedPosition] has run
  /// once in this process.
  Position? get cachedPosition => _cached;

  /// True when there is no fix at all, or the one held is older than
  /// [staleAfter]. A seed restored from disk carries the timestamp it was
  /// recorded with, so a fix persisted last week reads as stale on launch.
  bool get isStale {
    if (_cached == null) return true;
    final at = _fixedAt;
    if (at == null) return true;
    return DateTime.now().difference(at) > staleAfter;
  }

  /// Whether the platform will serve a fix right now — services on and
  /// permission granted. Cheap: it inspects state and never wakes the GPS, so
  /// it is safe to call on every resume.
  Future<bool> isAvailable() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return false;
      final permission = await Geolocator.checkPermission();
      return permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
    } catch (_) {
      return false;
    }
  }

  /// Instant, best-effort position: the coordinates persisted by an earlier
  /// launch, else whatever fix the platform already has cached. Returns in ~0 ms
  /// and never wakes the GPS.
  Future<Position?> seedPosition() async {
    if (_cached != null) return _cached;

    if (!_seedLoaded) {
      _seedLoaded = true;
      try {
        final prefs = await SharedPreferences.getInstance();
        final lat = prefs.getDouble(_kLat);
        final lng = prefs.getDouble(_kLng);
        if (lat != null && lng != null) {
          _cached = _synthetic(lat, lng);
          final at = prefs.getInt(_kFixAt);
          // A fix persisted before this key existed has no recorded age, so it
          // is treated as stale rather than trusted indefinitely.
          _fixedAt =
              at == null ? null : DateTime.fromMillisecondsSinceEpoch(at);
        }
      } catch (_) {}
    }

    if (_cached == null) {
      try {
        final known = await Geolocator.getLastKnownPosition();
        if (known != null) {
          _cached = known;
          _fixedAt = known.timestamp;
          unawaited(_persist(known));
        }
      } catch (_) {}
    }

    return _cached;
  }

  /// A real fix. Concurrent callers share one platform request; the result is
  /// cached in memory and persisted for the next launch. Returns null when
  /// location is off, denied, or the fix times out — callers must treat that as
  /// normal, not as an error.
  Future<Position?> freshPosition({
    Duration timeLimit = const Duration(seconds: 6),
    LocationAccuracy accuracy = LocationAccuracy.low,
  }) {
    final existing = _inFlight;
    if (existing != null) return existing;

    final request = _requestFresh(timeLimit, accuracy).whenComplete(() {
      _inFlight = null;
    });
    _inFlight = request;
    return request;
  }

  Future<Position?> _requestFresh(
      Duration timeLimit, LocationAccuracy accuracy) async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;

      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: accuracy,
          timeLimit: timeLimit,
        ),
      );
      _cached = pos;
      _fixedAt = DateTime.now();
      unawaited(_persist(pos));
      return pos;
    } catch (_) {
      return null;
    }
  }

  /// True when [fresh] is far enough from [seed] to be worth re-querying.
  /// A null seed always counts as moved.
  bool movedEnough(Position? seed, Position fresh) {
    if (seed == null) return true;
    return Geolocator.distanceBetween(
          seed.latitude,
          seed.longitude,
          fresh.latitude,
          fresh.longitude,
        ) >
        movedThresholdMeters;
  }

  Future<void> _persist(Position p) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_kLat, p.latitude);
      await prefs.setDouble(_kLng, p.longitude);
      await prefs.setInt(
          _kFixAt, (_fixedAt ?? DateTime.now()).millisecondsSinceEpoch);
    } catch (_) {}
  }

  /// A Position carrying only coordinates — enough for a radius query, which is
  /// all the seed is ever used for.
  Position _synthetic(double lat, double lng) => Position(
        latitude: lat,
        longitude: lng,
        timestamp: DateTime.fromMillisecondsSinceEpoch(0),
        accuracy: 0,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );
}
