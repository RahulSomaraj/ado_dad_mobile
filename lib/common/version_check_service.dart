import 'dart:io' show Platform;

import 'package:ado_dad_user/models/app_version_model.dart';
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

  /// Current build number (versionCode / CFBundleVersion), 0 if unknown.
  final int currentBuild;

  /// Build the prompt points at. Used as the snooze key for "Later", so a
  /// newer release prompts again. Null on the legacy version-name path.
  final int? targetBuild;

  final String storeUrl;
  final String? releaseNotes;
  final String? message;

  const VersionCheckResult({
    required this.requirement,
    required this.currentVersion,
    required this.latestVersion,
    required this.storeUrl,
    this.currentBuild = 0,
    this.targetBuild,
    this.releaseNotes,
    this.message,
  });

  bool get shouldPrompt =>
      requirement == UpdateRequirement.force ||
      requirement == UpdateRequirement.optional;

  bool get isForce => requirement == UpdateRequirement.force;

  /// Stable key for snoozing an optional prompt.
  String get snoozeKey => targetBuild != null ? 'b$targetBuild' : 'v$latestVersion';
}

/// Parses "1.2.3" or "1.2.3+4" into [major, minor, patch].
List<int> _parseVersion(String version) {
  final normalized = version.split('+').first.trim();
  final parts = normalized.split('.').map((s) => int.tryParse(s) ?? 0).toList();
  while (parts.length < 3) {
    parts.add(0);
  }
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
  final VersionRepository _repo;

  VersionCheckService({VersionRepository? repository})
      : _repo = repository ?? VersionRepository();

  /// Fetches version config from backend and decides none / optional / force.
  /// Throws on transport errors (offline) so the caller can retry later.
  Future<VersionCheckResult> check() async {
    final info = await PackageInfo.fromPlatform();
    final config = await _repo.getVersionConfig();
    return evaluate(
      isIOS: Platform.isIOS,
      currentVersion: info.version,
      currentBuild: int.tryParse(info.buildNumber.trim()) ?? 0,
      packageName: info.packageName,
      config: config,
    );
  }

  /// Pure decision logic (unit-tested).
  ///
  /// 1. If the backend sends a build policy for this platform, compare build
  ///    numbers: below `minSupported` → force, below `latest` → optional.
  /// 2. Otherwise fall back to the legacy version-name comparison with the
  ///    global `forceUpdate` flag (patch-only differences stay optional).
  static VersionCheckResult evaluate({
    required bool isIOS,
    required String currentVersion,
    required int currentBuild,
    required String packageName,
    required AppVersionData? config,
  }) {
    if (config == null) {
      return VersionCheckResult(
        requirement: UpdateRequirement.none,
        currentVersion: currentVersion,
        latestVersion: currentVersion,
        currentBuild: currentBuild,
        storeUrl: '',
      );
    }

    final latestVersion = isIOS ? config.iosVersion : config.androidVersion;
    final backendUrl =
        (isIOS ? config.iosStoreUrl : config.androidStoreUrl)?.trim() ?? '';
    final storeUrl = backendUrl.isNotEmpty
        ? backendUrl
        : (isIOS ? '' : VersionRepository.androidStoreUrlFor(packageName));

    VersionCheckResult result(UpdateRequirement r, {int? targetBuild}) {
      // Never block the user behind a dialog whose button goes nowhere.
      final req = storeUrl.isEmpty ? UpdateRequirement.none : r;
      return VersionCheckResult(
        requirement: req,
        currentVersion: currentVersion,
        latestVersion: latestVersion,
        currentBuild: currentBuild,
        targetBuild: targetBuild,
        storeUrl: storeUrl,
        releaseNotes: config.releaseNotes,
        message: config.message,
      );
    }

    final policy = isIOS ? config.iosBuilds : config.androidBuilds;

    // ── Build-number path ────────────────────────────────────────────────
    if (policy.isConfigured && currentBuild > 0) {
      final min = policy.minSupported;
      final latest = policy.latest;
      if (min != null && currentBuild < min) {
        return result(UpdateRequirement.force, targetBuild: latest ?? min);
      }
      if (latest != null && currentBuild < latest) {
        return result(UpdateRequirement.optional, targetBuild: latest);
      }
      return result(UpdateRequirement.none, targetBuild: latest);
    }

    // ── Legacy version-name path ─────────────────────────────────────────
    if (_compareVersions(currentVersion, latestVersion) < 0) {
      final requirement = _isPatchOnlyChange(currentVersion, latestVersion)
          ? UpdateRequirement.optional
          : (config.forceUpdate
              ? UpdateRequirement.force
              : UpdateRequirement.optional);
      return result(requirement);
    }
    return result(UpdateRequirement.none);
  }
}
