import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:ado_dad_user/common/app_colors.dart';
import 'package:ado_dad_user/common/app_textstyle.dart';
import 'package:ado_dad_user/common/get_responsive_size.dart';
import 'package:ado_dad_user/features/home/bloc/advertisement_bloc.dart';
import 'package:ado_dad_user/models/advertisement_model/add_model.dart';
import 'package:ado_dad_user/services/filter_state_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class CategoryListPage extends StatefulWidget {
  final String categoryId;
  final String categoryTitle;
  const CategoryListPage(
      {super.key, required this.categoryId, required this.categoryTitle});

  @override
  State<CategoryListPage> createState() => _CategoryListPageState();
}

class _CategoryListPageState extends State<CategoryListPage> {
  late final List<AddModel> filteredAds;
  final ScrollController _scrollController = ScrollController();
  Map<String, dynamic> _filters = {};
  final FilterStateService _filterStateService = FilterStateService();

  // Helper method to check if this is Premium Vehicles category
  bool get _isPremiumVehiclesCategory {
    return widget.categoryTitle.toLowerCase().contains('premium');
  }

  // Helper method to get categoryId - returns null for Premium Vehicles to fetch all categories
  String? get _effectiveCategoryId {
    return _isPremiumVehiclesCategory ? null : widget.categoryId;
  }

  @override
  void initState() {
    super.initState();

    // initial load: category with no filters
    // For Premium Vehicles, pass null to fetch all ads (will filter by isPremium client-side)
    context.read<AdvertisementBloc>().add(
          AdvertisementEvent.applyFilters(categoryId: _effectiveCategoryId),
        );

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 300) {
        context.read<AdvertisementBloc>().add(
              const AdvertisementEvent.fetchNextPage(),
            );
      }
    });
  }

  @override
  void dispose() {
    // Clear filter states when leaving the category list page
    _filterStateService.clearPropertyFilterState(widget.categoryId);
    _filterStateService.clearCarFilterState(widget.categoryId);
    _scrollController.dispose();
    super.dispose();
  }

  // Future<void> _fetchCategoryAds() async {
  //   setState(() => _isLoading = true);
  //   try {
  //     final repo = context.read<AdvertisementBloc>().repository;
  //     final result = await repo.fetchAllAds(
  //       page: _page,
  //       categoryId: widget.categoryId,
  //       minYear: _filters['minYear'] as int?, // <-- NEW
  //       maxYear: _filters['maxYear'] as int?, // <-- NEW
  //       manufacturerIds: (_filters['manufacturerIds'] as List?)?.cast<String>(),
  //     );

  //     setState(() {
  //       _page += 1;
  //       _hasMore = result.hasNext;
  //       _categoryAds.addAll(result.data);
  //     });
  //   } catch (e) {
  //     print("❌ Error fetching category ads: $e");
  //   } finally {
  //     setState(() => _isLoading = false);
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // we will handle back navigation ourselves
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return; // system/back already popped it
        context.pop(true); // send `true` result back to Home
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.whiteColor,
          leading: IconButton(
              // onPressed: () => context.go('/home'),
              onPressed: () => context.pop(true),
              icon: Icon(
                (!kIsWeb && Platform.isIOS)
                    ? Icons.arrow_back_ios
                    : Icons.arrow_back,
                size: GetResponsiveSize.getResponsiveSize(
                  context,
                  mobile: 24.0, // Keep mobile unchanged
                  tablet: 30.0,
                  largeTablet: 35.0,
                  desktop: 40.0,
                ),
              )),
          title: Text(
            widget.categoryTitle,
            style: AppTextstyle.appbarText.copyWith(
              fontSize: GetResponsiveSize.getResponsiveFontSize(
                context,
                mobile: AppTextstyle.appbarText.fontSize ??
                    18.0, // Keep mobile unchanged
                tablet: 24.0,
                largeTablet: 28.0,
                desktop: 32.0,
              ),
            ),
          ),
          actions: [
            Padding(
              padding: EdgeInsets.only(
                right: GetResponsiveSize.getResponsivePadding(
                  context,
                  mobile: 10,
                  tablet: 14,
                  largeTablet: 16,
                  desktop: 18,
                ),
              ),
              child: GestureDetector(
                // AppBar actions -> onTap:
                onTap: () async {
                  // Check if this is a property category
                  if (widget.categoryId == 'property') {
                    final result = await context.push(
                        '/property-filter?categoryId=${widget.categoryId}&title=${Uri.encodeComponent(widget.categoryTitle)}',
                        extra: _filters);
                    if (result is Map<String, dynamic>) {
                      _filters = result;
                      context.read<AdvertisementBloc>().add(
                            AdvertisementEvent.applyFilters(
                              categoryId: widget.categoryId,
                              propertyTypes: (result['propertyTypes'] as List?)
                                  ?.cast<String>(),
                              minBedrooms: result['minBedrooms'] as int?,
                              maxBedrooms: result['maxBedrooms'] as int?,
                              minPrice: result['minPrice'] as int?,
                              maxPrice: result['maxPrice'] as int?,
                              minArea: result['minArea'] as int?,
                              maxArea: result['maxArea'] as int?,
                              isFurnished: result['isFurnished'] as bool?,
                              hasParking: result['hasParking'] as bool?,
                            ),
                          );
                    }
                  } else {
                    // For vehicle categories, use car filter
                    final result = await context.push(
                        '/car-filter?categoryId=${widget.categoryId}&title=${Uri.encodeComponent(widget.categoryTitle)}',
                        extra: _filters);
                    if (result is Map<String, dynamic>) {
                      _filters = result;
                      context.read<AdvertisementBloc>().add(
                            AdvertisementEvent.applyFilters(
                              // For Premium Vehicles, pass null to fetch all categories
                              categoryId: _effectiveCategoryId,
                              minYear: result['minYear'] as int?,
                              maxYear: result['maxYear'] as int?,
                              manufacturerIds:
                                  (result['manufacturerIds'] as List?)
                                      ?.cast<String>(),
                              modelIds:
                                  (result['modelIds'] as List?)?.cast<String>(),
                              fuelTypeIds: (result['fuelTypeIds'] as List?)
                                  ?.cast<String>(),
                              transmissionTypeIds:
                                  (result['transmissionTypeIds'] as List?)
                                      ?.cast<String>(),
                              minPrice: result['minPrice'] as int?,
                              maxPrice: result['maxPrice'] as int?,
                            ),
                          );
                    }
                  }
                },

                child: SizedBox(
                  width: GetResponsiveSize.getResponsiveSize(
                    context,
                    mobile:
                        24.0, // Keep mobile unchanged (assuming default icon size)
                    tablet: 30.0,
                    largeTablet: 35.0,
                    desktop: 40.0,
                  ),
                  height: GetResponsiveSize.getResponsiveSize(
                    context,
                    mobile: 24.0, // Keep mobile unchanged
                    tablet: 30.0,
                    largeTablet: 35.0,
                    desktop: 40.0,
                  ),
                  child: Image.asset(
                    'assets/images/filter.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ],
        ),
        // body: _buildCategoryListView(),
        body: SafeArea(
          top: false,
          minimum: const EdgeInsets.only(bottom: 30),
          child: BlocBuilder<AdvertisementBloc, AdvertisementState>(
            builder: (context, state) {
              if (state is AdvertisementLoading ||
                  state is AdvertisementInitial) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state is AdvertisementError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: GetResponsiveSize.getResponsiveSize(
                            context,
                            mobile: 48,
                            tablet: 64,
                            largeTablet: 80,
                            desktop: 96,
                          ),
                          color: Colors.grey,
                        ),
                        SizedBox(
                          height: GetResponsiveSize.getResponsiveSize(
                            context,
                            mobile: 16,
                            tablet: 20,
                            largeTablet: 24,
                            desktop: 28,
                          ),
                        ),
                        Text(
                          _getUserFriendlyErrorMessage(state.message),
                          style: TextStyle(
                            fontSize: GetResponsiveSize.getResponsiveFontSize(
                              context,
                              mobile: 16.0,
                              tablet: 20.0,
                              largeTablet: 22.0,
                              desktop: 24.0,
                            ),
                            color: Colors.grey[700],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(
                          height: GetResponsiveSize.getResponsiveSize(
                            context,
                            mobile: 16,
                            tablet: 20,
                            largeTablet: 24,
                            desktop: 28,
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            // Retry loading
                            context.read<AdvertisementBloc>().add(
                                  AdvertisementEvent.applyFilters(
                                    categoryId: widget.categoryId,
                                  ),
                                );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            foregroundColor: AppColors.whiteColor,
                          ),
                          child: Text(
                            'Retry',
                            style: TextStyle(
                              fontSize: GetResponsiveSize.getResponsiveFontSize(
                                context,
                                mobile: 14.0,
                                tablet: 18.0,
                                largeTablet: 20.0,
                                desktop: 22.0,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              if (state is ListingsLoaded) {
                // Get the listings
                List<AddModel> items = state.listings;
                final isPremiumCategory =
                    widget.categoryTitle.toLowerCase().contains('premium');

                // For Premium Vehicles: Apply all filters client-side since we fetch all categories
                // (categoryId is null), so server-side filters may not work correctly
                if (isPremiumCategory) {
                  // First filter by isPremium
                  items = items
                      .where((ad) => ad.manufacturer?.isPremium == true)
                      .toList();

                  // Then apply all other filters from _filters map
                  // Manufacturer filter
                  final manufacturerIdsList = _filters['manufacturerIds'];
                  if (manufacturerIdsList != null &&
                      manufacturerIdsList is List &&
                      manufacturerIdsList.isNotEmpty) {
                    final manufacturerIds = manufacturerIdsList.cast<String>();
                    items = items
                        .where((ad) =>
                            ad.manufacturer?.id != null &&
                            manufacturerIds.contains(ad.manufacturer!.id))
                        .toList();
                  }

                  // Model filter
                  final modelIdsList = _filters['modelIds'];
                  if (modelIdsList != null &&
                      modelIdsList is List &&
                      modelIdsList.isNotEmpty) {
                    final modelIds = modelIdsList.cast<String>();
                    items = items
                        .where((ad) =>
                            ad.model?.id != null &&
                            modelIds.contains(ad.model!.id))
                        .toList();
                  }

                  // Fuel type filter
                  final fuelTypeIdsList = _filters['fuelTypeIds'];
                  if (fuelTypeIdsList != null &&
                      fuelTypeIdsList is List &&
                      fuelTypeIdsList.isNotEmpty) {
                    final fuelTypeIds = fuelTypeIdsList.cast<String>();
                    items = items
                        .where((ad) =>
                            ad.fuelTypeId != null &&
                            fuelTypeIds.contains(ad.fuelTypeId))
                        .toList();
                  }

                  // Transmission type filter
                  final transmissionTypeIdsList =
                      _filters['transmissionTypeIds'];
                  if (transmissionTypeIdsList != null &&
                      transmissionTypeIdsList is List &&
                      transmissionTypeIdsList.isNotEmpty) {
                    final transmissionTypeIds =
                        transmissionTypeIdsList.cast<String>();
                    items = items
                        .where((ad) =>
                            ad.transmissionId != null &&
                            transmissionTypeIds.contains(ad.transmissionId))
                        .toList();
                  }

                  // Year filter
                  final minYear = _filters['minYear'] as int?;
                  final maxYear = _filters['maxYear'] as int?;
                  if (minYear != null || maxYear != null) {
                    items = items.where((ad) {
                      if (ad.year == null) return false;
                      if (minYear != null && ad.year! < minYear) return false;
                      if (maxYear != null && ad.year! > maxYear) return false;
                      return true;
                    }).toList();
                  }

                  // Price filter
                  final minPrice = _filters['minPrice'] as int?;
                  final maxPrice = _filters['maxPrice'] as int?;
                  if (minPrice != null || maxPrice != null) {
                    items = items.where((ad) {
                      if (minPrice != null && ad.price < minPrice) return false;
                      if (maxPrice != null && ad.price > maxPrice) return false;
                      return true;
                    }).toList();
                  }
                }

                if (items.isEmpty) {
                  return Center(
                    child: Text(
                      'No ads found.',
                      style: TextStyle(
                        fontSize: GetResponsiveSize.getResponsiveFontSize(
                          context,
                          mobile: 16.0, // Keep mobile unchanged
                          tablet: 25.0,
                          largeTablet: 30.0,
                          desktop: 35.0,
                        ),
                        color: Colors.grey[700],
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    if (widget.categoryId == 'property') {
                      // Property filters
                      context.read<AdvertisementBloc>().add(
                            AdvertisementEvent.applyFilters(
                              categoryId: widget.categoryId,
                              propertyTypes:
                                  (_filters['propertyTypes'] as List?)
                                      ?.cast<String>(),
                              minBedrooms: _filters['minBedrooms'] as int?,
                              maxBedrooms: _filters['maxBedrooms'] as int?,
                              minPrice: _filters['minPrice'] as int?,
                              maxPrice: _filters['maxPrice'] as int?,
                              minArea: _filters['minArea'] as int?,
                              maxArea: _filters['maxArea'] as int?,
                              isFurnished: _filters['isFurnished'] as bool?,
                              hasParking: _filters['hasParking'] as bool?,
                            ),
                          );
                    } else {
                      // Vehicle filters
                      // For Premium Vehicles, pass null to fetch all categories
                      context.read<AdvertisementBloc>().add(
                            AdvertisementEvent.applyFilters(
                              categoryId: _effectiveCategoryId,
                              minYear: _filters['minYear'] as int?,
                              maxYear: _filters['maxYear'] as int?,
                              manufacturerIds:
                                  (_filters['manufacturerIds'] as List?)
                                      ?.cast<String>(),
                              modelIds: (_filters['modelIds'] as List?)
                                  ?.cast<String>(),
                              fuelTypeIds: (_filters['fuelTypeIds'] as List?)
                                  ?.cast<String>(),
                              transmissionTypeIds:
                                  (_filters['transmissionTypeIds'] as List?)
                                      ?.cast<String>(),
                              minPrice: _filters['minPrice'] as int?,
                              maxPrice: _filters['maxPrice'] as int?,
                            ),
                          );
                    }
                  },
                  child: ListView.builder(
                    controller: _scrollController,
                    // For Premium Vehicles, don't show loading indicator once list is loaded
                    // For other categories, show loading indicator if more pages are available
                    itemCount: items.length +
                        ((!isPremiumCategory && state.hasMore) ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index < items.length) {
                        final ad = items[index];
                        return Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: GetResponsiveSize.getResponsivePadding(
                              context,
                              mobile: 10,
                              tablet: 16,
                              largeTablet: 20,
                              desktop: 24,
                            ),
                            vertical: GetResponsiveSize.getResponsivePadding(
                              context,
                              mobile: 5,
                              tablet: 10,
                              largeTablet: 12,
                              desktop: 15,
                            ),
                          ),
                          child: GestureDetector(
                            onTap: () {
                              context.push('/add-detail-page', extra: ad);
                            },
                            child: Card(
                              color: AppColors.whiteColor,
                              elevation: GetResponsiveSize.getResponsiveSize(
                                context,
                                mobile: 5,
                                tablet: 6,
                                largeTablet: 7,
                                desktop: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  GetResponsiveSize.getResponsiveBorderRadius(
                                    context,
                                    mobile: 15,
                                    tablet: 18,
                                    largeTablet: 20,
                                    desktop: 22,
                                  ),
                                ),
                              ),
                              child: Stack(
                                children: [
                                  Padding(
                                    padding: EdgeInsets.all(
                                      GetResponsiveSize.getResponsivePadding(
                                        context,
                                        mobile: 12,
                                        tablet: 14,
                                        largeTablet: 16,
                                        desktop: 18,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            GetResponsiveSize
                                                .getResponsiveBorderRadius(
                                              context,
                                              mobile:
                                                  8, // Keep mobile unchanged
                                              tablet: 12,
                                              largeTablet: 14,
                                              desktop: 14,
                                            ),
                                          ),
                                          child: ad.images.isNotEmpty
                                              ? Image.network(
                                                  ad.images[0],
                                                  height: GetResponsiveSize
                                                      .getResponsiveSize(
                                                    context,
                                                    mobile:
                                                        60, // Keep mobile unchanged
                                                    tablet: 98,
                                                    largeTablet: 120,
                                                    desktop: 140,
                                                  ),
                                                  width: GetResponsiveSize
                                                      .getResponsiveSize(
                                                    context,
                                                    mobile:
                                                        60, // Keep mobile unchanged
                                                    tablet: 98,
                                                    largeTablet: 120,
                                                    desktop: 140,
                                                  ),
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error,
                                                      stackTrace) {
                                                    return Container(
                                                      height: GetResponsiveSize
                                                          .getResponsiveSize(
                                                        context,
                                                        mobile: 60,
                                                        tablet: 98,
                                                        largeTablet: 120,
                                                        desktop: 140,
                                                      ),
                                                      width: GetResponsiveSize
                                                          .getResponsiveSize(
                                                        context,
                                                        mobile: 60,
                                                        tablet: 98,
                                                        largeTablet: 120,
                                                        desktop: 140,
                                                      ),
                                                      color: Colors.grey[300],
                                                      child: const Icon(Icons
                                                          .image_not_supported),
                                                    );
                                                  },
                                                )
                                              : Container(
                                                  height: GetResponsiveSize
                                                      .getResponsiveSize(
                                                    context,
                                                    mobile: 60,
                                                    tablet: 100,
                                                    largeTablet: 120,
                                                    desktop: 140,
                                                  ),
                                                  width: GetResponsiveSize
                                                      .getResponsiveSize(
                                                    context,
                                                    mobile: 60,
                                                    tablet: 100,
                                                    largeTablet: 120,
                                                    desktop: 140,
                                                  ),
                                                  color: Colors.grey[300],
                                                  child: const Icon(Icons
                                                      .image_not_supported),
                                                ),
                                        ),
                                        SizedBox(
                                          width: GetResponsiveSize
                                              .getResponsiveSize(
                                            context,
                                            mobile: 15,
                                            tablet: 18,
                                            largeTablet: 20,
                                            desktop: 22,
                                          ),
                                        ),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(
                                                    '₹ ${ad.price.toString()}',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: GetResponsiveSize
                                                          .getResponsiveFontSize(
                                                        context,
                                                        mobile:
                                                            16.0, // Keep mobile unchanged
                                                        tablet: 22.0,
                                                        largeTablet: 26.0,
                                                        desktop: 30.0,
                                                      ),
                                                    ),
                                                  ),
                                                  const Spacer(),
                                                ],
                                              ),
                                              SizedBox(
                                                height: GetResponsiveSize
                                                    .getResponsiveSize(
                                                  context,
                                                  mobile: 5,
                                                  tablet: 6,
                                                  largeTablet: 7,
                                                  desktop: 8,
                                                ),
                                              ),
                                              Text(
                                                _getAdTitle(ad),
                                                style: TextStyle(
                                                  fontSize: GetResponsiveSize
                                                      .getResponsiveFontSize(
                                                    context,
                                                    mobile:
                                                        16.0, // Keep mobile unchanged
                                                    tablet: 20.0,
                                                    largeTablet: 22.0,
                                                    desktop: 24.0,
                                                  ),
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              Text(
                                                ad.location,
                                                style: AppTextstyle
                                                    .categoryLabelTextStyle
                                                    .copyWith(
                                                  fontSize: GetResponsiveSize
                                                      .getResponsiveFontSize(
                                                    context,
                                                    mobile:
                                                        12.0, // Keep mobile unchanged
                                                    tablet: 14.0,
                                                    largeTablet: 16.0,
                                                    desktop: 18.0,
                                                  ),
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              SizedBox(
                                                height: GetResponsiveSize
                                                    .getResponsiveSize(
                                                  context,
                                                  mobile: 5,
                                                  tablet: 6,
                                                  largeTablet: 7,
                                                  desktop: 8,
                                                ),
                                              ),
                                              Text(
                                                _getAdSubtitle(ad),
                                                style: AppTextstyle
                                                    .categoryLabelTextStyle
                                                    .copyWith(
                                                  fontSize: GetResponsiveSize
                                                      .getResponsiveFontSize(
                                                    context,
                                                    mobile:
                                                        12.0, // Keep mobile unchanged
                                                    tablet: 14.0,
                                                    largeTablet: 16.0,
                                                    desktop: 18.0,
                                                  ),
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                  // Premium badge in top right corner
                                  if (ad.manufacturer?.isPremium == true)
                                    Positioned(
                                      top: GetResponsiveSize.getResponsiveSize(
                                        context,
                                        mobile: 8,
                                        tablet: 10,
                                        largeTablet: 12,
                                        desktop: 14,
                                      ),
                                      right:
                                          GetResponsiveSize.getResponsiveSize(
                                        context,
                                        mobile: 8,
                                        tablet: 10,
                                        largeTablet: 12,
                                        desktop: 14,
                                      ),
                                      child: Container(
                                        width:
                                            GetResponsiveSize.getResponsiveSize(
                                          context,
                                          mobile: 32,
                                          tablet: 40,
                                          largeTablet: 48,
                                          desktop: 56,
                                        ),
                                        height:
                                            GetResponsiveSize.getResponsiveSize(
                                          context,
                                          mobile: 32,
                                          tablet: 40,
                                          largeTablet: 48,
                                          desktop: 56,
                                        ),
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                        padding: EdgeInsets.all(
                                          GetResponsiveSize.getResponsiveSize(
                                            context,
                                            mobile: 6,
                                            tablet: 8,
                                            largeTablet: 10,
                                            desktop: 12,
                                          ),
                                        ),
                                        child: Image.asset(
                                          'assets/images/vip-crown-2-line copy.png',
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      } else {
                        return const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                    },
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }

  String _getAdTitle(AddModel ad) {
    if (ad.vehicleType != null) {
      return '${ad.manufacturer?.name ?? ''} ${ad.model?.name ?? ''} ${ad.year ?? ''}'
          .trim();
    } else if (ad.propertyType != null) {
      return '${ad.propertyType} - ${ad.bedrooms ?? 0} BHK';
    } else {
      return ad.description.length > 50
          ? '${ad.description.substring(0, 50)}...'
          : ad.description;
    }
  }

  String _getAdSubtitle(AddModel ad) {
    if (ad.vehicleType != null) {
      return '${ad.mileage ?? 0} KM • ${ad.fuelType ?? 'N/A'} • ${ad.transmission ?? 'N/A'}';
    } else if (ad.propertyType != null) {
      return '${ad.areaSqft ?? 0} sq ft • ${ad.bathrooms ?? 0} bathrooms';
    } else {
      return ''; // Don't show category for other ad types
    }
  }

  String _getUserFriendlyErrorMessage(String errorMessage) {
    // Check for common Dio exception patterns and convert to user-friendly messages
    final message = errorMessage.toLowerCase();

    // Network/Connection errors
    if (message.contains('socketexception') ||
        message.contains('failed host lookup') ||
        message.contains('network is unreachable') ||
        message.contains('connectionerror') ||
        message.contains('no internet')) {
      return 'Unable to connect to the server. Please check your internet connection and try again.';
    }

    // Timeout errors
    if (message.contains('timeout') ||
        message.contains('connection timeout') ||
        message.contains('receive timeout') ||
        message.contains('send timeout')) {
      return 'Request timed out. Please try again.';
    }

    // Server errors
    if (message.contains('500') || message.contains('internal server error')) {
      return 'Server error occurred. Please try again later.';
    }

    if (message.contains('404') || message.contains('not found')) {
      return 'The requested information could not be found.';
    }

    if (message.contains('403') || message.contains('forbidden')) {
      return 'You do not have permission to access this content.';
    }

    if (message.contains('401') || message.contains('unauthorized')) {
      return 'Please log in again to continue.';
    }

    if (message.contains('400') || message.contains('bad request')) {
      return 'Invalid request. Please try again.';
    }

    // DioException patterns
    if (message.contains('dioexception') || message.contains('dio')) {
      return 'Network error occurred. Please check your connection and try again.';
    }

    // Generic error patterns
    if (message.contains('exception:') || message.contains('error:')) {
      // Try to extract a cleaner message
      final parts = errorMessage.split(':');
      if (parts.length > 1) {
        final cleanMessage = parts.sublist(1).join(':').trim();
        if (cleanMessage.isNotEmpty &&
            !cleanMessage.toLowerCase().contains('dio') &&
            !cleanMessage.toLowerCase().contains('exception')) {
          return cleanMessage;
        }
      }
    }

    // If it's a very technical error message, show a generic friendly message
    if (message.contains('dio') ||
        message.contains('exception') ||
        message.length > 100 ||
        message.contains('stacktrace') ||
        message.contains('at ')) {
      return 'Something went wrong. Please try again later.';
    }

    // Return the original message if it seems user-friendly already
    return errorMessage;
  }
}
