import 'sell_config.dart';

/// Resolves a free-typed or manufacturer colour name to one of the colours the
/// server sent in `GET /v2/sell/config` → `colors[]`.
///
/// Nothing here invents a colour. Every hex comes from the config; a name with
/// no match returns null and the field draws a dashed ring instead, which is
/// the honest answer for "Nexa Aurora".
class SellColorMatch {
  SellColorMatch._();

  /// Lower-cases and reduces every run of non-letters to a single space, so
  /// "Pearl Metallic — Arctic White!" and "pearl arctic white" normalise alike.
  static String _norm(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'[^a-z]+'), ' ').trim();

  /// The palette entry named inside [name], or null.
  ///
  /// Matching is whole-word, so "Silverstone" does not resolve to Silver. When
  /// several match, the one nearest the END of the name wins: English colour
  /// names put the base colour last ("Pearl Arctic **White**", "Fire **Red**"),
  /// so "Midnight Blue Black" is a black car, not a blue one. A longer name
  /// breaks a tie.
  static SellColor? match(String? name, List<SellColor> palette) {
    if (name == null) return null;
    final haystack = ' ${_norm(name)} ';
    if (haystack.trim().isEmpty) return null;

    SellColor? best;
    var bestAt = -1;
    var bestLen = 0;
    for (final c in palette) {
      for (final candidate in {c.label, c.value}) {
        final needle = ' ${_norm(candidate)} ';
        if (needle.trim().isEmpty) continue;
        final at = haystack.lastIndexOf(needle);
        if (at < 0) continue;
        final len = needle.length;
        if (at > bestAt || (at == bestAt && len > bestLen)) {
          best = c;
          bestAt = at;
          bestLen = len;
        }
      }
    }
    return best;
  }

  /// True when [name] is one of the palette's own labels rather than a
  /// manufacturer name that merely contains one.
  static bool isCanonical(String? name, List<SellColor> palette) {
    if (name == null) return false;
    final n = _norm(name);
    return palette.any((c) => _norm(c.label) == n || _norm(c.value) == n);
  }
}
