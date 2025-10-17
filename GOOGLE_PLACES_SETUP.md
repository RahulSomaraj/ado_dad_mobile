# Google Places API Setup Guide

This guide explains how to set up Google Places API for location search functionality in the Ado Dad User app.

## Prerequisites

1. Google Cloud Platform account
2. Google Places API enabled
3. API key with Places API permissions

## Setup Steps

### 1. Get Google Places API Key

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Enable the "Places API" for your project
4. Go to "Credentials" and create an API key
5. Restrict the API key to only use Places API for security

### 2. Configure API Key in the App

Replace the placeholder in `lib/env/env.dart`:

```dart
static const googlePlacesApiKey = String.fromEnvironment('GOOGLE_PLACES_API_KEY',
    defaultValue: 'YOUR_ACTUAL_API_KEY_HERE');
```

### 3. Run the App

The location search will now work with Google Places API. When users type in the location search field:

- For queries like "Pa", it will show places starting with "Pa" in India
- Results are biased towards India (region: 'in')
- Falls back to existing ad locations if API fails
- Shows up to 10 suggestions

## Features

- **Smart Suggestions**: Shows places starting with the entered text
- **India Biased**: Results are biased towards Indian locations
- **Fallback Support**: Falls back to existing ad locations if API fails
- **Real-time Search**: Updates suggestions as user types (minimum 2 characters)

## Testing

1. Open the app and navigate to search
2. Tap the location icon to enable location search mode
3. Type "Pa" to see places like "Palakkad, Kerala", "Pune, Maharashtra", etc.
4. Type "Koch" to see "Kochi, Kerala" and similar places

## API Usage

The implementation uses:
- `google_maps_flutter: ^2.7.0`
- `flutter_google_places: ^0.3.0` 
- `google_api_headers: ^2.0.2`

## Cost Considerations

Google Places API charges per request. Consider implementing:
- Debouncing to reduce API calls
- Caching for frequently searched locations
- Rate limiting for production use

## Security

- Never commit API keys to version control
- Use environment variables for API keys
- Restrict API key permissions in Google Cloud Console
- Consider using server-side proxy for production apps
