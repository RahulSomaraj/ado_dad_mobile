import 'dart:math' as math;

import 'package:flutter/foundation.dart';

/// Where a [UserPlace] came from.
///
/// * [device] — the phone's own fix. Follows the user: later fixes replace it.
/// * [manual] — a place the user picked. Sticky: GPS never overwrites it; only
///   another pick or an explicit "Use current location" does.
enum PlaceSource { device, manual }

/// The one value that answers "where is the user searching from".
///
/// Coordinates and their display name travel together so they cannot drift
/// apart, and a place without coordinates cannot be built — so a chip saying
/// one town while the feed queries another is unrepresentable.
@immutable
class UserPlace {
  static const int schemaVersion = 1;

  /// Written into `user_location` by older builds when lookup failed.
  static const String legacyFailureSentinel = 'Location not available';

  final double lat;
  final double lng;

  /// Null while the coordinates are known but not yet named.
  final String? label;
  final PlaceSource source;
  final DateTime fixedAt;

  const UserPlace._({
    required this.lat,
    required this.lng,
    required this.label,
    required this.source,
    required this.fixedAt,
  });

  /// The only way to build a place. Returns null for coordinates that are not
  /// finite, out of range, or exactly 0,0 (what a failed parse defaults to).
  static UserPlace? tryCreate({
    required double lat,
    required double lng,
    String? label,
    required PlaceSource source,
    DateTime? fixedAt,
  }) {
    if (!lat.isFinite || !lng.isFinite) return null;
    if (lat.abs() > 90 || lng.abs() > 180) return null;
    if (lat == 0 && lng == 0) return null;
    return UserPlace._(
      lat: lat,
      lng: lng,
      label: cleanLabel(label),
      source: source,
      fixedAt: fixedAt ?? DateTime.now(),
    );
  }

  /// Trims, and maps empty text and the legacy failure sentinel to null.
  static String? cleanLabel(String? raw) {
    final t = raw?.trim();
    if (t == null || t.isEmpty || t == legacyFailureSentinel) return null;
    return t;
  }

  bool get isManual => source == PlaceSource.manual;
  bool get hasLabel => label != null;

  /// A manual place never goes stale; a device fix does after [after].
  bool isStale(Duration after, {DateTime? now}) {
    if (isManual) return false;
    return (now ?? DateTime.now()).difference(fixedAt) > after;
  }

  /// Same point, same source, same timestamp — new name.
  UserPlace withLabel(String? newLabel) => UserPlace._(
        lat: lat,
        lng: lng,
        label: cleanLabel(newLabel),
        source: source,
        fixedAt: fixedAt,
      );

  bool samePoint(UserPlace other) => lat == other.lat && lng == other.lng;

  /// Great-circle distance in metres (haversine). Pure Dart so the model and
  /// its tests need no platform plugin.
  double distanceTo(UserPlace other) {
    const r = 6371000.0;
    double rad(double d) => d * math.pi / 180;
    final dLat = rad(other.lat - lat);
    final dLng = rad(other.lng - lng);
    final a = math.pow(math.sin(dLat / 2), 2) +
        math.cos(rad(lat)) *
            math.cos(rad(other.lat)) *
            math.pow(math.sin(dLng / 2), 2);
    return 2 * r * math.asin(math.min(1.0, math.sqrt(a)));
  }

  Map<String, dynamic> toJson() => {
        'v': schemaVersion,
        'lat': lat,
        'lng': lng,
        'label': label,
        'src': source.name,
        'at': fixedAt.millisecondsSinceEpoch,
      };

  /// Null for anything malformed or from an unknown schema version — callers
  /// treat that as "nothing saved", never as an error.
  static UserPlace? fromJson(Object? json) {
    if (json is! Map) return null;
    try {
      if (json['v'] != schemaVersion) return null;
      final lat = json['lat'];
      final lng = json['lng'];
      final at = json['at'];
      if (lat is! num || lng is! num || at is! int) return null;
      final src = PlaceSource.values.where((s) => s.name == json['src']);
      if (src.isEmpty) return null;
      final label = json['label'];
      return tryCreate(
        lat: lat.toDouble(),
        lng: lng.toDouble(),
        label: label is String ? label : null,
        source: src.first,
        fixedAt: DateTime.fromMillisecondsSinceEpoch(at),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  bool operator ==(Object other) =>
      other is UserPlace &&
      other.lat == lat &&
      other.lng == lng &&
      other.label == label &&
      other.source == source &&
      other.fixedAt == fixedAt;

  @override
  int get hashCode => Object.hash(lat, lng, label, source, fixedAt);

  @override
  String toString() =>
      'UserPlace(${source.name}, ${label ?? '<unnamed>'}, '
      '${lat.toStringAsFixed(3)},${lng.toStringAsFixed(3)})';
}
