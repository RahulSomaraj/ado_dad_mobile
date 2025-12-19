import 'dart:convert';
import 'dart:io';

import 'package:ado_dad_user/models/login_response_model.dart';
import 'package:ado_dad_user/models/profile_model.dart';
import 'package:ado_dad_user/services/auth_service.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';

/// File-based storage for iOS (avoids Pigeon channel issues)
class _IOSFileStorage {
  static File? _storageFile;
  static Map<String, dynamic> _cache = {};

  static Future<File> _getStorageFile() async {
    if (_storageFile != null) return _storageFile!;

    Directory directory = Directory.systemTemp; // Default fallback

    // Retry logic: platform channel might not be ready immediately
    const platform = MethodChannel('com.ado_dad_user/storage');
    String? documentsPath;

    for (int attempt = 1; attempt <= 5; attempt++) {
      try {
        // Use platform channel to get iOS documents directory
        // This is the ONLY reliable way to get the documents directory on iOS
        documentsPath =
            await platform.invokeMethod<String>('getDocumentsDirectory');

        if (documentsPath != null && documentsPath.isNotEmpty) {
          directory = Directory(documentsPath);
          print(
              '✅ [iOS FileStorage] Using documents directory from platform channel (attempt $attempt): $documentsPath');
          break; // Success!
        } else {
          throw Exception('Platform channel returned null/empty path');
        }
      } catch (e) {
        if (attempt < 5) {
          print(
              '⏳ [iOS FileStorage] Channel not ready (attempt $attempt/5), waiting 100ms...');
          await Future.delayed(const Duration(milliseconds: 100));
          continue;
        } else {
          print(
              '❌ [iOS FileStorage] Error getting documents directory after 5 attempts: $e');
          print(
              '⚠️ [iOS FileStorage] CRITICAL: Platform channel not available - data may not persist!');
          print(
              '⚠️ [iOS FileStorage] This should not happen in production - check AppDelegate channel registration');
          // Fallback to system temp (not ideal, but better than crashing)
          // In production, this should rarely happen if channel is registered early
          directory = Directory.systemTemp;
        }
      }
    }

    // Ensure directory exists
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    final file = File(path.join(directory.path, 'ado_dad_prefs.json'));

    // Create file if it doesn't exist
    if (!await file.exists()) {
      await file.create(recursive: true);
      await file.writeAsString('{}');
      print('✅ [iOS FileStorage] Created new storage file');
    } else {
      print('✅ [iOS FileStorage] Using existing storage file');
    }

    _storageFile = file;
    print('✅ [iOS FileStorage] Storage file path: ${file.path}');
    return file;
  }

  static Future<void> _loadCache() async {
    // Always reload from file to ensure we have latest data
    // This is important for persistence across app restarts
    try {
      final file = await _getStorageFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        if (content.isNotEmpty) {
          _cache = jsonDecode(content) as Map<String, dynamic>? ?? {};
          print('📂 [iOS FileStorage] Loaded ${_cache.length} keys from file');
        } else {
          _cache = {};
        }
      } else {
        _cache = {};
      }
    } catch (e) {
      print('⚠️ [iOS FileStorage] Error loading cache: $e');
      _cache = {};
    }
  }

  static Future<void> _saveCache() async {
    try {
      final file = await _getStorageFile();
      final jsonString = jsonEncode(_cache);
      await file.writeAsString(jsonString);
      print('💾 [iOS FileStorage] Saved ${_cache.length} keys to file');
    } catch (e) {
      print('⚠️ [iOS FileStorage] Error saving: $e');
      rethrow; // Re-throw so caller knows save failed
    }
  }

  static Future<String?> getString(String key) async {
    await _loadCache();
    final value = _cache[key];
    if (value == null) {
      print(
          '🔍 [iOS FileStorage] Key "$key" not found in cache (${_cache.length} total keys)');
      return null;
    }
    final result = value.toString();
    print(
        '✅ [iOS FileStorage] Retrieved key "$key" = ${result.length > 50 ? result.substring(0, 50) + "..." : result}');
    return result;
  }

  static Future<void> setString(String key, String value) async {
    try {
      await _loadCache();
      _cache[key] = value;
      print(
          '💾 [iOS FileStorage] Setting key: $key = ${value.length > 50 ? value.substring(0, 50) + "..." : value}');
      await _saveCache();

      // Verify the save worked (important for production)
      await _loadCache();
      if (_cache[key] == value) {
        print('✅ [iOS FileStorage] Saved and verified key: $key');
      } else {
        print('❌ [iOS FileStorage] Verification failed for key: $key');
        throw Exception('Failed to save $key - verification failed');
      }
    } catch (e) {
      print('❌ [iOS FileStorage] Error setting key "$key": $e');
      rethrow;
    }
  }

  static Future<void> remove(String key) async {
    await _loadCache();
    _cache.remove(key);
    await _saveCache();
  }

  static Future<void> clear() async {
    _cache.clear();
    await _saveCache();
  }
}

class SharedPrefs {
  static final SharedPrefs _instance = SharedPrefs._internal();
  SharedPreferences? _prefs; // Android only
  bool _isInitializing = false;
  bool _useFileStorage = false; // iOS file storage flag

  factory SharedPrefs() => _instance;

  SharedPrefs._internal() {
    // On iOS, use file storage instead of SharedPreferences
    _useFileStorage = Platform.isIOS;
  }

  /// Initialize SharedPreferences (Android) or File Storage (iOS)
  /// iOS uses file storage to avoid Pigeon channel issues
  /// Android uses SharedPreferences (works fine)
  Future<void> init({int maxRetries = 3}) async {
    if (_useFileStorage) {
      // iOS: File storage - no initialization needed, works immediately
      _isInitializing = false;
      print('✅ [iOS] Using file-based storage (no Pigeon channels)');
      return;
    }

    // Android: Use SharedPreferences
    if (_prefs != null) return; // Already initialized
    if (_isInitializing) {
      // Wait for ongoing initialization
      while (_isInitializing) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
      if (_prefs != null) return; // Initialized by another call
    }

    _isInitializing = true;
    int retries = 0;

    while (retries < maxRetries) {
      try {
        _prefs = await SharedPreferences.getInstance();
        _isInitializing = false;
        print('✅ [Android] SharedPreferences initialized');
        return; // Success
      } catch (e) {
        retries++;
        if (retries >= maxRetries) {
          _isInitializing = false;
          return;
        }
        // Exponential backoff: 100ms, 200ms, 400ms
        await Future.delayed(
            Duration(milliseconds: 100 * (1 << (retries - 1))));
      }
    }
    _isInitializing = false;
  }

  /// Ensure storage is initialized (lazy initialization)
  /// iOS: File storage (always ready)
  /// Android: SharedPreferences (may need initialization)
  Future<void> ensureInitialized() async {
    if (_useFileStorage) {
      // iOS: File storage is always ready
      return;
    }

    // Android: Ensure SharedPreferences is initialized
    if (_prefs != null) return;

    await init();
    if (_prefs == null) {
      await init(maxRetries: 5);
    }

    if (_prefs == null) {
      throw Exception(
          'Failed to initialize SharedPreferences after multiple attempts');
    }
  }

  /// Generic getter for Strings
  /// Note: This is synchronous and doesn't ensure initialization
  /// Use getStringAsync for guaranteed initialization
  String? getString(String key) {
    if (_useFileStorage) {
      // iOS: File storage - synchronous access not supported, return null
      // Caller should use getStringAsync
      return null;
    }
    try {
      return _prefs?.getString(key);
    } catch (e) {
      return null;
    }
  }

  /// Async getter that ensures initialization before reading
  /// iOS: Uses file storage (no channel issues)
  /// Android: Uses SharedPreferences
  Future<String?> getStringAsync(String key) async {
    if (_useFileStorage) {
      // iOS: Use file storage
      await ensureInitialized();
      return await _IOSFileStorage.getString(key);
    }

    // Android: Use SharedPreferences
    try {
      await ensureInitialized();
      if (_prefs == null) return null;
      return _prefs!.getString(key);
    } catch (e) {
      return null;
    }
  }

  /// Generic setter for Strings
  /// iOS: Uses file storage (no channel issues)
  /// Android: Uses SharedPreferences
  Future<void> setString(String key, String value) async {
    if (_useFileStorage) {
      // iOS: Use file storage
      await ensureInitialized();
      await _IOSFileStorage.setString(key, value);
      return;
    }

    // Android: Use SharedPreferences
    await ensureInitialized();
    if (_prefs == null) {
      throw Exception('SharedPreferences not initialized - cannot save $key');
    }
    await _prefs!.setString(key, value);
  }

  /// Remove a specific key
  Future<void> remove(String key) async {
    if (_useFileStorage) {
      // iOS: Use file storage
      await ensureInitialized();
      await _IOSFileStorage.remove(key);
      return;
    }

    // Android: Use SharedPreferences
    await ensureInitialized();
    if (_prefs == null) {
      throw Exception('SharedPreferences not initialized - cannot remove $key');
    }
    await _prefs!.remove(key);
  }

  /// Clear all stored preferences
  Future<void> clear() async {
    if (_useFileStorage) {
      // iOS: Use file storage
      await ensureInitialized();
      await _IOSFileStorage.clear();
      return;
    }

    // Android: Use SharedPreferences
    await ensureInitialized();
    if (_prefs == null) {
      throw Exception('SharedPreferences not initialized - cannot clear');
    }
    await _prefs!.clear();
  }

  /// 🔹 Save user ID
  Future<void> saveUserId(String userId) async {
    print("Saving User ID: $userId"); // Debug log before saving
    await setString("user_id", userId);
    print("User ID saved successfully.");
  }

  /// 🔹 Retrieve stored user ID
  /// Uses async access to work with both iOS file storage and Android SharedPreferences
  Future<String?> getUserId() async {
    String? userId = await getStringAsync("user_id");
    print("Retrieved User ID: $userId"); // Debug log
    return userId;
  }

  /// 🔹 Save user profile
  Future<void> saveUserProfile(UserProfile profile) async {
    await ensureInitialized();
    final profileJson = jsonEncode(profile.toJson());
    await setString("user_profile", profileJson);
    print("✅ Profile saved: ${profile.toJson()}");
  }

  /// 🔹 Retrieve stored user profile
  Future<UserProfile?> getUserProfile() async {
    await ensureInitialized();
    final String? userProfileString = await getStringAsync("user_profile");

    if (userProfileString != null) {
      return UserProfile.fromJson(jsonDecode(userProfileString));
    }
    print("⚠️ No profile found.");
    return null;
  }

  /// 🔐 Check if login session is expired
  Future<bool> isLoginExpired({int sessionDurationMinutes = 60}) async {
    final loginTimestampStr = await getStringAsync('loginTimestamp');

    if (loginTimestampStr == null) {
      print("⚠️ No login timestamp found.");
      return true; // No timestamp → consider session expired
    }

    final loginTime = int.tryParse(loginTimestampStr);
    if (loginTime == null) {
      print("⚠️ Invalid login timestamp.");
      return true;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final sessionDurationMillis = sessionDurationMinutes * 60 * 1000;

    if ((now - loginTime) > sessionDurationMillis) {
      print("⏰ Login session expired.");
      return true;
    }

    print("✅ Login session still valid.");
    return false;
  }
}

/// Save login response data
Future<void> saveLoginResponse(LoginResponse loginResponse) async {
  final sharedPrefs = SharedPrefs();

  // Ensure storage is initialized before saving
  // iOS: File storage (always ready, no delays needed)
  // Android: SharedPreferences (may need initialization)
  await sharedPrefs.ensureInitialized();

  final now = DateTime.now().millisecondsSinceEpoch;

  // Remove "Bearer " prefix from token if present (API response may include it, but we store without it)
  final cleanToken =
      loginResponse.token.replaceFirst(RegExp(r'^Bearer\s+'), '');
  final cleanRefreshToken =
      loginResponse.refreshToken.replaceFirst(RegExp(r'^Bearer\s+'), '');

  try {
    await sharedPrefs.setString('token', cleanToken);
    await sharedPrefs.setString('userName', loginResponse.name);
    await sharedPrefs.setString('refreshToken', cleanRefreshToken);
    await sharedPrefs.setString('userType', loginResponse.userType);
    await sharedPrefs.setString('email', loginResponse.email);
    await sharedPrefs.setString('user_id', loginResponse.id);
    await sharedPrefs.setString('loginTimestamp', now.toString());

    // Save profile picture if available
    if (loginResponse.profilePic != null &&
        loginResponse.profilePic!.isNotEmpty) {
      await sharedPrefs.setString('profilePicture', loginResponse.profilePic!);
      print("Profile picture saved: ${loginResponse.profilePic}");
    }
  } catch (e) {
    // If saving fails, log the error but don't throw - allow login to proceed
    print("❌ Error saving login response to SharedPreferences: $e");
    // Try to reinitialize and retry once
    try {
      await sharedPrefs.init(maxRetries: 5);
      await sharedPrefs.setString('token', cleanToken);
      await sharedPrefs.setString('userName', loginResponse.name);
      await sharedPrefs.setString('refreshToken', cleanRefreshToken);
      await sharedPrefs.setString('userType', loginResponse.userType);
      await sharedPrefs.setString('email', loginResponse.email);
      await sharedPrefs.setString('user_id', loginResponse.id);
      await sharedPrefs.setString('loginTimestamp', now.toString());
      if (loginResponse.profilePic != null &&
          loginResponse.profilePic!.isNotEmpty) {
        await sharedPrefs.setString(
            'profilePicture', loginResponse.profilePic!);
      }
      print("✅ Login response saved successfully after retry");
    } catch (retryError) {
      print("❌ Failed to save login response after retry: $retryError");
      // Don't throw - allow login to proceed even if saving fails
    }
  }

  // if (loginResponse.id != null) {
  //   await sharedPrefs.saveUserId(loginResponse.id);
  // }

  print("✅ Login response saved successfully:");
  print("   User ID: ${loginResponse.id}");
  print("   Name: ${loginResponse.name}");
  print(
      "   Token saved: ${cleanToken.isNotEmpty ? 'YES (${cleanToken.length} chars)' : 'NO'}");
  print(
      "   Refresh Token saved: ${cleanRefreshToken.isNotEmpty ? 'YES (${cleanRefreshToken.length} chars)' : 'NO'}");
  print("   ProfilePic: ${loginResponse.profilePic ?? 'N/A'}");

  // Reset initial refresh flag - token from login should work directly
  // Only refresh when token expires (401 error)
  AuthService().resetInitialRefreshFlag();
}

/// Retrieve stored token
/// Uses async getter to ensure initialization (important for iOS)
Future<String?> getToken() async {
  return await SharedPrefs().getStringAsync('token');
}

/// Retrieve stored refresh token
/// Uses async getter to ensure initialization (important for iOS)
Future<String?> getRefreshToken() async {
  return await SharedPrefs().getStringAsync('refreshToken');
}

/// Retrieve stored username
/// Uses async getter to ensure initialization (important for iOS)
Future<String?> getUserName() async {
  return await SharedPrefs().getStringAsync('userName');
}

/// Retrieve stored user email
/// Uses async getter to ensure initialization (important for iOS)
Future<String?> getUserEmail() async {
  return await SharedPrefs().getStringAsync('email');
}

/// Retrieve stored user type
/// Uses async getter to ensure initialization (important for iOS)
Future<String?> getUserType() async {
  return await SharedPrefs().getStringAsync('userType');
}

/// Retrieve stored profile picture (if applicable)
/// Uses async getter to ensure initialization (important for iOS)
Future<String?> getUserProfilePicture() async {
  return await SharedPrefs().getStringAsync('profilePicture');
}

/// Clear user-specific stored data
Future<void> clearUserData() async {
  final sharedPrefs = SharedPrefs();
  await sharedPrefs.remove('token');
  await sharedPrefs.remove('refreshToken');
  await sharedPrefs.remove('userName');
  await sharedPrefs.remove('userType');
  await sharedPrefs.remove('email');
  await sharedPrefs.remove('profilePicture');
  await sharedPrefs.remove('user_id');
  await sharedPrefs.remove("user_profile");
}
