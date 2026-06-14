import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ado_dad_user/common/app_colors.dart';
import 'package:ado_dad_user/common/get_responsive_size.dart';
import 'package:ado_dad_user/common/shared_pref.dart';
import 'package:ado_dad_user/common/widgets/rich_ad_card.dart';
import 'package:ado_dad_user/common/widgets/skeleton.dart';
import 'package:ado_dad_user/features/profile/MyAds/bloc/my_ads_bloc.dart';
import 'package:ado_dad_user/models/advertisement_model/add_model.dart';
import 'package:ado_dad_user/models/my_ads_model.dart';
import 'package:ado_dad_user/repositories/add_repo.dart';
import 'package:go_router/go_router.dart';

class MyAdsPage extends StatefulWidget {
  final bool embedded;
  const MyAdsPage({super.key, this.embedded = false});

  @override
  State<MyAdsPage> createState() => _MyAdsPageState();
}

class _MyAdsPageState extends State<MyAdsPage> {
  final ScrollController _scrollController = ScrollController();
  String _statusFilter = 'all';

  List<MyAd> _filterByStatus(List<MyAd> ads) {
    switch (_statusFilter) {
      case 'active':
        return ads.where((a) => a.isActive && a.soldOut != true).toList();
      case 'sold':
        return ads.where((a) => a.soldOut == true).toList();
      case 'inactive':
        return ads.where((a) => !a.isActive && a.soldOut != true).toList();
      default:
        return ads;
    }
  }

  Widget _buildStatusChips() {
    const items = [
      ['all', 'All'],
      ['active', 'Active'],
      ['sold', 'Sold'],
      ['inactive', 'Inactive'],
    ];
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final selected = _statusFilter == items[i][0];
          return GestureDetector(
            onTap: () => setState(() => _statusFilter = items[i][0]),
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: selected ? AppColors.primaryColor : Colors.transparent,
                border: Border.all(
                  color:
                      selected ? AppColors.primaryColor : Colors.grey.shade400,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                items[i][1],
                style: TextStyle(
                  fontSize: 12.5,
                  color: selected ? Colors.white : AppColors.blackColor,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (maxScroll > 0 && currentScroll >= maxScroll - 200) {
      final state = context.read<MyAdsBloc>().state;
      state.maybeMap(
        loaded: (s) {
          if (s.hasNext && !s.isPaging) {
            context.read<MyAdsBloc>().add(MyAdsEvent.loadMore(
                  nextPage: s.page + 1,
                  limit: 20,
                ));
          }
        },
        orElse: () {},
      );
    }
  }

  Future<void> _checkAuthentication() async {
    final token = await getToken();
    if (token == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Please login to view your ads',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red.shade300.withOpacity(0.9),
          ),
        );
        context.go('/login');
      }
      return;
    }
    if (mounted) {
      context
          .read<MyAdsBloc>()
          .add(const MyAdsEvent.load(page: 1, limit: 20));
    }
  }

  // ── Action handlers ──────────────────────────────────────────────────────

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

  Future<void> _handleEdit(BuildContext context, MyAd ad) async {
    final route = _editRouteFor(ad.category);
    if (route == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Editing not available for this category')),
      );
      return;
    }
    final changed =
        await context.push<bool>(route, extra: _toAddModel(ad));
    if (changed == true && context.mounted) {
      context
          .read<MyAdsBloc>()
          .add(const MyAdsEvent.load(page: 1, limit: 20));
    }
  }

  Future<void> _handleMarkSold(BuildContext context, MyAd ad) async {
    final ok = await _confirm(
        context, 'Mark as sold?', 'Buyers will see this listing as sold.');
    if (ok != true || !context.mounted) return;
    try {
      await AddRepository().markAdAsSold(ad.id);
      if (!context.mounted) return;
      context
          .read<MyAdsBloc>()
          .add(const MyAdsEvent.load(page: 1, limit: 20));
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Marked as sold')));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not mark as sold: $e')));
      }
    }
  }

  Future<void> _handleDelete(BuildContext context, MyAd ad) async {
    final ok = await _confirm(
        context, 'Delete advertisement?', 'This action cannot be undone.');
    if (ok != true || !context.mounted) return;
    try {
      await AddRepository().deleteAd(ad.id);
      if (!context.mounted) return;
      context
          .read<MyAdsBloc>()
          .add(const MyAdsEvent.load(page: 1, limit: 20));
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Advertisement deleted')));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not delete: $e')));
      }
    }
  }

  Future<bool?> _confirm(
      BuildContext context, String title, String message) {
    return showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Confirm')),
        ],
      ),
    );
  }

  // ── Model conversion ─────────────────────────────────────────────────────

  AddModel _toAddModel(MyAd ad) {
    final adUser = ad.user == null
        ? null
        : AdUser(id: ad.user!.id, name: ad.user!.name, email: ad.user!.email);
    return AddModel(
      id: ad.id,
      title: ad.title,
      description: ad.description,
      price: ad.price,
      images: ad.images,
      location: ad.location,
      category: ad.category,
      isActive: ad.isActive,
      updatedAt: ad.updatedAt,
      postedAt: ad.postedAt,
      soldOut: ad.soldOut,
      user: adUser,
      // Vehicle
      vehicleType: ad.vehicleDetails?.vehicleType,
      manufacturer: ad.manufacturer,
      model: ad.model,
      year: ad.year ?? ad.vehicleDetails?.year,
      mileage: ad.vehicleDetails?.mileage,
      transmissionId: ad.vehicleDetails?.transmissionTypeId,
      fuelTypeId: ad.vehicleDetails?.fuelTypeId,
      color: ad.vehicleDetails?.color,
      isFirstOwner: ad.vehicleDetails?.isFirstOwner,
      hasInsurance: ad.vehicleDetails?.hasInsurance,
      hasRcBook: ad.vehicleDetails?.hasRcBook,
      additionalFeatures: ad.vehicleDetails?.additionalFeatures,
      // Property
      propertyType: ad.propertyDetails?.propertyType,
      listingType: ad.propertyDetails?.listingType,
      bedrooms: ad.propertyDetails?.bedrooms,
      bathrooms: ad.propertyDetails?.bathrooms,
      areaSqft: ad.propertyDetails?.areaSqft,
      floor: ad.propertyDetails?.floor,
      isFurnished: ad.propertyDetails?.isFurnished,
      hasParking: ad.propertyDetails?.hasParking,
      hasGarden: ad.propertyDetails?.hasGarden,
      amenities: ad.propertyDetails?.amenities,
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F4FC),
      appBar: widget.embedded
          ? null
          : AppBar(
              elevation: 0,
              backgroundColor: const Color(0xFFF6F4FC),
              leading: IconButton(
                icon: Icon(
                  (!kIsWeb && Platform.isIOS)
                      ? Icons.arrow_back_ios
                      : Icons.arrow_back,
                  size: GetResponsiveSize.getResponsiveSize(context,
                      mobile: 24, tablet: 30, largeTablet: 32, desktop: 36),
                ),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              title: BlocBuilder<MyAdsBloc, MyAdsState>(
                builder: (context, state) {
                  final count = state.maybeMap(
                      loaded: (s) => s.ads.length, orElse: () => 0);
                  return Text(
                    'My Ads ($count)',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: GetResponsiveSize.getResponsiveFontSize(context,
                          mobile: 20,
                          tablet: 24,
                          largeTablet: 28,
                          desktop: 32),
                      color: const Color(0xFF16181B),
                    ),
                  );
                },
              ),
              centerTitle: false,
            ),
      body: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 20),
        child: BlocBuilder<MyAdsBloc, MyAdsState>(
          builder: (context, state) {
            return state.maybeMap(
              loading: (_) => const SkeletonList(),
              initial: (_) => const SkeletonList(),
              error: (e) => _ErrorView(
                message: e.message,
                onRetry: () => context
                    .read<MyAdsBloc>()
                    .add(const MyAdsEvent.load()),
              ),
              loaded: (loaded) {
                if (loaded.ads.isEmpty) {
                  return Center(
                    child: Text(
                      'No ads yet',
                      style: TextStyle(
                        fontSize: GetResponsiveSize.getResponsiveFontSize(
                            context,
                            mobile: 16,
                            tablet: 20,
                            largeTablet: 24,
                            desktop: 28),
                      ),
                    ),
                  );
                }
                final ads = _filterByStatus(loaded.ads);
                return Column(
                  children: [
                    _buildStatusChips(),
                    Expanded(
                      child: ads.isEmpty
                          ? Center(
                              child: Text(
                                'No ads in this filter',
                                style:
                                    TextStyle(color: Colors.grey.shade600),
                              ),
                            )
                          : GridView.builder(
                              controller: _scrollController,
                              padding:
                                  const EdgeInsets.fromLTRB(15, 10, 15, 100),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 15,
                                mainAxisSpacing: 15,
                                mainAxisExtent: richAdCardMainAxisExtent(
                                    context,
                                    columns: 2),
                              ),
                              itemCount: ads.length + (loaded.isPaging ? 1 : 0),
                              itemBuilder: (context, i) {
                                if (i >= ads.length) {
                                  return const Center(
                                      child: CircularProgressIndicator());
                                }
                                final ad = ads[i];
                                return Stack(
                                  children: [
                                    RichAdCard(ad: _toAddModel(ad)),
                                    Positioned(
                                      top: 5,
                                      right: 5,
                                      child: _MyAdActionsButton(
                                        ad: ad,
                                        onEdit: () =>
                                            _handleEdit(context, ad),
                                        onMarkSold: () =>
                                            _handleMarkSold(context, ad),
                                        onDelete: () =>
                                            _handleDelete(context, ad),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
              orElse: () => const SizedBox.shrink(),
            );
          },
        ),
      ),
    );
  }
}

// ── Error view ────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(GetResponsiveSize.getResponsivePadding(context,
            mobile: 16, tablet: 24, largeTablet: 32, desktop: 40)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: GetResponsiveSize.getResponsiveSize(context,
                  mobile: 64, tablet: 80, largeTablet: 96, desktop: 112),
              color: Colors.red.shade300,
            ),
            SizedBox(
                height: GetResponsiveSize.getResponsiveSize(context,
                    mobile: 16, tablet: 20, largeTablet: 24, desktop: 28)),
            Text(
              'Error loading your ads',
              style: TextStyle(
                fontSize: GetResponsiveSize.getResponsiveFontSize(context,
                    mobile: 18, tablet: 22, largeTablet: 26, desktop: 30),
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            SizedBox(
                height: GetResponsiveSize.getResponsiveSize(context,
                    mobile: 8, tablet: 12, largeTablet: 16, desktop: 20)),
            Text(
              message,
              style: TextStyle(
                fontSize: GetResponsiveSize.getResponsiveFontSize(context,
                    mobile: 14, tablet: 18, largeTablet: 20, desktop: 24),
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(
                height: GetResponsiveSize.getResponsiveSize(context,
                    mobile: 16, tablet: 24, largeTablet: 32, desktop: 40)),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: GetResponsiveSize.getResponsivePadding(context,
                      mobile: 16, tablet: 24, largeTablet: 32, desktop: 40),
                  vertical: GetResponsiveSize.getResponsivePadding(context,
                      mobile: 12, tablet: 16, largeTablet: 20, desktop: 24),
                ),
              ),
              child: Text(
                'Retry',
                style: TextStyle(
                  fontSize: GetResponsiveSize.getResponsiveFontSize(context,
                      mobile: 14, tablet: 18, largeTablet: 20, desktop: 24),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Per-card actions overlay ──────────────────────────────────────────────────

class _MyAdActionsButton extends StatelessWidget {
  const _MyAdActionsButton({
    required this.ad,
    required this.onEdit,
    required this.onMarkSold,
    required this.onDelete,
  });

  final MyAd ad;
  final VoidCallback onEdit;
  final VoidCallback onMarkSold;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isSold = ad.soldOut == true;
    return SizedBox(
      width: 28,
      height: 28,
      child: DecoratedBox(
        decoration: const BoxDecoration(
            color: Colors.white, shape: BoxShape.circle),
        child: PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, size: 16, color: AppColors.greyColor),
          padding: EdgeInsets.zero,
          onSelected: (value) {
            if (value == 'edit') onEdit();
            if (value == 'sold') onMarkSold();
            if (value == 'delete') onDelete();
          },
          itemBuilder: (_) => [
            const PopupMenuItem<String>(
              value: 'edit',
              child: Row(children: [
                Icon(Icons.edit_outlined, size: 18),
                SizedBox(width: 10),
                Text('Edit'),
              ]),
            ),
            if (!isSold)
              const PopupMenuItem<String>(
                value: 'sold',
                child: Row(children: [
                  Icon(Icons.check_circle_outline, size: 18),
                  SizedBox(width: 10),
                  Text('Mark as sold'),
                ]),
              ),
            const PopupMenuItem<String>(
              value: 'delete',
              child: Row(children: [
                Icon(Icons.delete_outline, size: 18, color: Colors.red),
                SizedBox(width: 10),
                Text('Delete', style: TextStyle(color: Colors.red)),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
