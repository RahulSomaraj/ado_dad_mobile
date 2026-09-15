# AdoDad mobile — frontend audit fix checklist

`ado_dad_mobile` · branch `dev_redesign` · companion to `FRONTEND_AUDIT.md`
Last updated 2026-09-14.

**Only open work is listed as checkboxes.** Everything already implemented is in
[Done](#done) at the bottom, as a log — do not re-do those.

> **Nothing in the Done log has been compiled or measured.** `flutter pub get`,
> `flutter analyze` and a device run could not be executed from the Cowork
> session that wrote it (the repo share won't mount and the proxy blocks the
> Dart SDK). Two dependency changes are stacked. Start here.

---

## Open

### V — Verify the unverified (do this first)
- [ ] `flutter pub get` — `flutter_secure_storage` and `cached_network_image`
      are both in `pubspec.yaml` but not yet resolved
- [ ] `flutter analyze` — first compile of everything below the Done line
- [ ] `flutter run --profile` on a real device
- [ ] **Login still works after the token move.** On a device that was logged in
      *before* this build: relaunch → still logged in (migration path), then
      log out / log in (fresh path). Confirm
      `/data/data/com.adodad.user/shared_prefs/*.xml` no longer contains `token`
- [ ] **`minSdk` is now 23** (`android/app/build.gradle`) — confirm that's
      acceptable for the Play listing before shipping
- [ ] Ad detail: open from Home → content on the first frame, no skeleton;
      values patch in when `/v2/ads/:id` lands
- [ ] Home → category → back: Home keeps its listings *and* scroll position,
      and no `/v2/ads/list` goes out on the back press
- [ ] Post / edit / mark-sold / delete an ad → the lists show the change
      (the repository cache is cleared on those writes; this is the path most
      likely to surface a caching bug)
- [ ] Pull-to-refresh on Home and on a category reaches the network

### V2 — Ad detail polish (pass 5, 2026-09-15) — verify on device
Written without a compiler. Run `flutter analyze lib` first; expect fixes to be
small (a missing import, a const). Spec: `claude/ad-detail-polish-pass5.md`.
- [ ] `flutter analyze lib` clean for `lib/features/home/ui/ad_detail/`,
      `add_detail_page.dart`, `lib/common/ad_format.dart`, `ad_category.dart`,
      `app_spacing.dart`, `app_colors.dart`, `app_textstyle.dart`, `add_model.dart`
- [ ] Buyer, car ad: price reads ₹4,85,000; 4 key facts; Overview table has no
      "-" rows; Documents shows RC / insurance only when the ad has them
- [ ] Two-wheeler, commercial and property ads each show their own key facts
      and rows (commercial: payload/axles/fitness/permit; property: beds/area)
- [ ] Gallery: no auto-advance, photos not dimmed, controls clear the notch,
      thumbnail tap jumps, "+N" opens fullscreen, video plays fullscreen
- [ ] Owner: Live pill + Views/Saved/Chats + tip; bar = Edit · Mark as sold;
      ⋮ → Delete ad asks for confirmation; no favourite/report/seller card
- [ ] Owner controls correct on the first frame (no buyer bar flash)
- [ ] Mark as sold / delete still pop back with `true` and lists refresh
- [ ] Call dials `+91…` (E.164); Chat/Offer send the ad *title*, not description
- [ ] Safety note dismiss survives an app restart (30-day snooze)
- [ ] Similar: "Similar Swift near you" when ≥2 same-model ads within ±20%,
      otherwise falls back to "Similar near you"
- [ ] Dark mode: no white blocks on the detail page
- [ ] Text scale 1.3×: key facts and bottom bar don't overflow
- [x] Key names confirmed against `get-ad-by-id.uc.ts`: `viewCount`,
      `favoritesCount`, `chatsCount`, `status` (approved/pending/rejected)
- [ ] Needs backend D-1…D-5 deployed (`ado-dad/BACKEND_FIX_CHECKLIST.md` §D):
      sold ad opens with the SOLD banner; "Price dropped ₹X · 3 days ago" after
      a price cut; distance appears in the meta line (detail now sends the
      seed `lat`/`lng`); verified tick shows for `isVerified` sellers
- [ ] Once analyze is green, delete the now-unused widgets in
      `ui/widgets/`: `ad_detail_title_price`, `ad_detail_description`,
      `ad_detail_seller_tile`, `ad_detail_bottom_buttons`,
      `ad_detail_carousel_dots`, `ad_detail_card_shell`, `ad_detail_key_val_row`,
      `ad_detail_spec_tile`, `ad_detail_tabs_section`, `ad_detail_report_button`,
      `ad_detail_mark_as_sold_button` (grep for other importers first)

### M — Baseline numbers (no performance claim is real without these)
Same device, cold start, 5 runs, report the median:
- [ ] launch → first `/v2/ads/list` on the wire (ms)
- [ ] launch → first `ListingsLoaded` emit (ms)
- [ ] HTTP requests in the first 10 s
- [ ] peak RSS after scrolling 5 pages
- [ ] Repeat Home → category → back → search and count requests; with the
      route-scoped blocs and the repo cache this should now be a small,
      bounded number

### P2-3b · Seller-profile grid still builds every card
- [ ] `seller_profile_page.dart:197` — `GridView.builder(shrinkWrap: true,
      physics: NeverScrollableScrollPhysics())` inside a scrolling `Column`
- [ ] Left alone deliberately: this page pages via an explicit "Load more"
      button, so the child count only grows when the user asks, and converting
      the page to `CustomScrollView` + slivers means restructuring a deeply
      nested build method — not worth doing without a compiler in the loop
- [ ] Do it in the same cycle as any other work on that page
- [ ] The other list screens were checked and are fine: category, search,
      showroom, wishlist and my-ads all use a plain `GridView.builder` /
      `ListView` with their own controller (lazy, recycling)

### P4-1 · God widgets
- [ ] `profile_page.dart` — 171 KB, one file
- [ ] Lift the remaining geocoding / direct API calls out of `initState` /
      `build` into services
- [ ] Deliberately not started: a mechanical split of this size needs
      `flutter analyze` between steps, which this session can't run. Do it
      locally, one extraction per commit

### ⛓ C2 / P2-2b · `POST /v2/ads/list` → `GET`
Blocked on the backend agent.
- [ ] Wait for the GET route to ship (POST stays alive for one release)
- [ ] Switch `_fetchAdsFromNetwork` to `_dio.get` with query params
- [ ] Add `If-None-Match` / ETag handling in `ApiService`; the repository cache
      keys are already normalised, so an ETag maps 1:1 onto a cache entry
- [ ] Tell the backend agent when the client stops sending POST

### ⛓ C4 / P3-6 · Client-side `commercialVehicleTypes` re-filter
Blocked on the backend agent.
- [ ] Backend confirms the filter applies to the `commercialVehicleDetails`
      sub-document
- [ ] Then delete the re-filter in `_fetchAdsFromNetwork` (`add_repo.dart`) —
      it silently shrinks pages (20 → 3) and is why `hasNext` needs a fallback

### ⛓ C1 · `hasNext` fallback removal
- [ ] Frontend already consumes `response.data['hasNext']`; the
      `(page*limit) < total` branch is only a fallback
- [ ] Once the server always sends `hasNext`, delete the fallback and tell the
      backend it can make `includeTotal` opt-in and drop the count query

### Hardening / follow-ups
- [ ] Exclude the secure-storage prefs file from Android auto-backup (or set
      `data_extraction_rules`) so a restore to a new device doesn't ship an
      undecryptable blob — today that path is caught and treated as "logged out"
- [ ] Favourite toggles don't invalidate the ads cache. They patch bloc state
      directly, so the UI is right; a stale cached page can briefly show an old
      heart after a cache hit. Fix if it shows up in testing
- [ ] `AdsCache` TTLs (`freshFor` 90 s, `keepFor` 5 min, 48 entries) are a first
      guess — tune once the request-count numbers from **M** exist

---

## Done

Implemented and committed to `dev_redesign`; unverified until section **V** passes.

### 2026-09-15 · ad detail polish (pass 5)

Written to disk, **not committed and not compiled** — see **V2**.

- `add_detail_page.dart` 3,094 → ~600 lines. One build path for all 8 bloc
  states (was 5 duplicated slivers trees); owner resolved synchronously from
  `SharedPrefs().getString('user_id')` (was 8+ `FutureBuilder`s).
- Sections moved to `lib/features/home/ui/ad_detail/`: `ad_detail_gallery`
  (carousel + thumbs + overlay buttons), `ad_detail_header` (price/title/meta,
  owner status/stats/tip), `ad_detail_specs` (per-category key facts, Overview,
  Documents, Features), `ad_detail_body` (expandable description, footer,
  safety note), `ad_detail_seller` (seller card + similar ads), `ad_detail_bars`
  (buyer / owner / sold bars), `ad_detail_states` (skeleton, error, sold
  banner), `ad_detail_section`, `ad_detail_media` (video + fullscreen viewers,
  moved verbatim).
- New `lib/common/ad_format.dart` (`AdFormat`: Indian grouping, km, relative
  time, title case), `ad_category.dart` (`AdCategory` enum + edit routes),
  `app_spacing.dart` (`AppSpacing`, `AppRadius`).
- `AppColors`: `textMuted` (#6B7080, 4.9:1), `positiveText`, `chipFill`,
  `primarySoft`, `successColor`. `AppTextstyle`: priceLarge, sectionTitle,
  titleMedium, bodyText, specValue, specLabel, caption, micro, button.
- `AddModel`: optional `viewCount`, `favoritesCount`, `chatsCount`, `status`.
- Bugs fixed: raw `₹ 485000` price, `Kmpl` odometer, fake EMI (detail and
  `RichAdCard`), full-photo gradient, gallery auto-advance timer, "No Parking" /
  "No Garden" as features, chat/offer sent `description` as the title, call
  ignored `countryCode`, hardcoded 65 dp bottom gap, `top: 50` controls,
  hardcoded white/black colours (dark mode), 9 sp badges.

### 2026-09-14 · second pass

**P2-1 — route-scoped feeds over a caching repository** *(F2, F4, F14)*
- `AdsCache` in `add_repo.dart`: in-flight dedupe (same key → one request),
  memory LRU (48 entries) with a 90 s fresh window, and stale-while-revalidate
  up to 5 min — a stale page is returned immediately and refreshed behind the
  caller.
- Cache key normalises the request body and buckets lat/lng to 2 dp (~1.1 km),
  so GPS jitter no longer produces a different key for the same query.
- Cleared on post / update / mark-sold / delete, so a write is never papered
  over by a cached page. `AddRepository.invalidateAdsCache()` is the public hook.
- `/search` and `/category-list-page` now build their own `AdvertisementBloc`
  in the route builder, disposed with the route. Home's instance (from
  `main.dart`) is no longer overwritten by either screen.
- Consequence: the blanket "refetch Home on return from category" is gone
  (`home_page.dart`) — the category page pops `true` on *every* back press, so
  that was a full feed reload every time.

**P1-7 — one GPS fix for the app** *(F7)*
- New `lib/services/location_service.dart`. `seedPosition()` is instant
  (coordinates persisted by the last launch, else the platform's cached fix) and
  never wakes the GPS; `freshPosition()` is one shared in-flight request with
  the result persisted for the next cold start; `movedEnough()` holds the 2 km
  re-query threshold.
- Home, the category list and the detail page's "similar near you" all go
  through it. The similar-ads section now takes the seed instead of starting its
  own fix — it is secondary content and was costing a third GPS wake.

**P1-6b — filter-sheet reference data cached for the session** *(F9)*
- `_ReferenceCache` in `add_repo.dart` holds the *Future* per key, so the five
  parallel lookups a sheet open fires are also deduped, not just repeated opens.
- Covers manufacturers, models, fuel types, transmission types and
  commercial-vehicle types. Manufacturers and models walk every page, so an
  uncached call was several round trips.
- Failures evict the key — a flaky first open doesn't poison the session.

**P3-4 — scroll listeners debounced** *(F10)*
- Home, category and search: dispatch once on *entering* the 200–300 px trigger
  zone, re-armed by scrolling back out. A single fling used to enqueue hundreds
  of bloc events for `_isFetching` to absorb.
- Search only spends the arm when it actually dispatches, so a page that lands
  later can still be paged from the same position.

**P4-4 — bloc lifecycle** *(F14)*
- `AdvertisementBloc` tracks its live instances and drops out on `close()`.
  `AdvertisementBloc.resetAll()` clears listings, cursors and all 18 filter
  fields, and drops the ads cache; both logout paths in `auth_service.dart`
  call it. The feed used to survive a logout into the next user's session.
- Deleted the dead `_videoController` / `_videoControllers` /
  `_onVideoCompleteCallbacks` fields in `add_detail_page.dart` — never assigned
  a live controller, and the callback map grew one entry per video URL. Real
  controllers are owned and disposed by `_VideoPlayerWidgetState`.

**P0-3 — tokens out of plaintext SharedPreferences** *(F11)*
- New `lib/common/secure_token_store.dart`: EncryptedSharedPreferences /
  Keychain, with an in-memory mirror so the Dio `onRequest` interceptor doesn't
  cross the platform channel on every request.
- One-time migration copies tokens out of SharedPreferences on first launch and
  **removes the plaintext keys** whether or not they were adopted.
- `getToken()` / `getRefreshToken()` keep their signatures, so all 14 call sites
  are untouched. `saveLoginResponse`, `clearUserData` and the refresh path in
  `auth_service.dart` write to the store.
- `main()` initialises it before `runApp`. A keystore that can no longer be
  decrypted (restored backup, rotated keys) is wiped and treated as logged out
  instead of throwing on every read.
- `pubspec.yaml`: `flutter_secure_storage: ^9.2.4`.
  `android/app/build.gradle`: `minSdk = Math.max(flutter.minSdkVersion, 23)`.

**P1-4 — ad detail opens on data it already has** *(F3)*
- `AdDetailBloc` takes a `seed` (the list row from `state.extra`) and starts in
  `loaded(seed)`; `fetch` skips `emit(loading())` when seeded, so there is no
  `SkeletonDetail` on open and `/v2/ads/:id` becomes a background revalidation.
- A failed revalidation no longer replaces the page with the error screen; only
  a cold load surfaces it.
- `_handleCall` says "Seller contact not available yet" when the seeded row has
  no phone, instead of a silent dead tap.

**C3 — frontend audit for the backend agent**
- Grepped all of `lib/`: `user.email` / `user.phone` are read in exactly two
  places, both in `add_detail_page.dart` (seller email row, call handler), both
  off the **detail** response. No list screen reads either field — safe to strip
  from the public list projection.
- Caveat from P1-4: for ~300 ms after open, the detail page shows the *list*
  row, so with C3 shipped the call button is briefly unavailable. Handled by the
  message above.

### 2026-09-14 · first pass

- **P1-1** Home and category feeds un-gated from GPS — `getLastKnownPosition`
  seeds the request, `getCurrentPosition` moved off the critical path, Places
  autocomplete detour removed from the load path.
- **P2-3** Home grid: `SingleChildScrollView` + `shrinkWrap` `GridView` →
  `CustomScrollView` + `SliverGrid` with `findChildIndexCallback` on `ad.id`.
- **P3-1** `AppNetworkImage` rebuilt on `cached_network_image`: disk cache,
  `memCacheWidth` from layout constraints × DPR, retry double-timer bug fixed,
  real progress indicator. Fullscreen viewer and avatar reuse the same bytes.
- **B4** Detail carousel no longer auto-advances images (a 10-photo ad was
  downloading all ten originals within 30 s of opening, then looping).
- **P2-6 / C1** `hasNext` read from the server response.
- **C8** Dio timeouts 30 s/15 s → 10 s/10 s, `sendTimeout` 15 s added.
- **F8** Duplicate `/banner` fetch at cold start removed.

---

## Working rules

- One fix per cycle: analyse → root cause → propose → implement one → test →
  measure → document → next.
- Never change a request/response shape without checking the ⛓ items and
  pinging the backend agent.
- Load-bearing, do not regress: the 401-refresh-retry interceptor, the
  `StatefulShellRoute` tab state, the login/OTP flow, the connectivity gate.
- No performance claim without a before/after measurement on the same device.
