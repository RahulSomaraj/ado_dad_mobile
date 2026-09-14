# AdoDad Mobile (Flutter) — Architecture, Performance & Security Audit
### Handover document for the **frontend** agent

**Repo:** `ado_dad_mobile` · **Branch analysed:** `dev_redesign`
**Counterpart:** the NestJS backend `ado-dad` (branch `develop`) is being worked by a separate agent against `BACKEND_AUDIT.md`. See **§9 Shared contracts** before changing anything that crosses the wire.
**Status:** analysis only. No code has been modified.

> **Terminology.** In this product "advertisements" are the **marketplace listings** themselves (vehicles / property / commercial vehicles), not third-party ad units. There is a separate small promo `/banner` carousel. Both are covered.

---

## 1. Current architecture

```
main.dart
  └── MultiBlocProvider  ← 15 blocs, ALL app-scoped singletons, never disposed
        LoginBloc, OtpBloc, SignupBloc,
        AdvertisementBloc   ← ONE instance shared by Home, Category,
                              Search, Seller-profile, Showroom
        ProfileBloc, BannerBloc (..add(fetchBanners()) at construction),
        AddPostBloc, AdEditBloc, MyAdsBloc, FavoriteBloc,
        SellerProfileBloc, ReportAdBloc, ChatBloc, NotificationBloc
  └── MaterialApp.router → AppRoutes.router
        StatefulShellRoute.indexedStack  →  /home  /my-activity  /chat-rooms  /profile
        everything else (/category-list-page, /search, /add-detail-page,
                         /car-filter, /seller-profile/:id …) pushed on top
  └── StartupConnectivityGate wraps every page

lib/repositories/*        thin, stateless, NO cache, NO dedupe
lib/common/api_service.dart
        singleton Dio · connectTimeout 30 s · receiveTimeout 15 s
        onRequest  → attach Bearer from SharedPreferences
        onError    → 401 → refresh → retry (with a concurrent-refresh guard)
        NO cache interceptor · NO ETag · NO request coalescing
lib/common/shared_pref.dart   token, refreshToken, user_id, user_profile, user_location
```

**State management:** `flutter_bloc` 8.x + `freezed`. **Routing:** `go_router` 14.x. **HTTP:** `dio` 5.x.
**Not present:** `cached_network_image`, `flutter_secure_storage`, `get_it`/`injectable` (DI is manual — repositories are `new`-ed inside `BlocProvider.create` and inside widgets).

---

## 2. Ads data flow as actually executed

```
HomePage.initState                                   home_page.dart:45-115
  ├─ context.read<BannerBloc>().add(fetchBanners())   line 62   ← 2nd copy (main.dart:210 already did it)
  ├─ await SharedPreferences.getInstance()            line 65
  ├─ await Geolocator.getCurrentPosition(timeLimit: 6s)  line 78-85   ⟵ BLOCKS EVERYTHING BELOW
  ├─ if no GPS but saved address:
  │     _applyLocationBasedRecommendations()          line 240-310
  │       → GooglePlaces.getPlacePredictions()        ← external round trip
  │       → GooglePlaces.getPlaceDetails()            ← external round trip
  └─ AdvertisementBloc.add(searchByLocation | fetchAllListings)
        → AddRepository.fetchAllAds(...)              add_repo.dart:19-120
        → POST /v2/ads/list  {page, limit:20, latitude, longitude, maxDistance:200}
        ← { data[], total, page, limit, … }
        → hasNext = (page * limit) < total            add_repo.dart:93-95   ⟵ client depends on `total`
        → AdvertisementState.listingsLoaded
        → buildGridView()                              home_page.dart:1218
             SingleChildScrollView (line 647)
               └ Column
                   └ GridView.builder(shrinkWrap: true,
                                      physics: NeverScrollableScrollPhysics)  line 1252-1255
                       └ RichAdCard → AppNetworkImage → Image.network (no cacheWidth)
```

---

## 3. Every ads call site

| Screen | File:line | Requests fired | Blocks first render? |
|---|---|---|---|
| App start | `main.dart:210` | `GET /banner` | no |
| Home | `home_page.dart:62,96,111` | `GET /banner` **again**, `POST /v2/ads/list` | **yes — after up to 6 s of GPS** |
| Home scroll | `home_page.dart:117-125` | `POST /v2/ads/list` page N | no |
| Home pull-to-refresh | `home_page.dart:1241` | `POST /v2/ads/list` (drops location mode) | yes |
| Return from category | `home_page.dart:1100-1104` | `POST /v2/ads/list` full refetch | yes |
| Category list | `category_list_page.dart:68-90` | GPS (5 s) → `POST /v2/ads/list` | **yes** |
| Category filter chips | `category_list_page.dart:233,258,375,689,708,729` | `POST /v2/ads/list` per tap | yes |
| Filter sheet | `app_routes.dart:317-360` | **5 parallel** `/vehicle-inventory/*` calls, every open | yes |
| Ad detail | `app_routes.dart:194-201` | `GET /v2/ads/:id` **despite the full `AddModel` already being in `state.extra`** | **yes — shows `SkeletonDetail`** |
| Ad detail “Similar ads” | `add_detail_page.dart:2247-2282` | GPS (5 s) → `POST /v2/ads/list` (category) | no |
| Ad detail seller tile | — | `GET /v2/ads/sellers/:id/stats` | no |
| Search | `search_page.dart:404,539,577` | `POST /v2/ads/list` | yes |
| Seller profile / Showroom / MyAds / Wishlist | respective pages | `POST /v2/ads/list` or `GET /ads` | yes |

**Representative session — Home → tap ad → back → tap category:**
`/banner ×2`, `/v2/ads/list ×4`, `/v2/ads/:id ×1`, `/sellers/:id/stats ×1`, and **three independent GPS fixes**.

---

## 4. Findings

### F1 — Home's ad feed is gated on a GPS fix *(Critical, biggest single win)*
`home_page.dart:78-85` awaits `Geolocator.getCurrentPosition(desiredAccuracy: low, timeLimit: Duration(seconds: 6))` **before** dispatching any ad event. On the no-GPS-but-saved-address path, `_applyLocationBasedRecommendations` (line 240-310) adds a Google Places *autocomplete* call **and** a *place details* call before the ad request is issued.
→ Time-to-first-byte for the hottest screen in the app is bounded below by the location subsystem, not by the API. 0.5–6 s of pure wall clock, plus 2 external round trips on the fallback path.

### F2 — One global `AdvertisementBloc` shared by five screens *(Critical)*
`main.dart:204-206`. Home, Category, Search, Seller-profile and Showroom all `context.read<AdvertisementBloc>()`. Each screen's `initState` overwrites the shared state.
Consequences visible in the code itself:
- `home_page.dart:1100-1104` re-dispatches `fetchAllListings()` on return from category — a full refetch, because Home's data is gone.
- The bloc carries **three interleaved pagination cursors** (`_currentPage`, `_allAdsPage`, `_searchPage`) plus `_isFetching`, `_isSearchFetching`, `_locationFallbackToAll`, `_locationQueryHasNext` and **20 mutable filter fields** (`advertisement_bloc.dart:26-70`), because one object serves five different feeds.
- Home stays alive in the `IndexedStack` while a pushed route mutates the state it is rendering.

### F3 — Ad detail refetches data it already holds, behind a skeleton *(High)*
`app_routes.dart:194-201` passes the complete `AddModel` via `state.extra`, then immediately `..add(AdDetailEvent.fetch(ad.id))`. The handler emits `AdDetailState.loading()` first (`ad_detail_bloc.dart:22-31`), and the builder renders `SkeletonDetail` (`add_detail_page.dart:268`).
→ A guaranteed perceived stall on the single most frequent interaction in the app, for data already in memory.

### F4 — No caching of any kind on the client *(High)*
No memory cache, no disk cache, no in-flight dedupe, no ETag/`If-None-Match`, no stale-while-revalidate. Repositories are stateless pass-throughs to Dio. `SharedPreferences` holds only auth + `user_location`.
→ Every navigation is a cold network fetch, even for identical filter sets seconds apart.

### F5 — `shrinkWrap` grids defeat lazy building and recycling *(High — jank + memory)*
`home_page.dart:647` `SingleChildScrollView` → `Column` → `home_page.dart:1252-1255` `GridView.builder(shrinkWrap: true, physics: NeverScrollableScrollPhysics())`. `shrinkWrap` forces layout of **every** child. Same pattern in `category_list_page.dart` and `search_page.dart`.
→ After 5 infinite-scroll pages, 100 `RichAdCard`s — each with a live `Image.network` — are alive simultaneously and re-laid-out on every rebuild. Nothing is ever recycled. `cacheExtent: 1000` on line 1247 is dead config under `shrinkWrap`.

### F6 — Full-resolution image decode *(High — dominant RSS growth)*
`common/widgets/app_network_image.dart` uses bare `Image.network` with **no `cacheWidth`/`cacheHeight`**. A 3000×2000 S3 photo decodes to roughly 24 MB of RAM to render a ~190 px-wide card. `cached_network_image` is not a dependency, so Flutter's memory-only `ImageCache` is the only layer — every cold start re-downloads every thumbnail.

### F7 — Three independent GPS fixes per browsing flow *(Medium)*
`home_page.dart:78`, `add_detail_page.dart:2253`, `category_list_page.dart:73`. None reuses the position Home already obtained; none is persisted for the next cold start. Each costs up to 5–6 s and battery.

### F8 — Duplicate `/banner` at cold start *(Medium, trivial fix)*
`main.dart:210` constructs `BannerBloc(...)..add(BannerEvent.fetchBanners())` **and** `home_page.dart:62` dispatches it again in `initState`.

### F9 — Static reference data refetched on every filter-sheet open *(Medium)*
`app_routes.dart:322-356` creates five blocs, each firing `load()` on construction: manufacturers, models, fuel types, transmission types, commercial-vehicle types. These are effectively immutable and are refetched every single time the sheet opens.

### F10 — Scroll listeners have no debounce *(Medium)*
`home_page.dart:117-125` and `category_list_page.dart:56-63` dispatch `fetchNextPage` on **every** scroll notification within 300 px of the bottom. The bloc's `_isFetching` flag absorbs the duplicates, but a single fling still enqueues hundreds of bloc events.

### F11 — Tokens in plaintext `SharedPreferences` *(High — security)*
`shared_pref.dart:99` and `:101` store `token` and `refreshToken` via `setString`. That is Android XML / iOS plist — readable on a rooted or jailbroken device and exposed in some backup flows. `flutter_secure_storage` is not in `pubspec.yaml`.

### F12 — Client re-filters to compensate for the server *(Medium — contract drift)*
`add_repo.dart:104-114` re-applies the `commercialVehicleTypes` filter locally with the comment *“backend may not apply it consistently.”* This silently shrinks pages (a 20-item page can render as 3) and breaks the `hasNext` arithmetic. Raise it with the backend agent rather than keeping the workaround.

### F13 — God widgets *(Medium)*
`profile_page.dart` 171 KB · `add_detail_page.dart` 113 KB · `search_page.dart` 60 KB · `home_page.dart` 57 KB, with GPS, geocoding, direct API calls and auth checks inline in `initState`/`build`. `add_detail_page.dart:61-72` already memoises a `Future` specifically to stop ~8 `FutureBuilder`s thrashing — a symptom, not a fix.

### F14 — Blocs never disposed *(Medium — memory)*
All 15 blocs in `main.dart` live for the process lifetime. `AdvertisementBloc` retains the full accumulated `listings` list forever; nothing clears it on tab change or logout. Also verify `_videoControllers` / `_onVideoCompleteCallbacks` in `add_detail_page.dart:58-59` are fully disposed — detail pages are pushed and popped constantly.

---

## 5. Root causes

| Symptom | Root cause | Fix |
|---|---|---|
| Ads take 4–8 s to appear on Home | `initState` awaits GPS (+2 Places calls) before dispatching | Dispatch immediately with cached coords; treat GPS as a background refinement |
| Same listings refetched on every navigation | One global bloc whose state each screen overwrites + zero repo caching | Route-scoped blocs over a caching `AdsRepository` |
| Ad detail flashes a skeleton for data in hand | Route passes `AddModel` then dispatches a fetch that emits `loading()` first | Seed `loaded(widget.ad)`, revalidate in background |
| Scroll jank, RSS climbs monotonically | `shrinkWrap` grid (no recycling) + full-res image decode | `CustomScrollView` + `SliverGrid`; `cacheWidth` + disk cache |
| Battery drain, slow category/detail opens | Three uncoordinated GPS fixes | One `LocationService` owning the last-known fix |

---

## 6. Target frontend architecture

```
  Route-scoped blocs (created in the GoRoute builder, disposed with the route)
    HomeAdsBloc   CategoryAdsBloc   SearchAdsBloc   AdDetailBloc
                            │
                            ▼
                ┌───────────────────────────────┐
                │        AdsRepository          │   single owner of ads I/O
                │  · normalised cache key:      │
                │      filters + geoBucket      │
                │      (lat/lng rounded 2dp)    │
                │  · in-flight dedupe           │   same key → one request
                │  · LRU memory cache, TTL 60-120s
                │  · stale-while-revalidate     │   serve stale, refresh behind
                └──────────────┬────────────────┘
                               │ miss / stale
                               ▼
                ┌───────────────────────────────┐
                │  ApiService (Dio)             │  + If-None-Match / ETag
                └──────────────┬────────────────┘
                               ▼
                    GET /v2/ads/list?…   (see §9 — backend agent owns the POST→GET move)

  LocationService (singleton)
      · last-known lat/lng persisted to SharedPreferences
      · one in-flight GPS request, shared by all callers
      · exposes cachedPosition (sync) + freshPosition (Future)
```

**Loading classification to drive the redesign**

| Class | Data | Rule |
|---|---|---|
| **Critical** | first 20 listings (cached coords, or no coords at all) | render as soon as available; **never** gate on GPS |
| **Important** | banners, precise address, distance labels | load in parallel, patch into the already-rendered UI |
| **Secondary** | similar ads, seller stats, favourite hearts, filter reference data | after first paint; never block |

---

## 7. Prioritized plan (frontend)

**P0 — Security**
- **P0-3** Move `token` + `refreshToken` from `SharedPreferences` to `flutter_secure_storage`. Keep `user_id`/`user_location` where they are. Migrate on first launch, then delete the old keys. *(`shared_pref.dart`, `api_service.dart`, `auth_service.dart`)*

**P1 — Major performance**
- **P1-1 ⭐ Un-gate Home from the GPS fix.** *(first task — see §8)*
- **P1-4** Seed `AdDetailBloc` with `AdDetailState.loaded(widget.ad)` from `state.extra`; revalidate in the background and emit the refreshed ad when it lands. Remove the skeleton on open. *(`app_routes.dart:194-201`, `ad_detail_bloc.dart`, `add_detail_page.dart:264-300`)*
- **P1-6b** Cache vehicle-inventory reference data in memory for the session (backend adds a Redis layer in parallel — see §9). *(`add_repo.dart:217-441`, `app_routes.dart:322-356`)*
- **P1-7** Delete the duplicate `fetchBanners()` in `home_page.dart:62`; introduce `LocationService` so the three GPS fixes become one. *(`home_page.dart`, `category_list_page.dart:68-80`, `add_detail_page.dart:2251-2263`)*

**P2 — Architecture**
- **P2-1** Route-scoped `AdvertisementBloc` instances backed by a caching `AdsRepository` (memory LRU + in-flight dedupe + SWR). This is the structural fix behind most of P1.
- **P2-3** Replace the `shrinkWrap` grids with `CustomScrollView` + `SliverGrid` in `home_page.dart`, `category_list_page.dart`, `search_page.dart` so lazy building and recycling actually work.
- **P2-2b** Switch `fetchAllAds` from `POST` to `GET` once the backend ships the GET route — **coordinate, see §9**.
- **P2-6** Stop deriving `hasNext` from `total`; consume the server's `hasNext` directly so the backend can drop its duplicate count query — **coordinate, see §9**.

**P3 — Optimization**
- **P3-1** `cacheWidth`/`cacheHeight` on every list image, sized from the card's layout extent; adopt `cached_network_image` for a disk cache that survives restarts. *(`app_network_image.dart`, `rich_ad_card.dart:254`)*
- **P3-4** Debounce the scroll listeners (~200 ms, or switch to a `NotificationListener` threshold guard).
- **P3-6** Remove the client-side `commercialVehicleTypes` re-filter once the backend confirms the server filter is correct (F12).

**P4 — Cleanup**
- **P4-1** Split `profile_page.dart` (171 KB) and `add_detail_page.dart` (113 KB); lift GPS/geocoding/API calls out of `initState`/`build` into services.
- **P4-4** Clear `AdvertisementBloc` state on logout; audit `_videoControllers` disposal.

---

## 8. FIRST IMPLEMENTATION TASK — P1-1

> **Stop gating the Home ad feed on the GPS fix.**

**Why this one first.** Largest single contributor to perceived slowness (0.5–6 s of wall clock before the first byte is requested, plus two Google Places round trips on the fallback path). Confined to one file. **Changes no API contract**, so it can ship in parallel with any backend work. Directly measurable.

**Change — `lib/features/home/ui/home_page.dart`:**
1. In `initState`, read cached `last_lat` / `last_lng` from `SharedPreferences` and dispatch the ad event **immediately**: `searchByLocation(cachedLat, cachedLng)` if present, otherwise `fetchAllListings()`.
2. Move `Geolocator.getCurrentPosition` off the critical path — **no `await` before the dispatch**. When it resolves, persist the coordinates and dispatch a refresh **only** if the position moved materially (> ~2 km) from the cached one.
3. Remove the Places autocomplete → place-details detour from the load path entirely (`_applyLocationBasedRecommendations`). It is an address-*display* concern; it must not sit between app launch and the ad request.

**Do not** touch the bloc's event shape, the repository, or the request body in this task. One change at a time.

**Baseline to capture before the change** — same device, cold start, airplane mode off, 5 runs, report median:
- `runApp` → first `ListingsLoaded` emit (ms)
- `initState` → first `POST /v2/ads/list` on the wire (ms)
- number of HTTP requests in the first 10 s
- peak RSS after scrolling 5 pages

**Expected:** request-issued time drops from ~1 000–6 000 ms to < 50 ms; first meaningful render becomes bounded by the API alone. Publish before/after numbers before moving to P1-4.

---

## 9. Shared contracts — coordinate with the backend agent

These four items **cannot be changed unilaterally**. The backend agent has the matching entries in `BACKEND_AUDIT.md`.

| # | Change | Backend does | Frontend does | Order |
|---|---|---|---|---|
| **C1** | **`hasNext` stops depending on `total`** | Returns `hasNext` from a `limit + 1` over-fetch; `includeTotal` becomes opt-in | Delete the `hasNext = (page*limit) < total` arithmetic at `add_repo.dart:93-95`; consume `response.data['hasNext']` | **Frontend first** (consume `hasNext`, which the server already returns), then backend drops the count query |
| **C2** | **`POST /v2/ads/list` → `GET /v2/ads/list`** | Adds the GET route, keeps POST alive for one release | `fetchAllAds` switches to `_dio.get` with query params; enables ETag | Backend ships GET first; frontend migrates; POST removed after |
| **C3** | **Seller `email`/`phoneNumber` removed from list rows** | Strips them from the public list projection (PII exposure — see backend S1) | **Audit first:** confirm nothing on a *list* screen reads `ad.user.email` / `ad.user.phone`. The call button `_handleCall` on `add_detail_page.dart` uses the **detail** response, which keeps the phone — that path is safe. Report any list-screen usage before the backend ships | **Frontend audits and reports, then backend ships** |
| **C4** | **`commercialVehicleTypes` server-side filter** | Confirms/fixes the filter on the `commercialVehicleDetails` sub-document | Removes the client-side re-filter at `add_repo.dart:104-114` | Backend fixes and confirms, then frontend removes the workaround |

**Independent of the backend (safe to ship any time):** P0-3, P1-1, P1-4, P1-7, P2-1, P2-3, P3-1, P3-4, P4-*.

---

## 10. Working rules for this handover

- One fix per cycle: **analyse → root cause → propose → implement one → test → measure → document → next.** Do not combine unrelated fixes.
- Never change an API request/response shape without checking §9 and pinging the backend agent.
- Never regress existing behaviour: the 401-refresh-retry interceptor, the `StatefulShellRoute` tab state, the login/OTP flow and the connectivity gate are all load-bearing.
- No performance claim without a before/after measurement on the same device.
