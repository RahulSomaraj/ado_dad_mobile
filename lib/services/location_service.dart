import 'dart:async';

import 'package:ado_dad_user/common/google_places_service.dart';
import 'package:ado_dad_user/config/app_config.dart';
import 'package:ado_dad_user/services/location/device_locator.dart';
import 'package:ado_dad_user/services/location/location_store.dart';
import 'package:ado_dad_user/services/location/place_resolver.dart';
import 'package:ado_dad_user/services/location/user_place.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

export 'package:ado_dad_user/services/location/place_resolver.dart'
    show PlaceSuggestion;
export 'package:ado_dad_user/services/location/user_place.dart';

/// Drives the chip while there is no [UserPlace] to show.
enum LocationStatus { idle, locating, unavailable, ready }

enum LocateResult {
  ok,
  permissionDenied,
  permissionDeniedForever,
  servicesOff,
  noFix,
}

enum SetPlaceResult { ok, empty, notFound }

/// The app's single owner of "where the user is searching from".
///
/// Holds one [UserPlace] (coordinates + name + source) in [place], hydrated
/// from disk by [restore] before the first frame, and changed only through
/// [_commit]. Widgets subscribe with `ValueListenableBuilder`; non-widget code
/// (repositories) reads [place] or awaits [seedPosition].
///
/// Rules this class enforces:
/// * A manual pick is never replaced by GPS — only by another pick or
///   [useDevice].
/// * Every async result is fenced by a generation counter: a GPS fix or name
///   lookup that finishes after a newer commit is dropped, never applied.
/// * Only [useDevice] ever shows the permission prompt, and only a user action
///   (or the first launch with nothing saved) calls it.
class LocationService {
  static LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;

  LocationService._internal()
      : _store = PrefsLocationStore(),
        _locator = const GeolocatorDeviceLocator(),
        _resolverOverride = null,
        _now = DateTime.now;

  @visibleForTesting
  LocationService.forTesting({
    required LocationStore store,
    required DeviceLocator locator,
    required PlaceResolver resolver,
    DateTime Function()? now,
  })  : _store = store,
        _locator = locator,
        _resolverOverride = resolver,
        _now = now ?? DateTime.now;

  @visibleForTesting
  static set instanceForTesting(LocationService service) =>
      _instance = service;

  final LocationStore _store;
  final DeviceLocator _locator;
  final DateTime Function() _now;
  PlaceResolver? _resolverOverride;

  /// Built lazily: AppConfig's key is only loaded partway through `main()`.
  PlaceResolver get resolver => _resolverOverride ??= DefaultPlaceResolver(
      GooglePlacesService(apiKey: AppConfig.googlePlacesApiKey));

  /// Distance (metres) a new device fix must move before the feed re-queries.
  static const double movedThresholdMeters = 2000;

  /// How long a device fix is trusted before [refreshIfFollowing] replaces it.
  static const Duration staleAfter = Duration(minutes: 30);

  /// The current place. Null only when nothing has ever been resolved.
  final ValueNotifier<UserPlace?> place = ValueNotifier<UserPlace?>(null);

  /// Meaningful while [place] is null: locating vs. nothing available.
  final ValueNotifier<LocationStatus> status =
      ValueNotifier<LocationStatus>(LocationStatus.idle);

  /// Bumped by every commit that changes the point or source. Label-only
  /// commits leave it alone so they do not invalidate an in-flight fix.
  int _gen = 0;

  Future<void>? _restoring;
  Future<void>? _starting;
  Future<void>? _refreshing;
  Future<DeviceFix?>? _inFlight;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  /// Loads the saved place. Awaited in `main()` before `runApp`, so every
  /// screen can read [place] synchronously from its first frame.
  Future<void> restore() => _restoring ??= _doRestore();

  Future<void> _doRestore() async {
    try {
      final saved = await _store.load();
      if (saved != null && place.value == null) {
        place.value = saved;
        status.value = LocationStatus.ready;
      }
    } catch (_) {}
  }

  /// Once per process, from Home. With nothing saved, asks for a device fix
  /// (this is the first-launch permission prompt); otherwise refreshes a stale
  /// device fix in the background.
  Future<void> start() => _starting ??= _doStart();

  Future<void> _doStart() async {
    await restore();
    if (place.value == null) {
      await useDevice();
    } else {
      await refreshIfFollowing();
    }
  }

  // ---------------------------------------------------------------------------
  // Writes — the only three ways the place changes
  // ---------------------------------------------------------------------------

  /// Background refresh (start, app resume). Never prompts for permission and
  /// never touches a manual place.
  Future<void> refreshIfFollowing({bool force = false}) =>
      _refreshing ??= _doRefresh(force).whenComplete(() => _refreshing = null);

  Future<void> _doRefresh(bool force) async {
    await restore();
    final current = place.value;
    if (current != null && current.isManual) return;
    if (!force &&
        current != null &&
        current.hasLabel &&
        !current.isStale(staleAfter, now: _now())) {
      return;
    }

    if (current == null) status.value = LocationStatus.locating;
    final startGen = _gen;

    final fix = await _deviceFix(
      timeLimit: const Duration(seconds: 6),
      highAccuracy: false,
    );

    // Something committed while we waited. A manual pick always wins; a device
    // fix wins if it is newer than ours. (A seed from the platform cache is
    // older, so ours still replaces it.)
    if (_gen != startGen) {
      final latest = place.value;
      if (latest == null || latest.isManual) return;
      if (fix == null || !fix.at.isAfter(latest.fixedAt)) return;
    }

    final next = fix == null
        ? null
        : UserPlace.tryCreate(
            lat: fix.lat,
            lng: fix.lng,
            source: PlaceSource.device,
            fixedAt: fix.at,
          );

    if (next == null) {
      if (place.value == null) {
        status.value = LocationStatus.unavailable;
      } else if (!place.value!.hasLabel) {
        // Coordinates without a name: try naming them again.
        unawaited(_labelInBackground(place.value!, _gen));
      }
      return;
    }

    // Keep the existing name when the device has not left the area, so a
    // routine refresh does not flicker the chip or spend a geocode call.
    final keepLabel = current != null &&
        current.hasLabel &&
        current.distanceTo(next) <= movedThresholdMeters;
    final committed = keepLabel ? next.withLabel(current.label) : next;
    final gen = _commit(committed);
    if (!committed.hasLabel) unawaited(_labelInBackground(committed, gen));
  }

  /// "Use current location": may prompt for permission, takes an accurate fix
  /// and switches the app back to following the device.
  Future<LocateResult> useDevice() async {
    final access = await _locator.access(request: true);
    if (access != DeviceLocationAccess.granted) {
      if (place.value == null) status.value = LocationStatus.unavailable;
      switch (access) {
        case DeviceLocationAccess.servicesOff:
          return LocateResult.servicesOff;
        case DeviceLocationAccess.deniedForever:
          return LocateResult.permissionDeniedForever;
        case DeviceLocationAccess.denied:
        case DeviceLocationAccess.granted:
          return LocateResult.permissionDenied;
      }
    }

    if (place.value == null) status.value = LocationStatus.locating;
    final fix = await _deviceFix(
      timeLimit: const Duration(seconds: 10),
      highAccuracy: true,
    );
    final next = fix == null
        ? null
        : UserPlace.tryCreate(
            lat: fix.lat,
            lng: fix.lng,
            source: PlaceSource.device,
            fixedAt: fix.at,
          );
    if (next == null) {
      if (place.value == null) status.value = LocationStatus.unavailable;
      return LocateResult.noFix;
    }

    final gen = _commit(next);
    unawaited(_labelInBackground(next, gen));
    return LocateResult.ok;
  }

  /// A place the user chose. Resolves coordinates first and commits nothing
  /// if that fails — a name without a point is never saved.
  Future<SetPlaceResult> setManual({
    String? placeId,
    required String text,
  }) async {
    final query = text.trim();
    if (query.isEmpty) return SetPlaceResult.empty;

    ForwardResult? r;
    try {
      r = await resolver.forward(placeId: placeId, text: query);
    } catch (_) {}
    if (r == null) return SetPlaceResult.notFound;

    final next = UserPlace.tryCreate(
      lat: r.lat,
      lng: r.lng,
      label: r.label,
      source: PlaceSource.manual,
      fixedAt: _now(),
    );
    if (next == null) return SetPlaceResult.notFound;

    _commit(next);
    return SetPlaceResult.ok;
  }

  /// The single assignment point for [place].
  int _commit(UserPlace next, {bool labelOnly = false}) {
    if (!labelOnly) _gen++;
    place.value = next;
    status.value = LocationStatus.ready;
    unawaited(_store.save(next));
    return _gen;
  }

  Future<void> _labelInBackground(UserPlace p, int gen) async {
    String? label;
    try {
      label = await resolver.reverse(p.lat, p.lng);
    } catch (_) {}
    if (label == null || gen != _gen) return;
    final current = place.value;
    if (current == null || !current.samePoint(p)) return;
    _commit(current.withLabel(label), labelOnly: true);
  }

  // ---------------------------------------------------------------------------
  // Device access
  // ---------------------------------------------------------------------------

  /// One platform request shared by all concurrent callers.
  Future<DeviceFix?> _deviceFix({
    required Duration timeLimit,
    required bool highAccuracy,
  }) {
    final existing = _inFlight;
    if (existing != null) return existing;

    late final Future<DeviceFix?> request;
    request = _requestFix(timeLimit, highAccuracy).whenComplete(() {
      if (identical(_inFlight, request)) _inFlight = null;
    });
    _inFlight = request;
    return request;
  }

  Future<DeviceFix?> _requestFix(Duration timeLimit, bool highAccuracy) async {
    try {
      final access = await _locator.access();
      if (access != DeviceLocationAccess.granted) return null;
      return await _locator.current(
        timeLimit: timeLimit,
        highAccuracy: highAccuracy,
      );
    } catch (_) {
      return null;
    }
  }

  Future<bool> openAppSettings() => _locator.openAppSettings();
  Future<bool> openLocationSettings() => _locator.openLocationSettings();

  // ---------------------------------------------------------------------------
  // Reads
  // ---------------------------------------------------------------------------

  /// Whether the feed should re-query when the place changes from [from] to
  /// [to]. A label-only change never does; a manual pick always does; device
  /// drift only past [movedThresholdMeters].
  static bool needsRequery(UserPlace? from, UserPlace? to) {
    if (from == null || to == null) return from != to;
    if (from.source != to.source) return true;
    if (from.isManual || to.isManual) return !from.samePoint(to);
    return from.distanceTo(to) > movedThresholdMeters;
  }

  /// Compatibility for callers that want a Position (repositories, the
  /// category list, "similar near you"). Instant: the current place, else the
  /// platform's cached fix — never wakes the GPS.
  Future<Position?> seedPosition() async {
    await restore();
    final existing = place.value;
    if (existing != null) return _toPosition(existing);

    final known = await _locator.lastKnown();
    if (known == null) return null;
    final seeded = UserPlace.tryCreate(
      lat: known.lat,
      lng: known.lng,
      source: PlaceSource.device,
      fixedAt: known.at,
    );
    if (seeded == null) return null;
    if (place.value == null) {
      final gen = _commit(seeded);
      unawaited(_labelInBackground(seeded, gen));
    }
    return _toPosition(place.value ?? seeded);
  }

  /// A raw device fix, deduplicated. Does not change [place].
  Future<Position?> freshPosition({
    Duration timeLimit = const Duration(seconds: 6),
    LocationAccuracy accuracy = LocationAccuracy.low,
  }) async {
    final fix = await _deviceFix(
      timeLimit: timeLimit,
      highAccuracy: accuracy == LocationAccuracy.high ||
          accuracy == LocationAccuracy.best ||
          accuracy == LocationAccuracy.bestForNavigation,
    );
    return fix == null ? null : _synthetic(fix.lat, fix.lng, fix.at);
  }

  Future<bool> isAvailable() async =>
      await _locator.access() == DeviceLocationAccess.granted;

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

  Position _toPosition(UserPlace p) => _synthetic(p.lat, p.lng, p.fixedAt);

  Position _synthetic(double lat, double lng, DateTime at) => Position(
        latitude: lat,
        longitude: lng,
        timestamp: at,
        accuracy: 0,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );
}
