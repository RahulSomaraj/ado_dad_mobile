import 'package:ado_dad_user/common/app_colors.dart';
import 'package:ado_dad_user/features/home/ad_detail/ad_detail_bloc.dart';
import 'package:ado_dad_user/models/advertisement_model/add_model.dart';
import 'package:ado_dad_user/features/chat/services/offer_service.dart';
import 'package:ado_dad_user/common/shared_pref.dart';
import 'package:ado_dad_user/features/home/favorite/bloc/favorite_bloc.dart';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class AdDetailPage extends StatefulWidget {
  // final String adId;
  final AddModel ad;
  const AdDetailPage({super.key, required this.ad});

  @override
  State<AdDetailPage> createState() => _AdDetailPageState();
}

class _AdDetailPageState extends State<AdDetailPage> {
  int _currentIndex = 0;

  // Check if current user is the owner of the ad
  Future<bool> _isCurrentUserOwner(AddModel ad) async {
    final currentUserId = await SharedPrefs().getUserId();
    return currentUserId != null &&
        ad.user?.id != null &&
        currentUserId == ad.user!.id;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocListener<AdDetailBloc, AdDetailState>(
        listener: (context, state) {
          state.when(
            initial: () {},
            loading: () {},
            error: (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            loaded: (ad) {},
            markingAsSold: () {},
            markedAsSold: (ad) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Ad marked as sold successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
          );
        },
        child: BlocBuilder<AdDetailBloc, AdDetailState>(
          builder: (context, state) {
            return state.when(
              initial: () =>
                  const Center(child: Text('Waiting for details...')),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e) => Center(child: Text('Error: $e')),
              loaded: (ad) => CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _headerCarousel(ad)),
                  SliverToBoxAdapter(child: _dots(ad.images.length)),
                  SliverToBoxAdapter(child: _titlePriceMeta(ad)),
                  SliverToBoxAdapter(child: Divider()),

                  SliverToBoxAdapter(child: _pillTabs(ad)),
                  SliverToBoxAdapter(child: _description(ad)),
                  SliverToBoxAdapter(child: _sellerTile(ad)),
                  // SliverToBoxAdapter(child: _recommendationsSection()),
                  // const SliverPadding(padding: EdgeInsets.only(bottom: 90)),
                ],
              ),
              markingAsSold: () => CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _headerCarousel(widget.ad)),
                  SliverToBoxAdapter(child: _dots(widget.ad.images.length)),
                  SliverToBoxAdapter(child: _titlePriceMeta(widget.ad)),
                  SliverToBoxAdapter(child: Divider()),
                  SliverToBoxAdapter(child: _pillTabs(widget.ad)),
                  SliverToBoxAdapter(child: _description(widget.ad)),
                  SliverToBoxAdapter(child: _sellerTile(widget.ad)),
                ],
              ),
              markedAsSold: (ad) => CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _headerCarousel(ad)),
                  SliverToBoxAdapter(child: _dots(ad.images.length)),
                  SliverToBoxAdapter(child: _titlePriceMeta(ad)),
                  SliverToBoxAdapter(child: Divider()),
                  SliverToBoxAdapter(child: _pillTabs(ad)),
                  SliverToBoxAdapter(child: _description(ad)),
                  SliverToBoxAdapter(child: _sellerTile(ad)),
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: BlocBuilder<AdDetailBloc, AdDetailState>(
          builder: (context, state) {
            return state.when(
              initial: () => const SizedBox.shrink(),
              loading: () => const SizedBox.shrink(),
              error: (e) => const SizedBox.shrink(),
              loaded: (ad) => _buildBottomButtons(ad),
              markingAsSold: () => _buildBottomButtons(widget.ad),
              markedAsSold: (ad) => _buildBottomButtons(ad),
            );
          },
        ),
      ),
    );
  }

  // Build bottom buttons based on user ownership
  Widget _buildBottomButtons(AddModel ad) {
    return FutureBuilder<bool>(
      future: _isCurrentUserOwner(ad),
      builder: (context, snapshot) {
        final isOwner = snapshot.data ?? false;

        // Hide buttons if current user is the owner of the ad
        if (isOwner) {
          return const SizedBox.shrink();
        }

        // Show "Make Offer" and "Chat" buttons only for non-owners
        return Row(
          children: [
            Expanded(
              child: _makeOfferBtn('Make an offer',
                  onTap: () => _handleMakeOffer(context)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _chatBtn('Chat', onTap: () {}
                  // onTap: () => _handleChat(context),
                  ),
            ),
          ],
        );
      },
    );
  }

  // Mark as Sold button for Other Details section
  Widget _markAsSoldButtonInDetails(AddModel ad) {
    return BlocBuilder<AdDetailBloc, AdDetailState>(
      builder: (context, state) {
        final isLoading = state.when(
          initial: () => false,
          loading: () => false,
          error: (e) => false,
          loaded: (ad) => false,
          markingAsSold: () => true,
          markedAsSold: (ad) => false,
        );
        final isSold = ad.soldOut == true;

        if (isSold) {
          return Container(
            width: double.infinity,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'SOLD',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.primaryColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: isLoading ? null : () => _handleMarkAsSold(context, ad),
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.sell, color: AppColors.primaryColor, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Mark as Sold',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }

  // Handle mark as sold action
  void _handleMarkAsSold(BuildContext context, AddModel ad) {
    // Store the bloc reference before showing the dialog
    final adDetailBloc = context.read<AdDetailBloc>();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Mark as Sold'),
          content: const Text(
            'Are you sure you want to mark this ad as sold? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Mark as Sold',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ======= Header (Carousel + overlay controls) =======
  Widget _headerCarousel(AddModel ad) {
    return Stack(
      children: [
        AspectRatio(
          aspectRatio: 16 / 10,
          child: CarouselSlider(
            options: CarouselOptions(
              viewportFraction: 1,
              height: double.infinity,
              autoPlay: false,
              onPageChanged: (i, _) => setState(() => _currentIndex = i),
            ),
            items: ad.images.map((img) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(24),
                            bottomRight: Radius.circular(24)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(24),
                            bottomRight: Radius.circular(24)),
                        child: Image.network(img, fit: BoxFit.cover),
                      )),
                  // dark gradient overlay (top+bottom)
                  Container(
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(24),
                          bottomRight: Radius.circular(24)),
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
              );
            }).toList(),
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
              _circleIconButton(
                Icons.arrow_back,
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
                        return _circleIconButton(Icons.edit, onTap: () {
                          _goToEdit(context, ad);
                        });
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
                  _buildFavoriteButton(ad),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _goToEdit(BuildContext context, AddModel ad) async {
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

  // page indicators (small pills)
  Widget _dots(int count) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(count, (i) {
          final isActive = i == _currentIndex;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            height: 6,
            width: isActive ? 14 : 6,
            decoration: BoxDecoration(
              color: isActive ? Colors.indigo : Colors.grey.shade400,
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }),
      ),
    );
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

  // ======= Title / Price / Meta =======
  Widget _titlePriceMeta(AddModel ad) {
    String title;
    if (ad.category == 'property') {
      title =
          '${ad.propertyType ?? ''} • ${ad.bedrooms ?? 0} BHK • ${ad.areaSqft ?? 0} sqft';
    } else {
      title =
          '${ad.manufacturer?.displayName ?? ad.manufacturer?.name ?? ''} ${ad.model?.displayName ?? ad.model?.name ?? ''} (${ad.year ?? ''})';
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  toTitleCase(title),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  'Posted on ${_niceDate(ad.updatedAt)}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            height: 40,
            child: const VerticalDivider(
              thickness: 1,
              color: Colors.grey,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 1,
            child: Text(
              '₹ ${(ad.price)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  // ======= Tabs (Pill segmented) + content =======
  Widget _pillTabs(AddModel ad) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            Container(
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFFF2F3F6),
                borderRadius: BorderRadius.circular(28),
              ),
              padding: const EdgeInsets.all(6),
              child: TabBar(
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  // boxShadow: [
                  //   BoxShadow(
                  //     color: Colors.black.withOpacity(0.06),
                  //     blurRadius: 8,
                  //   )
                  // ],
                ),
                indicatorColor: Colors.transparent, // removes default underline
                dividerColor: Colors.transparent,
                labelColor: AppColors.primaryColor,
                unselectedLabelColor: Colors.grey.shade600,
                tabs: const [
                  Tab(text: 'Specifications'),
                  Tab(text: 'Other Details'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: _contentHeightForSpecs(ad),
              child: TabBarView(
                children: [
                  _specsCard(ad),
                  _otherDetailsCard(ad),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _specsCard(AddModel ad) {
    if (ad.category == 'property') {
      // PROPERTY SPECS
      final items = <_Spec>[
        _Spec('Property Type', ad.propertyType ?? '-', icon: Icons.home_work),
        _Spec('Bedrooms', ad.bedrooms?.toString() ?? '-', icon: Icons.bed),
        _Spec('Bathrooms', ad.bathrooms?.toString() ?? '-',
            icon: Icons.bathtub),
        _Spec('Area (sqft)', ad.areaSqft?.toString() ?? '-',
            icon: Icons.square_foot),
        _Spec('Floor', ad.floor?.toString() ?? '-', icon: Icons.apartment),
        _Spec('Furnished', ad.isFurnished == true ? 'Yes' : 'No',
            icon: Icons.chair_alt),
        _Spec('Parking', ad.hasParking == true ? 'Yes' : 'No',
            icon: Icons.local_parking),
        _Spec('Garden', ad.hasGarden == true ? 'Yes' : 'No', icon: Icons.park),
      ];

      return _cardShell(
        child: GridView.builder(
          padding: const EdgeInsets.all(12),
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisExtent: 55,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: items.length,
          itemBuilder: (_, i) => _specTile(items[i]),
        ),
      );
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
      _Spec('Registration Year', (ad.year ?? 0).toString(),
          icon: Icons.calendar_today),
      _Spec('Mileage', (ad.mileage != null) ? '${ad.mileage} Kmpl' : '-',
          icon: Icons.speed),
    ];

    return _cardShell(
      child: GridView.builder(
        padding: const EdgeInsets.all(12),
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisExtent: 64,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: items.length,
        itemBuilder: (_, i) => _specTile(items[i]),
      ),
    );
  }

  Widget _otherDetailsCard(AddModel ad) {
    final sellerName = (ad.user?.name ?? '').trim();
    final sellerEmail = (ad.user?.email ?? '').trim();
    return _cardShell(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (sellerName.isNotEmpty) ...[
              const Text('Seller Information',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              _KeyValRow(label: 'Name', value: sellerName),
              if (sellerEmail.isNotEmpty) ...[
                const SizedBox(height: 8),
                _KeyValRow(label: 'Email', value: sellerEmail),
              ],
              const SizedBox(height: 16),
            ],
            const Text('Ad Details',
                style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            _KeyValRow(label: 'Location', value: ad.location),
            const SizedBox(height: 8),
            _KeyValRow(label: 'Category', value: toTitleCase(ad.category)),
            const SizedBox(height: 8),
            _KeyValRow(label: 'Posted On', value: _niceDate(ad.updatedAt)),
            const SizedBox(height: 16),
            // Mark as Sold button for ad owners
            FutureBuilder<bool>(
              future: _isCurrentUserOwner(ad),
              builder: (context, snapshot) {
                final isOwner = snapshot.data ?? false;
                if (isOwner) {
                  return _markAsSoldButtonInDetails(ad);
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }

  // ======= Description =======
  Widget _description(AddModel ad) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: _cardShell(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Description',
                style: TextStyle(color: Color(0xFF6B7280)),
              ),
              SizedBox(height: 10),
              Text(
                ad.description,
                style: TextStyle(color: Colors.black, height: 1.35),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ======= Seller Tile =======
  Widget _sellerTile(AddModel ad) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: _cardShell(
        child: ListTile(
          leading: CircleAvatar(
            radius: 24,
            backgroundImage: NetworkImage(ad.user?.profilePic ?? ''),
          ),
          title: Text(
            ad.user?.name?.trim().isNotEmpty == true
                ? ad.user!.name!
                : 'Seller',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (ad.user?.email?.trim().isNotEmpty == true)
                Text(ad.user!.email!),
              if (ad.user?.phone?.trim().isNotEmpty == true)
                Text(ad.user!.phone!),
              Text(ad.location),
            ],
          ),
          trailing: const Icon(Icons.chevron_right),
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
  Widget _buildFavoriteButton(AddModel ad) {
    return BlocBuilder<FavoriteBloc, FavoriteState>(
      builder: (context, state) {
        bool isFavorited = ad.isFavorited ?? false;

        // Check if this ad is currently being toggled
        if (state is FavoriteToggleLoading && state.adId == ad.id) {
          return Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.35),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
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
            height: 36,
            width: 36,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.35),
              shape: BoxShape.circle,
            ),
            child: Image.asset(
              isFavorited
                  ? 'assets/images/favorite_icon_filled.png'
                  : 'assets/images/favorite_icon_unfilled.png',
              width: 20,
              height: 20,
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
        height: 36,
        width: 36,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.35),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _chatBtn(String label, {required VoidCallback onTap}) {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        onPressed: onTap,
        child: Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.w700, color: AppColors.whiteColor)),
      ),
    );
  }

  void _handleMakeOffer(BuildContext context) {
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
        );
      },
      markingAsSold: () {},
      markedAsSold: (ad) {
        // Show the offer popup
        OfferService.showOfferPopup(
          context: context,
          adId: ad.id,
          adTitle: ad.description.isNotEmpty ? ad.description : 'Untitled Ad',
          adPosterName: ad.user?.name ?? 'Unknown Seller',
        );
      },
    );
  }

  Widget _makeOfferBtn(String label, {required VoidCallback onTap}) {
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AppColors.primaryColor),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        onPressed: onTap,
        child: Text(label,
            style: TextStyle(
                color: AppColors.primaryColor, fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _cardShell({required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _specTile(_Spec spec) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          height: 36,
          width: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFF4F6FA),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(spec.icon, size: 18, color: const Color(0xFF475569)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(spec.label,
                  style:
                      const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
              const SizedBox(height: 2),
              Text(spec.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
        )
      ],
    );
  }

  double _contentHeightForSpecs(AddModel ad) {
    // enough room for grid + showroom + mark as sold button; adjust if you add more rows
    return 320; // Increased from 260 to accommodate the Mark as Sold button
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
            width: 110,
            child: Text(label,
                style:
                    const TextStyle(fontSize: 12, color: Color(0xFF6B7280)))),
        const SizedBox(width: 8),
        Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13))),
      ],
    );
  }
}
