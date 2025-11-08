import 'dart:convert';

import 'package:ado_dad_user/models/login_response_model.dart';
import 'package:ado_dad_user/models/profile_model.dart';
import 'package:ado_dad_user/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefs {
  static final SharedPrefs _instance = SharedPrefs._internal();
  SharedPreferences? _prefs;

  factory SharedPrefs() => _instance;

  SharedPrefs._internal();

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Generic getter for Strings
  String? getString(String key) => _prefs?.getString(key);

  /// Generic setter for Strings
  Future<void> setString(String key, String value) async {
    await _prefs?.setString(key, value);
  }

  /// Remove a specific key
  Future<void> remove(String key) async {
    await _prefs?.remove(key);
  }

  /// Clear all stored preferences
  Future<void> clear() async {
    await _prefs?.clear();
  }

  /// 🔹 Save user ID
  Future<void> saveUserId(String userId) async {
    print("Saving User ID: $userId"); // Debug log before saving
    await setString("user_id", userId);
    print("User ID saved successfully.");
  }

  /// 🔹 Retrieve stored user ID
  Future<String?> getUserId() async {
    String? userId = getString("user_id");
    print("Retrieved User ID from SharedPreferences: $userId"); // Debug log
    return userId;
  }

  /// 🔹 Save user profile in SharedPreferences
  Future<void> saveUserProfile(UserProfile profile) async {
    await _prefs?.setString("user_profile", jsonEncode(profile.toJson()));
    print("✅ Profile saved in SharedPreferences: ${profile.toJson()}");
  }

  /// 🔹 Retrieve stored user profile
  Future<UserProfile?> getUserProfile() async {
    final String? userProfileString = _prefs?.getString("user_profile");

    if (userProfileString != null) {
      return UserProfile.fromJson(jsonDecode(userProfileString));
    }
    print("⚠️ No profile found in SharedPreferences.");
    return null;
  }

  /// 🔐 Check if login session is expired
  Future<bool> isLoginExpired({int sessionDurationMinutes = 60}) async {
    final loginTimestampStr = getString('loginTimestamp');

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
  final now = DateTime.now().millisecondsSinceEpoch;

  // Remove "Bearer " prefix from token if present (API response may include it, but we store without it)
  final cleanToken =
      loginResponse.token.replaceFirst(RegExp(r'^Bearer\s+'), '');
  final cleanRefreshToken =
      loginResponse.refreshToken.replaceFirst(RegExp(r'^Bearer\s+'), '');

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
Future<String?> getToken() async {
  return SharedPrefs().getString('token');
}

/// Retrieve stored refresh token
Future<String?> getRefreshToken() async {
  return SharedPrefs().getString('refreshToken');
}

/// Retrieve stored username
Future<String?> getUserName() async {
  return SharedPrefs().getString('userName');
}

/// Retrieve stored user email
Future<String?> getUserEmail() async {
  return SharedPrefs().getString('email');
}

/// Retrieve stored user type
Future<String?> getUserType() async {
  return SharedPrefs().getString('userType');
}

/// Retrieve stored profile picture (if applicable)
Future<String?> getUserProfilePicture() async {
  return SharedPrefs().getString('profilePicture');
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
