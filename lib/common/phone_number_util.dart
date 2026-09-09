/// Normalises what a user typed / pasted / autofilled into a phone field.
///
/// Fixes the "+91919474414563" bug: keyboards autofill "+91 94744 14563",
/// `digitsOnly` strips it to "919474414563", and the page prepended the
/// selected country code again. Everything that builds a phone identifier
/// (OTP login, password login, signup) must go through [normalise].
class PhoneNumberUtil {
  PhoneNumberUtil._();

  /// Country dial codes → expected national number length.
  /// Anything not listed accepts 7–15 digits (ITU E.164 upper bound).
  static const Map<String, int> _nationalLength = {
    '91': 10, // India
    '971': 9, // UAE
    '966': 9, // Saudi Arabia
    '974': 8, // Qatar
    '965': 8, // Kuwait
    '968': 8, // Oman
    '973': 8, // Bahrain
    '44': 10, // UK
    '1': 10, // US / Canada
  };

  /// [raw] is whatever is in the text field; [dialCode] is like "+91".
  static NormalisedPhone normalise(String raw, String dialCode) {
    final cc = dialCode.replaceAll(RegExp(r'\D'), '');
    var digits = raw.replaceAll(RegExp(r'\D'), '');
    final expected = _nationalLength[cc];

    // "00" international prefix (e.g. 0091…)
    if (digits.startsWith('00$cc') &&
        digits.length > cc.length + 2) {
      digits = digits.substring(cc.length + 2);
    }

    // Leading country code pasted along with the number: 91 + 10 digits.
    if (cc.isNotEmpty &&
        digits.startsWith(cc) &&
        expected != null &&
        digits.length == cc.length + expected) {
      digits = digits.substring(cc.length);
    }

    // Trunk prefix "0" typed before the number (09474414563).
    if (expected != null &&
        digits.length == expected + 1 &&
        digits.startsWith('0')) {
      digits = digits.substring(1);
    }

    final bool isValid = expected != null
        ? digits.length == expected
        : digits.length >= 7 && digits.length <= 15;

    return NormalisedPhone(
      national: digits,
      dialCode: '+$cc',
      isValid: isValid,
      expectedLength: expected,
    );
  }

  /// "+91 94744 14563" style display for a national number.
  static String format(String national, String dialCode) {
    if (national.length == 10) {
      return '$dialCode ${national.substring(0, 5)} ${national.substring(5)}';
    }
    return '$dialCode $national';
  }

  /// Masks an E.164 identifier for the verify screen: "+91 94•••• ••63".
  /// Falls back to the raw value for anything that doesn't look like a phone.
  static String mask(String e164) {
    final m = RegExp(r'^\+?(\d{1,3})(\d{7,15})$').firstMatch(e164.trim());
    if (m == null) return e164;
    final cc = m.group(1)!;
    final n = m.group(2)!;
    if (n.length < 4) return e164;
    return '+$cc ${n.substring(0, 2)}•••• ••${n.substring(n.length - 2)}';
  }
}

class NormalisedPhone {
  /// Digits only, without country code.
  final String national;

  /// "+91"
  final String dialCode;
  final bool isValid;
  final int? expectedLength;

  const NormalisedPhone({
    required this.national,
    required this.dialCode,
    required this.isValid,
    this.expectedLength,
  });

  /// "+919474414563" — what the backend expects as `identifier`.
  String get e164 => '$dialCode$national';

  String get validationMessage {
    if (national.isEmpty) return 'Phone is required';
    if (expectedLength != null) {
      return 'Enter a $expectedLength-digit mobile number';
    }
    return 'Enter a valid phone number';
  }
}
