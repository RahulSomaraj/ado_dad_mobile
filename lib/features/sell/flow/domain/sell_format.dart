import 'dart:math';

/// Indian number formatting and small helpers used across the sell flow.
class SellFormat {
  SellFormat._();

  /// 450000 → "4,50,000" (lakh/crore grouping).
  static String indianGroup(num value) {
    final negative = value < 0;
    final digits = value.abs().round().toString();
    if (digits.length <= 3) return '${negative ? '-' : ''}$digits';
    final last3 = digits.substring(digits.length - 3);
    var rest = digits.substring(0, digits.length - 3);
    final parts = <String>[];
    while (rest.length > 2) {
      parts.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) parts.insert(0, rest);
    return '${negative ? '-' : ''}${parts.join(',')},$last3';
  }

  /// "₹ 4,50,000"
  static String rupees(num value) => '₹ ${indianGroup(value)}';

  /// Digits only → int (null when empty).
  static int? parseDigits(String? text) {
    if (text == null) return null;
    final d = text.replaceAll(RegExp(r'[^0-9]'), '');
    if (d.isEmpty) return null;
    return int.tryParse(d);
  }

  static double? parseDecimal(String? text) {
    if (text == null) return null;
    final d = text.replaceAll(RegExp(r'[^0-9.]'), '');
    if (d.isEmpty || d == '.') return null;
    return double.tryParse(d);
  }

  static const _ones = [
    '', 'one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight', 'nine',
    'ten', 'eleven', 'twelve', 'thirteen', 'fourteen', 'fifteen', 'sixteen',
    'seventeen', 'eighteen', 'nineteen'
  ];
  static const _tens = [
    '', '', 'twenty', 'thirty', 'forty', 'fifty', 'sixty', 'seventy', 'eighty', 'ninety'
  ];

  static String _below100(int n) {
    if (n < 20) return _ones[n];
    final t = _tens[n ~/ 10];
    final o = _ones[n % 10];
    return o.isEmpty ? t : '$t $o';
  }

  static String _below1000(int n) {
    final h = n ~/ 100;
    final r = n % 100;
    final parts = <String>[];
    if (h > 0) parts.add('${_ones[h]} hundred');
    if (r > 0) parts.add(_below100(r));
    return parts.join(' ');
  }

  /// 450000 → "Four lakh fifty thousand rupees" (Indian system).
  static String rupeesInWords(int value) {
    if (value <= 0) return '';
    var n = value;
    final crore = n ~/ 10000000;
    n %= 10000000;
    final lakh = n ~/ 100000;
    n %= 100000;
    final thousand = n ~/ 1000;
    n %= 1000;
    final parts = <String>[];
    if (crore > 0) parts.add('${crore >= 1000 ? indianGroup(crore) : _below1000(crore)} crore');
    if (lakh > 0) parts.add('${_below100(lakh)} lakh');
    if (thousand > 0) parts.add('${_below100(thousand)} thousand');
    if (n > 0) parts.add(_below1000(n));
    final text = '${parts.join(' ')} rupees';
    return text[0].toUpperCase() + text.substring(1);
  }

  /// Square feet in one cent (Kerala land measure).
  static const double sqftPerCent = 435.6;

  static double toSqft(double value, String unit) =>
      unit == 'cent' ? value * sqftPerCent : value;

  static String trimNum(double v) =>
      v == v.roundToDouble() ? v.round().toString() : v.toStringAsFixed(2).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');

  /// RFC 4122 v4 UUID without adding a package.
  static String uuidV4() {
    final r = Random.secure();
    final b = List<int>.generate(16, (_) => r.nextInt(256));
    b[6] = (b[6] & 0x0f) | 0x40;
    b[8] = (b[8] & 0x3f) | 0x80;
    String hex(int i) => b[i].toRadixString(16).padLeft(2, '0');
    final s = List.generate(16, hex).join();
    return '${s.substring(0, 8)}-${s.substring(8, 12)}-${s.substring(12, 16)}-${s.substring(16, 20)}-${s.substring(20)}';
  }

  /// "2 h ago", "just now", "3 days ago".
  static String ago(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'just now';
    if (d.inMinutes < 60) return '${d.inMinutes} min ago';
    if (d.inHours < 24) return '${d.inHours} h ago';
    final days = d.inDays;
    return days == 1 ? 'yesterday' : '$days days ago';
  }
}
