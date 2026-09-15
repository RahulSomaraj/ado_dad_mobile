import 'dart:async';

import 'package:ado_dad_user/common/app_colors.dart';
import 'package:ado_dad_user/common/widgets/ado_dad_logo.dart';
import 'package:ado_dad_user/common/widgets/app_network_image.dart';
import 'package:ado_dad_user/common/widgets/rich_ad_card.dart';
import 'package:ado_dad_user/common/widgets/skeleton.dart';
import 'package:ado_dad_user/common/notification_badge_service.dart';
import 'package:ado_dad_user/common/app_textstyle.dart';
import 'package:ado_dad_user/features/home/banner_bloc/banner_bloc.dart';
import 'package:ado_dad_user/features/home/bloc/advertisement_bloc.dart';
import 'package:ado_dad_user/features/home/favorite/bloc/favorite_bloc.dart';
import 'package:ado_dad_user/features/home/ui/widgets/location_chip.dart';
import 'package:ado_dad_user/features/home/ui/widgets/location_picker_dialog.dart';
import 'package:ado_dad_user/models/cayegory_model.dart';
import 'package:ado_dad_user/repositories/add_repo.dart';
import 'package:ado_dad_user/services/location_service.dart';
import 'package:ado_dad_user/common/auth_guard.dart';
import 'package:ado_dad_user/common/widgets/dialog_util.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ado_dad_user/common/get_responsive_size.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.showLoginPromptForNotifications = false});

  final bool showLoginPromptForNotifications;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final CarouselSliderController _carouselController =
      CarouselSliderController();

  final ScrollController _scrollController = ScrollController();
  late final AdvertisementBloc _adBloc;

  /// The place the current feed was requested for. Location itself is owned
  /// by [LocationService]; this only remembers what the feed last asked for.
  UserPlace? _queriedPlace;

  @override
  void initState() {
    super.initState();
    // iOS-specific scrolling configurations
    _scrollController.addListener(_onScroll);

    // Opened from notification shade while not logged in: show login popup on home (do not open notifications page)
    if (widget.showLoginPromptForNotifications) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _showLoginPromptIfNeeded());
    }

    // Banners are already dispatched once when BannerBloc is created in main.dart;
    // re-dispatching here cost a second round trip competing with the first feed.

    _adBloc = context.read<AdvertisementBloc>();

    // The place was restored before runApp, so the first request goes out on
    // this frame with the right coordinates — no await, no "Locating…" flash.
    final location = LocationService();
    _dispatchFeed(location.place.value);
    location.place.addListener(_onPlaceChanged);
    // First launch: asks for a fix (permission prompt). Otherwise refreshes a
    // stale device fix. Never touches a manually chosen place.
    unawaited(location.start());
  }

  /// True while the viewport is inside the trigger zone, so a fling dispatches
  /// once on the way in rather than on every frame. Scrolling back out of the
  /// zone re-arms it.
  bool _nearBottomArmed = true;

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final nearBottom = _scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300;

    if (!nearBottom) {
      _nearBottomArmed = true;
      return;
    }
    if (!_nearBottomArmed) return;
    _nearBottomArmed = false;

    // Trigger next page load when nearing bottom
    _adBloc.add(const AdvertisementEvent.fetchNextPage());
  }

  Future<void> _showLoginPromptIfNeeded() async {
    if (!mounted) return;
    final isAuth = await AuthGuard.isAuthenticated();
    if (!mounted) return;
    if (!isAuth) {
      await DialogUtil.showLoginPromptDialog(
        context,
        message: 'Please login to view notifications.',
        redirectPath: '/notifications',
      );
      if (mounted) context.go('/home');
    }
  }

  @override
  void dispose() {
    LocationService().place.removeListener(_onPlaceChanged);
    _scrollController.dispose();
    super.dispose();
  }

  /// Re-queries the feed when the place moves (see
  /// [LocationService.needsRequery]); a name-only update does not refetch.
  void _onPlaceChanged() {
    if (!mounted) return;
    final next = LocationService().place.value;
    if (!LocationService.needsRequery(_queriedPlace, next)) return;
    _dispatchFeed(next);
  }

  void _dispatchFeed(UserPlace? place) {
    _queriedPlace = place;
    if (place == null) {
      _adBloc.add(const AdvertisementEvent.fetchAllListings());
    } else {
      _adBloc.add(
        AdvertisementEvent.searchByLocation(
          latitude: place.lat,
          longitude: place.lng,
        ),
      );
    }
  }

  Future<void> _openLocationPicker() => showLocationPickerDialog(context);

  @override
  Widget build(BuildContext context) {
    return BlocListener<FavoriteBloc, FavoriteState>(
      listener: (context, state) {
        if (state is FavoriteToggleSuccess) {
          // Update the advertisement in the list
          context.read<AdvertisementBloc>().add(
                AdvertisementEvent.updateAdFavoriteStatus(
                  adId: state.adId,
                  isFavorited: state.isFavorited,
                  favoriteId: state.favoriteId,
                ),
              );

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.message,
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: AppColors.primaryColor,
              duration: const Duration(seconds: 2),
            ),
          );
        } else if (state is FavoriteToggleError) {
          // Check if error is about login - show login popup instead of snackbar
          if (state.message.toLowerCase().contains('please login') ||
              state.message.toLowerCase().contains('login')) {
            DialogUtil.showLoginPromptDialog(
              context,
              message: state.message,
              redirectPath: '/home',
            );
          } else {
            // Show error message for other errors
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.message,
                  style: const TextStyle(color: Colors.white),
                ),
                duration: const Duration(seconds: 2),
                backgroundColor: Colors.red.shade300.withValues(alpha: 0.9),
              ),
            );
          }
        }
      },
      child: Scaffold(
        body: Column(
          children: [
            // 🔷 STICKY HEADER — logo, location, notifications + search bar
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppColors.primaryColor,
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 8,
                bottom: 12,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  buildTopBar(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                    child: _buildHomeSearchBar(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  // Pull-to-refresh must reach the network: drop the cached
                  // pages so the repository can't answer from memory.
                  AddRepository.invalidateAdsCache();
                  // Reuse the coordinates already held — no geocoding call.
                  _dispatchFeed(LocationService().place.value);
                },
                color: AppColors.primaryColor,
                backgroundColor: Colors.white,
                // CustomScrollView (not SingleChildScrollView + shrinkWrap
                // GridView): shrinkWrap forced the grid to build *every* card
                // to compute its intrinsic height, so all loaded cards fired
                // their image download at once. Slivers restore real laziness —
                // only visible cards (plus cacheExtent) are built.
                child: CustomScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 🔷 PROMO BANNER
                          Padding(
                            padding: const EdgeInsets.only(top: 14),
                            child: _buildPromoBanner(),
                          ),
                          const SizedBox(height: 8),

                          // 🔷 CATEGORIES
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: buildSectionTitle("Categories"),
                          ),
                          const SizedBox(height: 5),
                          buildCategories(context),

                          // extra space above Recommendations on larger devices
                          SizedBox(
                            height: GetResponsiveSize.getResponsiveSize(
                              context,
                              mobile: 0, // unchanged for phones
                              tablet: 25,
                              largeTablet: 30,
                              desktop: 30,
                            ),
                          ),

                          // 🔷 RECOMMENDATIONS TITLE
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                    child: buildSectionTitle("Fresh near you")),
                                GestureDetector(
                                  onTap: () =>
                                      context.push('/search?from=/home'),
                                  child: Text(
                                    "See all",
                                    style: TextStyle(
                                      color: AppColors.primaryColor,
                                      fontWeight: FontWeight.w500,
                                      fontSize: GetResponsiveSize
                                          .getResponsiveFontSize(
                                        context,
                                        mobile: 12,
                                        tablet: 16,
                                        largeTablet: 18,
                                        desktop: 18,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),

                    // 🔷 MAIN AD GRID — a real sliver, so it builds lazily.
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      sliver: buildGridSliver(),
                    ),

                    // Clear the floating bottom nav bar so the last row of ads
                    // and the load-more indicator are not hidden behind it.
                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
                ),
              ),
            ),
          ],
        ),
        // Bottom navigation is now provided by the persistent shell.
      ),
    );
  }

  Widget _buildPromoBanner() {
    return BlocBuilder<BannerBloc, BannerState>(
      builder: (context, state) {
        return state.when(
          initial: () => const SizedBox(),
          loading: () => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SkeletonBox(
              height: GetResponsiveSize.getResponsiveSize(
                context,
                mobile: 140,
                tablet: 250,
                largeTablet: 320,
                desktop: 360,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          error: (message) => const SizedBox(),
          loaded: (banners) => Column(
            children: [
              CarouselSlider(
                carouselController: _carouselController,
                options: CarouselOptions(
                  height: GetResponsiveSize.getResponsiveSize(
                    context,
                    mobile: 140,
                    tablet: 250,
                    largeTablet: 320,
                    desktop: 360,
                  ),
                  autoPlay: true,
                  enlargeCenterPage: true,
                  viewportFraction: 0.9,
                  onPageChanged: (index, _) {
                    setState(() {
                      BuildIndicator.currentIndex = index;
                    });
                  },
                ),
                items: banners.map((banner) {
                  return buildPromoCard(banner.phoneImage, banner.link);
                }).toList(),
              ),
              SizedBox(
                height: GetResponsiveSize.getResponsiveSize(
                  context,
                  mobile: 10,
                  tablet: 24,
                  largeTablet: 30,
                  desktop: 30,
                ),
              ),
              BuildIndicator(
                controller: _carouselController,
                itemCount: banners.length,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget buildTopBar() {
    final double locationFont = GetResponsiveSize.getResponsiveFontSize(
      context,
      mobile: 12,
      tablet: 22,
      largeTablet: 25,
      desktop: 25,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // White mark + wordmark sized by height so it is clearly visible on
          // the purple header.
          AdoDadLogo(
            height: GetResponsiveSize.getResponsiveSize(
              context,
              mobile: 28,
              tablet: 44,
              largeTablet: 52,
              desktop: 56,
            ),
          ),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ValueListenableBuilder<bool>(
                        valueListenable: NotificationBadgeService.hasUnread,
                        builder: (context, hasUnread, _) {
                          final bool isTab =
                              GetResponsiveSize.isTablet(context);
                          final double iconSize =
                              GetResponsiveSize.getResponsiveSize(
                            context,
                            mobile: 22,
                            tablet: 28,
                            largeTablet: 30,
                            desktop: 30,
                          );
                          return GestureDetector(
                            onTap: () async {
                              // Do not clear badge here – clear only when user opens the notifications page
                              final isAuthenticated =
                                  await AuthGuard.isAuthenticated();
                              if (!context.mounted) return;
                              if (isAuthenticated) {
                                context.push('/notifications');
                              } else {
                                DialogUtil.showLoginPromptDialog(
                                  context,
                                  message:
                                      'Please login to view notifications.',
                                  redirectPath: '/notifications',
                                );
                              }
                            },
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Icon(
                                  Icons.notifications_outlined,
                                  color: AppColors.whiteColor,
                                  size: isTab ? iconSize : 22,
                                ),
                                if (hasUnread)
                                  Positioned(
                                    top: -2,
                                    right: -2,
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                      SizedBox(width: 12),
                      GestureDetector(
                        onTap: _openLocationPicker,
                        child: Builder(
                          builder: (context) {
                            final bool isTab =
                                GetResponsiveSize.isTablet(context);
                            final double iconSize =
                                GetResponsiveSize.getResponsiveSize(
                              context,
                              mobile: 22,
                              tablet: 28,
                              largeTablet: 30,
                              desktop: 30,
                            );
                            return Image.asset(
                              'assets/images/Frame.png',
                              width: isTab ? iconSize : 22,
                              height: isTab ? iconSize : 22,
                              fit: BoxFit.contain,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  // Always rendered, never blank — see LocationChip.
                  SizedBox(height: 4),
                  LocationChip(
                    fontSize: locationFont,
                    onTap: _openLocationPicker,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildPromoCard(String imagePath, String link) {
    return GestureDetector(
      onTap: () {
        _launchURL(link);
      },
      child: Padding(
        // padding: const EdgeInsets.symmetric(horizontal: 12),
        padding: EdgeInsets.zero,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            height: 150,
            width: double.infinity,
            // color: Colors.red,
            // alignment: Alignment.center,
            child: AppNetworkImage(
              url: imagePath,
              fit: BoxFit.fill,
              height: 150,
              width: double.infinity,
            ),
          ),
        ),
      ),
    );
  }

  void _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {}
  }

  Widget buildSectionTitle(String title) {
    final baseSize = AppTextstyle.sectionTitleTextStyle.fontSize ?? 16;
    final responsiveSize = GetResponsiveSize.getResponsiveFontSize(
      context,
      mobile: baseSize, // keep phone unchanged
      tablet: baseSize + 15,
      largeTablet: baseSize + 18,
      desktop: baseSize + 18,
    );
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: AppTextstyle.sectionTitleTextStyle
            .copyWith(fontSize: responsiveSize),
      ),
    );
  }

  // Tappable search pill on Home; opens the full search screen in one tap.
  Widget _buildHomeSearchBar(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/search?from=/home'),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.whiteColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.dividerColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.search, color: AppColors.greyColor),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Search cars, bikes, property…',
                style: TextStyle(color: AppColors.greyColor, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildCategories(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Calculate item width to show multiple items per row
    // Increased mobile width to prevent word breaking (especially for "Commercial")
    // With reduced padding and spacing, we can use more width
    final itemWidth = GetResponsiveSize.isTablet(context)
        ? GetResponsiveSize.getResponsiveSize(
            context,
            mobile: screenWidth * 0.2, // not used on tablets
            tablet: screenWidth * 0.20,
            largeTablet: screenWidth * 0.26,
            desktop: screenWidth * 0.28,
          )
        : (screenWidth * 0.24).clamp(90.0,
            double.infinity); // Increased to 24% with min 90px for better fit

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: GetResponsiveSize.isTablet(context)
            ? GetResponsiveSize.getResponsivePadding(
                context,
                mobile: 12.0, // Not used on tablets
                tablet: 8.0, // Decreased left/right padding for tablets
                largeTablet: 8.0,
                desktop: 8.0,
              )
            : 8.0, // Reduced from 12.0 to give more width to categories
        vertical: 10,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: categories.map((category) {
            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: SizedBox(
                width: itemWidth,
                child: GestureDetector(
                  onTap: () async {
                    // Special handling for Showroom category
                    if (category.categoryId == 'showroom') {
                      // Navigate to showroom users - page handles both authenticated and unauthenticated access
                      context.push('/showroom-users');
                      return;
                    }

                    // context.read<AdvertisementBloc>().add(
                    //       AdvertisementEvent.fetchByCategory(
                    //           categoryId: category.categoryId),
                    //     );
                    // context.push(
                    //     '/category-list-page?categoryId=${category.categoryId}&title=${category.name}');

                    // No refetch on return. The category list runs on its own
                    // route-scoped bloc now, so Home's listings and scroll position
                    // survive the trip; a write (post / edit / sold / delete)
                    // clears the repository cache, so anything genuinely stale is
                    // refreshed by the next fetch rather than by a blanket reload
                    // of the whole feed on every back press.
                    await context.push(
                      '/category-list-page?categoryId=${category.categoryId}&title=${category.name}',
                    );
                  },
                  child: Column(
                    children: [
                      Container(
                        height: GetResponsiveSize.getResponsiveSize(
                          context,
                          mobile: 70, // unchanged for phones
                          tablet: 110,
                          largeTablet: 135,
                          desktop: 150,
                        ),
                        padding:
                            EdgeInsets.all(GetResponsiveSize.getResponsiveSize(
                          context,
                          mobile: 16,
                          tablet: 20,
                          largeTablet: 22,
                          desktop: 22,
                        )),
                        decoration: BoxDecoration(
                          color: AppColors.whiteColor,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(color: Colors.black12, blurRadius: 2)
                          ],
                        ),
                        child: SizedBox(
                          width: GetResponsiveSize.getResponsiveSize(
                            context,
                            mobile: 38, // leave phone small as before
                            tablet: 60,
                            largeTablet: 75,
                            desktop: 80,
                          ),
                          height: GetResponsiveSize.getResponsiveSize(
                            context,
                            mobile: 38,
                            tablet: 60,
                            largeTablet: 70,
                            desktop: 80,
                          ),
                          child:
                              Image.asset(category.image, fit: BoxFit.contain),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Builder(
                        builder: (context) {
                          final double baseSize =
                              AppTextstyle.categoryLabelTextStyle.fontSize ??
                                  12;
                          final double labelSize =
                              GetResponsiveSize.getResponsiveFontSize(
                            context,
                            mobile: baseSize, // keep phone unchanged
                            tablet: baseSize + 10,
                            largeTablet: baseSize + 13,
                            desktop: baseSize + 13,
                          );
                          // Allow multi-line text but ensure words don't break
                          // Text widget naturally wraps at word boundaries (not mid-word)
                          // Use ConstrainedBox to limit width, allowing natural word wrapping
                          return ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: itemWidth),
                            child: Text(
                              category.name,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              softWrap: true, // Wraps at word boundaries only
                              style: AppTextstyle.categoryLabelTextStyle
                                  .copyWith(fontSize: labelSize),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // 1) Helpers: decide columns and compute a responsive card height
  int _columnsForWidth(double w) {
    if (w >= 1200) return 5; // keep desktop dense
    if (w >= 900) return 2; // large tablets: 2 per row
    if (w >= 600) return 2; // tablets: 2 per row
    return 2; // phones unchanged
  }

  double _cardMainAxisExtent(BuildContext context, int columns) {
    final screenWidth = MediaQuery.of(context).size.width;
    const horizontalPagePadding = 15.0;
    const spacing = 15.0;

    final available =
        screenWidth - (horizontalPagePadding * 2) - (spacing * (columns - 1));
    final cardWidth = available / columns;

    final aspectRatio =
        GetResponsiveSize.isTablet(context) ? (16 / 9) : (16 / 10);
    final imageHeight = cardWidth / aspectRatio;

    // Matches RichAdCard: padding + price + title + chips + footer, where the
    // footer is now two lines (place, then distance/time). Includes a small
    // safety buffer so font-metric rounding can't overflow.
    const textBlockHeight = 15 + 18 + 3 + 16 + 6 + 22 + 14 + 18 + 6 + 10;

    return imageHeight + textBlockHeight;
  }

  /// The ad grid as a **sliver**, so only on-screen cards are built.
  ///
  /// The previous `GridView.builder(shrinkWrap: true, physics: Never…)` inside
  /// a `SingleChildScrollView` had to lay out every loaded item to compute its
  /// height, which meant every `RichAdCard` — 20, then 40, then 60 after a few
  /// paginations — started its full-resolution image download on the same
  /// frame. `cacheExtent` was inert in that arrangement too.
  Widget buildGridSliver() {
    return BlocBuilder<AdvertisementBloc, AdvertisementState>(
      builder: (context, state) {
        if (state is AdvertisementLoading) {
          // Skeleton grid that matches the real card layout for a fast feel.
          return SliverLayoutBuilder(
            builder: (context, constraints) {
              final cols = _columnsForWidth(constraints.crossAxisExtent);
              final mainExtent = _cardMainAxisExtent(context, cols);
              return SliverToBoxAdapter(
                child: SkeletonAdGrid(
                  crossAxisCount: cols,
                  mainAxisExtent: mainExtent,
                  itemCount: cols * 3,
                ),
              );
            },
          );
        } else if (state is ListingsLoaded) {
          final listings = state.listings;
          final hasMore = state.hasMore;

          return SliverLayoutBuilder(
            builder: (context, constraints) {
              final cols = _columnsForWidth(constraints.crossAxisExtent);
              final mainExtent = _cardMainAxisExtent(context, cols);

              return SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                  mainAxisExtent: mainExtent, // ✅ explicit, responsive height
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index < listings.length) {
                      final ad = listings[index];
                      return RichAdCard(key: ValueKey(ad.id), ad: ad);
                    }
                    return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  },
                  childCount: listings.length + (hasMore ? 1 : 0),
                  // Ads are identified by id, so Flutter can reuse element and
                  // image state across pagination instead of rebuilding rows.
                  findChildIndexCallback: (key) {
                    if (key is ValueKey<String>) {
                      final i = listings.indexWhere((ad) => ad.id == key.value);
                      return i == -1 ? null : i;
                    }
                    return null;
                  },
                ),
              );
            },
          );
        } else if (state is AdvertisementError) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      state.message,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        } else {
          return const SliverToBoxAdapter(
            child: Center(child: Text("No data available")),
          );
        }
      },
    );
  }
}

class BuildIndicator extends StatefulWidget {
  final CarouselSliderController controller;
  final int itemCount;
  const BuildIndicator(
      {super.key, required this.controller, required this.itemCount});

  static int currentIndex = 0;

  @override
  State<BuildIndicator> createState() => _BuildIndicatorState();
}

class _BuildIndicatorState extends State<BuildIndicator> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BannerBloc, BannerState>(
      builder: (context, state) {
        return state.when(
          initial: () => SizedBox(),
          loading: () => SizedBox(),
          error: (message) => SizedBox(),
          loaded: (banners) => Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(banners.length, (index) {
              final bool isTablet = GetResponsiveSize.isTablet(context);
              // Compute responsive indicator sizes
              final double activeWidth = GetResponsiveSize.getResponsiveSize(
                context,
                mobile: 15,
                tablet: 20,
                largeTablet: 24,
                desktop: 24,
              );
              final double inactiveWidth = GetResponsiveSize.getResponsiveSize(
                context,
                mobile: 6,
                tablet: 8,
                largeTablet: 10,
                desktop: 10,
              );
              final double dotHeight = GetResponsiveSize.getResponsiveSize(
                context,
                mobile: 6,
                tablet: 10,
                largeTablet: 10,
                desktop: 10,
              );
              final double dotMargin = GetResponsiveSize.getResponsiveSize(
                context,
                mobile: 5,
                tablet: 8,
                largeTablet: 7,
                desktop: 7,
              );
              return GestureDetector(
                onTap: () {
                  setState(() {
                    BuildIndicator.currentIndex = index;
                  });
                  widget.controller.jumpToPage(index);
                },
                child: Container(
                  width: BuildIndicator.currentIndex == index
                      ? (isTablet ? activeWidth : 15)
                      : (isTablet ? inactiveWidth : 6),
                  height: isTablet ? dotHeight : 6,
                  margin: EdgeInsets.symmetric(
                      horizontal: isTablet ? dotMargin : 5),
                  decoration: BoxDecoration(
                    shape: BoxShape.rectangle,
                    color: BuildIndicator.currentIndex == index
                        ? AppColors.primaryColor
                        : AppColors.greyColor,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width - 24;
    String current = '';
    try {
      current = GoRouterState.of(context).uri.path;
    } catch (_) {}
    return Container(
      width: width,
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _navItem(context, current,
              icon: Icons.home_rounded, label: 'Home', route: '/home'),
          _navItem(context, current,
              icon: Icons.favorite_border,
              label: 'Favorites',
              route: '/wishlist'),
          _sellButton(context),
          _navItem(context, current,
              icon: Icons.chat_bubble_outline,
              label: 'Chat',
              route: '/chat-rooms?from=home'),
          _navItem(context, current,
              icon: Icons.person_outline, label: 'Profile', route: '/profile'),
        ],
      ),
    );
  }

  bool _isActive(String current, String route) =>
      current == route.split('?').first;

  Widget _navItem(
    BuildContext context,
    String current, {
    required IconData icon,
    required String label,
    required String route,
  }) {
    final bool active = _isActive(current, route);
    final Color color = active ? AppColors.primaryColor : AppColors.greyColor;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _go(context, route),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 23, color: color),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sellButton(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _go(context, '/seller'),
        child: Center(
          child: Transform.translate(
            offset: const Offset(0, -16),
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.whiteColor, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryColor.withValues(alpha: 0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 26),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _go(BuildContext context, String route) async {
    final publicRoutes = ['/home', '/search'];
    final isPublicRoute = publicRoutes.any((r) => route.startsWith(r));
    if (isPublicRoute) {
      if (route.contains('/chat-rooms')) {
        context.go(route);
      } else {
        context.push(route);
      }
      return;
    }
    final isAuthenticated = await AuthGuard.isAuthenticated();
    if (!context.mounted) return;
    if (isAuthenticated) {
      if (route.contains('/chat-rooms')) {
        context.go(route);
      } else {
        context.push(route);
      }
    } else {
      DialogUtil.showLoginPromptDialog(
        context,
        message: "Please login to access this feature.",
        redirectPath: route.split('?').first,
      );
    }
  }
}
