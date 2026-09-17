import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Application configuration class that loads environment variables from .env file
class AppConfig {
  /// Production API. Release builds use this unless told otherwise, so a
  /// UAT `.env` bundled by mistake can never ship to the store.
  static const String productionBaseUrl = 'https://api.adodad.com';

  /// `--dart-define=BASE_URL=https://...` wins over everything.
  static const String _definedBaseUrl = String.fromEnvironment('BASE_URL');

  /// `--dart-define=API_ENV=uat` makes a release build (e.g. an internal
  /// testing APK) read BASE_URL from `.env` instead of using production.
  /// `API_ENV=prod` forces production in debug/profile too.
  static const String _apiEnv = String.fromEnvironment('API_ENV');

  /// Which API this build talks to. Order: BASE_URL define → API_ENV=prod or
  /// a release build (without API_ENV=uat) → `.env` BASE_URL.
  static String get baseUrl {
    if (_definedBaseUrl.isNotEmpty) return _trimSlash(_definedBaseUrl);
    final env = _apiEnv.toLowerCase();
    if (env == 'prod' || env == 'production' || (kReleaseMode && env != 'uat')) {
      return productionBaseUrl;
    }
    var url = _trimSlash(dotenv.env['BASE_URL'] ?? '');
    if (!kIsWeb && Platform.isAndroid && _isLocalDevUrl(url)) {
      // Physical device over Wi‑Fi: set DEV_HOST_IP to your PC's LAN IP (e.g. 192.168.1.42).
      // Android emulator: leave DEV_HOST_IP empty — uses 10.0.2.2 (host loopback alias).
      final host = dotenv.env['DEV_HOST_IP']?.trim();
      final resolvedHost =
          (host != null && host.isNotEmpty) ? host : '10.0.2.2';
      url = url
          .replaceAll('localhost', resolvedHost)
          .replaceAll('127.0.0.1', resolvedHost);
    }
    return url;
  }

  static String _trimSlash(String url) {
    var u = url.trim();
    while (u.endsWith('/')) {
      u = u.substring(0, u.length - 1);
    }
    return u;
  }

  static bool _isLocalDevUrl(String url) {
    return url.contains('localhost') || url.contains('127.0.0.1');
  }

  // Google Places API Key for map integration
  static String get googlePlacesApiKey =>
      dotenv.env['GOOGLE_PLACES_API_KEY'] ?? '';

  // Add other configuration getters here as needed
  // static String get exampleApiKey => dotenv.env['EXAMPLE_API_KEY'] ?? '';

  /// Initialize the environment configuration
  /// Call this method in main() before runApp()
  static Future<void> load() async {
    try {
      await dotenv.load();
    } catch (_) {
      // Handle error if .env file is not found
    }
  }

  /// Check if all required environment variables are loaded
  static bool get isConfigured =>
      baseUrl.isNotEmpty &&
      dotenv.env['GOOGLE_PLACES_API_KEY'] != null;
}
