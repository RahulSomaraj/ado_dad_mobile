import 'package:ado_dad_user/common/app_colors.dart';
import 'package:ado_dad_user/common/app_spacing.dart';
import 'package:ado_dad_user/common/auth_guard.dart';
import 'package:ado_dad_user/common/get_responsive_size.dart';
import 'package:ado_dad_user/common/widgets/app_network_image.dart';
import 'package:ado_dad_user/common/widgets/dialog_util.dart';
import 'package:ado_dad_user/features/home/favorite/bloc/favorite_bloc.dart';
import 'package:ado_dad_user/features/home/ui/ad_detail/ad_detail_media.dart';
import 'package:ado_dad_user/models/advertisement_model/add_model.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// One entry in the gallery's single index space (video first, then photos).
class _MediaItem {
  const _MediaItem.video(this.url) : isVideo = true;
  const _MediaItem.image(this.url) : isVideo = false;

  final String url;
  final bool isVideo;
}

/// Hero gallery: photos + optional video in one index, a 100 dp top scrim
/// behind the controls only, counter pill, and a 44 dp thumbnail strip.
class AdDetailGallery extends StatefulWidget {
  const AdDetailGallery({
    super.key,
    required this.ad,
    required this.actions,
    this.onBack,
    this.isOwner = false,
    this.onAddPhotos,
  });

  final AddModel ad;

  /// Right-hand overlay controls (share, favourite or owner menu).
  final List<Widget> actions;
  final VoidCallback? onBack;
  final bool isOwner;

  /// Shown on the empty state for owners.
  final VoidCallback? onAddPhotos;

  @override
  State<AdDetailGallery> createState() => _AdDetailGalleryState();
}

class _AdDetailGalleryState extends State<AdDetailGallery> {
  final CarouselSliderController _controller = CarouselSliderController();
  int _index = 0;

  static const int _maxThumbs = 6;

  List<_MediaItem> get _items {
    final out = <_MediaItem>[];
    final video = widget.ad.link?.trim() ?? '';
    if (video.isNotEmpty) out.add(_MediaItem.video(video));
    for (final img in widget.ad.images) {
      if (img.trim().isNotEmpty) out.add(_MediaItem.image(img.trim()));
    }
    return out;
  }

  @override
  void didUpdateWidget(covariant AdDetailGallery oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A background refresh can change the photo count; keep the index valid.
    final count = _items.length;
    if (_index >= count && count > 0) {
      _index = count - 1;
    }
  }

  void _open(List<_MediaItem> items, int index) {
    final item = items[index];
    if (item.isVideo) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => AdDetailVideoFullScreen(videoUrl: item.url),
      ));
      return;
    }
    final images = items.where((m) => !m.isVideo).map((m) => m.url).toList();
    final imageIndex = images.indexOf(item.url);
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => AdDetailImageGallery(
        images: images,
        initialIndex: imageIndex < 0 ? 0 : imageIndex,
      ),
    ));
  }

  void _jumpTo(int i) {
    setState(() => _index = i);
    _controller.animateToPage(i,
        duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    final topInset = MediaQuery.of(context).padding.top;
    final aspect = GetResponsiveSize.isTablet(context) ? 20 / 10 : 16 / 10;
    final isSold = widget.ad.soldOut == true;
    final isPremium = widget.ad.manufacturer?.isPremium == true;

    Widget media;
    if (items.isEmpty) {
      media = _NoPhotos(isOwner: widget.isOwner, onAddPhotos: widget.onAddPhotos);
    } else {
      media = CarouselSlider(
        carouselController: _controller,
        options: CarouselOptions(
          viewportFraction: 1,
          height: double.infinity,
          autoPlay: false,
          enableInfiniteScroll: false,
          onPageChanged: (i, _) => setState(() => _index = i),
        ),
        items: [
          for (var i = 0; i < items.length; i++)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _open(items, i),
              child: items[i].isVideo
                  ? _VideoSlide(url: items[i].url)
                  : AppNetworkImage(url: items[i].url, fit: BoxFit.cover),
            ),
        ],
      );
      if (isSold) {
        media = ColorFiltered(
          colorFilter: const ColorFilter.matrix(<double>[
            0.2126, 0.7152, 0.0722, 0, 0, //
            0.2126, 0.7152, 0.0722, 0, 0, //
            0.2126, 0.7152, 0.0722, 0, 0, //
            0, 0, 0, 1, 0,
          ]),
          child: media,
        );
      }
    }

    final g = AppSpacing.s(context, AppSpacing.gutter);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AspectRatio(
          aspectRatio: aspect,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(color: AppColors.chipFill, child: media),
              // Scrim behind the controls only — photos are never dimmed.
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 100,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x66000000),
                          Color(0x4D000000),
                          Color(0x00000000),
                        ],
                        stops: [0, 0.86, 1],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: topInset + AppSpacing.xs4,
                left: g - 4,
                right: g - 4,
                child: Row(
                  children: [
                    AdDetailOverlayButton(
                      icon: Icons.arrow_back,
                      semanticLabel: 'Back',
                      onTap: widget.onBack ??
                          () {
                            Navigator.of(context).maybePop();
                          },
                    ),
                    const Spacer(),
                    ...widget.actions,
                  ],
                ),
              ),
              if (isPremium)
                Positioned(
                  left: g,
                  bottom: AppSpacing.md12,
                  child: const _Tag(
                      label: 'PREMIUM', color: AppColors.primaryColor),
                ),
              if (items.length > 1)
                Positioned(
                  right: g,
                  bottom: AppSpacing.md12,
                  child: _CounterPill(
                    text: '${_index + 1} / ${items.length}',
                    isVideo: items[_index].isVideo,
                  ),
                ),
            ],
          ),
        ),
        if (items.length > 1)
          _ThumbStrip(
            items: items,
            current: _index,
            maxThumbs: _maxThumbs,
            onTap: _jumpTo,
            onMore: () => _open(items, _index),
          ),
      ],
    );
  }
}

class _VideoSlide extends StatelessWidget {
  const _VideoSlide({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        AbsorbPointer(
          child: AdDetailVideoPlayer(key: ValueKey(url), videoUrl: url),
        ),
        Center(
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.55),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.play_arrow_rounded,
                color: Colors.white, size: 36),
          ),
        ),
      ],
    );
  }
}

/// 40 dp white circle inside a 48 dp tap target.
class AdDetailOverlayButton extends StatelessWidget {
  const AdDetailOverlayButton({
    super.key,
    this.icon,
    this.child,
    required this.semanticLabel,
    this.onTap,
  }) : assert(icon != null || child != null);

  final IconData? icon;
  final Widget? child;
  final String semanticLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: SizedBox(
        width: AppSpacing.minTap,
        height: AppSpacing.minTap,
        child: Center(
          child: Material(
            color: Colors.white.withValues(alpha: 0.94),
            shape: const CircleBorder(),
            elevation: 1,
            shadowColor: Colors.black26,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: SizedBox(
                width: 40,
                height: 40,
                child: Center(
                  child: child ??
                      Icon(icon, size: 20, color: const Color(0xFF0A0A0A)),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Favourite toggle styled as an overlay button.
class AdDetailFavoriteOverlayButton extends StatelessWidget {
  const AdDetailFavoriteOverlayButton({super.key, required this.ad});

  final AddModel ad;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FavoriteBloc, FavoriteState>(
      buildWhen: (_, s) =>
          (s is FavoriteToggleLoading && s.adId == ad.id) ||
          (s is FavoriteToggleSuccess && s.adId == ad.id) ||
          (s is FavoriteToggleError && s.adId == ad.id),
      builder: (context, state) {
        var isFavorited = ad.isFavorited ?? false;
        if (state is FavoriteToggleSuccess && state.adId == ad.id) {
          isFavorited = state.isFavorited;
        }
        final loading = state is FavoriteToggleLoading && state.adId == ad.id;
        return AdDetailOverlayButton(
          semanticLabel: isFavorited ? 'Remove from saved' : 'Save ad',
          onTap: loading
              ? null
              : () async {
                  final ok = await AuthGuard.isAuthenticated();
                  if (!context.mounted) return;
                  if (!ok) {
                    DialogUtil.showLoginPromptDialog(
                      context,
                      message: 'Log in to save this ad.',
                      redirectPath: '/add-detail-page',
                    );
                    return;
                  }
                  context.read<FavoriteBloc>().add(
                        FavoriteEvent.toggleFavorite(
                          adId: ad.id,
                          isCurrentlyFavorited: isFavorited,
                        ),
                      );
                },
          child: loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                  ),
                )
              : Icon(
                  isFavorited ? Icons.favorite : Icons.favorite_border,
                  size: 20,
                  color: isFavorited
                      ? AppColors.redColor
                      : const Color(0xFF0A0A0A),
                ),
        );
      },
    );
  }
}

class _CounterPill extends StatelessWidget {
  const _CounterPill({required this.text, required this.isVideo});

  final String text;
  final bool isVideo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isVideo) ...[
            const Icon(Icons.videocam_outlined, size: 13, color: Colors.white),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _ThumbStrip extends StatelessWidget {
  const _ThumbStrip({
    required this.items,
    required this.current,
    required this.maxThumbs,
    required this.onTap,
    required this.onMore,
  });

  final List<_MediaItem> items;
  final int current;
  final int maxThumbs;
  final ValueChanged<int> onTap;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final g = AppSpacing.s(context, AppSpacing.gutter);
    final overflow = items.length > maxThumbs;
    final shown = overflow ? maxThumbs - 1 : items.length;
    return Container(
      color: AppColors.whiteColor,
      padding: EdgeInsets.fromLTRB(g, AppSpacing.md12, g, 0),
      height: 44 + AppSpacing.md12,
      child: Row(
        children: [
          for (var i = 0; i < shown; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.sm8),
            _Thumb(
              item: items[i],
              selected: i == current,
              onTap: () => onTap(i),
            ),
          ],
          if (overflow) ...[
            const SizedBox(width: AppSpacing.sm8),
            Semantics(
              button: true,
              label: 'See all ${items.length} photos',
              child: InkWell(
                onTap: onMore,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.chipFill,
                    borderRadius: BorderRadius.circular(10),
                    border: current >= shown
                        ? Border.all(color: AppColors.primaryColor, width: 2)
                        : null,
                  ),
                  child: Text(
                    '+${items.length - shown}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.blackColor1,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _MediaItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: item.isVideo ? 'Video' : 'Photo',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.primaryColor : Colors.transparent,
              width: 2,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: item.isVideo
                ? Container(
                    color: const Color(0xFF1B1E24),
                    alignment: Alignment.center,
                    child: const Icon(Icons.play_arrow_rounded,
                        color: Colors.white, size: 22),
                  )
                : AppNetworkImage(
                    url: item.url, fit: BoxFit.cover, width: 36, height: 36),
          ),
        ),
      ),
    );
  }
}

class _NoPhotos extends StatelessWidget {
  const _NoPhotos({required this.isOwner, this.onAddPhotos});

  final bool isOwner;
  final VoidCallback? onAddPhotos;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.image_outlined, size: 36, color: AppColors.textMuted),
        const SizedBox(height: AppSpacing.xs4),
        Text(
          'No photos yet',
          style: TextStyle(fontSize: 13, color: AppColors.textMuted),
        ),
        if (isOwner && onAddPhotos != null) ...[
          const SizedBox(height: AppSpacing.sm8),
          TextButton(onPressed: onAddPhotos, child: const Text('Add photos')),
        ],
      ],
    );
  }
}
