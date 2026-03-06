# App Versioning and Update Flow

## 1. Version format (semantic: major.minor.patch)

- **Format:** `1.1.0` = major.minor.patch (e.g. 1.1.4 in pubspec = major 1, minor 1, patch 4).
- **Where it comes from:** Single source of truth is `pubspec.yaml` → `version: 1.1.4+1`.
  - Flutter uses the part before `+` as **version name** (1.1.4) for both iOS (CFBundleShortVersionString) and Android (versionName).
  - The part after `+` is the **build number** (1) for iOS (CFBundleVersion) and Android (versionCode). You can bump the build number for each store upload without changing the user-facing version.

---

## 2. When to bump major, minor, or patch

| Bump | Example    | When to use |
|------|------------|-------------|
| **Patch** | 1.1.0 → 1.1.1 | Bug fixes, small tweaks, no new features and **no breaking API changes**. Old app versions can keep using the same APIs. |
| **Minor** | 1.1.0 → 1.2.0 | New features, backward-compatible API changes. Backend still supports 1.1.x. |
| **Major** | 1.1.0 → 2.0.0 | Breaking API or contract changes. You plan to **stop supporting** old app versions at some point (backend returns errors or forces update). |

You do **not** have to go 1.1.0 → 1.2.0 for every release. Releasing 1.1.1 after 1.1.0 is correct for patch releases.

**Your current situation:**

- App Store last released: **1.1.4**
- Play Store last released: **1.1.0**

Next release can be, for example:

- **1.1.5** (patch) if you only fix bugs and don’t change APIs.
- **1.2.0** (minor) if you add new features and keep backward compatibility.
- **2.0.0** (major) when you introduce breaking changes and plan to stop supporting 1.x.

---

## 3. Step-by-step release process

1. **Decide** whether this release is patch / minor / major (see table above).
2. **Update `pubspec.yaml`:**
   - Set `version: <major>.<minor>.<patch>+<build>`.
   - Example: next release after 1.1.4 → `1.1.5+2` or `1.2.0+1`.
3. **Build and upload** to App Store / Play Store (build number `+N` can differ per platform if needed).
4. **Backend:** When you are ready to **stop supporting** old versions:
   - Increase **min_version** (and optionally **latest_version**) in your version API (see below).
   - Old apps below **min_version** will get a **force update** dialog; others below **latest_version** get an **optional** update prompt.

---

## 4. How the app knows its version and when to prompt

- **Current app version** is read at runtime from the OS via `package_info_plus` (from `pubspec.yaml` → CFBundleShortVersionString / versionName).
- **Backend** exposes a **version config API** that returns:
  - **min_version** – minimum version the backend still supports. App version **below** this → **force update** (user must update to continue).
  - **latest_version** – latest version available on stores. App version **below** this but **≥ min_version** → **optional update** (user can tap “Later” or “Update”).
  - **Store URLs** (optional) – iOS and Android store links; if missing, app uses defaults.

So:

- **Major / breaking:** You raise **min_version** to the new major (e.g. 2.0.0) when you turn off old APIs. All 1.x users get **force update**.
- **Minor / patch:** You raise **latest_version** only; **min_version** stays at the oldest version you still support. Users on older 1.x get **optional** “Update available” until you decide to raise **min_version**.

---

## 5. Backend API contract (for version check)

The app calls **GET** on a version endpoint (e.g. `/api/app-version` – see `lib/repositories/version_repo.dart` for the path).

**Expected JSON:**

```json
{
  "min_version": "1.1.0",
  "latest_version": "1.1.4",
  "ios_url": "https://apps.apple.com/app/ado-dad/idYOUR_APP_ID",
  "android_url": "https://play.google.com/store/apps/details?id=com.adodad.user",
  "message": "Optional message shown in the update dialog."
}
```

- Keys can be **snake_case** (`min_version`, `latest_version`, `ios_url`, `android_url`) or **camelCase** (`minVersion`, `latestVersion`, `iosUrl`, `androidUrl`); the app accepts both.
- **min_version:** App versions **below** this get a **force** update dialog (cannot use app until they update).
- **latest_version:** App versions **below** this but **≥ min_version** get an **optional** update dialog.
- **ios_url** / **android_url:** Optional; if omitted, the app uses default store URLs defined in `VersionRepository`.

---

## 6. When APIs stop (e.g. new major release)

1. Release new app version (e.g. 2.0.0) to both stores.
2. On the backend, when you are ready to turn off old APIs:
   - Set **min_version** to the new minimum (e.g. `"2.0.0"`).
   - Set **latest_version** to the same or higher (e.g. `"2.0.0"`).
3. Old app versions (e.g. 1.1.4, 1.1.0) will get **force update** on next launch because they are below **min_version**.
4. Users are directed to the store to install 2.0.0; after that they use the new APIs only.

---

## 7. Summary table (in-app behavior)

| Current app version vs backend | Dialog |
|---------------------------------|--------|
| **< min_version**               | **Force update** – must tap “Update”; no “Later”. |
| **≥ min_version** but **< latest_version** | **Optional update** – “Later” or “Update”. |
| **≥ latest_version**            | No dialog. |

Version comparison is numeric (e.g. 1.1.0 < 1.1.4 < 1.2.0 < 2.0.0).

---

## 8. Files involved in this repo

- **Version source:** `pubspec.yaml` → `version: 1.1.4+1`
- **Model:** `lib/models/app_version_model.dart`
- **API:** `lib/repositories/version_repo.dart` (endpoint path and default store URLs)
- **Logic:** `lib/common/version_check_service.dart` (compare current vs min/latest)
- **UI:** `lib/common/widgets/update_app_dialog.dart`, `lib/common/version_check_wrapper.dart`
- **Integration:** `lib/main.dart` – `VersionCheckWrapper` runs after connectivity gate (when online).

Update the default store URLs in `VersionRepository` (and optionally the version endpoint path) to match your backend and store listings.
