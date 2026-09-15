# Ad share links → open app or web (OLX-style) — implementation plan

**Date:** 15 Sep 2026
**Repos read:** `C:\pendrive\personal\ado-dad-repo\` — `ado_dad_mobile` (dev_redesign), `ado-dad` (develop), `ado-dad-web` (the Jan 2026 copy; the current web repo is `ado_dad_web` on the Mac. See §4.0)
**Goal:** Sharing an ad produces `https://adodad.com/ad/<slug>-<adId>`. When someone taps it in WhatsApp:

| Receiver | Result |
|---|---|
| Android, app installed | Opens the **Adodad app on that ad** |
| iPhone, app installed | Opens the **Adodad app on that ad** |
| App not installed / desktop | Opens **adodad.com on that ad**, with an "Get the app" prompt |
| WhatsApp chat itself | Shows a **rich preview card** (photo, title, price, location) |

No third-party SDK is needed. Use Android App Links, iOS Universal Links, Flutter's built-in deep linking (go_router already handles it) and server-rendered Open Graph (og:) tags for link-preview crawlers. Firebase Dynamic Links shut down in Aug 2025, so don't use it.

---

## 0. What exists today (verified in code and on the live site)

| Area | Finding | File |
|---|---|---|
| Share text | Hard-coded homepage `https://adodad.com/`, no ad id. Sharing requires login. | `ado_dad_mobile/lib/features/home/ui/add_detail_page.dart:136-148` |
| Mobile routing | go_router 14. The detail route `/add-detail-page` **only works with `state.extra` (AddModel)**, so a URL can't open it. | `ado_dad_mobile/lib/common/app_routes.dart` |
| Detail page | Already copes with "no seed": `AdDetailBloc(seed: null)` shows a skeleton and fetches `/v2/ads/:id`. The page has `hasContent` / `coldError` branches. **The deep-link-ready core is there.** | `add_detail_page.dart`, `features/home/ad_detail/ad_detail_bloc.dart` |
| Back button | `Navigator.maybePop()`. On a cold-start deep link there is nothing to pop, so the button does nothing. | `features/home/ui/ad_detail/ad_detail_gallery.dart:189` |
| Auth guard | Prefix matching with `startsWith`. Adding `'/ad'` would also match `/add-*-form` (protected routes), so use `'/ad/'`. | `ado_dad_mobile/lib/common/auth_guard.dart` |
| Android | `applicationId com.adodad.user`, `MainActivity` launchMode `singleTop`, only a LAUNCHER intent-filter | `android/app/build.gradle`, `AndroidManifest.xml` |
| iOS | Bundle `com.adodad.mobile`, Team `LSJK74P4WN`. Debug/Profile/Release all use `Runner/Runner.entitlements`, which only has `aps-environment`. | `ios/Runner.xcodeproj/project.pbxproj` |
| Flutter SDK | `sdk: ^3.6.2` means Flutter ≥ 3.27, where built-in deep linking is on by default and go_router receives the URL path directly | `pubspec.yaml` |
| Web | Flutter web with `PathUrlStrategy`. A `/details/:id` route already loads an ad by id. The share button is a TODO. `index.html` has no og: tags (title "ado_dad_web", description "A new Flutter project."). | `ado-dad-web/lib/common/app_routes.dart`, `item_detail/widgets/header_section.dart:77-83`, `web/index.html` |
| Web hosting | EC2, `git pull` + `flutter build web` + nginx reload from `/var/www/html/ado-dad-web`. The nginx config is **not in the repo**. | `ado-dad-web/.github/workflows/main.yaml` |
| Backend | NestJS 11 + Mongo on a separate EC2 (PM2). `GET /v2/ads/:id` is public, cached 5 min, and exported from `AdsV2Module`. `FRONTEND_URL=https://adodad.com` already exists. | `src/ads-v2/*`, `env.example` |
| Live domain | `https://adodad.com/.well-known/assetlinks.json` returns **404** | — |

---

## 1. Architecture

```
                  share (app / web)
                         │
             https://adodad.com/ad/royal-enfield-std-2022-66e1c0...f3a
                         │  tapped in WhatsApp
      ┌──────────────────┼───────────────────────────────┐
      │                  │                               │
 WhatsApp crawler    Android / iOS, app installed    Browser (no app)
 (preview card)      OS checked the domain at        │
      │              install time via .well-known     │
      ▼                  ▼                            ▼
 nginx (web EC2)     App opens → Flutter passes      nginx → Flutter web SPA
 bot UA → proxy      "/ad/<slug>-<id>" to go_router  route /ad/:slugId
      │                  │                            │
      ▼                  ▼                            ▼
 NestJS              AdDetailPage(adId)              ItemDetail(itemId)
 GET /share/ad/:slugId   → GET /v2/ads/:id           → GET /v2/ads/:id
 → tiny HTML with og: tags
```

### Key decisions

1. **URL format:** `https://adodad.com/ad/<slug>-<24-hex ObjectId>`
   - The slug is only for humans and SEO. The app, web and backend parse the id with `([0-9a-fA-F]{24})$`, so a stale slug still works after the title changes.
   - Also claim the existing web path `/details/<id>` in the apps, so links already shared from the website open the app too.
   - Only the apex `adodad.com` is used. If `www.adodad.com` redirects to the apex, don't list it in the intent-filter or entitlements: verification fails on redirects.
2. **Verification files** are static files served by nginx on the web EC2, not by NestJS. They have no backend dependency and never break because of an API deploy.
3. **Preview card:** nginx sends link-preview bots (WhatsApp, Facebook, Telegram, X, Google, and so on) to a NestJS HTML endpoint. Humans always get the normal SPA. The web and API boxes are separate, so this avoids trying to inject tags into the Flutter build.
4. **One source for the URL:** the backend adds `shareUrl` to the ad detail response. Mobile and web use it and fall back to building it locally with the same slug rules.
5. **Rollout order matters.** Android verifies App Links when the app is **installed or updated**. iOS fetches the AASA file via Apple's CDN at install time. **Deploy the server pieces (§5, §3) before releasing the app build.**

---

## 2. Values needed before starting

| Value | Where to get it | Known? |
|---|---|---|
| Android package | `build.gradle` | `com.adodad.user` |
| Android SHA-256 (**Play App Signing key**) | Play Console → Test and release → Setup → App integrity → App signing key certificate | ❓ |
| Android SHA-256 (upload key) | Same page, "Upload key certificate". Or `keytool -list -v -keystore android/app/upload-keystore.jks` | ❓ |
| Android SHA-256 (debug, UAT only) | `keytool -list -v -keystore ~/.android/debug.keystore -storepass android` | ❓ |
| iOS App ID | `<TeamID>.<bundle>` | `LSJK74P4WN.com.adodad.mobile` |
| App Store numeric id | App Store Connect → App Information → Apple ID | ❓ |
| API origin (for nginx proxy) | Backend EC2 domain (e.g. `api.adodad.com`) | ❓ |
| Login-to-share | Currently required; plan recommends removing it | decide |

---

## 3. Backend: `ado-dad` (NestJS)

### 3.1 New files

```
src/deep-links/
  deep-links.module.ts
  share-preview.controller.ts
  share-preview.service.ts
  share-url.util.ts
  share-url.util.spec.ts
```

**`src/deep-links/share-url.util.ts`**

```ts
const OBJECT_ID_TAIL = /([0-9a-fA-F]{24})$/;

export function slugify(input: string | undefined | null, max = 60): string {
  return (input ?? '')
    .normalize('NFKD')
    .replace(/[\u0300-\u036f]/g, '')
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '')
    .slice(0, max)
    .replace(/-+$/g, '');
}

/** https://adodad.com/ad/royal-enfield-std-2022-<id> */
export function buildAdShareUrl(baseUrl: string, adId: string, title?: string): string {
  const slug = slugify(title);
  const tail = slug ? `${slug}-${adId}` : adId;
  return `${baseUrl.replace(/\/+$/, '')}/ad/${tail}`;
}

/** Accepts "<slug>-<id>", "<id>", or anything ending in a 24-hex id. */
export function parseAdIdFromSlug(slugId: string): string | null {
  const m = OBJECT_ID_TAIL.exec((slugId ?? '').trim());
  return m ? m[1].toLowerCase() : null;
}
```

**Title fallback.** `Ad.title` is optional. Build the display title the same way the app's `AdDetailSpecs.fallbackTitle` does: year + manufacturer + model (+ variant), or the property type for property ads, and finally the category label. Put this in one helper, `displayTitle(dto)`, in the same file and use it for both `shareUrl` and the preview.

**`src/deep-links/share-preview.service.ts`**

```ts
@Injectable()
export class SharePreviewService {
  constructor(
    private readonly getAdById: GetAdByIdUc,
    @InjectModel(Ad.name) private readonly adModel: Model<AdDocument>,
    private readonly config: ConfigService,
  ) {}

  async render(slugId: string): Promise<{ status: number; html: string }> {
    const base = this.config.get<string>('APP_CONFIG.FRONTEND_URL') ?? 'https://adodad.com';
    const id = parseAdIdFromSlug(slugId);
    if (!id) return { status: 404, html: this.page(this.fallback(base)) };

    // Only public ads get a real card. The /v2/ads/:id pipeline only filters isDeleted,
    // so pending / rejected / admin-removed ads would otherwise leak their photo and price.
    const visible = await this.adModel.exists({
      _id: id,
      isDeleted: { $ne: true },
      isRemovedByAdmin: { $ne: true },
      status: AdStatus.APPROVED,
    });
    if (!visible) return { status: 404, html: this.page(this.fallback(base)) };

    const ad = await this.getAdById.execPreview(id); // no view-count increment, no chats/favs
    const title = displayTitle(ad);
    const price = new Intl.NumberFormat('en-IN', { style: 'currency', currency: 'INR', maximumFractionDigits: 0 }).format(ad.price);
    const place = ad.location ?? '';
    // km field name: confirm in vehicle-ad.schema.ts (kmDriven/mileage) before wiring
    const km = ad.vehicleDetails?.kmDriven ? `${Number(ad.vehicleDetails.kmDriven).toLocaleString('en-IN')} km · ` : '';
    return {
      status: 200,
      html: this.page({
        title: `${ad.soldOut ? 'SOLD · ' : ''}${title} · ${price}`,
        description: `${km}${place} · See it on Adodad`,
        image: ad.images?.[0],
        url: buildAdShareUrl(base, ad.id, title),
      }),
    };
  }

  private fallback(base: string) {
    return { title: 'Adodad — Buy & sell vehicles and property', description: 'This ad is no longer available.', image: `${base}/icons/Icon-512.png`, url: base };
  }

  private page(m: { title: string; description: string; image?: string; url: string }): string {
    const e = escapeHtml; // user text: title/description/location MUST be escaped
    return `<!doctype html><html lang="en"><head><meta charset="utf-8">
<title>${e(m.title)}</title>
<meta name="description" content="${e(m.description)}">
<link rel="canonical" href="${e(m.url)}">
<meta property="og:type" content="product">
<meta property="og:site_name" content="Adodad">
<meta property="og:title" content="${e(m.title)}">
<meta property="og:description" content="${e(m.description)}">
${m.image ? `<meta property="og:image" content="${e(m.image)}">
<meta property="og:image:alt" content="${e(m.title)}">` : ''}
<meta property="og:url" content="${e(m.url)}">
<meta name="twitter:card" content="summary_large_image">
</head><body><a href="${e(m.url)}">${e(m.title)}</a></body></html>`;
  }
}

function escapeHtml(s: string): string {
  return s.replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]!));
}
```

**`src/deep-links/share-preview.controller.ts`**

```ts
@Controller('share')
export class SharePreviewController {
  constructor(private readonly svc: SharePreviewService) {}

  @Get('ad/:slugId')
  @Throttle({ name: 'sharePreview', limit: 300, ttl: 60 }) // custom Throttle from common/guards/auth-throttle.guard
  async ad(@Param('slugId') slugId: string, @Res() res: Response) {
    const { status, html } = await this.svc.render(slugId);
    res.status(status)
      .setHeader('Content-Type', 'text/html; charset=utf-8')
      .setHeader('Cache-Control', status === 200 ? 'public, max-age=600' : 'public, max-age=60')
      .send(html);
  }

  @Get('details/:id')
  details(@Param('id') id: string, @Res() res: Response) {
    return this.ad(id, res); // legacy web path, same page
  }
}
```

**`src/deep-links/deep-links.module.ts`** imports `AdsV2Module` (it already exports `GetAdByIdUc`) and `MongooseModule.forFeature([{ name: Ad.name, schema: AdSchema }])`. Register it in `src/app.module.ts` under the feature modules.

### 3.2 Changes to existing files

| File | Change |
|---|---|
| `src/ads-v2/application/use-cases/get-ad-by-id.uc.ts` | Pull the "cache read or aggregate + `mapToDetailedResponseDto` + `setById`" block (≈ lines 225-247) into `private async loadBase(adId)`. `exec()` calls it as before. Add `async execPreview(adId)` that returns `loadBase(adId)` only: **no** `$inc viewCount`, favourites, chats or ratings, so crawlers don't inflate views. |
| same file, `mapToDetailedResponseDto` | Add `shareUrl: buildAdShareUrl(FRONTEND_URL, id, displayTitle(dto))`. It's part of the cached base; invalidation already runs on ad edits via `invalidateById`. Inject `ConfigService` or read `process.env.FRONTEND_URL`. |
| `src/ads/dto/common/ad-response.dto.ts` (**CRLF, keep it**) | `@ApiPropertyOptional() shareUrl?: string;` on `DetailedAdResponseDto` |
| `src/app.module.ts` | `DeepLinksModule` in imports |
| `env.example`, `.env.uat`, `.env.prod` | Confirm `FRONTEND_URL` per environment (prod `https://adodad.com`, UAT its own web host) |
| (optional) list DTO / `list-ads.uc.ts` | Add `shareUrl` to list rows too if cards get a share action later |

### 3.3 Tests

- `share-url.util.spec.ts`: slugify (unicode, symbols, length cap), build/parse round-trip, parse rejects `abc`, parse accepts bare id, parse accepts a stale slug.
- `share-preview.service` spec: approved ad → 200 with escaped `<script>` in title; pending / rejected / removed / deleted → 404 fallback; invalid id → 404; sold → title prefixed `SOLD ·`.
- `get-ad-by-id.uc.spec.ts`: `execPreview` does not call the view increment.

---

## 4. Web: `ado_dad_web` (Flutter web)

### 4.0 Caveat

This was mapped against the pendrive copy `ado-dad-web` (routes `/`, `/details/:id`, …). The Mac repo `akhila/ado_dad_web` has since moved browsing into the URL (`/ads/:category`, `lib/common/browse_query.dart`). Apply the same changes to wherever the detail route now lives there.

### 4.1 Changes

| File | Change |
|---|---|
| `lib/common/ad_links.dart` **(new)** | Same logic as the mobile file (§6.4): `adPath(id, title)`, `adUrl(...)`, `parseAdId(slugId)` |
| `lib/common/app_routes.dart` | Add a route next to `/details/:id`:<br>`GoRoute(path: '/ad/:slugId', builder: (c, s) { final id = AdLinks.parseAdId(s.pathParameters['slugId']!); return id == null ? const NotFoundPage() : ItemDetail(itemId: id); })`<br>Keep `/details/:id` working. Optionally `redirect` it to `/ad/:id` so the canonical form wins. |
| internal links to detail (item grid, wishlist, profile products) | Navigate with `context.go(AdLinks.adPath(ad.id, ad.title))` so the address bar shows the shareable URL |
| `lib/features/item_detail/widgets/header_section.dart:77-83` | Replace the "coming soon" TODO: `SharePlus.instance.share(ShareParams(uri: Uri.parse(item.shareUrl ?? AdLinks.adUrl(...))))`. share_plus uses the Web Share API on mobile browsers and falls back to copying the link to the clipboard with a snackbar. |
| `web/index.html` | Real `<title>`, `description`, default og tags (site name, logo image) for non-ad pages, `<meta name="apple-itunes-app" content="app-id=APP_STORE_ID">` (Safari smart banner) |
| `lib/features/item_detail/ui/add_detail.dart` (optional) | "Open in app" banner for **mobile browsers only**. On Android Chrome use `intent://adodad.com/ad/<slug-id>#Intent;scheme=https;package=com.adodad.user;S.browser_fallback_url=<play-store-url>;end`. On iOS rely on the smart banner. This matters when someone is already *on* adodad.com, because same-domain navigation never triggers the app. |

---

## 5. Infra: nginx on the web EC2

Commit the config to the web repo as `deploy/nginx/adodad.conf` (it's currently only on the server) and the verification files to `deploy/well-known/`. The workflow already runs `nginx -t && reload`. Add one step that copies `deploy/well-known/*` to `/var/www/adodad-well-known/`.

### 5.1 `deploy/well-known/assetlinks.json`

```json
[
  {
    "relation": ["delegate_permission/common.handle_all_urls"],
    "target": {
      "namespace": "android_app",
      "package_name": "com.adodad.user",
      "sha256_cert_fingerprints": [
        "PLAY_APP_SIGNING_KEY_SHA256",
        "UPLOAD_KEY_SHA256"
      ]
    }
  }
]
```
UAT host only: also add the debug-key SHA-256.

### 5.2 `deploy/well-known/apple-app-site-association` (no extension)

```json
{
  "applinks": {
    "details": [
      {
        "appIDs": ["LSJK74P4WN.com.adodad.mobile"],
        "components": [
          { "/": "/ad/*",      "comment": "ad share links" },
          { "/": "/details/*", "comment": "legacy web detail links" }
        ]
      }
    ]
  }
}
```

### 5.3 nginx server block (merge into the existing one)

```nginx
# http {} level
map $http_user_agent $link_preview_bot {
    default 0;
    ~*(WhatsApp|facebookexternalhit|Facebot|meta-externalagent|Twitterbot|TelegramBot|Slackbot|LinkedInBot|Discordbot|SkypeUriPreview|Pinterest|redditbot|Applebot|Googlebot|bingbot) 1;
}

server {
    server_name adodad.com;
    root /var/www/html/ado-dad-web/build/web;

    # --- App Links / Universal Links verification: 200, JSON, no redirects ---
    location = /.well-known/assetlinks.json {
        alias /var/www/adodad-well-known/assetlinks.json;
        default_type application/json;
        add_header Cache-Control "public, max-age=3600";
    }
    location = /.well-known/apple-app-site-association {
        alias /var/www/adodad-well-known/apple-app-site-association;
        default_type application/json;
        add_header Cache-Control "public, max-age=3600";
    }

    # --- Ad pages: bots get og: HTML from the API, humans get the SPA ---
    location ~ ^/(ad|details)/ {
        if ($link_preview_bot) {
            rewrite ^/(ad|details)/(.*)$ /__share/$1/$2 last;
        }
        try_files $uri /index.html;
    }
    location ^~ /__share/ {
        internal;
        proxy_pass https://API_HOST/share/;      # /__share/ad/x -> /share/ad/x
        proxy_set_header Host API_HOST;
        proxy_ssl_server_name on;
        proxy_connect_timeout 3s;
        proxy_read_timeout 5s;
    }

    # SPA shell must not be cached, or new deploys don't show
    location = /index.html { add_header Cache-Control "no-cache"; }
    location / { try_files $uri $uri/ /index.html; }
}
```

**Check after deploy:**

```bash
curl -sI https://adodad.com/.well-known/assetlinks.json            # 200, application/json, no Location header
curl -sI https://adodad.com/.well-known/apple-app-site-association # 200, application/json
curl -s  -A "WhatsApp/2.23" https://adodad.com/ad/test-<realId> | grep og:   # og tags
curl -s  https://adodad.com/ad/test-<realId> | grep flutter_bootstrap         # humans get SPA
```

Google's checker: `https://digitalassetlinks.googleapis.com/v1/statements:list?source.web.site=https://adodad.com&relation=delegate_permission/common.handle_all_urls`
Apple's CDN copy (can lag hours): `https://app-site-association.cdn-apple.com/a/v1/adodad.com`

**Image note:** WhatsApp shows the thumbnail reliably only for public HTTPS images of about 300 KB or less and at least 300 px wide. If S3 originals are multi-MB, the card shows without a photo. A later improvement is a resized `thumb` variant at upload (`src/shared/s3.service.ts`) used for `og:image`.

---

## 6. Mobile: `ado_dad_mobile` (Flutter)

### 6.1 `android/app/src/main/AndroidManifest.xml`

Inside `<activity android:name=".MainActivity">`, after the LAUNCHER intent-filter:

```xml
<!-- Flutter ≥3.27 default is true; explicit so an SDK/plugin change can't silently disable it -->
<meta-data android:name="flutter_deeplinking_enabled" android:value="true" />

<!-- App Links: https://adodad.com/ad/* and legacy /details/* -->
<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="https" android:host="adodad.com" android:pathPrefix="/ad/" />
    <data android:scheme="https" android:host="adodad.com" android:pathPrefix="/details/" />
</intent-filter>
```

`launchMode="singleTop"` is fine. Flutter routes the new intent to go_router when the app is already running.

### 6.2 iOS

**`ios/Runner/Runner.entitlements`** (used by Debug, Profile and Release):

```xml
<dict>
    <key>aps-environment</key>
    <string>development</string>
    <key>com.apple.developer.associated-domains</key>
    <array>
        <string>applinks:adodad.com</string>
    </array>
</dict>
```

**`ios/Runner/Info.plist`**: add

```xml
<key>FlutterDeepLinkingEnabled</key>
<true/>
```

Also make the same edit in `Info.plist.production` if a build script still swaps it in.

**Apple Developer portal:** Identifiers → `com.adodad.mobile` → enable **Associated Domains**, then regenerate the provisioning profiles, or let Xcode automatic signing do it. Skipping this makes the entitlement fail at archive time.

Side note, not blocking: `NSExceptionDomains` in Info.plist lists `ado-dad.com` / `www.ado-dad.com` (with a hyphen) while the site is `adodad.com`.

### 6.3 `pubspec.yaml`

No new dependency. go_router 14 receives the deep-link path directly. `app_links` is only needed if you want to see the raw URI (for analytics). If you add it, set both flags above to `false`, otherwise two handlers fight over the link.

### 6.4 `lib/common/ad_links.dart` (new)

```dart
/// Canonical public URLs for ads. Keep in sync with backend share-url.util.ts.
class AdLinks {
  AdLinks._();

  static const String webOrigin = 'https://adodad.com';
  static final RegExp _idTail = RegExp(r'([0-9a-fA-F]{24})$');

  static String slugify(String? input, {int max = 60}) {
    var s = (input ?? '').toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    s = s.replaceAll(RegExp(r'^-+|-+$'), '');
    if (s.length > max) s = s.substring(0, max).replaceAll(RegExp(r'-+$'), '');
    return s;
  }

  /// `/ad/royal-enfield-std-2022-<id>`
  static String adPath(String id, [String? title]) {
    final slug = slugify(title);
    return '/ad/${slug.isEmpty ? id : '$slug-$id'}';
  }

  static String adUrl(String id, [String? title]) => '$webOrigin${adPath(id, title)}';

  /// Accepts `<slug>-<id>` or bare `<id>`; null when no 24-hex id at the end.
  static String? parseAdId(String? slugId) =>
      _idTail.firstMatch((slugId ?? '').trim())?.group(1)?.toLowerCase();
}
```

Add `test/ad_links_test.dart` with the same cases as the backend spec.

### 6.5 `lib/common/app_routes.dart`

Add these routes at top level, outside the `StatefulShellRoute`, next to `/add-detail-page`:

```dart
// Public share links: https://adodad.com/ad/<slug>-<id>. Arrives from
// Android App Links / iOS Universal Links (cold or warm start) or in-app nav.
GoRoute(
  path: '/ad/:slugId',
  builder: (context, state) {
    final id = AdLinks.parseAdId(state.pathParameters['slugId']);
    if (id == null) return const _RouteErrorScreen.unavailable();
    final seed = state.extra is AddModel ? state.extra as AddModel : null;
    return BlocProvider(
      create: (_) => AdDetailBloc(repository: AddRepository(), seed: seed)
        ..add(AdDetailEvent.fetch(id)),
      child: AdDetailPage(adId: id, seed: seed),
    );
  },
),
// Links shared from the website's older detail URL.
GoRoute(
  path: '/details/:id',
  redirect: (context, state) {
    final id = AdLinks.parseAdId(state.pathParameters['id']);
    return id == null ? null : '/ad/$id';
  },
  builder: (context, state) => const _RouteErrorScreen.unavailable(),
),
```

Update `/add-detail-page` to build `AdDetailPage(adId: ad.id, seed: ad)`. In phase 2, point callers at `/ad/...` and turn this route into a redirect.

**Cold start behaviour:** Flutter gives go_router `/ad/<slug-id>` as the initial location, so `initialLocation: '/'` and the splash chain are **skipped**. That's intended: OLX does the same. `main()` still runs Firebase/FCM/token init before `runApp`, and `StartupConnectivityGate` still wraps the page.

### 6.6 `lib/common/auth_guard.dart`

```dart
static const List<String> publicRoutes = [
  ...
  '/add-detail-page',
  '/ad/',       // ← trailing slash: '/ad' would startsWith-match '/add-*-form' (protected)
  '/details/',
  ...
];
```

`isPublicRoute` is checked **before** `isProtectedRoute`, so a bare `'/ad'` would make every `/add-…-form` route public. Add a unit test for this: `isPublicRoute('/add-two-wheeler-form') == false`.

### 6.7 `lib/features/home/ui/add_detail_page.dart`

1. **Constructor:** `AdDetailPage({super.key, required this.adId, this.seed})` with `final String adId; final AddModel? seed;`
   - `_lastAd` becomes `AddModel?`, set to `widget.seed` in `initState`.
   - `hasContent` becomes `_lastAd != null`.
   - Retry uses `widget.adId` instead of `widget.ad.id`.
   - `_isOwner`: the `identical(ad, widget.ad)` check becomes `identical(ad, widget.seed)`.
2. **Share (lines 136-148):**
   ```dart
   Future<void> _share(AddModel ad) async {
     final title = _titleFor(ad);
     final url = (ad.shareUrl?.isNotEmpty ?? false)
         ? ad.shareUrl!
         : AdLinks.adUrl(ad.id, title);
     final text = StringBuffer()
       ..writeln('$title — ${AdFormat.inr(ad.price)}')
       ..writeln(ad.location)
       ..writeln()
       ..writeln('See it on Adodad: $url');
     await SharePlus.instance.share(
       ShareParams(text: text.toString(), subject: '$title on Adodad'),
     );
   }
   ```
   - The **URL goes on its own last line**. WhatsApp builds the preview from the first URL in the message.
   - **Remove the login requirement**, unless that's a product rule. OLX lets guests share, and the link is public anyway.
3. **Login redirect:** `_loginRedirect = '/add-detail-page'` can't restore an ad (it has no extra). Use `AdLinks.adPath(widget.adId)` so login returns to the same ad.
4. **Back from a cold-start link:**
   ```dart
   void _back() => context.canPop() ? context.pop() : context.go('/home');
   ```
   - Pass `onBack: _back` to `AdDetailGallery`.
   - Wrap the `Scaffold` in `PopScope(canPop: context.canPop(), onPopInvokedWithResult: (didPop, _) { if (!didPop) context.go('/home'); })` so Android system back lands on Home instead of closing the app.
   - Apply the same to the skeleton and error scaffolds.
5. `_leaveAfterChange()` already falls back to `/home`, so no change there.

### 6.8 `lib/models/advertisement_model/add_model.dart`

Add `final String? shareUrl;` and parse `json['shareUrl']`. Regenerate if it's freezed/json_serializable (`dart run build_runner build --delete-conflicting-outputs`).

### 6.9 Internal navigation (phase 2, recommended)

| File | Change |
|---|---|
| `lib/common/widgets/rich_ad_card.dart:234` | `context.push(AdLinks.adPath(ad.id, ad.title), extra: ad)` |
| `lib/features/profile/MyAds/ui/my_ads_page.dart:165` | Same, with `_toAddModel(ad)` as extra |
| any other `'/add-detail-page'` push (chat ad header, notifications, wishlist, seller profile, showroom) | Same. Search for `add-detail-page`. |

After this, one route serves taps, deep links and restored state. `/add-detail-page` becomes `redirect: (_, s) => s.extra is AddModel ? AdLinks.adPath((s.extra as AddModel).id) : '/home'` (the extra is carried over).

### 6.10 Where else links help (optional)

- **Push notifications:** `main.dart` `_handleNotificationTap` always goes to `/notifications`. If the backend puts `data.link = shareUrl` in ad-related FCM payloads, route with `AppRoutes.router.go(Uri.parse(link).path)`.
- **Chat:** render `adodad.com/ad/...` URLs in messages as tappable cards that call `context.push(Uri.parse(url).path)`.

---

## 7. Not installed → install → open the same ad (deferred deep link): phase 3, optional

- **Android:** the web banner links to `https://play.google.com/store/apps/details?id=com.adodad.user&referrer=ad_id%3D<id>`. On first launch, read it with the `play_install_referrer` package and `go(AdLinks.adPath(id))` once (store a "consumed" flag in SharedPrefs).
- **iOS:** there's no free equivalent. It needs a paid service (Branch, AppsFlyer OneLink, Adjust) or a clipboard hack (which triggers iOS paste prompts, so not recommended). Skip it for now.

---

## 8. Rollout order

| Step | Repo | Ship |
|---|---|---|
| 1 | backend | `share-url.util`, `execPreview`, `shareUrl` in the detail DTO, `DeepLinksModule` (`/share/ad/:slugId`). Deploy UAT → prod. |
| 2 | web + nginx | `deploy/well-known/*`, nginx block, `/ad/:slugId` route, web share button, index.html meta. Deploy. Run the §5.3 curl checks and Google's statements API. |
| 3 | mobile | Manifest, entitlements + portal capability, Info.plist, `ad_links.dart`, routes, auth guard, detail page changes, model field. Build UAT with the debug SHA in the UAT assetlinks. |
| 4 | mobile | Release to Play / App Store **after** step 2 is live in prod |
| 5 | mobile/web | Phase 2 internal navigation refactor, notification links |
| 6 | optional | Thumbnails for og:image, Android install referrer |

---

## 9. Test plan

**Android**

```bash
adb shell pm verify-app-links --re-verify com.adodad.user
adb shell pm get-app-links com.adodad.user        # adodad.com: verified
adb shell am start -W -a android.intent.action.VIEW -c android.intent.category.BROWSABLE \
  -d "https://adodad.com/ad/royal-enfield-std-2022-<realId>" com.adodad.user
```

Tip for local/debug builds: `adb shell pm set-app-links --package com.adodad.user 0 all` resets the state. On Android 12+ an unverified domain opens the browser instead of the app.

**iOS**

- In a debug build: Settings → Developer → Associated Domains Development, add `applinks:adodad.com?mode=developer` to bypass the Apple CDN cache while testing.
- Paste the link into Notes or WhatsApp and tap it. A long-press should show "Open in Adodad".
- Typing the URL into Safari's address bar **doesn't** trigger Universal Links. That's expected.

**Matrix (each on Android + iOS)**

| # | Case | Expected |
|---|---|---|
| 1 | App killed, tap link in WhatsApp | App opens directly on the ad (skeleton → content); back → Home |
| 2 | App in background on another screen | Ad opens on top; back → Home |
| 3 | Logged out, tap link, press Chat | Login → returns to the same ad |
| 4 | Stale slug (`/ad/wrong-title-<id>`) | Opens the correct ad |
| 5 | Garbage (`/ad/hello`) | "This page is no longer available" → Go home |
| 6 | Deleted / rejected ad | App: existing error view. Web card: generic "no longer available". |
| 7 | Sold ad | Opens with the SOLD banner; card title starts "SOLD ·" |
| 8 | App not installed | adodad.com ad page with the store banner |
| 9 | WhatsApp preview | Photo + "2022 Royal Enfield STD · ₹1,60,000" + "73,000 km · Ranni, Kerala" |
| 10 | `/details/<id>` link from the old site | Opens the app on the ad |
| 11 | Auth guard | `/add-two-wheeler-form` while logged out still redirects to login |
| 12 | Views | Crawler hits don't increase `viewCount` |

The WhatsApp preview is cached per URL on WhatsApp's side, so when re-testing card changes add `?v=2`.

---

## 10. File change summary

| Repo | File | Type |
|---|---|---|
| ado-dad | `src/deep-links/deep-links.module.ts` | new |
| ado-dad | `src/deep-links/share-preview.controller.ts` | new |
| ado-dad | `src/deep-links/share-preview.service.ts` | new |
| ado-dad | `src/deep-links/share-url.util.ts` (+ `.spec.ts`) | new |
| ado-dad | `src/ads-v2/application/use-cases/get-ad-by-id.uc.ts` | edit: `loadBase`, `execPreview`, `shareUrl` |
| ado-dad | `src/ads/dto/common/ad-response.dto.ts` (CRLF) | edit: `shareUrl` |
| ado-dad | `src/app.module.ts` | edit: import module |
| ado-dad | `.env.uat` / `.env.prod` / `env.example` | confirm `FRONTEND_URL` |
| ado_dad_web | `deploy/nginx/adodad.conf` | new (copy of server config) |
| ado_dad_web | `deploy/well-known/assetlinks.json`, `apple-app-site-association` | new |
| ado_dad_web | `.github/workflows/main.yaml` | edit: copy well-known files before nginx reload |
| ado_dad_web | `lib/common/ad_links.dart` | new |
| ado_dad_web | `lib/common/app_routes.dart` | edit: `/ad/:slugId` |
| ado_dad_web | `lib/features/item_detail/widgets/header_section.dart` | edit: share |
| ado_dad_web | `web/index.html` | edit: meta, smart banner |
| ado_dad_web | `lib/features/item_detail/ui/add_detail.dart` | optional: open-in-app banner |
| ado_dad_mobile | `android/app/src/main/AndroidManifest.xml` | edit |
| ado_dad_mobile | `ios/Runner/Runner.entitlements` | edit |
| ado_dad_mobile | `ios/Runner/Info.plist` (+ `.production`) | edit |
| ado_dad_mobile | `lib/common/ad_links.dart` (+ test) | new |
| ado_dad_mobile | `lib/common/app_routes.dart` | edit: `/ad/:slugId`, `/details/:id` |
| ado_dad_mobile | `lib/common/auth_guard.dart` (+ test) | edit |
| ado_dad_mobile | `lib/features/home/ui/add_detail_page.dart` | edit: ctor, share, back, login redirect |
| ado_dad_mobile | `lib/models/advertisement_model/add_model.dart` | edit: `shareUrl` |
| ado_dad_mobile | `rich_ad_card.dart`, `my_ads_page.dart`, other `/add-detail-page` callers | phase 2 |
| Apple portal | App ID `com.adodad.mobile` → Associated Domains | config |

## 11. Related finding (existing, worth fixing alongside)

`GET /v2/ads/:id` matches only `isDeleted != true`. **Pending, rejected and admin-removed ads are publicly readable by id.** Once ids start travelling in share links, that gets easier to hit. The preview endpoint above guards itself. Consider applying the same `status`/`isRemovedByAdmin` rule in `get-ad-by-id.uc.ts` for non-owner, non-staff callers (the owner still needs to see their pending ad).
