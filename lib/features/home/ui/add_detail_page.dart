import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ado_dad_user/common/widgets/app_network_image.dart';
import 'package:ado_dad_user/common/widgets/skeleton.dart';
import 'package:ado_dad_user/common/app_colors.dart';
import 'package:ado_dad_user/common/get_responsive_size.dart';
import 'package:ado_dad_user/common/auth_guard.dart';
import 'package:ado_dad_user/common/widgets/dialog_util.dart';
import 'package:ado_dad_user/features/home/ad_detail/ad_detail_bloc.dart';
import 'package:ado_dad_user/models/advertisement_model/add_model.dart';
import 'package:ado_dad_user/features/home/services/offer_service.dart';
import 'package:ado_dad_user/features/home/services/chat_service.dart';
import 'package:ado_dad_user/common/shared_pref.dart';
import 'package:ado_dad_user/features/home/favorite/bloc/favorite_bloc.dart';
import 'package:ado_dad_user/features/home/ui/report_ad_dialog.dart';
import 'package:ado_dad_user/features/home/ui/widgets/ad_detail_title_price.dart';
import 'package:ado_dad_user/features/home/ui/widgets/ad_detail_description.dart';
import 'package:ado_dad_user/features/home/ui/widgets/ad_detail_seller_tile.dart';
import 'package:ado_dad_user/features/home/ui/widgets/ad_detail_bottom_buttons.dart';
import 'package:ado_dad_user/features/home/ui/widgets/ad_detail_action_buttons.dart';
import 'package:ado_dad_user/features/home/ui/widgets/ad_detail_report_button.dart';
import 'package:ado_dad_user/features/home/ui/widgets/ad_detail_carousel_dots.dart';
import 'package:ado_dad_user/features/home/ui/widgets/ad_detail_circle_icon_button.dart';
import 'package:ado_dad_user/features/home/ui/widgets/ad_detail_mark_as_sold_button.dart';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ado_dad_user/repositories/add_repo.dart';
import 'package:ado_dad_user/common/widgets/rich_ad_card.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:share_plus/share_plus.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'dart:async';

class AdDetailPage extends StatefulWidget {
  // final String adId;
  final AddModel ad;
  const AdDetailPage({super.key, required this.ad});

  @override
  State<AdDetailPage> createState() => _AdDetailPageState();
}

class _AdDetailPageState extends State<AdDetailPage> {
  int _currentIndex = 0;
  VideoPlayerController? _videoController;
  final CarouselSliderController _carouselController =
      CarouselSliderController();
  Timer? _autoPlayTimer;
  bool _hasVideo = false;
  final Map<String, VideoPlayerController?> _videoControllers = {};
  final Map<String, VoidCallback?> _onVideoCompleteCallbacks = {};

  // Cache the current user id so repeated owner-checks (many FutureBuilders,
  // re-run on every rebuild) don't hit SharedPreferences each time.
  String? _cachedUserId;
  bool _userIdLoaded = false;

  @override
  void initState() {
    super.initState();
  }

  // Check if current user is the owner of the ad
  Future<bool> _isCurrentUserOwner(AddModel ad) async {
    if (!_userIdLoaded) {
      _cachedUserId = await SharedPrefs().getUserId();
      _userIdLoaded = true;
    }
    return _cachedUserId != null &&
        ad.user?.id != null &&
        _cachedUserId == ad.user!.id;
  }

  // Share ad functionality
  Future<void> _shareAd(AddModel ad) async {
    // Check authentication before allowing share
    final isAuthenticated = await AuthGuard.isAuthenticated();
    if (!isAuthenticated) {
      DialogUtil.showLoginPromptDialog(
        context,
        message: "Please login to share this ad.",
        redirectPath: '/add-detail-page',
      );
      return;
    }
    String title;
    if (ad.category == 'property') {
      title =
          '${ad.propertyType ?? ''} • ${ad.bedrooms ?? 0} BHK • ${ad.areaSqft ?? 0} sqft';
    } else {
      title =
          '${ad.manufacturer?.displayName ?? ad.manufacturer?.name ?? ''} ${ad.model?.displayName ?? ad.model?.name ?? ''} (${ad.year ?? ''})';
    }

    final shareText = '''
🚗 Check out this amazing listing on Adodad!

${toTitleCase(title)}
📍 Location: ${ad.location}
💰 Price: ₹${ad.price}
📝 Description: ${ad.description}

🔗 Visit: https://adodad.com/

Download Adodad app to contact the seller and view more details!
''';

    Share.share(
      shareText,
      subject: 'Amazing listing on Adodad - ${toTitleCase(title)}',
    );
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _autoPlayTimer?.cancel();
    for (var controller in _videoControllers.values) {
      controller?.dispose();
    }
    super.dispose();
  }

  void _startAutoPlay(AddModel ad) {
    _autoPlayTimer?.cancel();

    final totalItems = _getTotalCarouselItems(ad);
    // Nothing to advance to when there's a single item — avoid an endless
    // 3s timer → nextPage → rebuild loop that spams logs and wastes CPU.
    if (totalItems <= 1) return;
    if (_currentIndex >= totalItems) return;

    // Check if current item is video (video is always first item if exists)
    final isVideo = _hasVideo && _currentIndex == 0;

    if (isVideo) {
      // For video in carousel, advance after a fixed duration (5 seconds)
      // Since we disabled auto-play on video to prevent tap conflicts,
      // we'll just advance after a delay
      _autoPlayTimer = Timer(const Duration(seconds: 5), () {
        if (mounted) {
          _carouselController.nextPage();
        }
      });
    } else {
      // For images, auto-advance after 3 seconds
      _autoPlayTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) {
          _carouselController.nextPage();
        }
      });
    }
  }

  void _onVideoComplete() {
    if (mounted) {
      _carouselController.nextPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: false,
        // minimum: const EdgeInsets.only(bottom: 80),
        child: BlocListener<AdDetailBloc, AdDetailState>(
          listener: (context, state) {
            state.when(
              initial: () {},
              loading: () {},
              error: (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Error: $e',
                      style: const TextStyle(color: Colors.white),
                    ),
                    backgroundColor: Colors.red.shade300.withOpacity(0.9),
                  ),
                );
              },
              loaded: (ad) {},
              markingAsSold: () {},
              markedAsSold: (ad) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text(
                      'Ad marked as sold successfully!',
                      style: TextStyle(color: Colors.white),
                    ),
                    backgroundColor: AppColors.primaryColor,
                  ),
                );
                context.go('/home');
              },
              deleting: () {},
              deleted: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text(
                      'Advertisement deleted successfully.',
                      style: TextStyle(color: Colors.white),
                    ),
                    backgroundColor: AppColors.primaryColor,
                  ),
                );
                context.go('/home');
              },
            );
          },
          child: BlocBuilder<AdDetailBloc, AdDetailState>(
            builder: (context, state) {
              return state.when(
                initial: () =>
                    const Center(child: Text('Waiting for details...')),
                loading: () => const SkeletonDetail(),
                error: (e) => Center(child: Text('Error: $e')),
                loaded: (ad) => CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(child: _headerCarousel(ad)),
                    SliverToBoxAdapter(
                        child: AdDetailCarouselDots(
                      count: _getTotalCarouselItems(ad),
                      currentIndex: _currentIndex,
                    )),
                    SliverToBoxAdapter(
                        child: AdDetailTitlePrice(
                      ad: ad,
                      isCurrentUserOwner: _isCurrentUserOwner,
                    )),
                    SliverToBoxAdapter(child: Divider()),

                    SliverToBoxAdapter(
                        child: _specsCard(ad)),
                    SliverToBoxAdapter(child: AdDetailDescription(ad: ad)),
                    SliverToBoxAdapter(
                        child: AdDetailReportButton(
                      ad: ad,
                      isCurrentUserOwner: _isCurrentUserOwner,
                    )),
                    SliverToBoxAdapter(child: AdDetailSellerTile(ad: ad)),
                    SliverToBoxAdapter(child: _ownerActionsCard(ad)),
                    SliverToBoxAdapter(child: _SimilarAdsSection(ad: ad)),
                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
                ),
                markingAsSold: () => CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(child: _headerCarousel(widget.ad)),
                    SliverToBoxAdapter(
                        child: AdDetailCarouselDots(
                      count: _getTotalCarouselItems(widget.ad),
                      currentIndex: _currentIndex,
                    )),
                    SliverToBoxAdapter(
                        child: AdDetailTitlePrice(
                      ad: widget.ad,
                      isCurrentUserOwner: _isCurrentUserOwner,
                    )),
                    SliverToBoxAdapter(child: Divider()),
                    SliverToBoxAdapter(
                        child: _specsCard(widget.ad)),
                    SliverToBoxAdapter(
                        child: AdDetailDescription(ad: widget.ad)),
                    SliverToBoxAdapter(
                        child: AdDetailReportButton(
                      ad: widget.ad,
                      isCurrentUserOwner: _isCurrentUserOwner,
                    )),
                    SliverToBoxAdapter(
                        child: AdDetailSellerTile(ad: widget.ad)),
                  ],
                ),
                markedAsSold: (ad) => CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(child: _headerCarousel(ad)),
                    SliverToBoxAdapter(
                        child: AdDetailCarouselDots(
                      count: _getTotalCarouselItems(ad),
                      currentIndex: _currentIndex,
                    )),
                    SliverToBoxAdapter(
                        child: AdDetailTitlePrice(
                      ad: ad,
                      isCurrentUserOwner: _isCurrentUserOwner,
                    )),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: GetResponsiveSize.getResponsivePadding(
                              context,
                              mobile: 16,
                              tablet: 20,
                              largeTablet: 24,
                              desktop: 28),
                        ),
                        child: Divider(
                          thickness: GetResponsiveSize.getResponsiveSize(
                              context,
                              mobile: 1,
                              tablet: 1.2,
                              largeTablet: 1.4,
                              desktop: 1.5),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                        child: _specsCard(ad)),
                    SliverToBoxAdapter(child: AdDetailDescription(ad: ad)),
                    SliverToBoxAdapter(
                        child: AdDetailReportButton(
                      ad: ad,
                      isCurrentUserOwner: _isCurrentUserOwner,
                    )),
                    SliverToBoxAdapter(child: AdDetailSellerTile(ad: ad)),
                    SliverToBoxAdapter(child: _ownerActionsCard(ad)),
                  ],
                ),
                deleting: () => CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(child: _headerCarousel(widget.ad)),
                    SliverToBoxAdapter(
                        child: AdDetailCarouselDots(
                      count: _getTotalCarouselItems(widget.ad),
                      currentIndex: _currentIndex,
                    )),
                    SliverToBoxAdapter(
                        child: AdDetailTitlePrice(
                      ad: widget.ad,
                      isCurrentUserOwner: _isCurrentUserOwner,
                    )),
                    SliverToBoxAdapter(child: Divider()),
                    SliverToBoxAdapter(
                        child: _specsCard(widget.ad)),
                    SliverToBoxAdapter(
                        child: AdDetailDescription(ad: widget.ad)),
                    SliverToBoxAdapter(
                        child: AdDetailReportButton(
                      ad: widget.ad,
                      isCurrentUserOwner: _isCurrentUserOwner,
                    )),
                    SliverToBoxAdapter(
                        child: AdDetailSellerTile(ad: widget.ad)),
                  ],
                ),
                deleted: () => const SizedBox.shrink(),
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 65),
        child: BlocBuilder<AdDetailBloc, AdDetailState>(
          builder: (context, state) {
            return state.when(
              initial: () => const SizedBox.shrink(),
              loading: () => const SizedBox.shrink(),
              error: (e) => const SizedBox.shrink(),
              loaded: (ad) => AdDetailBottomButtons(
                ad: ad,
                isCurrentUserOwner: _isCurrentUserOwner,
                onMakeOffer: () => _handleMakeOffer(context),
                onChat: () => _handleChat(context),
                onCall: () => _handleCall(context, ad),
              ),
              markingAsSold: () => AdDetailBottomButtons(
                ad: widget.ad,
                isCurrentUserOwner: _isCurrentUserOwner,
                onMakeOffer: () => _handleMakeOffer(context),
                onChat: () => _handleChat(context),
                onCall: () => _handleCall(context, widget.ad),
              ),
              markedAsSold: (ad) => AdDetailBottomButtons(
                ad: ad,
                isCurrentUserOwner: _isCurrentUserOwner,
                onMakeOffer: () => _handleMakeOffer(context),
                onChat: () => _handleChat(context),
                onCall: () => _handleCall(context, ad),
              ),
              deleting: () => const SizedBox.shrink(),
              deleted: () => const SizedBox.shrink(),
            );
          },
        ),
      ),
    );
  }

  // Handle mark as sold action
  Future<void> _handleMarkAsSold(BuildContext context, AddModel ad) async {
    // Check authentication before allowing mark as sold
    final isAuthenticated = await AuthGuard.isAuthenticated();
    if (!isAuthenticated) {
      DialogUtil.showLoginPromptDialog(
        context,
        message: "Please login to mark this ad as sold.",
        redirectPath: '/add-detail-page',
      );
      return;
    }

    // Store the bloc reference before showing the dialog
    final adDetailBloc = context.read<AdDetailBloc>();

    final isIOS = !kIsWeb && Platform.isIOS;

    if (isIOS) {
      // iOS-friendly Cupertino dialog
      showCupertinoDialog(
        context: context,
        builder: (BuildContext dialogContext) {
          return CupertinoAlertDialog(
            title: Text(
              'Mark as Sold',
              style: TextStyle(
                fontSize: GetResponsiveSize.getResponsiveFontSize(context,
                    mobile: 20, tablet: 26, largeTablet: 30, desktop: 34),
                fontWeight: FontWeight.w700,
              ),
            ),
            content: Text(
              'Are you sure you want to mark this ad as sold? This action cannot be undone.',
              style: TextStyle(
                fontSize: GetResponsiveSize.getResponsiveFontSize(context,
                    mobile: 14, tablet: 18, largeTablet: 22, desktop: 26),
              ),
            ),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    fontSize: GetResponsiveSize.getResponsiveFontSize(context,
                        mobile: 14, tablet: 18, largeTablet: 22, desktop: 26),
                  ),
                ),
              ),
              CupertinoDialogAction(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  adDetailBloc.add(
                    AdDetailEvent.markAsSold(ad.id),
                  );
                },
                isDestructiveAction: false,
                child: Text(
                  'Mark as Sold',
                  style: TextStyle(
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.w700,
                    fontSize: GetResponsiveSize.getResponsiveFontSize(context,
                        mobile: 14, tablet: 18, largeTablet: 22, desktop: 26),
                  ),
                ),
              ),
            ],
          );
        },
      );
    } else {
      // Material Design dialog for Android/Web
      showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            titlePadding: EdgeInsets.fromLTRB(
              GetResponsiveSize.getResponsivePadding(context,
                  mobile: 24, tablet: 28, largeTablet: 32, desktop: 36),
              GetResponsiveSize.getResponsivePadding(context,
                  mobile: 24, tablet: 28, largeTablet: 32, desktop: 36),
              GetResponsiveSize.getResponsivePadding(context,
                  mobile: 0, tablet: 4, largeTablet: 8, desktop: 12),
              GetResponsiveSize.getResponsivePadding(context,
                  mobile: 16, tablet: 20, largeTablet: 24, desktop: 28),
            ),
            contentPadding: EdgeInsets.fromLTRB(
              GetResponsiveSize.getResponsivePadding(context,
                  mobile: 24, tablet: 28, largeTablet: 32, desktop: 36),
              0,
              GetResponsiveSize.getResponsivePadding(context,
                  mobile: 24, tablet: 28, largeTablet: 32, desktop: 36),
              GetResponsiveSize.getResponsivePadding(context,
                  mobile: 16, tablet: 20, largeTablet: 24, desktop: 28),
            ),
            actionsPadding: EdgeInsets.fromLTRB(
              GetResponsiveSize.getResponsivePadding(context,
                  mobile: 8, tablet: 12, largeTablet: 16, desktop: 20),
              0,
              GetResponsiveSize.getResponsivePadding(context,
                  mobile: 8, tablet: 12, largeTablet: 16, desktop: 20),
              GetResponsiveSize.getResponsivePadding(context,
                  mobile: 8, tablet: 12, largeTablet: 16, desktop: 20),
            ),
            title: Text(
              'Mark as Sold',
              style: TextStyle(
                fontSize: GetResponsiveSize.getResponsiveFontSize(context,
                    mobile: 20, tablet: 26, largeTablet: 30, desktop: 34),
                fontWeight: FontWeight.w700,
              ),
            ),
            content: Text(
              'Are you sure you want to mark this ad as sold? This action cannot be undone.',
              style: TextStyle(
                fontSize: GetResponsiveSize.getResponsiveFontSize(context,
                    mobile: 14, tablet: 18, largeTablet: 22, desktop: 26),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: GetResponsiveSize.getResponsivePadding(context,
                        mobile: 16, tablet: 20, largeTablet: 24, desktop: 28),
                    vertical: GetResponsiveSize.getResponsivePadding(context,
                        mobile: 8, tablet: 12, largeTablet: 16, desktop: 20),
                  ),
                ),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    fontSize: GetResponsiveSize.getResponsiveFontSize(context,
                        mobile: 14, tablet: 18, largeTablet: 22, desktop: 26),
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  adDetailBloc.add(
                    AdDetailEvent.markAsSold(ad.id),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  padding: EdgeInsets.symmetric(
                    horizontal: GetResponsiveSize.getResponsivePadding(context,
                        mobile: 16, tablet: 20, largeTablet: 24, desktop: 28),
                    vertical: GetResponsiveSize.getResponsivePadding(context,
                        mobile: 12, tablet: 16, largeTablet: 20, desktop: 24),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      GetResponsiveSize.getResponsiveBorderRadius(context,
                          mobile: 14, tablet: 16, largeTablet: 18, desktop: 20),
                    ),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Mark as Sold',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: GetResponsiveSize.getResponsiveFontSize(context,
                        mobile: 14, tablet: 18, largeTablet: 22, desktop: 26),
                  ),
                ),
              ),
            ],
          );
        },
      );
    }
  }

  // ======= Header (Carousel + overlay controls) =======
  Widget _headerCarousel(AddModel ad) {
    // Initialize hasVideo flag
    _hasVideo = ad.link != null && ad.link!.isNotEmpty;

    return Stack(
      children: [
        AspectRatio(
          aspectRatio: GetResponsiveSize.isTablet(context)
              ? GetResponsiveSize.getResponsiveSize(
                  context,
                  mobile: 16 / 10, // Not used since we check isTablet first
                  tablet: 20 / 10,
                  largeTablet: 20 / 10,
                  desktop: 22 / 10,
                )
              : 16 / 10, // Keep mobile unchanged
          child: CarouselSlider(
            carouselController: _carouselController,
            options: CarouselOptions(
              viewportFraction: 1,
              height: double.infinity,
              autoPlay: false, // Disable autoPlay, we'll handle it manually
              onPageChanged: (i, _) {
                setState(() => _currentIndex = i);
                _startAutoPlay(ad); // Restart auto-play for new item
              },
            ),
            items: _buildCarouselItems(ad),
          ),
        ),
        // floating top actions
        Positioned(
          top: 50,
          left: 12,
          right: 12,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AdDetailCircleIconButton(
                icon: (!kIsWeb && Platform.isIOS)
                    ? Icons.arrow_back_ios
                    : Icons.arrow_back,
                onTap: () => Navigator.of(context).maybePop(),
              ),
              Row(
                children: [
                  // Show edit icon only if current user is the owner of the ad
                  FutureBuilder<bool>(
                    future: _isCurrentUserOwner(ad),
                    builder: (context, snapshot) {
                      final isOwner = snapshot.data ?? false;
                      if (isOwner) {
                        return AdDetailCircleIconButton(
                          icon: Icons.edit,
                          onTap: () {
                            _goToEdit(context, ad);
                          },
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  // Add spacing only if edit icon is shown
                  FutureBuilder<bool>(
                    future: _isCurrentUserOwner(ad),
                    builder: (context, snapshot) {
                      final isOwner = snapshot.data ?? false;
                      return isOwner
                          ? const SizedBox(width: 8)
                          : const SizedBox.shrink();
                    },
                  ),
                  // Share icon - only show for non-owners in the top overlay
                  FutureBuilder<bool>(
                    future: _isCurrentUserOwner(ad),
                    builder: (context, snapshot) {
                      final isOwner = snapshot.data ?? false;
                      if (!isOwner) {
                        return AdDetailCircleIconButton(
                          icon: Icons.share,
                          onTap: () {
                            _shareAd(
                                ad); // Already async, no await needed for fire-and-forget
                          },
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  // Add spacing only if share icon is shown
                  FutureBuilder<bool>(
                    future: _isCurrentUserOwner(ad),
                    builder: (context, snapshot) {
                      final isOwner = snapshot.data ?? false;
                      return !isOwner
                          ? const SizedBox(width: 8)
                          : const SizedBox.shrink();
                    },
                  ),
                  AdDetailFavoriteButton(ad: ad),
                ],
              ),
            ],
          ),
        ),
        // bottom-left: verified-seller badge (top) + PREMIUM / FOR RENT /
        // FOR SALE tag (bottom). Verified trust signal sits over the gallery so
        // it registers before the buyer scrolls.
        Positioned(
          left: 12,
          bottom: 12,
          child: Builder(
            builder: (_) {
              final bool isVerified = ad.user?.isVerified == true;
              final bool isPremium = ad.manufacturer?.isPremium == true;
              final bool isRent =
                  (ad.listingType ?? '').toLowerCase() == 'rent';
              final String? tag = isPremium
                  ? 'PREMIUM'
                  : (ad.category == 'property'
                      ? (isRent ? 'FOR RENT' : 'FOR SALE')
                      : null);
              final List<Widget> children = [];
              if (isVerified) {
                children.add(_detailVerifiedBadge());
              }
              if (tag != null) {
                if (children.isNotEmpty) {
                  children.add(const SizedBox(height: 6));
                }
                children.add(_detailImgTag(
                  tag,
                  isPremium
                      ? const Color(0xFF4F48EC)
                      : Colors.black.withOpacity(0.6),
                ));
              }
              if (children.isEmpty) return const SizedBox.shrink();
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              );
            },
          ),
        ),
        // bottom-right: photo / item count
        if (_getTotalCarouselItems(ad) > 1)
          Positioned(
            right: 12,
            bottom: 12,
            child: _detailImgPill(
              Icons.photo_outlined,
              '${_currentIndex + 1}/${_getTotalCarouselItems(ad)}',
            ),
          ),
        // SOLD overlay
        if (ad.soldOut == true)
          Positioned.fill(
            child: Container(
              alignment: Alignment.center,
              color: Colors.black.withOpacity(0.35),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'SOLD',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _detailVerifiedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF19A463),
        borderRadius: BorderRadius.circular(5),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified, size: 12, color: Colors.white),
          SizedBox(width: 4),
          Text(
            'VERIFIED SELLER',
            style: TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailImgTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(5)),
      child: Text(
        text,
        style: const TextStyle(
            color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _detailImgPill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(5)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(text,
              style: const TextStyle(color: Colors.white, fontSize: 10)),
        ],
      ),
    );
  }

  int _getTotalCarouselItems(AddModel ad) {
    int count = ad.images.length;
    if (ad.link != null && ad.link!.isNotEmpty) {
      count += 1; // Add video
    }
    return count;
  }

  List<Widget> _buildCarouselItems(AddModel ad) {
    List<Widget> items = [];

    // Add video as first item if it exists
    if (ad.link != null && ad.link!.isNotEmpty) {
      final videoUrl = ad.link!.trim();
      if (videoUrl.isNotEmpty) {
        items.add(_buildVideoItem(videoUrl));
      }
    }

    // Add all images
    items.addAll(ad.images.map((img) => _buildImageItem(img, ad)));

    // Start auto-play after building items
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _startAutoPlay(ad);
      }
    });

    return items;
  }

  Widget _buildVideoItem(String videoUrl) {
    print('🎥 Building video item with URL: $videoUrl');
    // Store callback for video completion
    _onVideoCompleteCallbacks[videoUrl] = _onVideoComplete;
    return GestureDetector(
      onTap: () {
        print('🎥 Video tapped, opening full screen...');
        _openVideoFullScreen(context, videoUrl);
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.zero,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.zero,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Video player - wrapped to prevent it from intercepting taps
              AbsorbPointer(
                child: _VideoPlayerWidget(
                  key: ValueKey(videoUrl),
                  videoUrl: videoUrl,
                  onVideoComplete: _onVideoCompleteCallbacks[videoUrl],
                ),
              ),
              // Subtle gradient overlay that doesn't interfere with controls
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 60,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x66000000),
                        Color(0x00000000),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 60,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Color(0x66000000),
                        Color(0x00000000),
                      ],
                    ),
                  ),
                ),
              ),
              // Play button overlay to indicate video is tappable
              // This overlay is always on top and catches all taps
              Positioned.fill(
                child: GestureDetector(
                  onTap: () {
                    print('🎥 Video overlay tapped, opening full screen...');
                    _openVideoFullScreen(context, videoUrl);
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    color: Colors.transparent,
                    child: Center(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            print(
                                '🎥 Play button tapped, opening full screen...');
                            _openVideoFullScreen(context, videoUrl);
                          },
                          borderRadius: BorderRadius.circular(50),
                          child: Container(
                            padding: EdgeInsets.all(
                              GetResponsiveSize.getResponsiveSize(
                                context,
                                mobile: 12,
                                tablet: 16,
                                largeTablet: 18,
                                desktop: 20,
                              ),
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.play_arrow,
                              color: Colors.white,
                              size: GetResponsiveSize.getResponsiveSize(
                                context,
                                mobile: 40,
                                tablet: 56,
                                largeTablet: 64,
                                desktop: 72,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Opens a full-screen video player
  void _openVideoFullScreen(BuildContext context, String videoUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _VideoFullScreenViewer(
          videoUrl: videoUrl,
        ),
      ),
    );
  }

  Widget _buildImageItem(String img, AddModel ad) {
    return GestureDetector(
      onTap: () => _openImageGallery(context, ad, img),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.zero,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.zero,
                child: AppNetworkImage(url: img, fit: BoxFit.cover),
              )),
          // dark gradient overlay (top+bottom)
          Container(
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.zero,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x99000000),
                  Color(0x00000000),
                  Color(0xAA000000),
                ],
                stops: [0.0, 0.55, 1.0],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Opens a full-screen image gallery with zoom capabilities
  void _openImageGallery(
      BuildContext context, AddModel ad, String initialImage) {
    // Get all images (exclude video)
    final List<String> images = List<String>.from(ad.images);

    // Check if there are any images
    if (images.isEmpty) {
      return;
    }

    // Find the initial image index
    int initialIndex = images.indexOf(initialImage);
    if (initialIndex == -1) {
      initialIndex = 0;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _ImageGalleryViewer(
          images: images,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  Future<void> _goToEdit(BuildContext context, AddModel ad) async {
    // Check authentication before allowing edit
    final isAuthenticated = await AuthGuard.isAuthenticated();
    if (!isAuthenticated) {
      DialogUtil.showLoginPromptDialog(
        context,
        message: "Please login to edit this ad.",
        redirectPath: '/add-detail-page',
      );
      return;
    }

    final route = _editRouteFor(ad.category);
    if (route == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Editing not available for this category')),
      );
      return;
    }

    // Navigate and wait for result (edit page should: Navigator.pop(true) on success)
    final changed = await context.push<bool>(route, extra: ad);

    if (!context.mounted) return;
    if (changed == true) {
      // re-fetch detail to reflect saved changes
      context.read<AdDetailBloc>().add(AdDetailEvent.fetch(ad.id));
    }
  }

  String? _editRouteFor(String category) {
    switch (category) {
      case 'two_wheeler':
        return '/edit-two-wheeler';
      case 'private_vehicle':
        return '/edit-private-vehicle';
      case 'commercial_vehicle':
        return '/edit-commercial-vehicle';
      case 'property':
        return '/edit-property';
      default:
        return null;
    }
  }

  String _normalize(String s) => s
      .replaceAll(RegExp(r'[_\-]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  String toTitleCase(String? input) {
    if (input == null) return '';
    final s = _normalize(input.toLowerCase());
    if (s.isEmpty) return '';
    return s
        .split(' ')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  /// If you really want strict camelCase (no spaces), use this:
  String toCamelCase(String? input) {
    final t = toTitleCase(input).replaceAll(' ', '');
    if (t.isEmpty) return '';
    return '${t[0].toLowerCase()}${t.substring(1)}';
  }

  Widget _specsCard(AddModel ad) {
    if (ad.category == 'property') {
      // PROPERTY SPECS
      final items = <_Spec>[
        _Spec('Property Type', ad.propertyType ?? '-', icon: Icons.home_work),
        _Spec('Listing Type', toTitleCase(ad.listingType ?? '-'),
            icon: Icons.sell),
        _Spec('Bedrooms', ad.bedrooms != null ? '${ad.bedrooms} Beds' : '-',
            icon: Icons.bed),
        _Spec('Bathrooms', ad.bathrooms != null ? '${ad.bathrooms} Baths' : '-',
            icon: Icons.bathtub),
        _Spec('Area', ad.areaSqft != null ? '${ad.areaSqft} sqft' : '-',
            icon: Icons.square_foot),
        _Spec('Floor', ad.floor != null ? 'Floor ${ad.floor}' : '-',
            icon: Icons.apartment),
        _Spec('Furnished',
            ad.isFurnished == true ? 'Furnished' : 'Unfurnished',
            icon: Icons.chair_alt),
        _Spec('Parking', ad.hasParking == true ? 'Parking' : 'No Parking',
            icon: Icons.local_parking),
        _Spec('Garden', ad.hasGarden == true ? 'Garden' : 'No Garden',
            icon: Icons.park),
      ];

      return _specChips(items, amenities: ad.amenities);
    }

    // VEHICLE SPECS (default)
    final items = <_Spec>[
      _Spec(
          'Brand Name',
          toTitleCase(
              ad.manufacturer?.displayName ?? ad.manufacturer?.name ?? '-'),
          icon: Icons.factory_outlined),
      _Spec('Model Name',
          toTitleCase(ad.model?.displayName ?? ad.model?.name ?? '-'),
          icon: Icons.directions_car),
      _Spec('Transmission', ad.transmission ?? '-', icon: Icons.settings),
      _Spec('Fuel Type', ad.fuelType ?? '-', icon: Icons.local_gas_station),
      _Spec(
          'Registration Year',
          (ad.year != null && ad.year != 0) ? '${ad.year}' : '-',
          icon: Icons.calendar_today),
      _Spec('Mileage', (ad.mileage != null) ? '${ad.mileage} Kmpl' : '-',
          icon: Icons.speed),
      if (ad.isFirstOwner != null)
        _Spec('Owner', ad.isFirstOwner == true ? '1st owner' : '2nd+ owner',
            icon: Icons.person_outline),
    ];

    return _specChips(items);
  }

  // Compact spec chips (year · km · fuel · transmission · owner) to match the
  // ad-detail wireframe. Unknown values ('-') are filtered out.
  Widget _specChips(List<_Spec> items, {List<String>? amenities}) {
    final visible = items
        .where((s) => s.value.trim().isNotEmpty && s.value.trim() != '-')
        .toList();
    final amenityList = (amenities ?? [])
        .where((a) => a.trim().isNotEmpty)
        .toList();
    if (visible.isEmpty && amenityList.isEmpty) return const SizedBox.shrink();
    final gap = GetResponsiveSize.getResponsiveSize(context,
        mobile: 12, tablet: 16, largeTablet: 18, desktop: 20);
    final chipSpacing = GetResponsiveSize.getResponsiveSize(context,
        mobile: 8, tablet: 12, largeTablet: 14, desktop: 16);
    Widget header(String text) => Text(
          text,
          style: TextStyle(
            fontSize: GetResponsiveSize.getResponsiveFontSize(context,
                mobile: 15, tablet: 22, largeTablet: 26, desktop: 30),
            fontWeight: FontWeight.w700,
            color: AppColors.blackColor,
          ),
        );
    return _cardShell(
      child: Padding(
        padding: EdgeInsets.all(
          GetResponsiveSize.getResponsivePadding(context,
              mobile: 12, tablet: 16, largeTablet: 20, desktop: 24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (visible.isNotEmpty) ...[
              header('Key specs'),
              SizedBox(height: gap),
              Wrap(
                spacing: chipSpacing,
                runSpacing: chipSpacing,
                children: visible.map(_specChip).toList(),
              ),
            ],
            if (amenityList.isNotEmpty) ...[
              SizedBox(height: visible.isNotEmpty ? gap + 6 : 0),
              header('Amenities'),
              SizedBox(height: gap),
              Wrap(
                spacing: chipSpacing,
                runSpacing: chipSpacing,
                children: amenityList
                    .map((a) => _specChip(
                        _Spec('', toTitleCase(a), icon: Icons.check_circle_outline)))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _specChip(_Spec s) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: GetResponsiveSize.getResponsiveSize(context,
            mobile: 10, tablet: 14, largeTablet: 16, desktop: 18),
        vertical: GetResponsiveSize.getResponsiveSize(context,
            mobile: 7, tablet: 10, largeTablet: 12, desktop: 14),
      ),
      decoration: BoxDecoration(
        color: AppColors.isDark
            ? Colors.white.withOpacity(0.06)
            : const Color(0xFFF4F6FA),
        border: Border.all(color: AppColors.dividerColor, width: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            s.icon,
            size: GetResponsiveSize.getResponsiveSize(context,
                mobile: 14, tablet: 20, largeTablet: 24, desktop: 28),
            color: AppColors.greyColor,
          ),
          SizedBox(
              width: GetResponsiveSize.getResponsiveSize(context,
                  mobile: 5, tablet: 8, largeTablet: 10, desktop: 12)),
          Text(
            s.value,
            style: TextStyle(
              fontSize: GetResponsiveSize.getResponsiveFontSize(context,
                  mobile: 12, tablet: 18, largeTablet: 22, desktop: 26),
              fontWeight: FontWeight.w500,
              color: AppColors.blackColor,
            ),
          ),
        ],
      ),
    );
  }

  // Owner-only actions (Mark as Sold + Delete). Restored after the tabbed
  // "Other Details" section was replaced by the spec chips.
  Widget _ownerActionsCard(AddModel ad) {
    return FutureBuilder<bool>(
      future: _isCurrentUserOwner(ad),
      builder: (context, snapshot) {
        final isOwner = snapshot.data ?? false;
        if (!isOwner) return const SizedBox.shrink();
        return Padding(
          padding: EdgeInsets.fromLTRB(
            GetResponsiveSize.getResponsivePadding(context,
                mobile: 16, tablet: 20, largeTablet: 24, desktop: 28),
            GetResponsiveSize.getResponsivePadding(context,
                mobile: 12, tablet: 16, largeTablet: 20, desktop: 24),
            GetResponsiveSize.getResponsivePadding(context,
                mobile: 16, tablet: 20, largeTablet: 24, desktop: 28),
            0,
          ),
          child: _cardShell(
            child: Padding(
              padding: EdgeInsets.all(
                GetResponsiveSize.getResponsivePadding(context,
                    mobile: 12, tablet: 16, largeTablet: 20, desktop: 24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AdDetailMarkAsSoldButton(ad: ad),
                  SizedBox(
                      height: GetResponsiveSize.getResponsiveSize(context,
                          mobile: 10,
                          tablet: 12,
                          largeTablet: 14,
                          desktop: 16)),
                  SizedBox(
                    width: double.infinity,
                    height: GetResponsiveSize.getResponsiveSize(context,
                        mobile: 44, tablet: 65, largeTablet: 75, desktop: 85),
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.redColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            GetResponsiveSize.getResponsiveBorderRadius(context,
                                mobile: 12,
                                tablet: 14,
                                largeTablet: 16,
                                desktop: 18),
                          ),
                        ),
                      ),
                      onPressed: () => _showDeleteConfirmDialog(context, ad),
                      icon: Icon(Icons.delete_outline,
                          color: AppColors.redColor,
                          size: GetResponsiveSize.getResponsiveSize(context,
                              mobile: 18,
                              tablet: 26,
                              largeTablet: 30,
                              desktop: 34)),
                      label: Text(
                        'Delete Advertisement',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.redColor,
                          fontSize: GetResponsiveSize.getResponsiveFontSize(
                              context,
                              mobile: 14,
                              tablet: 22,
                              largeTablet: 26,
                              desktop: 30),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, AddModel ad) {
    final bloc = context.read<AdDetailBloc>();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Advertisement',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text(
            'Are you sure you want to delete this advertisement? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              bloc.add(AdDetailEvent.deleteAd(ad.id));
            },
            child: Text('Delete',
                style: TextStyle(
                    color: AppColors.redColor, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _otherDetailsCard(AddModel ad) {
    final sellerName = (ad.user?.name ?? '').trim();
    final sellerEmail = (ad.user?.email ?? '').trim();
    return _cardShell(
      child: Padding(
        padding: EdgeInsets.all(
          GetResponsiveSize.getResponsivePadding(context,
              mobile: 10, tablet: 20, largeTablet: 24, desktop: 28),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (sellerName.isNotEmpty) ...[
              Text('Seller Information',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: GetResponsiveSize.getResponsiveFontSize(context,
                        mobile: 16, tablet: 24, largeTablet: 28, desktop: 32),
                  )),
              SizedBox(
                  height: GetResponsiveSize.getResponsiveSize(context,
                      mobile: 10, tablet: 12, largeTablet: 14, desktop: 16)),
              _KeyValRow(label: 'Name', value: sellerName),
              if (sellerEmail.isNotEmpty) ...[
                SizedBox(
                    height: GetResponsiveSize.getResponsiveSize(context,
                        mobile: 8, tablet: 10, largeTablet: 12, desktop: 14)),
                _KeyValRow(label: 'Email', value: sellerEmail),
              ],
              SizedBox(
                  height: GetResponsiveSize.getResponsiveSize(context,
                      mobile: 10, tablet: 20, largeTablet: 24, desktop: 28)),
            ],
            Text('Ad Details',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: GetResponsiveSize.getResponsiveFontSize(context,
                      mobile: 16, tablet: 24, largeTablet: 28, desktop: 32),
                )),
            SizedBox(
                height: GetResponsiveSize.getResponsiveSize(context,
                    mobile: 10, tablet: 12, largeTablet: 14, desktop: 16)),
            _KeyValRow(label: 'Location', value: ad.location),
            SizedBox(
                height: GetResponsiveSize.getResponsiveSize(context,
                    mobile: 8, tablet: 10, largeTablet: 12, desktop: 14)),
            _KeyValRow(label: 'Category', value: toTitleCase(ad.category)),
            SizedBox(
                height: GetResponsiveSize.getResponsiveSize(context,
                    mobile: 8, tablet: 10, largeTablet: 12, desktop: 14)),
            _KeyValRow(label: 'Posted On', value: _niceDate(ad.postedAt!)),
            SizedBox(
                height: GetResponsiveSize.getResponsiveSize(context,
                    mobile: 8, tablet: 24, largeTablet: 32, desktop: 40)),
            // Mark as Sold and Delete Advertisement buttons for ad owners
            FutureBuilder<bool>(
              future: _isCurrentUserOwner(ad),
              builder: (context, snapshot) {
                final isOwner = snapshot.data ?? false;
                if (isOwner) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AdDetailMarkAsSoldButton(ad: ad),
                      SizedBox(
                          height: GetResponsiveSize.getResponsiveSize(context,
                              mobile: 10, tablet: 12, largeTablet: 14, desktop: 16)),
                      SizedBox(
                        width: double.infinity,
                        height: GetResponsiveSize.getResponsiveSize(context,
                            mobile: 44, tablet: 65, largeTablet: 75, desktop: 85),
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: AppColors.redColor,
                              width: GetResponsiveSize.getResponsiveSize(context,
                                  mobile: 1, tablet: 1.5, largeTablet: 2, desktop: 2.5),
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: GetResponsiveSize.getResponsivePadding(context,
                                  mobile: 12, tablet: 20, largeTablet: 24, desktop: 28),
                              vertical: GetResponsiveSize.getResponsivePadding(context,
                                  mobile: 6, tablet: 16, largeTablet: 20, desktop: 24),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                GetResponsiveSize.getResponsiveBorderRadius(context,
                                    mobile: 12, tablet: 14, largeTablet: 16, desktop: 18),
                              ),
                            ),
                          ),
                          onPressed: () {
                            // TODO: wire delete action (dialog + API)
                          },
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.delete_outline,
                                  color: AppColors.redColor,
                                  size: GetResponsiveSize.getResponsiveSize(context,
                                      mobile: 18,
                                      tablet: 26,
                                      largeTablet: 30,
                                      desktop: 34),
                                ),
                                SizedBox(
                                    width: GetResponsiveSize.getResponsiveSize(context,
                                        mobile: 6,
                                        tablet: 10,
                                        largeTablet: 12,
                                        desktop: 14)),
                                Text(
                                  'Delete Advertisement',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.redColor,
                                    fontSize: GetResponsiveSize.getResponsiveFontSize(
                                        context,
                                        mobile: 14,
                                        tablet: 22,
                                        largeTablet: 26,
                                        desktop: 30),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            SizedBox(
                height: GetResponsiveSize.getResponsiveSize(context,
                    mobile: 0, tablet: 8, largeTablet: 12, desktop: 16)),
          ],
        ),
      ),
    );
  }

  // ======= Description =======
  Widget _description(AddModel ad) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        GetResponsiveSize.getResponsivePadding(context,
            mobile: 16, tablet: 20, largeTablet: 24, desktop: 28),
        GetResponsiveSize.getResponsivePadding(context,
            mobile: 8, tablet: 10, largeTablet: 12, desktop: 14),
        GetResponsiveSize.getResponsivePadding(context,
            mobile: 16, tablet: 20, largeTablet: 24, desktop: 28),
        0,
      ),
      child: _cardShell(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: GetResponsiveSize.getResponsivePadding(context,
                mobile: 16, tablet: 20, largeTablet: 24, desktop: 28),
            vertical: GetResponsiveSize.getResponsivePadding(context,
                mobile: 10, tablet: 14, largeTablet: 18, desktop: 22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Description',
                style: TextStyle(
                  color: const Color(0xFF6B7280),
                  fontSize: GetResponsiveSize.getResponsiveFontSize(context,
                      mobile: 14, tablet: 22, largeTablet: 26, desktop: 30),
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(
                  height: GetResponsiveSize.getResponsiveSize(context,
                      mobile: 10, tablet: 12, largeTablet: 14, desktop: 16)),
              Text(
                ad.description,
                style: TextStyle(
                  color: Colors.black,
                  height: 1.35,
                  fontSize: GetResponsiveSize.getResponsiveFontSize(context,
                      mobile: 14, tablet: 22, largeTablet: 26, desktop: 30),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ======= Report Ad Button =======
  Widget _reportAdButton(AddModel ad) {
    return FutureBuilder<bool>(
      future: _isCurrentUserOwner(ad),
      builder: (context, snapshot) {
        final isOwner = snapshot.data ?? false;

        // Only show report button for other users' ads
        if (isOwner) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: EdgeInsets.fromLTRB(
            GetResponsiveSize.getResponsivePadding(context,
                mobile: 16, tablet: 20, largeTablet: 24, desktop: 28),
            GetResponsiveSize.getResponsivePadding(context,
                mobile: 8, tablet: 10, largeTablet: 12, desktop: 14),
            GetResponsiveSize.getResponsivePadding(context,
                mobile: 16, tablet: 20, largeTablet: 24, desktop: 28),
            0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => _showReportDialog(context, ad),
                icon: Icon(
                  Icons.report_problem,
                  size: GetResponsiveSize.getResponsiveSize(context,
                      mobile: 18, tablet: 25, largeTablet: 29, desktop: 33),
                  color: Colors.red.shade600,
                ),
                label: Text(
                  'Report Ad',
                  style: TextStyle(
                    color: Colors.red.shade600,
                    fontWeight: FontWeight.w600,
                    fontSize: GetResponsiveSize.getResponsiveFontSize(context,
                        mobile: 14, tablet: 22, largeTablet: 25, desktop: 30),
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: GetResponsiveSize.getResponsivePadding(context,
                        mobile: 12, tablet: 16, largeTablet: 20, desktop: 24),
                    vertical: GetResponsiveSize.getResponsivePadding(context,
                        mobile: 8, tablet: 10, largeTablet: 12, desktop: 14),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Show report dialog
  void _showReportDialog(BuildContext context, AddModel ad) {
    final reportedUserId = ad.user?.id;
    if (reportedUserId == null || reportedUserId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Unable to report: User information not available',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red.shade300.withOpacity(0.9),
        ),
      );
      return;
    }

    if (!kIsWeb && Platform.isIOS) {
      showCupertinoDialog(
        context: context,
        builder: (context) => ReportAdDialog(
          reportedUserId: reportedUserId,
          adId: ad.id,
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => ReportAdDialog(
          reportedUserId: reportedUserId,
          adId: ad.id,
        ),
      );
    }
  }

  // ======= Seller Tile =======
  Widget _sellerTile(AddModel ad) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        GetResponsiveSize.getResponsivePadding(context,
            mobile: 16, tablet: 20, largeTablet: 24, desktop: 28),
        GetResponsiveSize.getResponsivePadding(context,
            mobile: 12, tablet: 16, largeTablet: 20, desktop: 24),
        GetResponsiveSize.getResponsivePadding(context,
            mobile: 16, tablet: 20, largeTablet: 24, desktop: 28),
        0,
      ),
      child: _cardShell(
        child: ListTile(
          leading: CircleAvatar(
            radius: GetResponsiveSize.getResponsiveSize(context,
                mobile: 24, tablet: 32, largeTablet: 38, desktop: 44),
            backgroundColor: AppColors.scaffoldBackground,
            backgroundImage: ad.user?.profilePic?.trim().isNotEmpty == true
                ? NetworkImage(ad.user!.profilePic!)
                : null,
            child: ad.user?.profilePic?.trim().isNotEmpty == true
                ? null
                : Icon(Icons.person, color: AppColors.greyColor),
          ),
          title: Text(
            ad.user?.name?.trim().isNotEmpty == true
                ? ad.user!.name!
                : 'Seller',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: GetResponsiveSize.getResponsiveFontSize(context,
                  mobile: 16, tablet: 24, largeTablet: 28, desktop: 32),
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (ad.user?.email?.trim().isNotEmpty == true)
                Text(
                  ad.user!.email!,
                  style: TextStyle(
                    fontSize: GetResponsiveSize.getResponsiveFontSize(context,
                        mobile: 14, tablet: 20, largeTablet: 24, desktop: 28),
                  ),
                ),
              if (ad.user?.phone?.trim().isNotEmpty == true)
                Text(
                  ad.user!.phone!,
                  style: TextStyle(
                    fontSize: GetResponsiveSize.getResponsiveFontSize(context,
                        mobile: 14, tablet: 20, largeTablet: 24, desktop: 28),
                  ),
                ),
              Text(
                ad.location,
                style: TextStyle(
                  fontSize: GetResponsiveSize.getResponsiveFontSize(context,
                      mobile: 14, tablet: 20, largeTablet: 24, desktop: 28),
                ),
              ),
            ],
          ),
          trailing: Icon(
            Icons.chevron_right,
            size: GetResponsiveSize.getResponsiveSize(context,
                mobile: 24, tablet: 28, largeTablet: 32, desktop: 36),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: GetResponsiveSize.getResponsivePadding(context,
                mobile: 16, tablet: 20, largeTablet: 24, desktop: 28),
            vertical: GetResponsiveSize.getResponsivePadding(context,
                mobile: 8, tablet: 12, largeTablet: 16, desktop: 20),
          ),
          onTap: () {
            final sellerId = ad.user?.id;
            if (sellerId != null && sellerId.isNotEmpty && ad.user != null) {
              context.push('/seller-profile/$sellerId', extra: ad.user);
            }
          },
        ),
      ),
    );
  }

  // ======= Small helpers =======
  // Share button for ad owners - positioned above price section on the right side
  Widget _buildOwnerShareButton(AddModel ad) {
    return FutureBuilder<bool>(
      future: _isCurrentUserOwner(ad),
      builder: (context, snapshot) {
        final isOwner = snapshot.data ?? false;

        if (!isOwner) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: EdgeInsets.fromLTRB(
            GetResponsiveSize.getResponsivePadding(context,
                mobile: 16, tablet: 20, largeTablet: 24, desktop: 28),
            GetResponsiveSize.getResponsivePadding(context,
                mobile: 8, tablet: 10, largeTablet: 12, desktop: 14),
            GetResponsiveSize.getResponsivePadding(context,
                mobile: 16, tablet: 20, largeTablet: 24, desktop: 28),
            0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              InkWell(
                onTap: () => _shareAd(ad),
                child: Icon(
                  Icons.share,
                  color: AppColors.primaryColor,
                  size: GetResponsiveSize.getResponsiveSize(context,
                      mobile: 24, tablet: 30, largeTablet: 36, desktop: 42),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFavoriteButton(AddModel ad) {
    return BlocBuilder<FavoriteBloc, FavoriteState>(
      builder: (context, state) {
        bool isFavorited = ad.isFavorited ?? false;

        // Check if this ad is currently being toggled
        if (state is FavoriteToggleLoading && state.adId == ad.id) {
          return Container(
            height: GetResponsiveSize.getResponsiveSize(
              context,
              mobile: 36,
              tablet: 48,
              largeTablet: 56,
              desktop: 64,
            ),
            width: GetResponsiveSize.getResponsiveSize(
              context,
              mobile: 36,
              tablet: 48,
              largeTablet: 56,
              desktop: 64,
            ),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.35),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: SizedBox(
                width: GetResponsiveSize.getResponsiveSize(
                  context,
                  mobile: 16,
                  tablet: 20,
                  largeTablet: 24,
                  desktop: 28,
                ),
                height: GetResponsiveSize.getResponsiveSize(
                  context,
                  mobile: 16,
                  tablet: 20,
                  largeTablet: 24,
                  desktop: 28,
                ),
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
          );
        }

        // Update the favorite status if we have a toggle success state for this ad
        if (state is FavoriteToggleSuccess && state.adId == ad.id) {
          isFavorited = state.isFavorited;
        }

        return InkWell(
          onTap: () {
            context.read<FavoriteBloc>().add(
                  FavoriteEvent.toggleFavorite(
                    adId: ad.id,
                    isCurrentlyFavorited: isFavorited,
                  ),
                );
          },
          child: Container(
            height: GetResponsiveSize.getResponsiveSize(
              context,
              mobile: 36,
              tablet: 48,
              largeTablet: 56,
              desktop: 64,
            ),
            width: GetResponsiveSize.getResponsiveSize(
              context,
              mobile: 36,
              tablet: 48,
              largeTablet: 56,
              desktop: 64,
            ),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.35),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: SizedBox(
                width: GetResponsiveSize.getResponsiveSize(
                  context,
                  mobile: 18,
                  tablet: 20,
                  largeTablet: 24,
                  desktop: 28,
                ),
                height: GetResponsiveSize.getResponsiveSize(
                  context,
                  mobile: 18,
                  tablet: 20,
                  largeTablet: 24,
                  desktop: 28,
                ),
                child: Image.asset(
                  isFavorited
                      ? 'assets/images/heart-3-fill.png'
                      : 'assets/images/heart-3-line.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _circleIconButton(IconData icon, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: GetResponsiveSize.getResponsiveSize(
          context,
          mobile: 36, // Keep mobile unchanged
          tablet: 48,
          largeTablet: 56,
          desktop: 64,
        ),
        width: GetResponsiveSize.getResponsiveSize(
          context,
          mobile: 36, // Keep mobile unchanged
          tablet: 48,
          largeTablet: 56,
          desktop: 64,
        ),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.35),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: GetResponsiveSize.getResponsiveSize(
            context,
            mobile: 20, // Keep mobile unchanged
            tablet: 26,
            largeTablet: 30,
            desktop: 34,
          ),
        ),
      ),
    );
  }

  Future<void> _handleMakeOffer(BuildContext context) async {
    // Check authentication before allowing make offer
    final isAuthenticated = await AuthGuard.isAuthenticated();
    if (!isAuthenticated) {
      DialogUtil.showLoginPromptDialog(
        context,
        message: "Please login to make an offer on this ad.",
        redirectPath: '/add-detail-page',
      );
      return;
    }

    // Get the ad from the current state
    final state = context.read<AdDetailBloc>().state;
    state.when(
      initial: () {},
      loading: () {},
      error: (message) {},
      loaded: (ad) {
        // Show the offer popup
        OfferService.showOfferPopup(
          context: context,
          adId: ad.id,
          adTitle: ad.description.isNotEmpty ? ad.description : 'Untitled Ad',
          adPosterName: ad.user?.name ?? 'Unknown Seller',
          otherUserId: ad.user?.id ?? '',
        );
      },
      markingAsSold: () {},
      markedAsSold: (ad) {
        OfferService.showOfferPopup(
          context: context,
          adId: ad.id,
          adTitle: ad.description.isNotEmpty ? ad.description : 'Untitled Ad',
          adPosterName: ad.user?.name ?? 'Unknown Seller',
          otherUserId: ad.user?.id ?? '',
        );
      },
      deleting: () {},
      deleted: () {},
    );
  }

  // Place a phone call to the seller using the device dialer.
  Future<void> _handleCall(BuildContext context, AddModel ad) async {
    final rawPhone = ad.user?.phone?.trim() ?? '';
    if (rawPhone.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: rawPhone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open phone app')),
      );
    }
  }

  Future<void> _handleChat(BuildContext context) async {
    // Check authentication before allowing chat
    final isAuthenticated = await AuthGuard.isAuthenticated();
    if (!isAuthenticated) {
      DialogUtil.showLoginPromptDialog(
        context,
        message: "Please login to chat with the seller.",
        redirectPath: '/add-detail-page',
      );
      return;
    }

    // Get the ad from the current state
    final state = context.read<AdDetailBloc>().state;
    state.when(
      initial: () {},
      loading: () {},
      error: (message) {},
      loaded: (ad) {
        // Start direct chat
        ChatService.startDirectChat(
          context: context,
          adId: ad.id,
          adTitle: ad.description.isNotEmpty ? ad.description : 'Untitled Ad',
          adPosterName: ad.user?.name ?? 'Unknown Seller',
          otherUserId: ad.user?.id ?? '',
        );
      },
      markingAsSold: () {},
      markedAsSold: (ad) {
        ChatService.startDirectChat(
          context: context,
          adId: ad.id,
          adTitle: ad.description.isNotEmpty ? ad.description : 'Untitled Ad',
          adPosterName: ad.user?.name ?? 'Unknown Seller',
          otherUserId: ad.user?.id ?? '',
        );
      },
      deleting: () {},
      deleted: () {},
    );
  }

  Widget _makeOfferBtn(String label, {required VoidCallback onTap}) {
    return SizedBox(
      height: GetResponsiveSize.getResponsiveSize(context,
          mobile: 48, tablet: 65, largeTablet: 75, desktop: 85),
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: AppColors.primaryColor,
            width: GetResponsiveSize.getResponsiveSize(context,
                mobile: 1, tablet: 1.5, largeTablet: 2, desktop: 2.5),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: GetResponsiveSize.getResponsivePadding(context,
                mobile: 16, tablet: 20, largeTablet: 24, desktop: 28),
            vertical: GetResponsiveSize.getResponsivePadding(context,
                mobile: 12, tablet: 16, largeTablet: 20, desktop: 24),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              GetResponsiveSize.getResponsiveBorderRadius(context,
                  mobile: 14, tablet: 16, largeTablet: 18, desktop: 20),
            ),
          ),
        ),
        onPressed: onTap,
        child: Text(
          label,
          style: TextStyle(
            color: AppColors.primaryColor,
            fontWeight: FontWeight.w700,
            fontSize: GetResponsiveSize.getResponsiveFontSize(context,
                mobile: 16, tablet: 22, largeTablet: 26, desktop: 30),
          ),
        ),
      ),
    );
  }

  Widget _chatBtn(String label, {required VoidCallback onTap}) {
    return SizedBox(
      height: GetResponsiveSize.getResponsiveSize(context,
          mobile: 48, tablet: 65, largeTablet: 75, desktop: 85),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryColor,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(
            horizontal: GetResponsiveSize.getResponsivePadding(context,
                mobile: 16, tablet: 20, largeTablet: 24, desktop: 28),
            vertical: GetResponsiveSize.getResponsivePadding(context,
                mobile: 12, tablet: 16, largeTablet: 20, desktop: 24),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              GetResponsiveSize.getResponsiveBorderRadius(context,
                  mobile: 14, tablet: 16, largeTablet: 18, desktop: 20),
            ),
          ),
        ),
        onPressed: onTap,
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: GetResponsiveSize.getResponsiveFontSize(context,
                mobile: 16, tablet: 22, largeTablet: 26, desktop: 30),
          ),
        ),
      ),
    );
  }

  Widget _cardShell({required Widget child}) {
    return Container(
      margin: EdgeInsets.only(
        bottom: GetResponsiveSize.getResponsiveSize(context,
            mobile: 8, tablet: 10, largeTablet: 12, desktop: 14),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          GetResponsiveSize.getResponsiveBorderRadius(context,
              mobile: 14, tablet: 16, largeTablet: 18, desktop: 20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: GetResponsiveSize.getResponsiveSize(context,
                mobile: 10, tablet: 12, largeTablet: 14, desktop: 16),
            offset: Offset(
              0,
              GetResponsiveSize.getResponsiveSize(context,
                  mobile: 4, tablet: 5, largeTablet: 6, desktop: 7),
            ),
          ),
        ],
      ),
      child: child,
    );
  }

  // String _vehicleTitle(AddModel ad) {
  //   // e.g. "Hyundai i20 (2020), Magna"
  //   final brand = ad.manufacturer ?? '';
  //   final model = ad.model ?? '';
  //   final variant = ad.variant != null ? ', ${ad.variant}' : '';
  //   final year = ad.year != null ? ' (${ad.year})' : '';
  //   return '${brand.isNotEmpty ? brand : ''} ${model.isNotEmpty ? model : ''}$year$variant'
  //       .trim();
  // }

  String _niceDate(String iso) {
    // expects your ad.updatedAt string; fallback
    try {
      final dt = DateTime.tryParse(iso) ?? DateTime.now();
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return iso;
    }
  }
}

/// "Similar near you" — fetches ads of the same category and shows a compact
/// horizontal rail. Reuses the existing list endpoint (no backend changes).
class _SimilarAdsSection extends StatefulWidget {
  final AddModel ad;
  const _SimilarAdsSection({required this.ad});

  @override
  State<_SimilarAdsSection> createState() => _SimilarAdsSectionState();
}

class _SimilarAdsSectionState extends State<_SimilarAdsSection> {
  final AddRepository _repo = AddRepository();
  List<AddModel> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    double? lat, lng;
    try {
      final permission = await Geolocator.checkPermission();
      if (permission != LocationPermission.denied &&
          permission != LocationPermission.deniedForever) {
        final pos = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.low,
            timeLimit: const Duration(seconds: 5));
        lat = pos.latitude;
        lng = pos.longitude;
      }
    } catch (_) {}

    try {
      final res = await _repo.fetchAllAds(
        category: widget.ad.category,
        limit: 12,
        latitude: lat,
        longitude: lng,
      );
      final filtered =
          res.data.where((a) => a.id != widget.ad.id).take(10).toList();
      if (!mounted) return;
      setState(() {
        _items = filtered;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _items.isEmpty) return const SizedBox.shrink();
    final cardH = richAdCardMainAxisExtent(
      context,
      columns: 1,
      horizontalPadding: (MediaQuery.of(context).size.width - 190) / 2,
      spacing: 0,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Similar near you',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.blackColor,
                ),
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => context.push('/search?from=ad-detail'),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'See all',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryColor,
                      ),
                    ),
                    Icon(Icons.chevron_right,
                        size: 18, color: AppColors.primaryColor),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: cardH,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) => SizedBox(
              width: 190,
              height: cardH,
              child: RichAdCard(ad: _items[i]),
            ),
          ),
        ),
      ],
    );
  }

}

class _Spec {
  final String label;
  final String value;
  final IconData icon;
  const _Spec(this.label, this.value, {required this.icon});
}

class _KeyValRow extends StatelessWidget {
  final String label;
  final String value;
  const _KeyValRow({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
            width: GetResponsiveSize.getResponsiveSize(context,
                mobile: 110, tablet: 140, largeTablet: 170, desktop: 200),
            child: Text(
              label,
              style: TextStyle(
                fontSize: GetResponsiveSize.getResponsiveFontSize(context,
                    mobile: 12, tablet: 18, largeTablet: 22, desktop: 26),
                color: const Color(0xFF6B7280),
              ),
            )),
        SizedBox(
            width: GetResponsiveSize.getResponsiveSize(context,
                mobile: 8, tablet: 12, largeTablet: 16, desktop: 20)),
        Expanded(
            child: Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: GetResponsiveSize.getResponsiveFontSize(context,
                mobile: 13, tablet: 20, largeTablet: 24, desktop: 28),
          ),
        )),
      ],
    );
  }
}

class _VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  final VoidCallback? onVideoComplete;

  const _VideoPlayerWidget({
    super.key,
    required this.videoUrl,
    this.onVideoComplete,
  });

  @override
  State<_VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<_VideoPlayerWidget> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _isInitialized = false;
  bool _hasError = false;
  String? _errorMessage;
  bool _isLoading = true;
  bool _hasCalledCompletion = false; // Prevent multiple callback calls

  @override
  void initState() {
    super.initState();
    print(
        '🎥 _VideoPlayerWidget initState called with URL: ${widget.videoUrl}');
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      print('🎥 Initializing video: ${widget.videoUrl}');

      // Validate URL
      if (widget.videoUrl.isEmpty) {
        throw Exception('Video URL is empty');
      }

      // Clean and validate URL
      String cleanUrl = widget.videoUrl.trim();
      if (!cleanUrl.startsWith('http://') && !cleanUrl.startsWith('https://')) {
        cleanUrl = 'https://$cleanUrl';
      }

      final uri = Uri.parse(cleanUrl);
      if (!uri.hasScheme || (!uri.scheme.startsWith('http'))) {
        throw Exception('Invalid video URL format: $cleanUrl');
      }

      print('🎥 Creating VideoPlayerController with URI: $uri');

      // Skip URL accessibility test as it often fails unnecessarily
      // and video player can handle network issues better
      print(
          '🎥 Skipping URL accessibility test - proceeding with video initialization');

      _videoPlayerController = VideoPlayerController.networkUrl(uri);

      // Add listener to update UI when video state changes
      _videoPlayerController!.addListener(_videoListener);

      print('🎥 Starting video initialization...');

      // Add timeout to video initialization
      await _videoPlayerController!.initialize().timeout(
        const Duration(seconds: 15), // Reduced timeout
        onTimeout: () {
          throw Exception('Video initialization timeout after 15 seconds');
        },
      );

      print('🎥 Video initialized successfully');
      print('🎥 Video duration: ${_videoPlayerController!.value.duration}');
      print('🎥 Video size: ${_videoPlayerController!.value.size}');
      print(
          '🎥 Video aspect ratio: ${_videoPlayerController!.value.aspectRatio}');

      // Initialize Chewie controller with proper controls
      // Disable auto-play in carousel - user will tap to open full screen
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: false, // Disable autoplay - user taps to open full screen
        looping: false,
        allowPlaybackSpeedChanging: false, // Disable in carousel
        allowMuting: false, // Disable sound controls
        showControls:
            false, // Hide controls in carousel - show play button overlay instead
        showOptions: false, // Disable options in carousel
        allowFullScreen: false, // Disable fullscreen
        startAt: Duration.zero, // Start from beginning
        materialProgressColors: ChewieProgressColors(
          playedColor: AppColors.primaryColor,
          handleColor: Colors.white,
          backgroundColor: Colors.grey.withOpacity(0.3),
          bufferedColor: Colors.lightBlueAccent.withOpacity(0.3),
        ),
        cupertinoProgressColors: ChewieProgressColors(
          playedColor: AppColors.primaryColor,
          handleColor: Colors.white,
          backgroundColor: Colors.grey.withOpacity(0.3),
          bufferedColor: Colors.lightBlueAccent.withOpacity(0.3),
        ),
        // Keep controls hidden in carousel
        hideControlsTimer: const Duration(seconds: 0),
        showControlsOnInitialize: false,
      );

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _isLoading = false;
        });
        print('🎥 Video state updated to initialized');
      }
    } catch (e) {
      print('❌ Video initialization error: $e');
      print('❌ Error type: ${e.runtimeType}');
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
          _errorMessage = _getUserFriendlyErrorMessage(e);
        });
        print('🎥 Video state updated to error');
      }
    }
  }

  void _videoListener() {
    if (mounted && _videoPlayerController != null) {
      final value = _videoPlayerController!.value;
      print(
          '🎥 Video state: initialized=${value.isInitialized}, error=${value.errorDescription}');
      print(
          '🎥 Video duration: ${value.duration}, position: ${value.position}');
      print('🎥 Video size: ${value.size}, aspectRatio: ${value.aspectRatio}');

      if (value.hasError && value.errorDescription != null) {
        print('❌ Video player error: ${value.errorDescription}');
        setState(() {
          _hasError = true;
          _isLoading = false;
          _errorMessage =
              _getUserFriendlyErrorMessage(Exception(value.errorDescription!));
        });
      } else if (value.isInitialized && _isLoading) {
        setState(() {
          _isLoading = false;
        });
        print(
            '🎥 Video player initialized successfully - controls should be available');
      }

      // Reset completion flag if video position resets (user seeks back, etc.)
      if (value.position < value.duration - const Duration(seconds: 1)) {
        _hasCalledCompletion = false;
      }

      // Check if video has completed
      if (value.isInitialized &&
          value.duration > Duration.zero &&
          value.position >=
              value.duration - const Duration(milliseconds: 100) &&
          !_hasCalledCompletion) {
        // Video has reached the end (with 100ms tolerance)
        print('🎥 Video completed - calling completion callback');
        _hasCalledCompletion = true;
        widget.onVideoComplete?.call();
      }
    }
  }

  String _getUserFriendlyErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('timeout')) {
      return 'Video loading timeout. Please check your internet connection.';
    } else if (errorString.contains('network') ||
        errorString.contains('connection')) {
      return 'Network error. Please check your internet connection.';
    } else if (errorString.contains('format') ||
        errorString.contains('codec')) {
      return 'Video format not supported.';
    } else if (errorString.contains('not found') ||
        errorString.contains('404')) {
      return 'Video not found.';
    } else if (errorString.contains('permission') ||
        errorString.contains('access')) {
      return 'Access denied to video.';
    } else {
      return 'Unable to load video. Please try again.';
    }
  }

  Future<void> _testWithSampleVideo() async {
    try {
      print('🎥 Testing with sample video...');

      // Use a known working sample video URL
      const testVideoUrl =
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4';

      _videoPlayerController?.removeListener(_videoListener);
      _videoPlayerController?.dispose();
      _chewieController?.dispose();

      _videoPlayerController =
          VideoPlayerController.networkUrl(Uri.parse(testVideoUrl));

      // Add listener to update UI when video state changes
      _videoPlayerController!.addListener(_videoListener);

      print('🎥 Starting test video initialization...');
      await _videoPlayerController!.initialize().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Test video initialization timeout after 15 seconds');
        },
      );

      print('🎥 Test video initialized successfully');
      print(
          '🎥 Test video duration: ${_videoPlayerController!.value.duration}');
      print('🎥 Test video size: ${_videoPlayerController!.value.size}');

      // Initialize Chewie controller for test video
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: false,
        looping: false,
        allowPlaybackSpeedChanging: true,
        allowMuting: false, // Disable sound controls
        showControls: true,
        showOptions: true,
        allowFullScreen: false, // Disable fullscreen
        startAt: Duration.zero,
        materialProgressColors: ChewieProgressColors(
          playedColor: AppColors.primaryColor,
          handleColor: Colors.white,
          backgroundColor: Colors.grey.withOpacity(0.3),
          bufferedColor: Colors.lightBlueAccent.withOpacity(0.3),
        ),
        cupertinoProgressColors: ChewieProgressColors(
          playedColor: AppColors.primaryColor,
          handleColor: Colors.white,
          backgroundColor: Colors.grey.withOpacity(0.3),
          bufferedColor: Colors.lightBlueAccent.withOpacity(0.3),
        ),
        hideControlsTimer: const Duration(seconds: 3),
        showControlsOnInitialize: true,
      );

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _isLoading = false;
        });
        print('🎥 Test video state updated to initialized');
      }
    } catch (e) {
      print('❌ Test video initialization error: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
          _errorMessage =
              'Test video failed: ${_getUserFriendlyErrorMessage(e)}';
        });
      }
    }
  }

  @override
  void dispose() {
    _videoPlayerController?.removeListener(_videoListener);
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.videocam_off,
                  color: Colors.white,
                  size: 48,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Video not available',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _hasError = false;
                          _isInitialized = false;
                          _isLoading = true;
                          _errorMessage = null;
                        });
                        _initializeVideo();
                      },
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Retry'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _hasError = false;
                          _isInitialized = false;
                          _isLoading = true;
                          _errorMessage = null;
                        });
                        _testWithSampleVideo();
                      },
                      icon: const Icon(Icons.play_circle_outline, size: 18),
                      label: const Text('Test Video'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_isLoading || !_isInitialized || _chewieController == null) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
              SizedBox(height: 12),
              Text(
                'Loading video...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Return Chewie - parent will use AbsorbPointer to prevent tap interception
    return Chewie(controller: _chewieController!);
  }
}

/// Full-screen image gallery viewer with zoom and pan capabilities
class _ImageGalleryViewer extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const _ImageGalleryViewer({
    required this.images,
    required this.initialIndex,
  });

  @override
  State<_ImageGalleryViewer> createState() => _ImageGalleryViewerState();
}

class _ImageGalleryViewerState extends State<_ImageGalleryViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            (!kIsWeb && Platform.isIOS)
                ? Icons.arrow_back_ios
                : Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          '${_currentIndex + 1} / ${widget.images.length}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: PhotoViewGallery.builder(
        scrollPhysics: const BouncingScrollPhysics(),
        builder: (BuildContext context, int index) {
          return PhotoViewGalleryPageOptions(
            imageProvider: NetworkImage(widget.images[index]),
            initialScale: PhotoViewComputedScale.contained,
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 2,
            heroAttributes: PhotoViewHeroAttributes(
              tag: widget.images[index],
            ),
          );
        },
        itemCount: widget.images.length,
        loadingBuilder: (context, event) => Center(
          child: Container(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              value: event == null
                  ? 0
                  : event.cumulativeBytesLoaded / event.expectedTotalBytes!,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ),
        pageController: _pageController,
        onPageChanged: _onPageChanged,
        backgroundDecoration: const BoxDecoration(
          color: Colors.black,
        ),
      ),
    );
  }
}

/// Full-screen video player viewer
class _VideoFullScreenViewer extends StatefulWidget {
  final String videoUrl;

  const _VideoFullScreenViewer({
    required this.videoUrl,
  });

  @override
  State<_VideoFullScreenViewer> createState() => _VideoFullScreenViewerState();
}

class _VideoFullScreenViewerState extends State<_VideoFullScreenViewer> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _isInitialized = false;
  bool _hasError = false;
  String? _errorMessage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      print('🎥 Initializing full-screen video: ${widget.videoUrl}');

      if (widget.videoUrl.isEmpty) {
        throw Exception('Video URL is empty');
      }

      String cleanUrl = widget.videoUrl.trim();
      if (!cleanUrl.startsWith('http://') && !cleanUrl.startsWith('https://')) {
        cleanUrl = 'https://$cleanUrl';
      }

      final uri = Uri.parse(cleanUrl);
      if (!uri.hasScheme || (!uri.scheme.startsWith('http'))) {
        throw Exception('Invalid video URL format: $cleanUrl');
      }

      _videoPlayerController = VideoPlayerController.networkUrl(uri);
      _videoPlayerController!.addListener(_videoListener);

      await _videoPlayerController!.initialize().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Video initialization timeout after 15 seconds');
        },
      );

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: true,
        looping: false,
        allowPlaybackSpeedChanging: true,
        allowMuting: true,
        showControls: true,
        showOptions: true,
        allowFullScreen: true,
        startAt: Duration.zero,
        materialProgressColors: ChewieProgressColors(
          playedColor: AppColors.primaryColor,
          handleColor: Colors.white,
          backgroundColor: Colors.grey.withOpacity(0.3),
          bufferedColor: Colors.lightBlueAccent.withOpacity(0.3),
        ),
        cupertinoProgressColors: ChewieProgressColors(
          playedColor: AppColors.primaryColor,
          handleColor: Colors.white,
          backgroundColor: Colors.grey.withOpacity(0.3),
          bufferedColor: Colors.lightBlueAccent.withOpacity(0.3),
        ),
        hideControlsTimer: const Duration(seconds: 3),
        showControlsOnInitialize: true,
      );

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Full-screen video initialization error: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
          _errorMessage = _getUserFriendlyErrorMessage(e);
        });
      }
    }
  }

  void _videoListener() {
    if (mounted && _videoPlayerController != null) {
      final value = _videoPlayerController!.value;
      if (value.hasError && value.errorDescription != null) {
        setState(() {
          _hasError = true;
          _isLoading = false;
          _errorMessage =
              _getUserFriendlyErrorMessage(Exception(value.errorDescription!));
        });
      } else if (value.isInitialized && _isLoading) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getUserFriendlyErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();
    if (errorString.contains('timeout')) {
      return 'Video loading timeout. Please check your internet connection.';
    } else if (errorString.contains('network') ||
        errorString.contains('connection')) {
      return 'Network error. Please check your internet connection.';
    } else if (errorString.contains('format') ||
        errorString.contains('codec')) {
      return 'Video format not supported.';
    } else if (errorString.contains('not found') ||
        errorString.contains('404')) {
      return 'Video not found.';
    } else if (errorString.contains('permission') ||
        errorString.contains('access')) {
      return 'Access denied to video.';
    } else {
      return 'Unable to load video. Please try again.';
    }
  }

  @override
  void dispose() {
    _videoPlayerController?.removeListener(_videoListener);
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            (!kIsWeb && Platform.isIOS)
                ? Icons.arrow_back_ios
                : Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _hasError
          ? Container(
              color: Colors.black,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.videocam_off,
                          color: Colors.white, size: 48),
                      const SizedBox(height: 12),
                      const Text(
                        'Video not available',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _errorMessage!,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _hasError = false;
                            _isInitialized = false;
                            _isLoading = true;
                            _errorMessage = null;
                          });
                          _initializeVideo();
                        },
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : _isLoading || !_isInitialized || _chewieController == null
              ? Container(
                  color: Colors.black,
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                        SizedBox(height: 12),
                        Text(
                          'Loading video...',
                          style:
                              TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                )
              : Center(child: Chewie(controller: _chewieController!)),
    );
  }
}