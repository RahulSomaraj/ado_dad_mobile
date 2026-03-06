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
          ? AppVersionData.fromJson(dataJson, message: json['message']?.toString())
          : null,
    );
  }
}

/// Inner "data" object: { versions, forceUpdate, storeUrls }.
class AppVersionData {
  /// Latest versions per platform: { "ios": "1.1.4", "android": "1.1.0" }.
  final String iosVersion;
  final String androidVersion;

  /// When true, show update as mandatory (no "Later").
  final bool forceUpdate;

  /// Store URLs: { "ios": "...", "android": "..." }.
  final String? iosStoreUrl;
  final String? androidStoreUrl;

  /// Optional message (from top-level API "message").
  final String? message;

  const AppVersionData({
    required this.iosVersion,
    required this.androidVersion,
    required this.forceUpdate,
    this.iosStoreUrl,
    this.androidStoreUrl,
    this.message,
  });

  factory AppVersionData.fromJson(
    Map<String, dynamic> json, {
    String? message,
  }) {
    final versions = json['versions'];
    final storeUrls = json['storeUrls'];

    final versionsMap = versions is Map ? versions : null;
    final storeUrlsMap = storeUrls is Map ? storeUrls : null;

    return AppVersionData(
      iosVersion: (versionsMap?['ios'] ?? '0.0.0').toString(),
      androidVersion: (versionsMap?['android'] ?? '0.0.0').toString(),
      forceUpdate: json['forceUpdate'] == true,
      iosStoreUrl: storeUrlsMap?['ios']?.toString(),
      androidStoreUrl: storeUrlsMap?['android']?.toString(),
      message: message ?? json['message']?.toString(),
    );
  }
}
