import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Application configuration class that loads environment variables from .env file
class AppConfig {
  // Base URL for API calls
  static String get baseUrl {
    var url = dotenv.env['BASE_URL'] ?? '';
    // Android emulator: localhost is the emulator itself, not the dev machine.
    if (!kIsWeb && Platform.isAndroid) {
      url = url
          .replaceAll('localhost', '10.0.2.2')
          .replaceAll('127.0.0.1', '10.0.2.2');
    }
    return url;
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
