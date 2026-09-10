/// Shared, framework-free formatting helpers.
///
/// These consolidate the several near-identical private copies that were
/// scattered across the app (`RichAdCard.inr`, `_formatInr` / `_niceDate` in
/// `ad_detail_title_price.dart`, `_relTime` in `rich_ad_card.dart`, and the
/// three `toTitleCase` variants). Behaviour is deliberately kept compatible
/// with those originals so call sites can be migrated one at a time.
///
/// Pure Dart — no Flutter imports — so it is safe to use from models,
/// repositories and blocs as well as from widgets.
library;

/// The placeholder shown wherever a value is missing or not meaningful.
const String kEmptyValue = '—';

const List<String> _kMonths = <String>[
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// Groups the digits of [value] the Indian way: the last three digits stay
/// together, everything before that is grouped in pairs
/// (`485000` -> `4,85,000`).
///
/// [value] is rounded to the nearest whole number first; the sign is dropped
/// (callers add it back). This is the exact algorithm used by the old
/// `RichAdCard.inr` and `_formatInr` helpers.
String groupIndianDigits(num value) {
  final String s = value.abs().round().toString();
  if (s.length <= 3) return s;
  final String last3 = s.substring(s.length - 3);
  String rest = s.substring(0, s.length - 3);
  final List<String> parts = <String>[];
  while (rest.length > 2) {
    parts.insert(0, rest.substring(rest.length - 2));
    rest = rest.substring(0, rest.length - 2);
  }
  if (rest.isNotEmpty) parts.insert(0, rest);
  return '${parts.join(',')},$last3';
}

/// Formats [value] as an Indian-grouped rupee amount, e.g. `₹4,85,000`.
///
/// Returns [kEmptyValue] when [value] is `null` or zero, because a listing
/// with no price should read as "—", not "₹0".
///
/// When [monthly] is true a `/mo` suffix is appended (`₹18,000/mo`) — this is
/// what the old cards did for `listingType == 'rent'` and for EMI estimates.
///
/// Note: the previous `RichAdCard` price text used `'₹ '` (with a space) while
/// the ad-detail page used `'₹'` (no space). This helper standardises on the
/// no-space form.
String formatInr(num? value, {bool monthly = false}) {
  if (value == null || value == 0) return kEmptyValue;
  final String sign = value < 0 ? '-' : '';
  final String amount = '$sign₹${groupIndianDigits(value)}';
  return monthly ? '$amount/mo' : amount;
}

/// Formats an odometer / mileage reading, e.g. `42,300 km`.
///
/// Uses the same Indian digit grouping as [formatInr]. Returns [kEmptyValue]
/// when [km] is `null` or negative; `0` is formatted normally as `0 km`.
String formatKm(num? km) {
  if (km == null || km < 0) return kEmptyValue;
  return '${groupIndianDigits(km)} km';
}

/// A short, human relative age for [d], e.g. `today`, `yesterday`,
/// `3 days ago`, `3 weeks ago`.
///
/// Anything older than roughly two months falls back to [niceDate] so the
/// reader gets an actual date instead of an unhelpful "9 weeks ago". Future
/// timestamps (clock skew) are reported as `today`. Returns an empty string
/// when [d] is `null`.
String relativeTime(DateTime? d) {
  if (d == null) return '';
  final Duration diff = DateTime.now().difference(d);
  final int days = diff.inDays;
  if (days <= 0) return 'today';
  if (days == 1) return 'yesterday';
  if (days < 7) return '$days days ago';
  if (days > 60) return niceDate(d);
  final int weeks = days ~/ 7;
  return weeks == 1 ? '1 week ago' : '$weeks weeks ago';
}

/// Formats [d] as a compact, unambiguous date: `5 Jan 2025`.
///
/// Returns an empty string when [d] is `null`.
String niceDate(DateTime? d) {
  if (d == null) return '';
  return '${d.day} ${_kMonths[d.month - 1]} ${d.year}';
}

/// Title-cases a raw backend string for display.
///
/// Underscores and hyphens become spaces, runs of whitespace collapse, and
/// each word gets an initial capital: `'commercial_vehicle'` -> `'Commercial
/// Vehicle'`, `'FOR-RENT'` -> `'For Rent'`.
///
/// This matches the `add_detail_page.dart` variant (the only one of the three
/// copies in the app that normalised `_`/`-` and lower-cased the tail), so
/// migrating the other copies to it is a small behaviour *fix*, not a
/// regression. Returns an empty string for `null` or blank input.
String toTitleCase(String? s) {
  if (s == null) return '';
  final String normalized = s
      .toLowerCase()
      .replaceAll(RegExp(r'[_\-]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (normalized.isEmpty) return '';
  return normalized
      .split(' ')
      .map((String w) =>
          w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}
