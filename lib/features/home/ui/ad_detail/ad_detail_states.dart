import 'package:ado_dad_user/common/app_colors.dart';
import 'package:ado_dad_user/common/app_spacing.dart';
import 'package:ado_dad_user/common/app_textstyle.dart';
import 'package:ado_dad_user/common/get_responsive_size.dart';
import 'package:ado_dad_user/features/home/ui/ad_detail/ad_detail_bars.dart';
import 'package:flutter/material.dart';

/// Loading skeleton with the same geometry as the loaded page (16:10 gallery,
/// thumbs, price block, facts grid), so nothing jumps when data lands.
class AdDetailSkeleton extends StatelessWidget {
  const AdDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final g = AppSpacing.s(context, AppSpacing.gutter);
    final aspect = GetResponsiveSize.isTablet(context) ? 20 / 10 : 16 / 10;
    Widget box(double h, {double? w, double r = 6}) => Container(
          height: h,
          width: w,
          decoration: BoxDecoration(
            color: AppColors.chipFill,
            borderRadius: BorderRadius.circular(r),
          ),
        );
    return Semantics(
      label: 'Loading ad',
      child: ListView(
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          AspectRatio(aspectRatio: aspect, child: box(double.infinity, r: 0)),
          Container(
            color: AppColors.whiteColor,
            padding: EdgeInsets.fromLTRB(g, AppSpacing.md12, g, 0),
            child: Row(
              children: [
                for (var i = 0; i < 5; i++) ...[
                  if (i > 0) const SizedBox(width: AppSpacing.sm8),
                  box(44, w: 44, r: 10),
                ],
              ],
            ),
          ),
          Container(
            color: AppColors.whiteColor,
            padding: EdgeInsets.fromLTRB(g, AppSpacing.md12, g, AppSpacing.xl20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                box(28, w: 160),
                const SizedBox(height: AppSpacing.sm8),
                box(16, w: 240),
                const SizedBox(height: AppSpacing.sm8),
                box(12, w: 190),
                const SizedBox(height: AppSpacing.lg16),
                box(62, r: AppRadius.control12),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm8),
          Container(
            color: AppColors.whiteColor,
            padding: EdgeInsets.fromLTRB(g, AppSpacing.lg16, g, AppSpacing.xl20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                box(18, w: 110),
                const SizedBox(height: AppSpacing.md12),
                for (var i = 0; i < 4; i++) ...[
                  box(14),
                  const SizedBox(height: 18),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Cold-load failure: app bar, explanation, Try again.
class AdDetailErrorView extends StatelessWidget {
  const AdDetailErrorView({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          SizedBox(
            height: 56,
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Back',
                  icon: Icon(Icons.arrow_back, color: AppColors.blackColor),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
                Text('Ad details', style: AppTextstyle.appbarText),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.wifi_off_rounded,
                        size: 40, color: AppColors.textMuted),
                    const SizedBox(height: AppSpacing.md12),
                    Text("Couldn't load this ad",
                        style: AppTextstyle.sectionTitle,
                        textAlign: TextAlign.center),
                    const SizedBox(height: AppSpacing.xs4),
                    Text(
                      'Check your connection and try again.',
                      style: AppTextstyle.caption.copyWith(fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.lg16),
                    SizedBox(
                      width: 160,
                      child: AdDetailBarButton.filled(
                        label: 'Try again',
                        onPressed: onRetry,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Red strip under the gallery on sold ads.
class AdDetailSoldBanner extends StatelessWidget {
  const AdDetailSoldBanner({super.key, required this.isProperty});

  final bool isProperty;

  @override
  Widget build(BuildContext context) {
    final g = AppSpacing.s(context, AppSpacing.gutter);
    return Container(
      color: AppColors.redColor,
      padding: EdgeInsets.symmetric(horizontal: g, vertical: AppSpacing.sm8),
      child: Text(
        isProperty ? 'This property is no longer available' : 'This ad is marked as sold',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
