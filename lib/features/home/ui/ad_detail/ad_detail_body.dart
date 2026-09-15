import 'package:ado_dad_user/common/ad_format.dart';
import 'package:ado_dad_user/common/app_colors.dart';
import 'package:ado_dad_user/common/app_spacing.dart';
import 'package:ado_dad_user/common/app_textstyle.dart';
import 'package:ado_dad_user/models/advertisement_model/add_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Description clamped to 3 lines; "Read more" expands in place.
class AdDetailExpandableText extends StatefulWidget {
  const AdDetailExpandableText({super.key, required this.text});

  final String text;

  @override
  State<AdDetailExpandableText> createState() => _AdDetailExpandableTextState();
}

class _AdDetailExpandableTextState extends State<AdDetailExpandableText> {
  bool _expanded = false;
  static const int _lines = 3;

  @override
  Widget build(BuildContext context) {
    final style = AppTextstyle.bodyText;
    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: TextSpan(text: widget.text, style: style),
          maxLines: _lines,
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
        )..layout(maxWidth: constraints.maxWidth);
        final overflows = painter.didExceedMaxLines;
        painter.dispose();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSize(
              duration: const Duration(milliseconds: 180),
              alignment: Alignment.topCenter,
              child: Text(
                widget.text,
                style: style,
                maxLines: _expanded ? null : _lines,
                overflow:
                    _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
              ),
            ),
            if (overflows)
              InkWell(
                onTap: () => setState(() => _expanded = !_expanded),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 36),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    widthFactor: 1,
                    child: Text(
                      _expanded ? 'Show less' : 'Read more',
                      style: AppTextstyle.caption.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Ad ID · posted date · views, with a quiet "Report ad" link.
class AdDetailFooter extends StatelessWidget {
  const AdDetailFooter({
    super.key,
    required this.ad,
    this.onReport,
  });

  final AddModel ad;

  /// Null hides the link (owners can't report their own ad).
  final VoidCallback? onReport;

  String get _shortId {
    final id = ad.id.trim();
    if (id.length <= 6) return id.toUpperCase();
    return id.substring(id.length - 6).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final g = AppSpacing.s(context, AppSpacing.gutter);
    final posted = AdFormat.niceDate(ad.postedAt, omitCurrentYear: true);
    final parts = <String>[
      'Ad ID $_shortId',
      if (posted != null) 'Posted $posted',
      if ((ad.viewCount ?? 0) > 0)
        '${AdFormat.groupIndian(ad.viewCount!)} view${ad.viewCount == 1 ? '' : 's'}',
    ];
    return Container(
      color: AppColors.whiteColor,
      padding: EdgeInsets.fromLTRB(g, AppSpacing.xs4, g, AppSpacing.xs4),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onLongPress: () {
                Clipboard.setData(ClipboardData(text: ad.id));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ad ID copied')),
                );
              },
              child: Text(
                parts.join(' · '),
                style: AppTextstyle.caption.copyWith(fontSize: 12),
                maxLines: 2,
              ),
            ),
          ),
          if (onReport != null)
            TextButton(
              onPressed: onReport,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textMuted,
                minimumSize: const Size(48, 44),
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: Text(
                'Report ad',
                style: AppTextstyle.caption.copyWith(
                  fontSize: 12,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// One-sentence safety tip. Dismissal is remembered for 30 days.
class AdDetailSafetyNote extends StatefulWidget {
  const AdDetailSafetyNote({super.key, required this.isProperty});

  final bool isProperty;

  @override
  State<AdDetailSafetyNote> createState() => _AdDetailSafetyNoteState();
}

class _AdDetailSafetyNoteState extends State<AdDetailSafetyNote> {
  static const String _key = 'ad_detail_safety_dismissed_at';
  static const Duration _snooze = Duration(days: 30);

  // Start hidden-but-sized as "unknown" to avoid a flash for users who
  // dismissed it; resolved in one prefs read.
  bool? _visible;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    var visible = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final ms = prefs.getInt(_key);
      if (ms != null) {
        final at = DateTime.fromMillisecondsSinceEpoch(ms);
        visible = DateTime.now().difference(at) > _snooze;
      }
    } catch (_) {
      visible = true;
    }
    if (mounted) setState(() => _visible = visible);
  }

  Future<void> _dismiss() async {
    setState(() => _visible = false);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_key, DateTime.now().millisecondsSinceEpoch);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_visible != true) return const SizedBox.shrink();
    final g = AppSpacing.s(context, AppSpacing.gutter);
    final text = widget.isProperty
        ? 'Visit the property in person and check the title deed and tax '
            'receipt before paying any advance.'
        : 'Meet in a public place and check the RC and chassis number before '
            'you pay anything.';
    // Carries its own leading band so a dismissed note leaves no double gap.
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.sm8),
        Container(
          color: AppColors.whiteColor,
          padding: EdgeInsets.fromLTRB(g, AppSpacing.lg16, g, AppSpacing.lg16),
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(AppRadius.control12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.shield_outlined,
                    size: 20, color: AppColors.primaryColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Text(
                      text,
                      style: AppTextstyle.caption
                          .copyWith(color: AppColors.blackColor1),
                    ),
                  ),
                ),
                SizedBox(
                  width: 36,
                  height: 36,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    tooltip: 'Dismiss',
                    iconSize: 18,
                    color: AppColors.textMuted,
                    onPressed: _dismiss,
                    icon: const Icon(Icons.close),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
