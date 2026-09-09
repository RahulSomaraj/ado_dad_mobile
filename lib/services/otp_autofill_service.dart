import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:smart_auth/smart_auth.dart';

/// Reads the login OTP out of the incoming SMS on Android.
///
/// The SMS currently sent by the backend is:
///
///   Dear User,
///   Your Login otp is 833448. Do not share with any one.
///   Team Adodad
///
/// It carries no app-hash (`<#> … xxxxxxxxxxx`), so Google's silent
/// SMS Retriever API cannot match it. We use the SMS **User Consent** API
/// instead: Android shows a one-tap system sheet ("Allow Adodad to read this
/// message?") and hands us the text, from which we pull the 6-digit code.
/// No SMS permission is required.
///
/// If the backend later appends the app hash to the message, switch
/// [listen] to `getSmsWithRetrieverApi()` and the prompt disappears.
///
/// iOS needs nothing here — the first OTP box uses
/// `autofillHints: [AutofillHints.oneTimeCode]` and the keyboard offers the
/// code automatically.
class OtpAutofillService {
  OtpAutofillService._();
  static final OtpAutofillService instance = OtpAutofillService._();

  final SmartAuth _smartAuth = SmartAuth.instance;
  bool _listening = false;

  static final RegExp _codePattern =
      RegExp(r'(?:otp|code)\D{0,20}?(\d{6})', caseSensitive: false);
  static final RegExp _anySixDigits = RegExp(r'\b(\d{6})\b');

  bool get isSupported => !kIsWeb && Platform.isAndroid;

  /// Resolves with the 6-digit code, or null if the user dismissed the sheet,
  /// the SMS timed out (~5 min), or no code could be parsed.
  Future<String?> listen() async {
    if (!isSupported || _listening) return null;
    _listening = true;
    try {
      final res = await _smartAuth.getSmsWithUserConsentApi();
      final sms = res.data?.sms ?? '';
      return extractCode(sms) ?? res.data?.code;
    } catch (e) {
      debugPrint('OTP autofill failed: $e');
      return null;
    } finally {
      _listening = false;
    }
  }

  Future<void> stop() async {
    if (!isSupported) return;
    try {
      await _smartAuth.removeUserConsentApiListener();
    } catch (_) {}
    _listening = false;
  }

  /// Prefers the number right after "otp"/"code"; falls back to any 6 digits.
  @visibleForTesting
  static String? extractCode(String sms) {
    if (sms.isEmpty) return null;
    return _codePattern.firstMatch(sms)?.group(1) ??
        _anySixDigits.firstMatch(sms)?.group(1);
  }
}
