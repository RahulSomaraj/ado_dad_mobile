# Location state — investigation & architecture plan

Ado-dad mobile · 15 Sep 2026 · status: **Phases 1–3 implemented (uncompiled) — run `tool/location_verify.bat`, then Phase 4 on device**

Files read: `lib/services/location_service.dart`, `lib/features/home/ui/home_page.dart`, `lib/main.dart`, `lib/common/shared_pref.dart`, `lib/repositories/add_repo.dart`, `lib/features/home/ui/category_list_page.dart`, `lib/features/home/ui/ad_detail/ad_detail_seller.dart`, `lib/features/search/ui/search_page.dart`, `pubspec.yaml`.

---

## 1. What the code actually does (verified)

The earlier diagnosis holds: location has two owners. `LocationService` owns coordinates (`last_lat` / `last_lng` / `last_fix_at`). `_HomePageState._userLocation` owns the label (`user_location`). But reading the whole flow turns up a worse problem than "label and point can disagree". **A place the user picks by hand doesn't stick. The app quietly reverts it.**

### Confirmed defects

| # | Defect | Where | What the user sees |
|---|---|---|---|
| D1 | The label is only read in Phase 2 of `_bootstrapFeed`, after `await seedPosition()` and `await SharedPreferences.getInstance()` | home_page.dart:101–132 | Cold start shows "Locating…" even though the answer is already on disk |
| D2 | A manual pick never reaches `LocationService`. The dialog writes only `user_location` (home_page.dart:700), then `_applyLocationBasedRecommendations` resolves coords through Places and sends them **straight to the bloc** | home_page.dart:421–476, 1062–1072 | Home feed shows Mumbai. Category list, ad-detail distance and "similar near you" still use GPS (Kerala) |
| D3 | **Manual picks get reverted.** On resume after 30 min, `_refreshLocationOnResume` → `freshPosition` → `_applyResolvedAddress` overwrites the label with the GPS address and re-queries the feed. On cold start, Phase 2's `freshPosition` does the same | home_page.dart:252–270, 137–157 | User sets Mumbai, reopens later, and it's back to their GPS town with no action on their part |
| D4 | **Race.** If the user picks a place during Phase 2's GPS wait (up to 6 s), the late fix calls `_updateAddressDisplay(fresh)` and may dispatch `searchByLocation(gps)` after the manual pick | home_page.dart:137–157 | The pick "doesn't take" on first launch |
| D5 | If Places fails (expired key), a manual pick falls back to `fetchAllListings` while the chip still says Mumbai | home_page.dart:469–475 | Label says one place, feed is unfiltered |
| D6 | Pull-to-refresh re-geocodes the **label text** through Places instead of reusing the coordinates it already has | home_page.dart:798–800 | An extra network call on every refresh. Breaks whenever the key breaks |
| D7 | `_persist` does 3 separate `setDouble`/`setInt` writes, unawaited. They aren't atomic | location_service.dart:167–175 | Rare: if the process dies mid-write, lat and lng come from different fixes |
| D8 | The resume observer lives on `HomePage`. If Home isn't mounted (deep link straight into an ad, for example), resume doesn't refresh | home_page.dart:216–222 | Stale radius on other screens |
| D9 | Geocoding logic is copied twice (`_resolveAddress` and the dialog's "Use current location") and lives in a 67 KB widget | home_page.dart:357–388, 635–669 | Fixes land in one copy and miss the other (this already happened once, per the code comment) |

### Not a problem (checked)

- Logout (`clearUserData`) removes only auth keys, so location survives logout.
- Search's location mode (search_page.dart:587) is a deliberate one-off query. It shouldn't change the user's place. Leave it alone.

### Adjacent risk — checked, not an issue

The category list already gets its own route-scoped `AdvertisementBloc` (app_routes.dart:193), so it no longer overwrites the Home feed. Search still shares the global bloc, but that's out of scope here.

---

## 2. Design principles

1. **One value, one owner.** Coordinates and label form a single immutable `UserPlace`, and only `LocationService` writes it.
2. **A place always has coordinates.** A label-only place can't be represented, which rules out D2 and D5 by construction.
3. **Manual beats GPS.** A place carries a `source`. GPS updates apply only while the user is in "follow my location" mode, which fixes D3 and D4.
4. **Every async write is fenced.** A generation counter drops late results, so an old GPS fix or reverse-geocode can never overwrite a newer pick (D4).
5. **Hydrate before the first frame.** One awaited read in `main()`. After that, everything reads synchronously (D1).
6. **Widgets subscribe, they don't copy.** Screens use `ValueListenableBuilder`, and the Home feed reacts to changes instead of each code path dispatching its own event.
7. **Injectable edges.** Geolocator, geocoders and storage sit behind small interfaces so the race and revert cases can be unit-tested.

---

## 3. Target architecture

```
lib/services/location/
  user_place.dart          UserPlace value + JSON (v1) + validation
  location_store.dart      single-key persistence + legacy migration
  device_locator.dart      interface over Geolocator (fake in tests)
  place_resolver.dart      reverse + forward geocoding, Google → platform fallback, label cache
  location_service.dart    owner: ValueNotifier<UserPlace?> + ValueNotifier<LocationStatus>
  location_lifecycle.dart  app-level resume observer
```

`lib/services/location_service.dart` stays as a one-line `export` so the four existing imports keep compiling.

### 3.1 `UserPlace`

```dart
enum PlaceSource { device, manual }

@immutable
class UserPlace {
  final double lat, lng;
  final String? label;        // null = coords known, name not resolved yet
  final PlaceSource source;
  final DateTime fixedAt;

  const UserPlace._(this.lat, this.lng, this.label, this.source, this.fixedAt);

  /// Only way to build one — rejects NaN, out-of-range and the 0,0 null-island.
  static UserPlace? tryCreate({required double lat, required double lng,
      String? label, required PlaceSource source, DateTime? fixedAt}) {
    if (!lat.isFinite || !lng.isFinite) return null;
    if (lat.abs() > 90 || lng.abs() > 180) return null;
    if (lat == 0 && lng == 0) return null;
    final l = label?.trim();
    return UserPlace._(lat, lng, (l == null || l.isEmpty || l == 'Location not available') ? null : l,
        source, fixedAt ?? DateTime.now());
  }

  bool get isManual => source == PlaceSource.manual;
  bool isStale(Duration after) => !isManual && DateTime.now().difference(fixedAt) > after;
  UserPlace withLabel(String label) => UserPlace._(lat, lng, label, source, fixedAt);

  Map<String, dynamic> toJson() => {'v': 1, 'lat': lat, 'lng': lng, 'label': label,
      'src': source.name, 'at': fixedAt.millisecondsSinceEpoch};
  static UserPlace? fromJson(Map<String, dynamic> j) { /* v check, tryCreate, else null */ }
}
```

A manual place is never stale. A device place goes stale after 30 min, same as today.

### 3.2 `LocationStore` — atomic and migrating

- One key, `user_place.v1`, holding a JSON string. That's one `setString`, so a write can't land half-done (D7).
- `load()`: read `user_place.v1`. If it's missing, **migrate**: `last_lat`/`last_lng`/`last_fix_at` plus `user_location` (ignoring the `Location not available` sentinel) become `UserPlace(source: device)`. Write it forward, then remove the four legacy keys.
- Corrupt JSON returns null and the key is removed. Never throw.
- Uses the `SharedPreferences` instance that `SharedPrefs().init()` already holds, so there's no second `getInstance`.

> Migration sets `source: device` even when the legacy label was typed by hand. Nothing on disk records which one it was. The worst case is one GPS refresh relabelling it, which is today's behaviour, so the migration is no worse than now.

### 3.3 `LocationService` — the owner

```dart
enum LocationStatus { idle, locating, unavailable, ready }

class LocationService {
  final ValueNotifier<UserPlace?> place = ValueNotifier(null);
  final ValueNotifier<LocationStatus> status = ValueNotifier(LocationStatus.idle);
  int _gen = 0;                       // bumps on every commit

  Future<void> restore();             // main(), before runApp
  Future<bool> useDevice({bool askPermission = false});   // "Use current location"
  Future<SetPlaceResult> setManual({String? placeId, required String text});
  Future<void> refreshIfFollowing();  // resume / bootstrap — no-op when manual

  // Compatibility — existing callers unchanged:
  Future<Position?> seedPosition();   // => place.value as synthetic Position
  Future<Position?> freshPosition({...});  // raw fix, dedup kept, does NOT commit a manual place away
  bool movedEnough(...);
}
```

**The commit rule** (the only function that assigns `place.value`):

```dart
int _commit(UserPlace next) {
  _gen++;
  place.value = next;
  status.value = LocationStatus.ready;
  unawaited(_store.save(next));
  return _gen;
}

Future<void> _labelInBackground(UserPlace p, int gen) async {
  final label = await _resolver.reverse(p.lat, p.lng);
  if (label == null || gen != _gen) return;     // superseded → drop (D4)
  _commit(p.withLabel(label));                  // same point, now named
}
```

**Flows:**

| Call | Behaviour |
|---|---|
| `restore()` | `place.value = await store.load()`; status becomes `ready` if the place is non-null, else `idle`. Target cost is one prefs read (single-digit ms). |
| `refreshIfFollowing()` | Returns if `place?.isManual`. Returns if the place is fresh and labelled. Otherwise `status=locating` (only when place is null), `freshPosition()`. On null: `status=unavailable` if place is null, else keep the old place. On a fix: `gen=_commit(device place, label: old label if within 2 km else null)`, then `_labelInBackground`. |
| `useDevice(askPermission)` | Checks and, if asked, requests permission. **Only called from an explicit tap.** Gets a high-accuracy fix with a 10 s timeout, commits `source: device` (which also switches back to follow mode), then labels in the background. Returns false with `status=unavailable` on failure. |
| `setManual(placeId?, text)` | Coordinates come from `resolver.forward(placeId, text)`: Places details when a suggestion was picked, else the platform `locationFromAddress`. **On failure nothing is committed** and `SetPlaceResult.notFound` goes back to the dialog. On success, commit `source: manual, label: text`. |

### 3.4 `PlaceResolver`

- `reverse(lat, lng)`: Google reverse geocode → `_formatIndian` (moved from home_page) → platform `placemarkFromCoordinates` → null. Results cached in memory, keyed by coords rounded to 2 dp (~1 km), so a resume in the same town makes no call.
- `forward({placeId, text})`: `placeId` → `getPlaceDetails` → `geometry.location`. Otherwise platform `locationFromAddress(text)` from `geocoding ^4`, **which needs no Google key**.
- Every call has a timeout (5 s) and catches everything, returning null. It never throws into the UI.

### 3.5 `LocationLifecycle`

A `WidgetsBindingObserver` registered once in `MyApp.initState`, so it works on every screen (D8):

- On `resumed`: debounce 1 s, then `LocationService().refreshIfFollowing()`. Single-flight is already guaranteed by `freshPosition`'s in-flight future.
- `HomePage` drops its own observer, `_resumeRefreshInFlight`, `_determinePosition`, `_resolveAddress`, `_getDetailedAddressFromCoordinates`, `_formatAddressFromGooglePlaces`, `_getLocationAndAddress`, `_applyLocationBasedRecommendations`, `_userLocation`, `_locationUnavailable` and `_kNoLocation`. That's roughly 400 lines out of home_page.

### 3.6 Home feed reacts, not pushes

```dart
// initState
_lastQueried = LocationService().place.value;
_dispatchFeed(_lastQueried);                          // first frame, no await
LocationService().place.addListener(_onPlaceChanged);
unawaited(LocationService().refreshIfFollowing());

void _onPlaceChanged() {
  final p = LocationService().place.value;
  if (!_needsRequery(_lastQueried, p)) return;       // label-only change → no refetch
  _lastQueried = p;
  _dispatchFeed(p);
}

bool _needsRequery(UserPlace? a, UserPlace? b) =>
    a == null || b == null || a.source != b.source ||
    Geolocator.distanceBetween(a.lat, a.lng, b.lat, b.lng) > LocationService.movedThresholdMeters;

void _dispatchFeed(UserPlace? p) => p == null
    ? _adBloc.add(const AdvertisementEvent.fetchAllListings())
    : _adBloc.add(AdvertisementEvent.searchByLocation(latitude: p.lat, longitude: p.lng));
```

Pull-to-refresh becomes `AddRepository.invalidateAdsCache(); _dispatchFeed(LocationService().place.value);`. That's coordinates, with no Places call (D6). Remove the listener in `dispose`.

### 3.7 Chip — one widget, four states, never blank

`lib/features/home/ui/widgets/location_chip.dart`:

```dart
ValueListenableBuilder<UserPlace?>(
  valueListenable: LocationService().place,
  builder: (_, place, __) => ValueListenableBuilder<LocationStatus>(
    valueListenable: LocationService().status,
    builder: (_, status, __) {
      final label = place?.label
          ?? (place != null ? 'Current location'
          : status == LocationStatus.unavailable ? 'Set location' : 'Locating…');
      ...
    }),
)
```

Tapping the chip or the pin opens `LocationPickerSheet`, which replaces `_showLocationInputDialog`:

- Suggestions keep their `placeId`, not just `description`. The dialog currently throws the id away, which forces a second autocomplete round later.
- **Use current location** calls `LocationService().useDevice(askPermission: true)` and closes on success.
- **Save** calls `setManual(placeId: selected?.id, text: controller.text)`. On `notFound` it shows an inline error ("Couldn't find that place") and stays open. It never saves a label alone.
- Debounce autocomplete by 300 ms. The dialog currently calls Places on every keystroke from 2 characters on.
- Watch for `setState` after the dialog closes. Use a `mounted` guard or a `StatefulWidget` sheet.

---

## 4. Your two judgement calls

**1. Should a typed place set coordinates?** Yes, always, and if it can't, it isn't saved. The expired key doesn't block this: the platform `locationFromAddress` in `geocoding` is keyless and covers free text, and Places details (when the key works) covers picked suggestions. "Clear coords and show unfiltered" isn't needed, because a place with no coordinates can't exist in this model.

**2. ValueNotifier vs Cubit.** Use ValueNotifier on the service. `add_repo.dart` can't read a bloc, and `place` is a single value with no events. If a bloc is wanted later for `BlocListener` ergonomics, a 10-line `LocationCubit` that mirrors the notifier can wrap it without changing ownership.

**One new question** the design raises. Default below, override if you disagree:
- **Does a manual place apply app-wide?** Default is yes (OLX-style). Category list, ad-detail distance and "similar near you" all use it, because they already go through `seedPosition()`, which will return the chosen place. If you'd rather keep distance on ad detail based on real GPS, `fetchAdDetail` switches to `cachedDevicePosition` instead.

---

## 5. Implementation phases

Each phase compiles and ships on its own.

### Phase 1 — model, store, hydrate (fixes D1, D7)
- [ ] `user_place.dart`, `location_store.dart` (+ migration), `device_locator.dart`
- [ ] `LocationService.restore()` + `place`/`status` notifiers. `seedPosition()` reads `place.value` first
- [ ] `main.dart`: `await LocationService().restore();` right after `await SharedPrefs().init();`
- [ ] `home_page` initState: pre-fill the chip from `place.value?.label` synchronously (temporary bridge until Phase 2)
- [ ] Unit tests: JSON round-trip, validation, migration (with and without the sentinel, lat without lng, corrupt JSON)

### Phase 2 — single write path (fixes D2, D3, D4, D5)
- [ ] `place_resolver.dart` (move the formatter and fallbacks out of home_page)
- [ ] `_commit` + generation fence, `refreshIfFollowing`, `useDevice`, `setManual`
- [ ] `LocationChip` + `LocationPickerSheet`. Delete `_userLocation`, the dialog, `_kNoLocation` and all `user_location` reads and writes
- [ ] Unit tests with a fake locator and resolver:
  - manual set → `refreshIfFollowing` → place unchanged
  - GPS fix pending → `setManual` → fix resolves → manual kept (race)
  - reverse label resolves after a newer commit → dropped
  - `setManual` forward-geocode fails → nothing persisted
  - `useDevice` after manual → source flips to device

### Phase 3 — reactive feed + app lifecycle (fixes D6, D8, D9)
- [ ] `location_lifecycle.dart` registered in `MyApp`. Remove HomePage's observer
- [ ] Home `_onPlaceChanged` listener + `_dispatchFeed`. Pull-to-refresh uses coordinates
- [ ] Delete `_bootstrapFeed` Phase 2, `_refreshLocationOnResume`, `_getLocationAndAddress`, `_determinePosition`
- [ ] `category_list_page._initLoad`: keep `seedPosition`. Replace its own `freshPosition` upgrade with a `place` listener (same re-query rule)

### Phase 4 — verify on device
- [ ] V-L1 Fresh install, permission allowed → chip goes "Locating…" to town name, feed is nearby
- [ ] V-L2 Kill and relaunch → **first frame** shows the town name (no "Locating…")
- [ ] V-L3 Set "Mumbai" → Home feed, category list, ad-detail distance and similar ads all reflect Mumbai
- [ ] V-L4 Background 35 min, resume → still Mumbai
- [ ] V-L5 Kill and relaunch → still Mumbai, no GPS relabel
- [ ] V-L6 Picker → Use current location → back to GPS town, follows on later resumes
- [ ] V-L7 Deny permission → "Set location", tappable. Grant in Settings, resume → resolves
- [ ] V-L8 Airplane mode / bad key → typed place resolves via the platform geocoder, or shows an inline error. The chip never disagrees with the feed
- [ ] V-L9 Upgrade over the current build with `user_location` and `last_lat` set → shows the old label instantly, and legacy keys are gone
- [ ] V-L10 Set a place within 2 s of cold start (race) → pick survives

---

## 6. Size & risk

- New: ~6 small files (~450 lines incl. tests). home_page.dart shrinks by ~400 lines.
- Touched: `location_service.dart` (rewritten, API-compatible), `main.dart` (+1 line), `home_page.dart`, `category_list_page.dart` (small). `add_repo.dart` and `ad_detail_seller.dart` don't change.
- **Main risk:** `restore()` before `runApp` adds startup latency. It's one prefs read on an instance that's already loaded, so it should take <5 ms. Measure it in V-L2.
- **Rollback:** Phase 1 is additive. Phases 2 and 3 are the behaviour changes, so ship them together in one build.

---

## 7. Implementation log (15 Sep 2026)

**New**
- `lib/services/location/user_place.dart`: value type, JSON v1, validation, haversine
- `lib/services/location/location_store.dart`: `PrefsLocationStore` (key `user_place.v1`, legacy migration, corrupt-safe) + `MemoryLocationStore`
- `lib/services/location/device_locator.dart`: `DeviceLocator` interface + Geolocator implementation (hard timeout)
- `lib/services/location/place_resolver.dart`: reverse (Google → platform, 1 km cache), forward (placeId → Places text search → platform `locationFromAddress`), suggestions
- `lib/services/location/location_lifecycle.dart`: app-level resume observer, 1 s debounce
- `lib/features/home/ui/widgets/location_chip.dart`, `location_picker_dialog.dart`
- `test/services/location/{user_place,location_store,location_service}_test.dart`: covers the revert, race, late label, not-found, migration and corrupt JSON cases
- `tool/location_verify.bat`: pub get + analyze on the touched files + location tests, writing to `tool/location_verify.log`

**Changed**
- `lib/services/location_service.dart`: rewritten. `seedPosition` / `freshPosition` / `movedEnough` / `isAvailable` kept for existing callers. `freshPosition` no longer changes the place
- `lib/main.dart`: `await LocationService().restore()` after `SharedPrefs().init()`, plus `LocationLifecycle.instance.attach()`
- `lib/features/home/ui/home_page.dart`: all location state, geocoding, the dialog and the lifecycle observer removed (1,760 → 1,120 lines). Feed dispatch runs through `_dispatchFeed` + a `place` listener. Pull-to-refresh reuses the coordinates
- `lib/features/home/ui/category_list_page.dart`: its own GPS upgrade is replaced by a `place` listener. It skips re-querying while filters are applied, so the user's filters aren't reset

**Differences from the plan**
- Kept a dialog (not a bottom sheet) to limit visual change. It has a 300 ms debounce, keeps `placeId`, shows inline errors with an "Open settings" action, and prefills only a manual label
- Address formatter: `contains('pin')` became a whole-word match (it was dropping place names like "Pinarayi")
- A legacy `user_location` with no saved coordinates is dropped on migration rather than geocoded
- `add_repo.dart` and `ad_detail_seller.dart` are unchanged. They pick up manual places through `seedPosition()`
