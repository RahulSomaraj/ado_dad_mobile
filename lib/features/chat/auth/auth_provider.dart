import 'dart:async';
import 'package:ado_dad_user/common/shared_pref.dart';

/// Interface for chat authentication provider
abstract class ChatAuthProvider {
  /// Get the current JWT token (raw token without Bearer prefix)
  String? get token;

  /// Get the current user ID
  String? get userId;

  /// Stream of token changes (for token refresh scenarios)
  /// Returns null if token change notifications are not supported
  Stream<void>? get tokenChanges;

  /// Check if user is authenticated
  bool get isAuthenticated;

  /// Get token asynchronously (useful for async operations)
  Future<String?> getTokenAsync();

  /// Get user ID asynchronously (useful for async operations)
  Future<String?> getUserIdAsync();
}

/// Implementation of ChatAuthProvider using existing SharedPrefs
class SharedPrefsChatAuthProvider implements ChatAuthProvider {
  final SharedPrefs _sharedPrefs;
  final StreamController<void> _tokenChangeController =
      StreamController<void>.broadcast();

  SharedPrefsChatAuthProvider({SharedPrefs? sharedPrefs})
      : _sharedPrefs = sharedPrefs ?? SharedPrefs();

  @override
  String? get token => _sharedPrefs.getString('token');

  @override
  String? get userId => _sharedPrefs.getString('user_id');

  @override
  Stream<void>? get tokenChanges => _tokenChangeController.stream;

  @override
  bool get isAuthenticated {
    final token = this.token;
    final userId = this.userId;
    return token != null &&
        token.isNotEmpty &&
        userId != null &&
        userId.isNotEmpty;
  }

  @override
  Future<String?> getTokenAsync() async {
    return _sharedPrefs.getString('token');
  }

  @override
  Future<String?> getUserIdAsync() async {
    return _sharedPrefs.getString('user_id');
  }

  /// Notify listeners when token changes (call this when token is refreshed)
  void notifyTokenChanged() {
    _tokenChangeController.add(null);
  }

  /// Dispose the stream controller
  void dispose() {
    _tokenChangeController.close();
  }
}

/// Global instance of the chat auth provider
class ChatAuthProviderInstance {
  static ChatAuthProvider? _instance;

  static ChatAuthProvider get instance {
    _instance ??= SharedPrefsChatAuthProvider();
    return _instance!;
  }

  static void setInstance(ChatAuthProvider provider) {
    _instance = provider;
  }

  static void dispose() {
    if (_instance is SharedPrefsChatAuthProvider) {
      (_instance as SharedPrefsChatAuthProvider).dispose();
    }
    _instance = null;
  }
}
