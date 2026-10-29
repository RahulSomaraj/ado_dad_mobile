import 'package:ado_dad_user/common/app_colors.dart';
import 'package:ado_dad_user/common/get_responsive_size.dart';
import 'package:ado_dad_user/common/widgets/app_network_image.dart';
import 'package:ado_dad_user/common/widgets/skeleton.dart';
import 'package:ado_dad_user/features/home/banner_bloc/banner_bloc.dart';
import 'package:ado_dad_user/features/home/ui/widgets/home_hero.dart';
import 'package:ado_dad_user/models/banner_model.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

/// Home banner carousel showing the live banners from [BannerBloc] one at a
/// time, full width (no neighbouring slides peeking in), with dots below.
///
/// Loading shows a skeleton of the same size; with no banners (or an error)
/// a built-in blue "Explore bikes" slide keeps the section from collapsing.
class HomePromoCarousel extends StatefulWidget {
  const HomePromoCarousel({super.key, required this.onExploreBikes});

  final VoidCallback onExploreBikes;

  /// Admin banner artwork is roughly 2.76 : 1.
  static const double aspectRatio = 2.76;

  @override
  State<HomePromoCarousel> createState() => _HomePromoCarouselState();
}

class _HomePromoCarouselState extends State<HomePromoCarousel> {
  final CarouselSliderController _controller = CarouselSliderController();
  int _index = 0;

  Future<void> _open(String link) async {
    final uri = Uri.tryParse(link.trim());
    if (link.trim().isEmpty || uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool tab = GetResponsiveSize.isTablet(context);
    final double side = tab ? 28 : 16;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth - side * 2;
        final double height = width / HomePromoCarousel.aspectRatio;

        return BlocBuilder<BannerBloc, BannerState>(
          builder: (context, state) {
            final bool loading = state.maybeWhen(
              initial: () => true,
              loading: () => true,
              orElse: () => false,
            );
            if (loading) {
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: side),
                child: SkeletonBox(
                  height: height,
                  borderRadius: BorderRadius.circular(20),
                ),
              );
            }

            final List<BannerModel> banners = state.maybeWhen(
              loaded: (b) =>
                  b.where((x) => x.phoneImage.trim().isNotEmpty).toList(),
              orElse: () => const <BannerModel>[],
            );

            final List<Widget> slides = banners.isEmpty
                ? [_FallbackSlide(onTap: widget.onExploreBikes)]
                : banners
                    .map((b) => _ImageSlide(
                          banner: b,
                          onTap: () => _open(b.link),
                        ))
                    .toList();
            final int active = _index.clamp(0, slides.length - 1).toInt();

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CarouselSlider(
                  carouselController: _controller,
                  items: slides
                      .map((s) => Padding(
                            padding: EdgeInsets.symmetric(horizontal: side),
                            child: _SlideFrame(child: s),
                          ))
                      .toList(),
                  options: CarouselOptions(
                    height: height,
                    // One slide at a time, full width — nothing peeks in.
                    viewportFraction: 1.0,
                    enlargeCenterPage: false,
                    enableInfiniteScroll: slides.length > 1,
                    autoPlay: slides.length > 1,
                    autoPlayInterval: const Duration(seconds: 5),
                    autoPlayCurve: Curves.easeOutCubic,
                    onPageChanged: (i, _) => setState(() => _index = i),
                  ),
                ),
                if (slides.length > 1) ...[
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(slides.length, (i) {
                      final bool on = i == active;
                      return GestureDetector(
                        onTap: () => _controller.animateToPage(i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOut,
                          width: on ? 18 : 6,
                          height: 6,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            color: on
                                ? AppColors.brandText
                                : AppColors.dividerColor,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }
}

class _SlideFrame extends StatelessWidget {
  const _SlideFrame({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: HomeHeroPalette.shadowInk
                .withValues(alpha: AppColors.isDark ? 0.5 : 0.25),
            blurRadius: 22,
            offset: const Offset(0, 10),
            spreadRadius: -10,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SizedBox.expand(child: child),
      ),
    );
  }
}

class _ImageSlide extends StatelessWidget {
  const _ImageSlide({required this.banner, required this.onTap});
  final BannerModel banner;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: banner.link.isNotEmpty,
      label: banner.title.isEmpty ? 'Promotion' : banner.title,
      child: GestureDetector(
        onTap: onTap,
        child: AppNetworkImage(url: banner.phoneImage, fit: BoxFit.cover),
      ),
    );
  }
}

/// Shown only when there are no live banners.
class _FallbackSlide extends StatelessWidget {
  const _FallbackSlide({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool tab = GetResponsiveSize.isTablet(context);
    return DecoratedBox(
      decoration: BoxDecoration(gradient: HomeHeroPalette.gradient),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
                horizontal: tab ? 28 : 18, vertical: tab ? 20 : 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        TextSpan(
                          style:
                              HomeHeroPalette.display(size: tab ? 30 : 21),
                          children: [
                            const TextSpan(text: 'Your next ride is '),
                            TextSpan(
                              text: 'nearby.',
                              style: HomeHeroPalette.display(
                                size: tab ? 30 : 21,
                                color: HomeHeroPalette.soft,
                              ),
                            ),
                          ],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: tab ? 12 : 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Explore bikes',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: tab ? 15 : 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.arrow_forward_rounded,
                              size: 15, color: Colors.white),
                        ],
                      ),
                    ],
                  ),
                ),
                Image.asset(
                  'assets/images/cat_bike.png',
                  height: tab ? 110 : 70,
                  fit: BoxFit.contain,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
