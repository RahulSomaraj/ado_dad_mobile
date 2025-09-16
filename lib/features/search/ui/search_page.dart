import 'package:ado_dad_user/common/app_colors.dart';
import 'package:ado_dad_user/common/app_textstyle.dart';
import 'package:ado_dad_user/features/home/bloc/advertisement_bloc.dart';
import 'package:ado_dad_user/models/advertisement_model/add_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class SearchPage extends StatefulWidget {
  final String? previousRoute;
  const SearchPage({super.key, this.previousRoute});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<AddModel> allAds = [];
  List<AddModel> filteredAds = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    // Initialize with all ads from the bloc
    _loadAllAds();
  }

  void _loadAllAds() {
    // Trigger the bloc to fetch all ads
    context.read<AdvertisementBloc>().add(const FetchAllListingsEvent());
  }

  void _handleBackNavigation() {
    // If previousRoute is provided, navigate to that specific route
    if (widget.previousRoute != null) {
      context.go(widget.previousRoute!);
    } else {
      // Fallback to pop if no previous route is specified
      context.pop();
    }
  }

  // Function to filter ads based on the search term
  void _filterAds(String query) {
    if (query.isEmpty) {
      setState(() {
        filteredAds = allAds;
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    final filteredList = allAds.where((ad) {
      final searchQuery = query.toLowerCase();

      // Search across multiple fields
      return ad.description.toLowerCase().contains(searchQuery) ||
          ad.category.toLowerCase().contains(searchQuery) ||
          ad.location.toLowerCase().contains(searchQuery) ||
          (ad.manufacturer?.name?.toLowerCase().contains(searchQuery) ??
              false) ||
          (ad.model?.name.toLowerCase().contains(searchQuery) ?? false) ||
          (ad.vehicleType?.toLowerCase().contains(searchQuery) ?? false) ||
          (ad.propertyType?.toLowerCase().contains(searchQuery) ?? false) ||
          ad.price.toString().contains(searchQuery);
    }).toList();

    setState(() {
      filteredAds = filteredList;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.whiteColor,
        leading: IconButton(
          onPressed: () => _handleBackNavigation(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            fillColor: Colors.grey[50],
            hintText: "Search ads...",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            isDense: true,
            contentPadding: EdgeInsets.symmetric(vertical: 5, horizontal: 12),
            prefixIcon: Image.asset(
              'assets/images/search-icon.png',
              color: AppColors.greyColor,
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      _filterAds('');
                      setState(() {});
                    },
                    child: Image.asset('assets/images/close.png'),
                  )
                : null,
          ),
          onChanged: (value) {
            _filterAds(value);
            setState(() {});
          },
        ),
        // actions: [
        //   Padding(
        //     padding: EdgeInsets.symmetric(horizontal: 10),
        //     child: Row(
        //       children: [
        //         GestureDetector(
        //           child: Image.asset('assets/images/location.png'),
        //         ),
        //         SizedBox(width: 15),
        //         GestureDetector(
        //           child: Image.asset('assets/images/filter.png'),
        //         )
        //       ],
        //     ),
        //   )
        // ],
      ),
      body: BlocConsumer<AdvertisementBloc, AdvertisementState>(
        listener: (context, state) {
          state.when(
            initial: () {},
            loading: () {},
            listingsLoaded: (listings, hasMore) {
              setState(() {
                allAds = listings;
                if (!_isSearching) {
                  filteredAds = listings;
                }
              });
            },
            error: (message) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(message)),
              );
            },
          );
        },
        builder: (context, state) {
          return state.when(
            initial: () => _buildLoadingState(),
            loading: () => _buildLoadingState(),
            listingsLoaded: (listings, hasMore) => _buildAdsList(),
            error: (message) => _buildErrorState(message),
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Failed to load ads',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadAllAds,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildAdsList() {
    if (filteredAds.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isSearching ? Icons.search_off : Icons.inventory_2_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _isSearching ? 'No results found' : 'No ads available',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              _isSearching
                  ? 'Try searching with different keywords'
                  : 'Check back later for new listings',
              style: TextStyle(color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredAds.length,
      itemBuilder: (BuildContext context, int index) {
        final ad = filteredAds[index];
        return _buildAdCard(ad);
      },
    );
  }

  Widget _buildAdCard(AddModel ad) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: GestureDetector(
        onTap: () {
          // Navigate to ad detail page
          context.push('/add-detail-page', extra: ad);
        },
        child: Card(
          color: AppColors.whiteColor,
          elevation: 5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: ad.images.isNotEmpty
                      ? Image.network(
                          ad.images[0],
                          height: 98,
                          width: 98,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 98,
                              width: 98,
                              color: Colors.grey[300],
                              child: const Icon(Icons.image_not_supported),
                            );
                          },
                        )
                      : Container(
                          height: 100,
                          width: 100,
                          color: Colors.grey[300],
                          child: const Icon(Icons.image_not_supported),
                        ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '₹ ${ad.price.toString()}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const Spacer(),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _getAdTitle(ad),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        ad.location,
                        style: AppTextstyle.categoryLabelTextStyle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _getAdSubtitle(ad),
                        style: AppTextstyle.categoryLabelTextStyle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                )
              ],
            ),
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
}
