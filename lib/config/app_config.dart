import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Application configuration class that loads environment variables from .env file
class AppConfig {
  // Base URL for API calls
  static String get baseUrl {
    var url = dotenv.env['BASE_URL'] ?? '';
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
      print('📡 API base URL: $baseUrl');
    } catch (e) {
      // Handle error if .env file is not found
      print('Warning: Could not load .env file: $e');
    }
  }

  /// Check if all required environment variables are loaded
  static bool get isConfigured =>
      dotenv.env['BASE_URL'] != null &&
      dotenv.env['GOOGLE_PLACES_API_KEY'] != null;
}
