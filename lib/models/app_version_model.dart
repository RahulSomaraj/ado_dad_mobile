/// Full API response: { success, statusCode, message, data }.
class AppVersionResponse {
  final bool success;
  final int statusCode;
  final String? message;
  final AppVersionData? data;

  const AppVersionResponse({
    required this.success,
    this.statusCode = 200,
    this.message,
    this.data,
  });

  factory AppVersionResponse.fromJson(Map<String, dynamic> json) {
    final dataJson = json['data'];
    return AppVersionResponse(
      success: json['success'] == true,
      statusCode: (json['statusCode'] is int) ? json['statusCode'] as int : 200,
      message: json['message']?.toString(),
      data: dataJson is Map<String, dynamic>
          ? AppVersionData.fromJson(dataJson,
              message: json['message']?.toString())
          : null,
    );
  }
}

/// Build-number policy for one platform (`data.builds.<platform>`).
///
/// Build number = Android versionCode / iOS CFBundleVersion = the `+N` in
/// pubspec `version: 1.3.0+N`.
class PlatformBuildPolicy {
  /// Newest build live in the store. Below this → optional prompt.
  final int? latest;

  /// Oldest build still allowed. Below this → forced update.
  final int? minSupported;

  const PlatformBuildPolicy({this.latest, this.minSupported});

  bool get isConfigured => latest != null || minSupported != null;

  factory PlatformBuildPolicy.fromJson(dynamic json) {
    if (json is! Map) return const PlatformBuildPolicy();
    return PlatformBuildPolicy(
      latest: _toInt(json['latest']),
      minSupported: _toInt(json['minSupported']),
    );
  }

  static int? _toInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }
}

/// Inner "data" object: { versions, forceUpdate, storeUrls, builds, releaseNotes }.
class AppVersionData {
  /// Latest version names per platform: { "ios": "1.1.4", "android": "1.1.0" }.
  final String iosVersion;
  final String androidVersion;

  /// Legacy global switch, only used when no build policy is configured.
  final bool forceUpdate;

  /// Store URLs: { "ios": "...", "android": "..." }.
  final String? iosStoreUrl;
  final String? androidStoreUrl;

  /// Build-number policy per platform (preferred over version names).
  final PlatformBuildPolicy iosBuilds;
  final PlatformBuildPolicy androidBuilds;

  /// Optional "what's new" text shown in the dialog.
  final String? releaseNotes;

  /// Optional message (from top-level API "message").
  final String? message;

  const AppVersionData({
    required this.iosVersion,
    required this.androidVersion,
    required this.forceUpdate,
    this.iosStoreUrl,
    this.androidStoreUrl,
    this.iosBuilds = const PlatformBuildPolicy(),
    this.androidBuilds = const PlatformBuildPolicy(),
    this.releaseNotes,
    this.message,
  });

  factory AppVersionData.fromJson(
    Map<String, dynamic> json, {
    String? message,
  }) {
    final versions = json['versions'];
    final storeUrls = json['storeUrls'];
    final builds = json['builds'];

    final versionsMap = versions is Map ? versions : null;
    final storeUrlsMap = storeUrls is Map ? storeUrls : null;
    final buildsMap = builds is Map ? builds : null;

    final notes = json['releaseNotes']?.toString().trim();

    return AppVersionData(
      iosVersion: (versionsMap?['ios'] ?? '0.0.0').toString(),
      androidVersion: (versionsMap?['android'] ?? '0.0.0').toString(),
      forceUpdate: json['forceUpdate'] == true,
      iosStoreUrl: storeUrlsMap?['ios']?.toString(),
      androidStoreUrl: storeUrlsMap?['android']?.toString(),
      iosBuilds: PlatformBuildPolicy.fromJson(buildsMap?['ios']),
      androidBuilds: PlatformBuildPolicy.fromJson(buildsMap?['android']),
      releaseNotes: (notes == null || notes.isEmpty) ? null : notes,
      message: message ?? json['message']?.toString(),
    );
  }
}
