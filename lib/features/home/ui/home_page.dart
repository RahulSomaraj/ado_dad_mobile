import 'dart:async';

import 'package:ado_dad_user/common/app_colors.dart';
import 'package:ado_dad_user/common/widgets/rich_ad_card.dart';
import 'package:ado_dad_user/common/widgets/skeleton.dart';
import 'package:ado_dad_user/features/home/bloc/advertisement_bloc.dart';
import 'package:ado_dad_user/features/home/favorite/bloc/favorite_bloc.dart';
import 'package:ado_dad_user/features/home/ui/widgets/home_category_strip.dart';
import 'package:ado_dad_user/features/home/ui/widgets/home_hero.dart';
import 'package:ado_dad_user/features/home/ui/widgets/home_promo_carousel.dart';
import 'package:ado_dad_user/features/home/ui/widgets/location_picker_dialog.dart';
import 'package:ado_dad_user/models/cayegory_model.dart';
import 'package:ado_dad_user/repositories/add_repo.dart';
import 'package:ado_dad_user/services/location_service.dart';
import 'package:ado_dad_user/common/auth_guard.dart';
import 'package:ado_dad_user/common/widgets/dialog_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ado_dad_user/common/get_responsive_size.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.showLoginPromptForNotifications = false});

  final bool showLoginPromptForNotifications;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  /// True once the hero has scrolled away and the compact header shows.
  final ValueNotifier<bool> _showCompactHeader = ValueNotifier<bool>(false);

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
    final bool compact = _scrollController.position.pixels > 240;
    if (compact != _showCompactHeader.value) {
      _showCompactHeader.value = compact;
    }
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
    _showCompactHeader.dispose();
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
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        // The hero is always navy, so the status bar icons stay light.
        value: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
        ),
        child: Scaffold(
          backgroundColor: AppColors.scaffoldBackground,
          body: Stack(
            children: [
              RefreshIndicator(
                onRefresh: () async {
                  // Pull-to-refresh must reach the network: drop the cached
                  // pages so the repository can't answer from memory.
                  AddRepository.invalidateAdsCache();
                  // Reuse the coordinates already held — no geocoding call.
                  _dispatchFeed(LocationService().place.value);
                },
                edgeOffset: MediaQuery.of(context).padding.top,
                color: AppColors.primaryColor,
                backgroundColor: Colors.white,
                // CustomScrollView (not SingleChildScrollView + shrinkWrap
                // GridView): slivers keep the ad grid lazy — only visible
                // cards (plus cacheExtent) are built.
                child: CustomScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // 🔷 HEADER + CATEGORIES + BANNERS + "Fresh near you" title
                    SliverToBoxAdapter(child: _buildTop(context)),

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

              // 🔷 COMPACT HEADER — slides in once the hero scrolls away.
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: ValueListenableBuilder<bool>(
                  valueListenable: _showCompactHeader,
                  builder: (context, show, child) => IgnorePointer(
                    ignoring: !show,
                    child: AnimatedSlide(
                      offset: show ? Offset.zero : const Offset(0, -1),
                      duration: const Duration(milliseconds: 240),
                      curve: Curves.easeOutCubic,
                      child: AnimatedOpacity(
                        opacity: show ? 1 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: child,
                      ),
                    ),
                  ),
                  child: HomeCompactHeader(
                    onLocationTap: _openLocationPicker,
                    onNotificationsTap: _onNotificationsTap,
                    onSearchTap: _openSearch,
                  ),
                ),
              ),
            ],
          ),
          // Bottom navigation is now provided by the persistent shell.
        ),
      ),
    );
  }

  /// Hero with the category tiles overlapping its bottom edge, the promo
  /// carousel and the "Fresh near you" heading.
  Widget _buildTop(BuildContext context) {
    final bool tab = GetResponsiveSize.isTablet(context);
    final double side = tab ? 28 : 16;
    final double card = HomeCategoryCard.heightOf(context, categories.length);
    final double overlap = tab ? 80 : 66;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 🔷 BLUE HEADER + floating category card over its bottom edge
        Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: EdgeInsets.only(bottom: card - overlap),
              child: HomeHero(
                bottomInset: overlap + 20,
                onLocationTap: _openLocationPicker,
                onNotificationsTap: _onNotificationsTap,
                onSearchTap: _openSearch,
              ),
            ),
            Positioned(
              left: side,
              right: side,
              bottom: 0,
              child: HomeCategoryCard(
                items: categories,
                onTap: _openCategory,
              ),
            ),
          ],
        ),
        SizedBox(height: tab ? 24 : 18),

        // 🔷 BANNERS — one at a time, full width
        HomePromoCarousel(onExploreBikes: _exploreBikes),
        SizedBox(height: tab ? 28 : 20),

        // 🔷 FRESH NEAR YOU
        Padding(
          padding: EdgeInsets.symmetric(horizontal: side - 2),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Fresh near you',
                  style: HomeHeroPalette.display(
                    size: tab ? 32 : 25,
                    color: AppColors.blackColor,
                  ),
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: _openSearch,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                  child: Text(
                    'See all',
                    style: TextStyle(
                      color: AppColors.brandText,
                      fontWeight: FontWeight.w700,
                      fontSize: tab ? 17 : 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  void _openSearch() => context.push('/search?from=/home');

  Future<void> _onNotificationsTap() async {
    // Do not clear the badge here – it clears when the notifications page opens.
    final isAuthenticated = await AuthGuard.isAuthenticated();
    if (!mounted) return;
    if (isAuthenticated) {
      context.push('/notifications');
    } else {
      DialogUtil.showLoginPromptDialog(
        context,
        message: 'Please login to view notifications.',
        redirectPath: '/notifications',
      );
    }
  }

  /// No refetch on return: the category list runs on its own route-scoped
  /// bloc, so Home's listings and scroll position survive the trip.
  Future<void> _openCategory(CategoryModel category) async {
    if (category.categoryId == 'showroom') {
      // Showroom page handles both authenticated and guest access.
      context.push('/showroom-users');
      return;
    }
    await context.push(
      '/category-list-page?categoryId=${category.categoryId}&title=${category.name}',
    );
  }

  void _exploreBikes() {
    final bike = categories.firstWhere(
      (c) => c.categoryId == 'two_wheeler',
      orElse: () => categories.first,
    );
    _openCategory(bike);
  }
  // 1) Helpers: decide columns and compute a responsive card height
  int _columnsForWidth(double w) {
    if (w >= 1200) return 5; // keep desktop dense
    if (w >= 900) return 2; // large tablets: 2 per row
    if (w >= 600) return 2; // tablets: 2 per row
    return 2; // phones unchanged
  }

  /// Same cell height as every other RichAdCard grid (scales with font size).
  double _cardMainAxisExtent(BuildContext context, int columns) =>
      richAdCardMainAxisExtent(context, columns: columns);

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
    final Color color = active ? AppColors.brandText : AppColors.greyColor;
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
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
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
                // Theme 1: Sell is an action control, the only orange in the nav.
                color: AppColors.ctaColor,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.whiteColor, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.ctaColor.withValues(alpha: 0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(Icons.add, color: AppColors.onCta, size: 26),
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
