import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Access + refresh tokens, held in the platform keystore.
///
/// They used to live in `SharedPreferences`, i.e. plaintext Android XML and an
/// iOS plist — readable on a rooted/jailbroken device and included in some
/// backup flows. `FlutterSecureStorage` puts them in EncryptedSharedPreferences
/// (Android) / the Keychain (iOS) instead.
///
/// The keystore is slower than a plist read and the Dio request interceptor
/// asks for the token on *every* request, so the values are mirrored in memory
/// after [init] and reads never touch the platform channel again.
class SecureTokenStore {
  static final SecureTokenStore _instance = SecureTokenStore._internal();
  factory SecureTokenStore() => _instance;
  SecureTokenStore._internal();

  static const String _kToken = 'token';
  static const String _kRefreshToken = 'refreshToken';

  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  String? _token;
  String? _refreshToken;
  bool _ready = false;

  /// Loads both tokens into memory and migrates any left in SharedPreferences.
  /// Call once from `main()` after `SharedPrefs().init()`.
  Future<void> init() async {
    if (_ready) return;
    try {
      _token = await _storage.read(key: _kToken);
      _refreshToken = await _storage.read(key: _kRefreshToken);
    } catch (_) {
      // Known Android failure mode: the keystore entry can no longer be
      // decrypted (app restored to a new device, keys rotated). Wipe and treat
      // the user as logged out rather than crashing on every read.
      try {
        await _storage.deleteAll();
      } catch (_) {}
      _token = null;
      _refreshToken = null;
    }
    _ready = true;
    await _migrateFromPrefs();
  }

  /// One-time move of tokens written by a pre-secure-storage build.
  Future<void> _migrateFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final legacyToken = prefs.getString(_kToken);
      final legacyRefresh = prefs.getString(_kRefreshToken);
      if (legacyToken == null && legacyRefresh == null) return;

      if (_token == null && legacyToken != null && legacyToken.isNotEmpty) {
        await setToken(legacyToken);
      }
      if (_refreshToken == null &&
          legacyRefresh != null &&
          legacyRefresh.isNotEmpty) {
        await setRefreshToken(legacyRefresh);
      }
      // Remove the plaintext copies whether or not they were adopted — leaving
      // them behind is the exposure this class exists to close.
      await prefs.remove(_kToken);
      await prefs.remove(_kRefreshToken);
    } catch (_) {
      // Migration is best-effort; a failure here must not block startup.
    }
  }

  String? get token => _token;

  String? get refreshToken => _refreshToken;

  Future<void> setToken(String value) async {
    _token = value;
    try {
      await _storage.write(key: _kToken, value: value);
    } catch (_) {
      // Keep the in-memory copy so the current session still works.
    }
  }

  Future<void> setRefreshToken(String value) async {
    _refreshToken = value;
    try {
      await _storage.write(key: _kRefreshToken, value: value);
    } catch (_) {}
  }

  Future<void> clear() async {
    _token = null;
    _refreshToken = null;
    try {
      await _storage.delete(key: _kToken);
      await _storage.delete(key: _kRefreshToken);
    } catch (_) {}
  }
}
