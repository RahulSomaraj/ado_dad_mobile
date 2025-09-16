import 'package:ado_dad_user/common/app_colors.dart';
import 'package:ado_dad_user/common/app_textstyle.dart';
import 'package:ado_dad_user/features/home/bloc/advertisement_bloc.dart';
import 'package:ado_dad_user/models/advertisement_model/add_model.dart';
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

  @override
  void initState() {
    super.initState();

    // initial load: category with no filters
    context.read<AdvertisementBloc>().add(
          AdvertisementEvent.applyFilters(categoryId: widget.categoryId),
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
              icon: const Icon(Icons.arrow_back)),
          title: Text(widget.categoryTitle, style: AppTextstyle.appbarText),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: GestureDetector(
                // AppBar actions -> onTap:
                onTap: () async {
                  // Check if this is a property category
                  if (widget.categoryId == 'property') {
                    final result = await context.push('/property-filter');
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
                    final result = await context.push('/car-filter');
                    if (result is Map<String, dynamic>) {
                      _filters = result;
                      context.read<AdvertisementBloc>().add(
                            AdvertisementEvent.applyFilters(
                              categoryId: widget.categoryId,
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

                child: Image.asset('assets/images/filter.png'),
              ),
            ),
          ],
        ),
        // body: _buildCategoryListView(),
        body: BlocBuilder<AdvertisementBloc, AdvertisementState>(
          builder: (context, state) {
            if (state is AdvertisementLoading ||
                state is AdvertisementInitial) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is AdvertisementError) {
              return Center(child: Text(state.message));
            }
            if (state is ListingsLoaded) {
              final items = state.listings;
              if (items.isEmpty) {
                return const Center(child: Text('No ads found.'));
              }

              return RefreshIndicator(
                onRefresh: () async {
                  if (widget.categoryId == 'property') {
                    // Property filters
                    context.read<AdvertisementBloc>().add(
                          AdvertisementEvent.applyFilters(
                            categoryId: widget.categoryId,
                            propertyTypes: (_filters['propertyTypes'] as List?)
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
                    context.read<AdvertisementBloc>().add(
                          AdvertisementEvent.applyFilters(
                            categoryId: widget.categoryId,
                            minYear: _filters['minYear'] as int?,
                            maxYear: _filters['maxYear'] as int?,
                            manufacturerIds:
                                (_filters['manufacturerIds'] as List?)
                                    ?.cast<String>(),
                            modelIds:
                                (_filters['modelIds'] as List?)?.cast<String>(),
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
                  itemCount: items.length + (state.hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index < items.length) {
                      final ad = items[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        child: Card(
                          color: AppColors.whiteColor,
                          elevation: 5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: ListTile(
                            onTap: () {
                              context.push('/add-detail-page', extra: ad);
                            },
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: ad.images.isNotEmpty
                                  ? Image.network(
                                      ad.images[0],
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                    )
                                  : const SizedBox.shrink(),
                            ),
                            title: Text(
                              "₹${ad.price}",
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(ad.description,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                                Text(ad.location,
                                    style: const TextStyle(color: Colors.grey)),
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
    );
  }
}
