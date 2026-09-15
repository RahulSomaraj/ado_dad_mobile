import 'dart:convert';

import 'package:ado_dad_user/services/location/user_place.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persistence for the single [UserPlace]. An interface so the service can be
/// tested with an in-memory store.
abstract class LocationStore {
  Future<UserPlace?> load();
  Future<void> save(UserPlace place);
  Future<void> clear();
}

/// Stores the place as one JSON string under [key].
///
/// One `setString` is one atomic write: the previous layout used three
/// separate unawaited writes, so a process killed between them could leave a
/// latitude from one fix next to a longitude from another.
class PrefsLocationStore implements LocationStore {
  static const String key = 'user_place.v1';

  // Layout written by builds before the location refactor.
  static const String legacyLat = 'last_lat';
  static const String legacyLng = 'last_lng';
  static const String legacyFixAt = 'last_fix_at';
  static const String legacyLabel = 'user_location';

  PrefsLocationStore({Future<SharedPreferences> Function()? prefs})
      : _prefs = prefs ?? SharedPreferences.getInstance;

  final Future<SharedPreferences> Function() _prefs;

  @override
  Future<UserPlace?> load() async {
    final SharedPreferences prefs;
    try {
      prefs = await _prefs();
    } catch (_) {
      return null;
    }

    final raw = _read(() => prefs.getString(key));
    if (raw != null) {
      UserPlace? place;
      try {
        place = UserPlace.fromJson(jsonDecode(raw));
      } catch (_) {}
      if (place != null) return place;
      // Corrupt or from an unknown schema: drop it rather than fail every
      // launch, then see whether legacy keys can still provide something.
      await _quiet(() => prefs.remove(key));
    }

    return _migrateLegacy(prefs);
  }

  /// One-time move from the old four-key layout. The legacy label is kept only
  /// together with coordinates — a name with no point is exactly the state
  /// this refactor removes. Source is `device` because nothing on disk says
  /// whether the old label was typed; the worst case is one GPS refresh
  /// renaming it, which is what older builds did anyway.
  Future<UserPlace?> _migrateLegacy(SharedPreferences prefs) async {
    final lat = _read(() => prefs.getDouble(legacyLat));
    final lng = _read(() => prefs.getDouble(legacyLng));
    final at = _read(() => prefs.getInt(legacyFixAt));
    final label = _read(() => prefs.getString(legacyLabel));

    final hadLegacy =
        lat != null || lng != null || at != null || label != null;
    if (!hadLegacy) return null;

    UserPlace? place;
    if (lat != null && lng != null) {
      place = UserPlace.tryCreate(
        lat: lat,
        lng: lng,
        label: label,
        source: PlaceSource.device,
        // No recorded age → epoch, i.e. stale, so it is refreshed promptly
        // instead of being trusted indefinitely.
        fixedAt: DateTime.fromMillisecondsSinceEpoch(at ?? 0),
      );
    }

    if (place != null) {
      try {
        await prefs.setString(key, jsonEncode(place.toJson()));
      } catch (_) {
        // Keep the legacy keys so the next launch can try again.
        return place;
      }
    }

    for (final k in const [legacyLat, legacyLng, legacyFixAt, legacyLabel]) {
      await _quiet(() => prefs.remove(k));
    }
    return place;
  }

  @override
  Future<void> save(UserPlace place) async {
    try {
      final prefs = await _prefs();
      await prefs.setString(key, jsonEncode(place.toJson()));
    } catch (_) {
      // A failed write only costs the next cold start its instant place.
    }
  }

  @override
  Future<void> clear() async {
    try {
      final prefs = await _prefs();
      await prefs.remove(key);
    } catch (_) {}
  }

  /// SharedPreferences getters throw when a key holds a different type.
  static T? _read<T>(T? Function() get) {
    try {
      return get();
    } catch (_) {
      return null;
    }
  }

  static Future<void> _quiet(Future<Object?> Function() op) async {
    try {
      await op();
    } catch (_) {}
  }
}

/// In-memory store for tests.
class MemoryLocationStore implements LocationStore {
  MemoryLocationStore([this.value]);

  UserPlace? value;
  int saves = 0;

  @override
  Future<UserPlace?> load() async => value;

  @override
  Future<void> save(UserPlace place) async {
    value = place;
    saves++;
  }

  @override
  Future<void> clear() async => value = null;
}
