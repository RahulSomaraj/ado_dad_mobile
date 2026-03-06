import 'dart:io' show Platform;

import 'package:ado_dad_user/repositories/version_repo.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Result of comparing current app version with backend.
enum UpdateRequirement {
  none,
  optional,
  force,
}

/// How to handle the update (for UI).
class VersionCheckResult {
  final UpdateRequirement requirement;
  final String currentVersion;
  final String latestVersion;
  final String storeUrl;
  final String? message;

  const VersionCheckResult({
    required this.requirement,
    required this.currentVersion,
    required this.latestVersion,
    required this.storeUrl,
    this.message,
  });

  bool get shouldPrompt =>
      requirement == UpdateRequirement.force ||
      requirement == UpdateRequirement.optional;
}

/// Parses "1.2.3" or "1.2.3+4" into [major, minor, patch].
List<int> _parseVersion(String version) {
  final normalized = version.split('+').first.trim();
  final parts = normalized.split('.').map((s) => int.tryParse(s) ?? 0).toList();
  while (parts.length < 3) parts.add(0);
  return parts.take(3).toList();
}

/// Returns: negative if a < b, 0 if a == b, positive if a > b.
int _compareVersions(String a, String b) {
  final va = _parseVersion(a);
  final vb = _parseVersion(b);
  for (int i = 0; i < 3; i++) {
    final d = va[i] - vb[i];
    if (d != 0) return d;
  }
  return 0;
}

/// True if only the patch segment differs (same major and minor). e.g. 1.1.4 vs 1.1.5.
bool _isPatchOnlyChange(String current, String latest) {
  final va = _parseVersion(current);
  final vb = _parseVersion(latest);
  return va[0] == vb[0] && va[1] == vb[1] && va[2] != vb[2];
}

/// Service to check if app needs update based on backend version config.
class VersionCheckService {
  final VersionRepository _repo = VersionRepository();

  /// Fetches version config from backend and compares current app version
  /// with platform-specific latest (data.versions.ios / data.versions.android).
  /// Uses data.forceUpdate to decide force vs optional when update is needed.
  Future<VersionCheckResult> check() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final current = packageInfo.version;

    final config = await _repo.getVersionConfig();
    if (config == null) {
      print('📌 Version check: no config (API failed or null data) → no update prompt');
      final defaultUrl = Platform.isIOS
          ? VersionRepository.defaultIosStoreUrl
          : VersionRepository.defaultAndroidStoreUrl;
      return VersionCheckResult(
        requirement: UpdateRequirement.none,
        currentVersion: current,
        latestVersion: current,
        storeUrl: defaultUrl,
      );
    }

    final latest = Platform.isIOS ? config.iosVersion : config.androidVersion;
    final storeUrl = (Platform.isIOS
            ? config.iosStoreUrl
            : config.androidStoreUrl) ??
        (Platform.isIOS
            ? VersionRepository.defaultIosStoreUrl
            : VersionRepository.defaultAndroidStoreUrl);

    final cmp = _compareVersions(current, latest);
    print('📌 Version check: current=$current latest=$latest compare=$cmp (platform: ${Platform.isIOS ? "ios" : "android"})');

    // Current is below this platform's latest → show update
    if (cmp < 0) {
      // Patch-only change (e.g. 1.1.4 → 1.1.5): always optional update
      final requirement = _isPatchOnlyChange(current, latest)
          ? UpdateRequirement.optional
          : (config.forceUpdate ? UpdateRequirement.force : UpdateRequirement.optional);
      return VersionCheckResult(
        requirement: requirement,
        currentVersion: current,
        latestVersion: latest,
        storeUrl: storeUrl,
        message: config.message,
      );
    }

    return VersionCheckResult(
      requirement: UpdateRequirement.none,
      currentVersion: current,
      latestVersion: latest,
      storeUrl: storeUrl,
    );
  }

}
