/// Formatting helpers for ad screens (price, distance, dates, labels).
///
/// Kept as static methods on a class (not top-level functions) so they can
/// never collide with the several legacy top-level `toTitleCase` functions
/// still living in older widget files.
class AdFormat {
  AdFormat._();

  /// Shown wherever a value is unknown. Prefer hiding the row instead.
  static const String empty = '—';

  /// 485000 → "4,85,000" (Indian lakh/crore grouping).
  static String groupIndian(num n) {
    final negative = n < 0;
    final s = n.abs().round().toString();
    if (s.length <= 3) return '${negative ? '-' : ''}$s';
    final last3 = s.substring(s.length - 3);
    var rest = s.substring(0, s.length - 3);
    final parts = <String>[];
    while (rest.length > 2) {
      parts.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) parts.insert(0, rest);
    return '${negative ? '-' : ''}${parts.join(',')},$last3';
  }

  /// 485000 → "₹4,85,000". Returns [empty] for null or 0.
  static String inr(num? n, {bool monthly = false}) {
    if (n == null || n == 0) return empty;
    return '₹${groupIndian(n)}${monthly ? '/mo' : ''}';
  }

  /// 45200 → "45,200 km". Null when unknown so callers can hide the row.
  static String? km(num? n) {
    if (n == null || n <= 0) return null;
    return '${groupIndian(n)} km';
  }

  /// 4.23 → "4.2 km", 18.6 → "19 km". Null when unknown.
  static String? distance(double? d) {
    if (d == null || d <= 0) return null;
    return '${d.toStringAsFixed(d < 10 ? 1 : 0)} km';
  }

  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static DateTime? parse(String? iso) {
    if (iso == null || iso.trim().isEmpty) return null;
    return DateTime.tryParse(iso.trim())?.toLocal();
  }

  /// "13 Sep 2026". Drops the year when it's the current year and
  /// [omitCurrentYear] is set.
  static String? niceDate(String? iso, {bool omitCurrentYear = false}) {
    final dt = parse(iso);
    if (dt == null) return null;
    final base = '${dt.day} ${_months[dt.month - 1]}';
    if (omitCurrentYear && dt.year == DateTime.now().year) return base;
    return '$base ${dt.year}';
  }

  /// "Mar 2024".
  static String monthYear(DateTime dt) => '${_months[dt.month - 1]} ${dt.year}';

  /// "just now", "5 min ago", "3 hours ago", "yesterday", "4 days ago",
  /// then falls back to [niceDate].
  static String? relativeTime(String? iso) {
    final dt = parse(iso);
    if (dt == null) return null;
    final diff = DateTime.now().difference(dt);
    if (diff.isNegative || diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) {
      return diff.inHours == 1 ? '1 hour ago' : '${diff.inHours} hours ago';
    }
    if (diff.inDays == 1) return 'yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    if (diff.inDays < 30) {
      final w = (diff.inDays / 7).floor();
      return w == 1 ? '1 week ago' : '$w weeks ago';
    }
    return niceDate(iso);
  }

  /// "commercial_vehicle" / "PETROL" / "power-windows" → "Commercial Vehicle",
  /// "Petrol", "Power Windows". Null/blank → null.
  static String? titleCase(String? input) {
    if (input == null) return null;
    final s = input
        .replaceAll(RegExp(r'[_\-]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (s.isEmpty) return null;
    return s
        .split(' ')
        .map((w) => w.isEmpty
            ? w
            : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');
  }

  /// Returns [value] trimmed, or null when blank / "null" / "-".
  static String? clean(String? value) {
    if (value == null) return null;
    final v = value.trim();
    if (v.isEmpty || v == '-' || v.toLowerCase() == 'null') return null;
    return v;
  }

  /// 1 → "1st", 2 → "2nd", 3 → "3rd", 4 → "4th", 11 → "11th".
  static String ordinal(int n) {
    final mod100 = n % 100;
    if (mod100 >= 11 && mod100 <= 13) return '${n}th';
    switch (n % 10) {
      case 1:
        return '${n}st';
      case 2:
        return '${n}nd';
      case 3:
        return '${n}rd';
      default:
        return '${n}th';
    }
  }
}
