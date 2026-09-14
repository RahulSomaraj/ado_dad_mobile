# AdoDad mobile — audit fix checklist

`ado_dad_mobile` · branch `dev_redesign` · checked against the working tree on 2026-09-14.

Legend: `[x]` done and in the tree · `[~]` partly done · `[ ]` open · **⛓** blocked on the backend agent.
Nothing below has been compiled — `flutter pub get` / `flutter analyze` still cannot run from this
session (the folder share won't mount, and the proxy blocks the Dart SDK download).

---

## P0 — Security

### P0-3 · Tokens out of plaintext SharedPreferences (F11) — **done this pass**
- [x] `lib/common/secure_token_store.dart` — new keystore-backed store
      (`EncryptedSharedPreferences` on Android, Keychain on iOS), with an in-memory
      mirror so the Dio `onRequest` interceptor doesn't cross the platform channel
      on every request
- [x] One-time migration: tokens left in SharedPreferences are copied into the
      keystore on first launch, then **both plaintext keys are removed** whether or
      not they were adopted
- [x] `getToken()` / `getRefreshToken()` now read the store — signatures unchanged,
      so the 14 call sites need no edit
- [x] `saveLoginResponse()` writes tokens to the store; `userName` / `userType` /
      `email` / `user_id` / `user_profile` / `loginTimestamp` stay in prefs
- [x] `clearUserData()` clears the store (and still removes the legacy keys)
- [x] `auth_service.refreshAccessToken()` — the two `setString('token'…)` writes
      after a successful refresh now go to the store
- [x] `main()` — `await SecureTokenStore().init()` right after `SharedPrefs().init()`,
      before `runApp`
- [x] `pubspec.yaml` — `flutter_secure_storage: ^9.2.4`
- [x] `android/app/build.gradle` — `minSdk = Math.max(flutter.minSdkVersion, 23)`
      (EncryptedSharedPreferences needs 23+)
- [x] Keystore read failure (restored backup, rotated keys) is caught → `deleteAll()`
      → treated as logged out, instead of throwing on every request
- [ ] **Verify:** `flutter pub get`, `flutter analyze`, then on a device that was
      logged in *before* this build: relaunch → still logged in, and
      `/data/data/com.adodad.user/shared_prefs/*.xml` no longer contains `token`
- [ ] Optional hardening: exclude the app from Android auto-backup (or add
      `data_extraction_rules` excluding the secure prefs file) so a restore to a new
      device doesn't ship an undecryptable blob and force the re-login path

---

## P1 — Major performance

### P1-1 · Home feed un-gated from GPS (F1) — done in the 14 Sep pass
- [x] `_bootstrapFeed()` dispatches off `getLastKnownPosition()` (~0 ms), never
      awaiting `getCurrentPosition` before the first ad request
- [x] Fresh fix only re-issues the feed when it moved > 2 km from the seed
- [x] Places autocomplete → place-details detour off the load path
- [x] Same shape in `category_list_page._initLoad()`
- [ ] **Measure:** launch → first `/v2/ads/list` on the wire, 5 cold runs, median.
      Nothing has been measured on-device yet — the whole P1 story is unverified
      until this number exists

### P1-4 · Ad detail opens on data it already has (F3) — **done this pass**
- [x] `AdDetailBloc({required repository, AddModel? seed})` — starts in
      `AdDetailState.loaded(seed)` instead of `initial()`
- [x] `fetch` skips `emit(loading())` when a seed is present → no `SkeletonDetail`
      on open; the `/v2/ads/:id` call is now a background revalidation
- [x] A failed revalidation no longer replaces the page with the error screen
      (cold loads still surface it)
- [x] `app_routes.dart:/add-detail-page` passes `seed: ad` from `state.extra`
- [x] `_handleCall` tells the user when the seeded row carries no seller phone yet,
      instead of a dead tap (it used to `return` silently)
- [ ] **Verify:** open an ad from Home → content is on screen on the first frame;
      price/status update in place when the detail response lands; the owner
      actions card and bottom buttons don't flicker

### P1-6b · Filter-sheet reference data cached for the session (F9)
- [ ] `app_routes.dart:322-360` creates 5 blocs on every sheet open, each firing
      `load()` in its constructor — manufacturers, models, fuel types, transmission
      types, commercial-vehicle types
- [ ] Add a `ReferenceDataCache` (plain singleton, `Map<String, Future<List<T>>>`)
      in `add_repo.dart` so each list is fetched once per process and the second
      open is instant
- [ ] Keep the bloc interface — cache at the repository, not in the widget tree
- [ ] Coordinate only loosely with the backend's Redis layer; the client cache is
      worth having regardless

### P1-7 · One GPS fix per browsing flow (F7, F8)
- [x] Duplicate `/banner` at cold start removed (`home_page.initState`; `main.dart`
      already dispatches it)
- [ ] `LocationService` singleton: last-known lat/lng persisted to prefs, **one**
      in-flight `getCurrentPosition` shared by all callers, `cachedPosition` (sync)
      + `freshPosition` (Future)
- [ ] Route the three call sites through it — `home_page:_bootstrapFeed`,
      `category_list_page:_initLoad`, `add_detail_page:2251-2263` (similar ads)
- [ ] Persist the fix so the *next* cold start seeds from it rather than from
      whatever the platform happens to have cached

---

## P2 — Architecture

### P2-1 · Route-scoped ads blocs over a caching repository (F2, F4, F14)
The structural fix behind most of P1. Biggest item on the list; do it as its own cycle.
- [ ] `AdsRepository` — single owner of ads I/O:
  - [ ] normalised cache key = filters + geo bucket (lat/lng rounded to 2 dp)
  - [ ] in-flight dedupe (same key → one request, shared Future)
  - [ ] LRU memory cache, TTL 60–120 s
  - [ ] stale-while-revalidate: serve stale immediately, refresh behind
- [ ] Split `AdvertisementBloc` into `HomeAdsBloc` / `CategoryAdsBloc` /
      `SearchAdsBloc`, created in the `GoRoute` builder and disposed with the route
- [ ] Drop the three interleaved cursors (`_currentPage`, `_allAdsPage`,
      `_searchPage`) and the `_isFetching` / `_isSearchFetching` /
      `_locationFallbackToAll` / `_locationQueryHasNext` flags — each feed owns one
- [ ] Delete the return-from-category full refetch (`home_page.dart:1100-1104`);
      Home's state survives on its own bloc
- [ ] Remove `AdvertisementBloc` from `main.dart`'s 15 app-scoped singletons

### P2-3 · Lazy, recycling grids (F5)
- [x] Home: `SingleChildScrollView` + `shrinkWrap` grid → `CustomScrollView` +
      `SliverGrid`, with `findChildIndexCallback` keyed on `ad.id`
- [x] Category: `GridView.builder` with its own controller (no `shrinkWrap`) —
      already lazy, nothing to change
- [x] Search: same — `GridView.builder` inside an `Expanded`, already lazy
- [ ] Re-check the seller-profile / showroom / wishlist / my-ads grids, which the
      audit didn't cover

### P2-2b ⛓ · `POST /v2/ads/list` → `GET` (C2)
- [ ] Wait for the backend to ship the GET route
- [ ] Switch `add_repo.fetchAllAds` to `_dio.get` with query params
- [ ] Enable `If-None-Match` / ETag handling in `ApiService`
- [ ] Tell the backend agent when the client no longer sends POST

### P2-6 · `hasNext` no longer derived from `total` (C1)
- [x] `add_repo.fetchAllAds` prefers `response.data['hasNext']`; the
      `(page*limit) < total` arithmetic is now only a fallback
- [ ] Once the server always sends `hasNext`, delete the fallback branch entirely
- [ ] Tell the backend agent the client has migrated, so it can make `includeTotal`
      opt-in and drop the count query

---

## P3 — Optimization

### P3-1 · Image decode + disk cache (F6)
- [x] `AppNetworkImage` rewritten on `cached_network_image` — disk cache survives
      restarts
- [x] `memCacheWidth` from `LayoutBuilder` constraints × `devicePixelRatio`
      (a 172 pt card decodes ~517 px, not 3000)
- [x] Fullscreen viewer and seller avatar use `CachedNetworkImageProvider`, so they
      read bytes the grid already downloaded
- [x] Retry double-timer bug fixed; real progress indicator; `FilterQuality.low`
- [ ] **Measure:** peak RSS after scrolling 5 pages, before/after

### P3-4 · Debounce the scroll listeners (F10)
- [ ] `home_page.dart:165-170` and `category_list_page.dart:56-63` dispatch on every
      notification within 300 px of the bottom; a single fling enqueues hundreds of
      events that `_isFetching` then absorbs
- [ ] Same in `search_page.dart:370-380`
- [ ] Add a ~200 ms debounce (or a `NotificationListener` threshold guard that only
      fires on the crossing, not on every frame)

### P3-6 ⛓ · Drop the client-side `commercialVehicleTypes` re-filter (F12, C4)
- [ ] The workaround at `add_repo.dart:112-125` silently shrinks pages (20 → 3) and
      is the reason `hasNext` had to be defensive
- [ ] Ask the backend agent to confirm the server filter on
      `commercialVehicleDetails` is correct, then delete the block

---

## P4 — Cleanup

### P4-1 · God widgets (F13)
- [ ] `profile_page.dart` (171 KB) — split by section
- [ ] `add_detail_page.dart` (114 KB) — the carousel, specs card and similar-ads
      section are already separable
- [ ] Lift GPS / geocoding / direct API calls out of `initState` / `build` into
      services (falls out of P1-7 and P2-1)

### P4-4 · Bloc lifecycle (F14)
- [ ] Clear `AdvertisementBloc` state on logout — the accumulated `listings` list is
      currently retained for the process lifetime
- [ ] Audit `_videoControllers` / `_onVideoCompleteCallbacks` disposal in
      `add_detail_page` (detail pages are pushed and popped constantly)
- [ ] Dead fields `_videoController` / `_videoControllers` are never assigned —
      delete rather than "fix"

---

## Shared contracts — for the backend agent

### C1 · `hasNext` — **frontend done, backend's move**
Client consumes `response.data['hasNext']` when present. Safe to make `includeTotal`
opt-in and drop the duplicate count query.

### C2 · `POST` → `GET /v2/ads/list` — waiting on the backend
Ship GET, keep POST for one release; the client migrates then.

### C3 · Seller `email` / `phoneNumber` in list rows — **frontend audit complete**
Grepped the whole `lib/` tree for `user.email` / `user.phone`:
- Only two reads, both in `add_detail_page.dart` (lines 1433, 1754) — the seller
  email row and the call handler, both on the **detail** response.
- **No list screen reads either field.** Safe to strip them from the public list
  projection.
- One caveat introduced by P1-4: the detail page now opens seeded from a *list* row,
  so for the ~300 ms before `/v2/ads/:id` lands, email/phone come from the list
  projection. With C3 shipped that means the call button is briefly unavailable —
  handled: it now shows "Seller contact not available yet" rather than doing nothing.

### C4 · `commercialVehicleTypes` server-side filter — waiting on the backend
Confirm the filter applies to the `commercialVehicleDetails` sub-document; the
client removes its re-filter after that.

---

## Suggested next cycle

1. `flutter pub get` + `flutter analyze` + a device run — nothing since the 14 Sep
   pass has been compiled, and two dependency changes are now stacked.
2. Capture the P1-1 baseline numbers (launch → first `/v2/ads/list`, request count in
   the first 10 s, peak RSS after 5 pages). Every claim above is unmeasured.
3. P1-7 `LocationService` — small, self-contained, kills two of the three GPS fixes.
4. P2-1 — the big one, on its own branch.
