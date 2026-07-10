import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:ado_dad_user/common/app_colors.dart';
import 'package:ado_dad_user/common/widgets/rich_ad_card.dart';
import 'package:ado_dad_user/common/widgets/skeleton.dart';
import 'package:ado_dad_user/common/app_textstyle.dart';
import 'package:ado_dad_user/common/get_responsive_size.dart';
import 'package:ado_dad_user/common/api_service.dart';
import 'package:ado_dad_user/features/home/bloc/advertisement_bloc.dart';
import 'package:ado_dad_user/models/advertisement_model/add_model.dart';
import 'package:ado_dad_user/services/filter_state_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';

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

  /// Client-side sort of the loaded list (wireframe: "Category list" chips).
  String _sort = 'newest'; // newest | price_desc | price_asc
  final FilterStateService _filterStateService = FilterStateService();
  final Dio _dio = ApiService().dio;
  Map<String, bool?> _manufacturerPremiumCache =
      {}; // Cache manufacturer isPremium
  double? _lat;
  double? _lng;

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

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 300) {
        context.read<AdvertisementBloc>().add(
              const AdvertisementEvent.fetchNextPage(),
            );
      }
    });

    Future.microtask(() => _initLoad());
  }

  Future<void> _initLoad() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission != LocationPermission.denied &&
          permission != LocationPermission.deniedForever) {
        final pos = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.low,
            timeLimit: const Duration(seconds: 5));
        _lat = pos.latitude;
        _lng = pos.longitude;
      }
    } catch (_) {}

    if (!mounted) return;

    // For Premium Vehicles, pass null to fetch all ads (will filter by isPremium client-side)
    context.read<AdvertisementBloc>().add(
          AdvertisementEvent.applyFilters(
            categoryId: _effectiveCategoryId,
            latitude: _lat,
            longitude: _lng,
          ),
        );

    if (_isPremiumVehiclesCategory) {
      _fetchManufacturerPremiumData();
    }
  }

  /// Fetch manufacturer isPremium data from API
  Future<void> _fetchManufacturerPremiumData() async {
    if (_manufacturerPremiumCache.isNotEmpty) return; // Already cached

    try {
      final response = await _dio.get('/vehicle-inventory/manufacturers');
      if (response.statusCode == 200 && response.data['data'] != null) {
        final List<dynamic> manufacturers = response.data['data'];
        for (final mfg in manufacturers) {
          if (mfg is Map<String, dynamic>) {
            final id = (mfg['_id'] ?? mfg['id'] ?? '').toString();
            final isPremium = mfg['isPremium'] as bool?;
            if (id.isNotEmpty) {
              _manufacturerPremiumCache[id] = isPremium ?? false;
            }
          }
        }
        print(
            '✅ Cached ${_manufacturerPremiumCache.length} manufacturers with isPremium data');
      }
    } catch (e) {
      print('⚠️ Error fetching manufacturer isPremium: $e');
    }
  }

  /// Enrich ad's manufacturer with isPremium from cache
  AddModel _enrichAdWithPremium(AddModel ad) {
    if (ad.manufacturer == null) return ad;
    if (ad.manufacturer!.isPremium != null) return ad; // Already has isPremium

    // Get isPremium from cache
    final isPremium = _manufacturerPremiumCache[ad.manufacturer!.id];
    if (isPremium != null) {
      // Create enriched manufacturer with isPremium
      final enrichedMfg = Manufacturer(
        id: ad.manufacturer!.id,
        name: ad.manufacturer!.name,
        displayName: ad.manufacturer!.displayName,
        isPremium: isPremium,
      );
      return ad.copyWith(manufacturer: enrichedMfg);
    }

    return ad;
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
                              latitude: _lat,
                              longitude: _lng,
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
                              latitude: _lat,
                              longitude: _lng,
                              commercialVehicleTypes:
                                  (result['commercialVehicleTypes'] as List?)
                                      ?.cast<String>(),
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
                return const SkeletonList();
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
                                    latitude: _lat,
                                    longitude: _lng,
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
                // Get the listings (this accumulates all pages)
                List<AddModel> items = state.listings;
                final isPremiumCategory =
                    widget.categoryTitle.toLowerCase().contains('premium');

                // For Premium Vehicles: Apply all filters client-side since we fetch all categories
                // (categoryId is null), so server-side filters may not work correctly
                if (isPremiumCategory) {
                  // Debug: Show total items from all pages
                  print(
                      '📦 Total items loaded from all pages: ${items.length} (hasMore: ${state.hasMore})');

                  // Enrich ads with manufacturer isPremium data from cache
                  items = items.map((ad) => _enrichAdWithPremium(ad)).toList();

                  // Debug: Check what's in the manufacturer objects
                  print(
                      '🔍 Premium Category Filter - Total items before filter: ${items.length}');

                  // Check for specific ad ID
                  final specificAdId = '690325a2fb5f59e577b0208c';
                  final specificAd =
                      items.where((ad) => ad.id == specificAdId).firstOrNull;
                  if (specificAd != null) {
                    print('🎯 SPECIFIC AD FOUND - ID: ${specificAd.id}');
                    print('🎯 Manufacturer ID: ${specificAd.manufacturer?.id}');
                    print(
                        '🎯 Manufacturer isPremium: ${specificAd.manufacturer?.isPremium}');
                    print(
                        '🎯 Manufacturer name: ${specificAd.manufacturer?.name}');
                    print(
                        '🎯 Manufacturer object: ${specificAd.manufacturer?.toJson()}');
                  } else {
                    print('⚠️ SPECIFIC AD NOT FOUND in items list');
                  }

                  // Count how many have isPremium == true
                  final premiumCount = items
                      .where((ad) => ad.manufacturer?.isPremium == true)
                      .length;
                  print(
                      '📊 Ads with isPremium == true: $premiumCount out of ${items.length}');

                  // First filter by isPremium
                  items = items.where((ad) {
                    final isPremium = ad.manufacturer?.isPremium == true;
                    if (ad.id == specificAdId) {
                      print(
                          '🎯 FILTERING - Ad ID: ${ad.id}, isPremium result: $isPremium');
                    }
                    return isPremium;
                  }).toList();

                  print(
                      '✅ Premium Category Filter - Total items after filter: ${items.length}');

                  // Check if specific ad is in filtered list
                  final isInFilteredList =
                      items.any((ad) => ad.id == specificAdId);
                  print('🎯 SPECIFIC AD IN FILTERED LIST: $isInFilteredList');

                  // Debug: Print all filtered ad IDs
                  print(
                      '📋 Filtered ad IDs: ${items.map((ad) => ad.id).toList()}');

                  // For premium category, we need to load ALL pages to get all premium items
                  // Since filtering is client-side, we need all data first
                  // Auto-load more pages if we have more data available
                  if (state.hasMore) {
                    print(
                        '🔄 Auto-loading more pages for premium category (hasMore: true)...');
                    // Use Future.microtask to avoid setState during build
                    Future.microtask(() {
                      if (mounted) {
                        context.read<AdvertisementBloc>().add(
                              const AdvertisementEvent.fetchNextPage(),
                            );
                      }
                    });
                  } else {
                    print('✅ All pages loaded (hasMore: false)');
                  }

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

                // Client-side sorting (does not mutate bloc state)
                if (_sort == 'price_desc') {
                  items = List.of(items)
                    ..sort((a, b) => b.price.compareTo(a.price));
                } else if (_sort == 'price_asc') {
                  items = List.of(items)
                    ..sort((a, b) => a.price.compareTo(b.price));
                }

                if (items.isEmpty) {
                  return _buildEmptyState(context);
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSortChips(context),
                    Expanded(
                      child: _buildListingsGrid(context, state, items),
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }

  /// Sort chip row (wireframe: docs/ado_dad_wireframes_missing_pages.html
  /// → "Category list").
  Widget _buildSortChips(BuildContext context) {
    const options = [
      ('newest', 'Newest'),
      ('price_desc', 'Price ↓'),
      ('price_asc', 'Price ↑'),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 10, 15, 0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: options.map((option) {
            final selected = _sort == option.$1;
            return Padding(
              padding: const EdgeInsets.only(right: 7),
              child: ChoiceChip(
                label: Text(option.$2),
                selected: selected,
                onSelected: (_) => setState(() => _sort = option.$1),
                selectedColor: AppColors.primaryColor,
                labelStyle: TextStyle(
                  fontSize: GetResponsiveSize.getResponsiveFontSize(context,
                      mobile: 12, tablet: 15, largeTablet: 17, desktop: 19),
                  color: selected ? Colors.white : AppColors.blackColor,
                ),
                backgroundColor: AppColors.whiteColor,
                shape: StadiumBorder(
                  side: BorderSide(
                    color: selected
                        ? AppColors.primaryColor
                        : AppColors.greyColor.withOpacity(0.4),
                  ),
                ),
                showCheckmark: false,
                visualDensity: VisualDensity.compact,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  /// Friendly empty state with a filter reset (wireframe: "Category list").
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sentiment_dissatisfied_outlined,
              size: GetResponsiveSize.getResponsiveSize(context,
                  mobile: 40, tablet: 52, largeTablet: 64, desktop: 76),
              color: AppColors.greyColor,
            ),
            const SizedBox(height: 10),
            Text(
              'No ads found',
              style: TextStyle(
                fontSize: GetResponsiveSize.getResponsiveFontSize(
                  context,
                  mobile: 16.0, // Keep mobile unchanged
                  tablet: 25.0,
                  largeTablet: 30.0,
                  desktop: 35.0,
                ),
                fontWeight: FontWeight.w600,
                color: AppColors.blackColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Try clearing a filter or widening your price range.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: GetResponsiveSize.getResponsiveFontSize(context,
                    mobile: 12.5, tablet: 16, largeTablet: 18, desktop: 20),
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 14),
            OutlinedButton(
              onPressed: _resetFilters,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.greyColor.withOpacity(0.6)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
              ),
              child: Text(
                'Reset filters',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: AppColors.blackColor,
                  fontSize: GetResponsiveSize.getResponsiveFontSize(context,
                      mobile: 13, tablet: 16, largeTablet: 18, desktop: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _resetFilters() {
    setState(() {
      _filters = {};
      _sort = 'newest';
    });
    context.read<AdvertisementBloc>().add(
          AdvertisementEvent.applyFilters(
            categoryId: widget.categoryId == 'property'
                ? widget.categoryId
                : _effectiveCategoryId,
            latitude: _lat,
            longitude: _lng,
          ),
        );
  }

  Widget _buildListingsGrid(
      BuildContext context, ListingsLoaded state, List<AddModel> items) {
    final isPremiumCategory =
        widget.categoryTitle.toLowerCase().contains('premium');
    return RefreshIndicator(
                  onRefresh: () async {
                    if (widget.categoryId == 'property') {
                      // Property filters
                      context.read<AdvertisementBloc>().add(
                            AdvertisementEvent.applyFilters(
                              categoryId: widget.categoryId,
                              latitude: _lat,
                              longitude: _lng,
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
                              latitude: _lat,
                              longitude: _lng,
                              commercialVehicleTypes:
                                  (_filters['commercialVehicleTypes'] as List?)
                                      ?.cast<String>(),
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
                  child: GridView.builder(
                    controller: _scrollController,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                      mainAxisExtent:
                          richAdCardMainAxisExtent(context, columns: 2),
                    ),
                    padding: const EdgeInsets.fromLTRB(15, 10, 15, 100),
                    // For Premium Vehicles, don't show loading indicator once list is loaded
                    // For other categories, show loading indicator if more pages are available
                    itemCount: items.length +
                        ((!isPremiumCategory && state.hasMore) ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index < items.length) {
                        return RichAdCard(ad: items[index]);
                      } else {
                        return const Center(
                            child: CircularProgressIndicator());
                      }
                    },
                  ),
                );
  }

  String _getAdTitle(AddModel ad) {
    if (ad.vehicleType != null) {
      return '${ad.manufacturer?.name ?? ''} ${ad.model?.name ?? ''} ${ad.year ?? ''}'
          .trim();
    } else if (ad.propertyType != null) {
      if (ad.propertyType!.toLowerCase() == 'plot') {
        return ad.propertyType!;
      }
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
