import 'package:ado_dad_user/common/ad_format.dart';
import 'package:ado_dad_user/common/app_colors.dart';
import 'package:ado_dad_user/common/app_spacing.dart';
import 'package:ado_dad_user/common/app_textstyle.dart';
import 'package:ado_dad_user/common/widgets/rich_ad_card.dart';
import 'package:ado_dad_user/features/home/ui/ad_detail/ad_detail_section.dart';
import 'package:ado_dad_user/models/advertisement_model/add_model.dart';
import 'package:ado_dad_user/models/seller_stats.dart';
import 'package:ado_dad_user/repositories/add_repo.dart';
import 'package:ado_dad_user/services/location_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Seller row on the gutter + trust tiles from GET /v2/ads/sellers/:id/stats.
class AdDetailSellerCard extends StatefulWidget {
  const AdDetailSellerCard({super.key, required this.ad});

  final AddModel ad;

  @override
  State<AdDetailSellerCard> createState() => _AdDetailSellerCardState();
}

class _AdDetailSellerCardState extends State<AdDetailSellerCard> {
  final AddRepository _repo = AddRepository();
  SellerStats? _stats;
  bool _loading = true;
  String? _loadedFor;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant AdDetailSellerCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The seeded list row may lack the user; the detail response fills it in.
    if (widget.ad.user?.id != _loadedFor) _load();
  }

  Future<void> _load() async {
    final id = widget.ad.user?.id;
    _loadedFor = id;
    if (id == null || id.isEmpty) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    final stats = await _repo.fetchSellerStats(id);
    if (!mounted || _loadedFor != id) return;
    setState(() {
      _stats = stats;
      _loading = false;
    });
  }

  void _openProfile() {
    final user = widget.ad.user;
    if (user == null || user.id.isEmpty) return;
    context.push('/seller-profile/${user.id}', extra: user);
  }

  static String? _replyValue(int? minutes) {
    if (minutes == null || minutes <= 0) return null;
    if (minutes < 60) return '~$minutes min';
    final h = (minutes / 60).round();
    if (h < 24) return '~$h hr';
    final d = (h / 24).round();
    return '~$d day${d == 1 ? '' : 's'}';
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.ad.user;
    final name = AdFormat.clean(user?.name) ?? 'Seller';
    final pic = (user?.profilePic ?? '').trim();
    final hasPic = pic.startsWith('http');
    final verified = user?.isVerified == true || _stats?.isVerified == true;

    final sub = <String>[
      if (_stats?.memberSince != null)
        'Member since ${AdFormat.monthYear(_stats!.memberSince!)}',
      if (AdFormat.clean(widget.ad.location) != null)
        widget.ad.location.split(',').first.trim(),
    ];

    final tiles = <(String, String)>[
      if (_replyValue(_stats?.avgReplyMinutes) != null)
        (_replyValue(_stats?.avgReplyMinutes)!, 'Replies in'),
      if ((_stats?.adCount ?? 0) > 0)
        ('${_stats!.adCount}', _stats!.adCount == 1 ? 'Ad posted' : 'Ads posted'),
    ];

    return AdDetailSection(
      title: 'Seller',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            button: true,
            label: 'Seller $name${verified ? ', verified' : ''}. Open profile',
            excludeSemantics: true,
            child: InkWell(
              onTap: _openProfile,
              borderRadius: BorderRadius.circular(AppRadius.control12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.primarySoft,
                      backgroundImage:
                          hasPic ? CachedNetworkImageProvider(pic) : null,
                      child: hasPic
                          ? null
                          : Text(
                              name.characters.first.toUpperCase(),
                              style: const TextStyle(
                                color: AppColors.primaryColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 18,
                              ),
                            ),
                    ),
                    const SizedBox(width: AppSpacing.md12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  name,
                                  style: AppTextstyle.titleMedium
                                      .copyWith(fontWeight: FontWeight.w600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (verified) ...[
                                const SizedBox(width: AppSpacing.xs4),
                                const Icon(Icons.verified,
                                    size: 16, color: AppColors.primaryColor),
                              ],
                            ],
                          ),
                          if (sub.isNotEmpty)
                            Text(
                              sub.join(' · '),
                              style: AppTextstyle.caption,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right,
                        size: 20, color: AppColors.textMuted),
                  ],
                ),
              ),
            ),
          ),
          if (_loading) ...[
            const SizedBox(height: AppSpacing.md12),
            const _TileRow(tiles: null),
          ] else if (tiles.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md12),
            _TileRow(tiles: tiles),
          ],
        ],
      ),
    );
  }
}

class _TileRow extends StatelessWidget {
  const _TileRow({required this.tiles});

  /// Null → loading skeleton.
  final List<(String, String)>? tiles;

  @override
  Widget build(BuildContext context) {
    final items = tiles;
    final count = items?.length ?? 2;
    return Row(
      children: [
        for (var i = 0; i < count; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.sm8),
          Expanded(
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: AppColors.chipFill,
                borderRadius: BorderRadius.circular(10),
              ),
              child: items == null
                  ? const SizedBox.shrink()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          items[i].$1,
                          style: AppTextstyle.specValue.copyWith(
                              fontSize: 13.5, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(items[i].$2,
                            style: AppTextstyle.micro,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Same model, ±20% price, near the buyer; falls back to same category.
class AdDetailSimilarAds extends StatefulWidget {
  const AdDetailSimilarAds({super.key, required this.ad});

  final AddModel ad;

  @override
  State<AdDetailSimilarAds> createState() => _AdDetailSimilarAdsState();
}

class _AdDetailSimilarAdsState extends State<AdDetailSimilarAds> {
  final AddRepository _repo = AddRepository();
  List<AddModel> _items = const [];
  bool _sameModel = false;
  bool _loading = true;

  static const double _cardWidth = 190;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final ad = widget.ad;
    final seed = await LocationService().seedPosition();
    final lat = seed?.latitude;
    final lng = seed?.longitude;
    final modelId = ad.model?.id.trim() ?? '';

    List<AddModel> pick(List<AddModel> rows) =>
        rows.where((a) => a.id != ad.id && a.soldOut != true).take(10).toList();

    var items = <AddModel>[];
    var sameModel = false;
    try {
      if (modelId.isNotEmpty && ad.price > 0) {
        final res = await _repo.fetchAllAds(
          category: ad.category,
          modelIds: [modelId],
          minPrice: (ad.price * 0.8).round(),
          maxPrice: (ad.price * 1.2).round(),
          limit: 12,
          latitude: lat,
          longitude: lng,
        );
        items = pick(res.data);
        sameModel = items.length >= 2;
      }
      if (items.length < 2) {
        final res = await _repo.fetchAllAds(
          category: ad.category,
          limit: 12,
          latitude: lat,
          longitude: lng,
        );
        items = pick(res.data);
        sameModel = false;
      }
    } catch (_) {
      items = const [];
    }
    if (!mounted) return;
    setState(() {
      _items = items;
      _sameModel = sameModel;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _items.isEmpty) return const SizedBox.shrink();
    final modelName = AdFormat.titleCase(AdFormat.clean(widget.ad.model?.displayName) ??
        AdFormat.clean(widget.ad.model?.name));
    final title = _sameModel && modelName != null
        ? 'Similar $modelName near you'
        : 'Similar near you';
    final cardH = richAdCardMainAxisExtent(
      context,
      columns: 1,
      horizontalPadding: (MediaQuery.of(context).size.width - _cardWidth) / 2,
      spacing: 0,
    );
    final g = AppSpacing.s(context, AppSpacing.gutter);
    // Leading band lives here so an empty result leaves no stray gap.
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AdDetailBand(),
        AdDetailSection(
      title: title,
      bleedRight: true,
      trailing: AdDetailTextAction(
        label: 'See all',
        onTap: () => context.push('/search?from=ad-detail'),
      ),
      child: SizedBox(
        height: cardH,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.only(right: g),
          itemCount: _items.length,
          separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md12),
          itemBuilder: (_, i) => SizedBox(
            width: _cardWidth,
            height: cardH,
            child: RichAdCard(ad: _items[i]),
          ),
        ),
      ),
        ),
      ],
    );
  }
}
