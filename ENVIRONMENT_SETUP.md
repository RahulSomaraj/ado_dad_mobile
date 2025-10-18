# Environment Configuration Setup

This project uses environment variables to securely store API keys and configuration values.

## Setup Instructions

### 1. Create Environment File
Copy the example environment file and fill in your actual API keys:

```bash
cp .env.example .env
```

### 2. Configure Your API Keys
Edit the `.env` file with your actual API keys:

```env
# Base URL for API calls
BASE_URL=https://uat.ado-dad.com

# Google Places API Key for map integration
GOOGLE_PLACES_API_KEY=your_actual_google_places_api_key_here

# Add other API keys here as needed
# EXAMPLE_API_KEY=your_api_key_here
```

### 3. Security Notes
- ✅ The `.env` file is already added to `.gitignore` and will NOT be committed to version control
- ✅ Never commit your actual API keys to the repository
- ✅ Use the `.env.example` file as a template for other developers

## Usage in Code

### Accessing Environment Variables
Use the `AppConfig` class to access your environment variables:

```dart
import 'package:ado_dad_user/config/app_config.dart';

// Get the base URL
String baseUrl = AppConfig.baseUrl;

// Get the Google Places API key
String apiKey = AppConfig.googlePlacesApiKey;

// Check if configuration is loaded
bool isConfigured = AppConfig.isConfigured;
```

### Adding New Environment Variables

1. Add the variable to your `.env` file:
```env
NEW_API_KEY=your_new_api_key_here
```

2. Add a getter to `lib/config/app_config.dart`:
```dart
static String get newApiKey => dotenv.env['NEW_API_KEY'] ?? '';
```

3. Update `.env.example` with the new variable (without the actual key):
```env
NEW_API_KEY=your_new_api_key_here
```

## Migration from env.dart

The old `lib/env/env.dart` file has been replaced with this new system. If you have any code using the old `Env` class, update it to use `AppConfig` instead:

**Old:**
```dart
import 'package:ado_dad_user/env/env.dart';
String apiKey = Env.googlePlacesApiKey;
```

**New:**
```dart
import 'package:ado_dad_user/config/app_config.dart';
String apiKey = AppConfig.googlePlacesApiKey;
```

## Troubleshooting

### Environment variables not loading
- Ensure the `.env` file exists in the project root
- Check that `.env` is listed in `pubspec.yaml` under `assets:`
- Verify that `AppConfig.load()` is called in `main()` before `runApp()`

### API key not working
- Verify the API key is correct in your `.env` file
- Check that there are no extra spaces or quotes around the key
- Ensure the API key has the necessary permissions for your use case
