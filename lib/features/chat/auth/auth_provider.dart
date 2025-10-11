/// Abstract interface for chat authentication providers
abstract class ChatAuthProvider {
  /// Get the current authentication token
  String? get token;

  /// Get the current user ID
  String? get userId;

  /// Stream of token changes for reactive updates
  Stream<void>? get tokenChanges;

  /// Check if the user is currently authenticated
  bool get isAuthenticated;

  /// Get token asynchronously
  Future<String?> getTokenAsync();

  /// Get user ID asynchronously
  Future<String?> getUserIdAsync();
}
