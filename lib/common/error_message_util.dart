/// Utility class to convert technical error messages to user-friendly messages
class ErrorMessageUtil {
  /// Converts technical error messages to user-friendly messages
  static String getUserFriendlyMessage(String errorMessage) {
    if (errorMessage.isEmpty) {
      return 'Something went wrong. Please try again.';
    }

    final message = errorMessage.toLowerCase();

    // Remove common prefixes and patterns like "Exception: ", "Error: ", "❌ " from anywhere in the message
    String cleanMessage = errorMessage
        .replaceAll(RegExp(r'^Exception:\s*', caseSensitive: false), '')
        .replaceAll(RegExp(r'^Error:\s*', caseSensitive: false), '')
        .replaceAll(RegExp(r'\bException:\s*', caseSensitive: false), '')
        .replaceAll(RegExp(r'\bError:\s*', caseSensitive: false), '')
        .replaceAll('❌', '')
        .replaceAll(
            RegExp(r'\s+'), ' ') // Replace multiple spaces with single space
        .trim();

    // Network/Connection errors
    if (message.contains('socketexception') ||
        message.contains('failed host lookup') ||
        message.contains('network is unreachable') ||
        message.contains('connectionerror') ||
        message.contains('no internet') ||
        message.contains('connection timeout') ||
        message.contains('connection error')) {
      return 'Unable to connect to the server. Please check your internet connection and try again.';
    }

    // Timeout errors
    if (message.contains('timeout') ||
        message.contains('receive timeout') ||
        message.contains('send timeout')) {
      return 'Request timed out. Please try again.';
    }

    // Server errors
    if (message.contains('500') || message.contains('internal server error')) {
      return 'Server error occurred. Please try again later.';
    }

    if (message.contains('404') || message.contains('not found')) {
      return 'The requested information could not be found.';
    }

    if (message.contains('403') || message.contains('forbidden')) {
      return 'You do not have permission to access this content.';
    }

    if (message.contains('401') || message.contains('unauthorized')) {
      return 'Please log in again to continue.';
    }

    if (message.contains('400') || message.contains('bad request')) {
      return 'Invalid request. Please check your input and try again.';
    }

    // DioException patterns
    if (message.contains('dioexception') ||
        message.contains('dio') ||
        message.contains('dioerror')) {
      return 'Network error occurred. Please check your connection and try again.';
    }

    // Upload/File errors
    if (message.contains('upload failed') ||
        message.contains('failed to upload') ||
        message.contains('no signed url')) {
      return 'Failed to upload file. Please try again.';
    }

    // Authentication errors
    if (message.contains('session expired') ||
        message.contains('token expired') ||
        message.contains('authentication failed')) {
      return 'Your session has expired. Please log in again.';
    }

    // Generic error patterns
    if (message.contains('exception:') || message.contains('error:')) {
      // Try to extract a cleaner message
      final parts = cleanMessage.split(':');
      if (parts.length > 1) {
        final extractedMessage = parts.sublist(1).join(':').trim();
        if (extractedMessage.isNotEmpty &&
            !extractedMessage.toLowerCase().contains('dio') &&
            !extractedMessage.toLowerCase().contains('exception') &&
            !extractedMessage.toLowerCase().contains('stacktrace')) {
          // Check if it's already user-friendly
          if (extractedMessage.length < 100 &&
              !extractedMessage.contains('at ') &&
              !extractedMessage.contains('stacktrace')) {
            return extractedMessage;
          }
        }
      }
    }

    // If it's a very technical error message, show a generic friendly message
    if (message.contains('dio') ||
        message.contains('exception') ||
        message.length > 100 ||
        message.contains('stacktrace') ||
        message.contains('at ') ||
        message.contains('stack trace') ||
        message.contains('dart:') ||
        message.contains('package:')) {
      return 'Something went wrong. Please try again later.';
    }

    // Remove emoji and clean up if message seems user-friendly
    if (cleanMessage != errorMessage && cleanMessage.isNotEmpty) {
      return cleanMessage;
    }

    // Return the original message if it seems user-friendly already
    return errorMessage;
  }
}
