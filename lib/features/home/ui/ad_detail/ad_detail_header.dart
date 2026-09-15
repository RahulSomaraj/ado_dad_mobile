import 'package:ado_dad_user/common/ad_format.dart';
import 'package:ado_dad_user/common/app_colors.dart';
import 'package:ado_dad_user/common/app_spacing.dart';
import 'package:ado_dad_user/common/app_textstyle.dart';
import 'package:ado_dad_user/features/home/ui/ad_detail/ad_detail_specs.dart';
import 'package:ado_dad_user/models/advertisement_model/add_model.dart';
import 'package:flutter/material.dart';

/// Price → title → location · distance · time, then the key facts grid.
class AdDetailHeader extends StatelessWidget {
  const AdDetailHeader({
    super.key,
    required this.ad,
    required this.specs,
    this.ownerBlock,
  });

  final AddModel ad;
  final AdDetailSpecs specs;

  /// Status pill + stats + tip, shown above the price for the owner.
  final Widget? ownerBlock;

  /// "Price dropped ₹15,000 · 3 days ago" — only for a real drop in the last
  /// 30 days on an unsold ad.
  String? get _priceDrop {
    final prev = ad.previousPrice;
    if (ad.soldOut == true ||
        prev == null ||
        prev <= ad.price ||
        ad.price <= 0) {
      return null;
    }
    final changed = AdFormat.parse(ad.priceChangedAt);
    if (changed == null ||
        DateTime.now().difference(changed) > const Duration(days: 30)) {
      return null;
    }
    final when = AdFormat.relativeTime(ad.priceChangedAt);
    final amount = AdFormat.inr(prev - ad.price);
    return when == null
        ? 'Price dropped $amount'
        : 'Price dropped $amount · $when';
  }

  @override
  Widget build(BuildContext context) {
    final g = AppSpacing.s(context, AppSpacing.gutter);
    final isSold = ad.soldOut == true;
    final title = AdFormat.clean(ad.title) ?? specs.fallbackTitle;
    final isRent = (ad.listingType ?? '').toLowerCase() == 'rent';

    final meta = <String>[
      if (AdFormat.clean(ad.location) != null) ad.location.trim(),
      if (AdFormat.distance(ad.distance) != null)
        AdFormat.distance(ad.distance)!,
      if (AdFormat.relativeTime(ad.postedAt) != null)
        AdFormat.relativeTime(ad.postedAt)!,
    ];

    final price =
        AdFormat.inr(ad.price, monthly: specs.category.isProperty && isRent);
    final facts = specs.keyFacts;

    return Container(
      color: AppColors.whiteColor,
      padding: EdgeInsets.fromLTRB(
          g, AppSpacing.md12, g, AppSpacing.s(context, AppSpacing.xl20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (ownerBlock != null) ...[
            ownerBlock!,
            const SizedBox(height: AppSpacing.lg16),
          ],
          Semantics(
            label: isSold ? 'Sold. Was $price' : 'Price $price',
            excludeSemantics: true,
            child: Text(
              price,
              style: AppTextstyle.priceLarge.copyWith(
                fontSize: AppSpacing.s(context, 26),
                color: isSold ? AppColors.textMuted : null,
                decoration: isSold ? TextDecoration.lineThrough : null,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (_priceDrop != null) ...[
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(Icons.arrow_downward_rounded,
                    size: 14, color: AppColors.positiveText),
                const SizedBox(width: 2),
                Flexible(
                  child: Text(
                    _priceDrop!,
                    style: AppTextstyle.caption.copyWith(
                      fontWeight: FontWeight.w500,
                      color: AppColors.positiveText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.xs4),
          Text(
            title,
            style: AppTextstyle.titleMedium
                .copyWith(fontSize: AppSpacing.s(context, 15)),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (meta.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(Icons.location_on_outlined,
                    size: 14, color: AppColors.textMuted),
                const SizedBox(width: AppSpacing.xs4),
                Expanded(
                  child: Text(
                    meta.join(' · '),
                    style: AppTextstyle.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          if (facts.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg16),
            AdDetailKeyFacts(facts: facts),
          ],
        ],
      ),
    );
  }
}

/// Owner-only: status pill, performance strip and one tip.
class AdDetailOwnerBlock extends StatelessWidget {
  const AdDetailOwnerBlock({super.key, required this.ad});

  final AddModel ad;

  ({String label, Color color}) get _status {
    if (ad.soldOut == true) {
      return (label: 'Sold', color: AppColors.redColor);
    }
    final s = (ad.status ?? '').toLowerCase();
    if (s.contains('pending') || s.contains('review')) {
      return (label: 'Under review', color: const Color(0xFFB7791F));
    }
    if (s.contains('reject')) {
      return (label: 'Rejected', color: AppColors.redColor);
    }
    if (s.contains('expire') || ad.isActive == false) {
      return (label: 'Not live', color: AppColors.greyColor);
    }
    return (label: 'Live', color: AppColors.successColor);
  }

  String? get _tip {
    if (ad.soldOut == true) return null;
    final photos = ad.images.where((i) => i.trim().isNotEmpty).length;
    if (photos < 10) {
      final need = 10 - photos;
      return 'Add $need more photo${need == 1 ? '' : 's'}. Ads with 10 or more '
          'photos get more chats. You have $photos.';
    }
    if (ad.description.trim().length < 80) {
      return 'Add a longer description. Mention service history, '
          'documents and why you are selling.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;
    final posted = AdFormat.niceDate(ad.postedAt, omitCurrentYear: true);
    final tip = _tip;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: status.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                        color: status.color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    status.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: status.color,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            if (posted != null)
              Text('Posted $posted', style: AppTextstyle.caption),
          ],
        ),
        const SizedBox(height: AppSpacing.md12),
        _StatsStrip(ad: ad),
        if (tip != null) ...[
          const SizedBox(height: AppSpacing.md12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.chipFill,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lightbulb_outline,
                    size: 18, color: AppColors.primaryColor),
                const SizedBox(width: AppSpacing.sm8),
                Expanded(
                  child: Text(tip,
                      style: AppTextstyle.caption
                          .copyWith(color: AppColors.blackColor1)),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _StatsStrip extends StatelessWidget {
  const _StatsStrip({required this.ad});

  final AddModel ad;

  @override
  Widget build(BuildContext context) {
    final rule = AppColors.dividerColor;
    final cells = <(String, int?)>[
      ('Views', ad.viewCount),
      ('Saved', ad.favoritesCount),
      ('Chats', ad.chatsCount),
    ];
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: rule),
        borderRadius: BorderRadius.circular(AppRadius.control12),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < cells.length; i++) ...[
              if (i > 0) VerticalDivider(width: 1, thickness: 1, color: rule),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        cells[i].$2 == null
                            ? AdFormat.empty
                            : AdFormat.groupIndian(cells[i].$2!),
                        style: AppTextstyle.specValue.copyWith(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color:
                              cells[i].$2 == null ? AppColors.textMuted : null,
                        ),
                      ),
                      Text(cells[i].$1, style: AppTextstyle.micro),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
