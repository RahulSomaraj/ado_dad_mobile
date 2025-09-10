/// Utility class for handling chat-specific errors
class ChatErrorHandler {
  /// Convert server error to user-friendly message
  static String getUserFriendlyMessage(String error) {
    // Handle common error patterns
    if (error.toLowerCase().contains('unauthorized')) {
      return 'Session expired. Please log in again.';
    }

    if (error.toLowerCase().contains('network')) {
      return 'Network error. Please check your connection.';
    }

    if (error.toLowerCase().contains('timeout')) {
      return 'Request timed out. Please try again.';
    }

    if (error.toLowerCase().contains('not found')) {
      return 'Chat not found. It may have been deleted.';
    }

    if (error.toLowerCase().contains('permission')) {
      return 'You don\'t have permission to access this chat.';
    }

    if (error.toLowerCase().contains('empty') ||
        error.toLowerCase().contains('invalid')) {
      return 'Invalid message. Please try again.';
    }

    // Default error message
    return 'Something went wrong. Please try again.';
  }

  /// Check if error is retryable
  static bool isRetryableError(String error) {
    final retryableErrors = [
      'network',
      'timeout',
      'connection',
      'server error',
      'temporary',
    ];

    return retryableErrors
        .any((retryableError) => error.toLowerCase().contains(retryableError));
  }

  /// Check if error requires re-authentication
  static bool requiresReAuth(String error) {
    return error.toLowerCase().contains('unauthorized') ||
        error.toLowerCase().contains('token') ||
        error.toLowerCase().contains('expired');
  }

  /// Get retry delay based on error type
  static Duration getRetryDelay(String error) {
    if (error.toLowerCase().contains('rate limit')) {
      return const Duration(seconds: 30);
    }

    if (error.toLowerCase().contains('timeout')) {
      return const Duration(seconds: 5);
    }

    return const Duration(seconds: 2);
  }

  /// Format error for logging
  static String formatErrorForLog(String error, {String? context}) {
    final timestamp = DateTime.now().toIso8601String();
    final contextInfo = context != null ? ' [$context]' : '';
    return '[$timestamp]$contextInfo $error';
  }

  /// Validate message content
  static String? validateMessageContent(String content) {
    if (content.trim().isEmpty) {
      return 'Message cannot be empty';
    }

    if (content.length > 1000) {
      return 'Message too long (max 1000 characters)';
    }

    // Check for only whitespace characters
    if (content.trim().isEmpty) {
      return 'Message cannot contain only spaces';
    }

    return null; // No validation error
  }

  /// Get error category for analytics
  static String getErrorCategory(String error) {
    if (requiresReAuth(error)) {
      return 'authentication';
    }

    if (isRetryableError(error)) {
      return 'network';
    }

    if (error.toLowerCase().contains('validation')) {
      return 'validation';
    }

    if (error.toLowerCase().contains('permission')) {
      return 'permission';
    }

    return 'unknown';
  }
}
