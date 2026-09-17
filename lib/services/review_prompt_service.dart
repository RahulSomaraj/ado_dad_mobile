import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Moments that earn a review prompt (audit 3.3).
enum ReviewTrigger {
  /// The seller sees their ad live (instant approval or opening it approved).
  adLive,

  /// A real conversation: 3 replies from the other side on one thread.
  chatReplies,

  /// The seller marked an ad as sold.
  adSold,
}

/// Decides whether a trigger may open the Play / App Store review sheet.
///
/// Never on the first day after install, never on a day something went wrong
/// (a failed post), at most once per 90 days and 3 times per calendar year.
/// It calls `requestReview()` directly: Play policy forbids asking "Do you
/// like the app?" first. The stores throttle on their own too, so a call is
/// not a promise that a sheet appears. Every storage or plugin error is
/// swallowed — a review prompt must never break the flow that triggered it.
class ReviewPromptService {
  ReviewPromptService._();
  static final ReviewPromptService instance = ReviewPromptService._();

  static const _kFirstSeen = 'review_first_seen_ms';
  static const _kLastAsked = 'review_last_asked_ms';
  static const _kAskYear = 'review_ask_year';
  static const _kAskCount = 'review_ask_count';
  static const _kProblemDay = 'review_problem_day';

  static const Duration minAge = Duration(days: 1);
  static const Duration minGap = Duration(days: 90);
  static const int maxPerYear = 3;

  bool _asking = false;

  /// Pure gate, exposed for tests.
  @visibleForTesting
  static bool shouldAsk({
    required DateTime now,
    required DateTime? firstSeen,
    required DateTime? lastAsked,
    required int askedThisYear,
    required String? problemDay,
  }) {
    if (firstSeen == null || now.difference(firstSeen) < minAge) return false;
    if (problemDay == dayKey(now)) return false;
    if (lastAsked != null && now.difference(lastAsked) < minGap) return false;
    if (askedThisYear >= maxPerYear) return false;
    return true;
  }

  static String dayKey(DateTime t) => '${t.year}-${t.month}-${t.day}';

  /// Call once at startup so "first day" is measured from install.
  Future<void> markSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!prefs.containsKey(_kFirstSeen)) {
        await prefs.setInt(_kFirstSeen, DateTime.now().millisecondsSinceEpoch);
      }
    } catch (_) {}
  }

  /// Something failed for the user today (e.g. posting an ad): no prompt today.
  Future<void> noteProblem() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kProblemDay, dayKey(DateTime.now()));
    } catch (_) {}
  }

  Future<void> maybeAsk(ReviewTrigger trigger) async {
    if (_asking || kIsWeb) return;
    _asking = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      DateTime? at(String k) {
        final v = prefs.getInt(k);
        return v == null ? null : DateTime.fromMillisecondsSinceEpoch(v);
      }

      final year = prefs.getInt(_kAskYear);
      final count = year == now.year ? (prefs.getInt(_kAskCount) ?? 0) : 0;
      final ok = shouldAsk(
        now: now,
        firstSeen: at(_kFirstSeen),
        lastAsked: at(_kLastAsked),
        askedThisYear: count,
        problemDay: prefs.getString(_kProblemDay),
      );
      if (!ok) return;

      final review = InAppReview.instance;
      if (!await review.isAvailable()) return;
      // Recorded before the call: the store may show nothing, and retrying on
      // every trigger would burn the quota anyway.
      await prefs.setInt(_kLastAsked, now.millisecondsSinceEpoch);
      await prefs.setInt(_kAskYear, now.year);
      await prefs.setInt(_kAskCount, count + 1);
      await review.requestReview();
    } catch (_) {
    } finally {
      _asking = false;
    }
  }
}
