/// Trust signals for an ad seller, shown on the ad-detail seller tile.
/// Backed by GET /v2/ads/sellers/:id/stats.
class SellerStats {
  /// Total ads the seller has posted (excludes soft-deleted).
  final int adCount;

  /// When the seller joined, if known.
  final DateTime? memberSince;

  /// Whether the seller carries the verified badge.
  final bool isVerified;

  /// Average reply time in minutes, or null when there isn't enough signal.
  final int? avgReplyMinutes;

  /// Seller rating 1–5, or null until ad-seller ratings exist server-side.
  final double? rating;

  /// Number of ratings backing [rating].
  final int ratingCount;

  const SellerStats({
    this.adCount = 0,
    this.memberSince,
    this.isVerified = false,
    this.avgReplyMinutes,
    this.rating,
    this.ratingCount = 0,
  });

  factory SellerStats.fromJson(Map<dynamic, dynamic> json) {
    int asInt(dynamic v) => v is int
        ? v
        : (v is num ? v.toInt() : int.tryParse('${v ?? ''}') ?? 0);
    int? asIntOrNull(dynamic v) =>
        v == null ? null : (v is num ? v.toInt() : int.tryParse('$v'));
    double? asDoubleOrNull(dynamic v) =>
        v == null ? null : (v is num ? v.toDouble() : double.tryParse('$v'));
    DateTime? asDate(dynamic v) =>
        (v == null || '$v'.isEmpty) ? null : DateTime.tryParse('$v');

    return SellerStats(
      adCount: asInt(json['adCount']),
      memberSince: asDate(json['memberSince']),
      isVerified: json['isVerified'] == true,
      avgReplyMinutes: asIntOrNull(json['avgReplyMinutes']),
      rating: asDoubleOrNull(json['rating']),
      ratingCount: asInt(json['ratingCount']),
    );
  }

  /// "replies in ~5m" / "~2h" style label, or null when unknown.
  String? get replyLabel {
    final m = avgReplyMinutes;
    if (m == null || m <= 0) return null;
    if (m < 60) return 'replies in ~${m}m';
    final hours = (m / 60).round();
    if (hours < 24) return 'replies in ~${hours}h';
    final days = (hours / 24).round();
    return 'replies in ~${days}d';
  }

  /// "Member since 2023" style label, or null when unknown.
  String? get memberSinceLabel =>
      memberSince == null ? null : 'Member since ${memberSince!.year}';
}
