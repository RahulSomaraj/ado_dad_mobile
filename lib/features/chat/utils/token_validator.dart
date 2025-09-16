import 'dart:convert';
import 'dart:developer';

class TokenValidator {
  /// Validates JWT token format and extracts payload information
  static void validateToken(String token) {
    try {
      // log('🔍 JWT Token Validation:');

      // Check if token is not empty
      if (token.isEmpty) {
        log('❌ Token is empty');
        return;
      }

      // Check token format (should have 3 parts separated by dots)
      final parts = token.split('.');
      if (parts.length != 3) {
        log('❌ Invalid JWT format - should have 3 parts separated by dots');
        log('   Current parts: ${parts.length}');
        return;
      }

      // log('✅ JWT format is valid (3 parts)');

      // Decode header
      try {
        final header = parts[0];
        // Add padding if needed for base64 decoding
        String normalizedHeader = base64Url.normalize(header);
        while (normalizedHeader.length % 4 != 0) {
          normalizedHeader += '=';
        }
        final headerDecoded = utf8.decode(base64Url.decode(normalizedHeader));
        final headerJson = jsonDecode(headerDecoded);
        // log('📋 JWT Header: $headerJson');

        if (headerJson['typ'] != 'JWT') {
          log('⚠️ Warning: Token type is not JWT');
        }

        if (headerJson['alg'] == null) {
          log('⚠️ Warning: No algorithm specified');
        } else {
          log('🔐 Algorithm: ${headerJson['alg']}');
        }
      } catch (e) {
        log('❌ Failed to decode JWT header: $e');
      }

      // Decode payload
      try {
        final payload = parts[1];
        // Add padding if needed for base64 decoding
        String normalizedPayload = base64Url.normalize(payload);
        while (normalizedPayload.length % 4 != 0) {
          normalizedPayload += '=';
        }
        final payloadDecoded = utf8.decode(base64Url.decode(normalizedPayload));
        final payloadJson = jsonDecode(payloadDecoded);
        // log('📄 JWT Payload: $payloadJson');

        // Check expiration
        if (payloadJson['exp'] != null) {
          final exp =
              DateTime.fromMillisecondsSinceEpoch(payloadJson['exp'] * 1000);
          final now = DateTime.now();
          log('⏰ Token expires: $exp');
          log('🕐 Current time: $now');

          if (now.isAfter(exp)) {
            log('❌ Token is EXPIRED!');
          } else {
            log('✅ Token is still valid');
            final timeLeft = exp.difference(now);
            log('⏳ Time remaining: ${timeLeft.inMinutes} minutes');
          }
        } else {
          log('⚠️ Warning: No expiration time found in token');
        }

        // Check issuer
        if (payloadJson['iss'] != null) {
          // log('🏢 Issuer: ${payloadJson['iss']}');
        }

        // Check subject (user ID)
        if (payloadJson['sub'] != null) {
          log('👤 Subject (User ID): ${payloadJson['sub']}');
        }

        // Check audience
        if (payloadJson['aud'] != null) {
          // log('🎯 Audience: ${payloadJson['aud']}');
        }
      } catch (e) {
        log('❌ Failed to decode JWT payload: $e');
      }

      // Check signature (just verify it exists)
      final signature = parts[2];
      if (signature.isEmpty) {
        log('❌ JWT signature is empty');
      } else {
        log('✅ JWT signature exists (${signature.length} characters)');
      }
    } catch (e) {
      log('❌ Token validation failed: $e');
    }
  }

  /// Checks if token is likely expired based on format
  static bool isTokenLikelyExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;

      final payload = parts[1];
      // Add padding if needed for base64 decoding
      String normalizedPayload = base64Url.normalize(payload);
      while (normalizedPayload.length % 4 != 0) {
        normalizedPayload += '=';
      }
      final payloadDecoded = utf8.decode(base64Url.decode(normalizedPayload));
      final payloadJson = jsonDecode(payloadDecoded);

      if (payloadJson['exp'] != null) {
        final exp =
            DateTime.fromMillisecondsSinceEpoch(payloadJson['exp'] * 1000);
        return DateTime.now().isAfter(exp);
      }

      return false;
    } catch (e) {
      log('❌ Failed to check token expiration: $e');
      return true;
    }
  }
}
