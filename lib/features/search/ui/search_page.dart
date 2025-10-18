import 'package:ado_dad_user/common/app_colors.dart';
import 'package:ado_dad_user/common/app_textstyle.dart';
import 'package:ado_dad_user/common/google_places_service.dart';
import 'package:ado_dad_user/config/app_config.dart';
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
  bool _isLocationSearchMode = false;
  List<String> _addressSuggestions = [];
  bool _showSuggestions = false;
  late GooglePlacesService _placesService;

  @override
  void initState() {
    super.initState();
    // Initialize Google Places service
    _placesService = GooglePlacesService(apiKey: AppConfig.googlePlacesApiKey);
    // Initialize with all ads from the bloc
    _loadAllAds();
    // Ensure initial state shows all ads
    _isSearching = false;
  }

  void _loadAllAds() {
    // Check if we already have ads in the current state
    final currentState = context.read<AdvertisementBloc>().state;
    if (currentState is ListingsLoaded && currentState.listings.isNotEmpty) {
      setState(() {
        allAds = currentState.listings;
        filteredAds = currentState.listings;
        _isSearching = false;
      });
    } else {
      // Trigger the bloc to fetch all ads
      context.read<AdvertisementBloc>().add(const FetchAllListingsEvent());
    }
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

  void _handleLocationTap() {
    setState(() {
      _isLocationSearchMode = !_isLocationSearchMode;
      // Clear search when switching modes
      _searchController.clear();
      _filterAds('');
      _showSuggestions = false;
      _addressSuggestions.clear();
    });
  }

  void _generateAddressSuggestions(String query) async {
    if (query.isEmpty) {
      setState(() {
        _addressSuggestions.clear();
        _showSuggestions = false;
      });
      return;
    }

    // Minimum 2 characters for Google Places API
    if (query.length < 2) {
      setState(() {
        _addressSuggestions.clear();
        _showSuggestions = false;
      });
      return;
    }

    try {
      // Use Google Places API to get location suggestions
      final predictions = await _placesService.getPlacePredictions(
        input: query,
        region: 'in', // Bias results to India
        language: 'en',
      );

      if (predictions.isNotEmpty) {
        // Extract descriptions from predictions
        final suggestions = predictions
            .map((prediction) => prediction.description)
            .take(10) // Limit to 10 suggestions
            .toList();

        setState(() {
          _addressSuggestions = suggestions;
          _showSuggestions = suggestions.isNotEmpty;
        });
      } else {
        // If no Google Places results, fall back to existing ad locations
        _fallbackToExistingLocations(query);
      }
    } catch (e) {
      print('Google Places API error: $e');
      // Fall back to existing ad locations if API fails
      _fallbackToExistingLocations(query);
    }
  }

  void _fallbackToExistingLocations(String query) {
    // Get unique locations from all ads as fallback
    final uniqueLocations = allAds
        .map((ad) => ad.location)
        .where((location) => location.isNotEmpty)
        .toSet()
        .toList();

    // Filter locations that start with the query (prioritize exact matches)
    final exactMatches = uniqueLocations
        .where((location) =>
            location.toLowerCase().startsWith(query.toLowerCase()))
        .take(5)
        .toList();

    // If we don't have enough exact matches, add partial matches
    final suggestions = <String>[];
    suggestions.addAll(exactMatches);

    if (suggestions.length < 5) {
      final partialMatches = uniqueLocations
          .where((location) =>
              !location.toLowerCase().startsWith(query.toLowerCase()) &&
              location.toLowerCase().contains(query.toLowerCase()))
          .take(5 - suggestions.length)
          .toList();
      suggestions.addAll(partialMatches);
    }

    setState(() {
      _addressSuggestions = suggestions;
      _showSuggestions = suggestions.isNotEmpty;
    });
  }

  // Function to filter ads based on the search term
  void _filterAds(String query) {
    if (query.isEmpty) {
      setState(() {
        filteredAds = allAds;
        _isSearching = false;
        _showSuggestions = false;
        _addressSuggestions.clear();
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    if (_isLocationSearchMode) {
      // In location mode, generate suggestions immediately without delay
      _generateAddressSuggestions(query);
      return;
    }

    // Global search mode - search across multiple fields
    final filteredList = allAds.where((ad) {
      final searchQuery = query.toLowerCase();
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

  void _selectAddressSuggestion(String address) async {
    setState(() {
      _searchController.text = address;
      _showSuggestions = false;
      _addressSuggestions.clear();
    });

    try {
      // Find the place ID for the selected address
      final predictions = await _placesService.getPlacePredictions(
        input: address,
        region: 'in',
        language: 'en',
      );

      if (predictions.isNotEmpty) {
        // Find the exact match for the selected address
        final selectedPrediction = predictions.firstWhere(
          (prediction) => prediction.description == address,
          orElse: () => predictions.first,
        );

        // Get place details to get coordinates
        final placeDetails = await _placesService.getPlaceDetails(
          selectedPrediction.placeId,
        );

        if (placeDetails?.geometry?.location != null) {
          final location = placeDetails!.geometry!.location;

          // Call the location-based API
          context.read<AdvertisementBloc>().add(
                AdvertisementEvent.searchByLocation(
                  latitude: location.lat,
                  longitude: location.lng,
                ),
              );

          setState(() {
            _isSearching = true;
          });
          return;
        }
      }
    } catch (e) {
      print('Error getting coordinates for location: $e');
    }

    // Fallback to text-based filtering if coordinates are not available
    final filteredList = allAds.where((ad) {
      return ad.location.toLowerCase().contains(address.toLowerCase());
    }).toList();

    setState(() {
      filteredAds = filteredList;
      _isSearching = true;
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
        title: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  fillColor:
                      _isLocationSearchMode ? Colors.blue[50] : Colors.grey[50],
                  hintText: _isLocationSearchMode
                      ? "Search by location..."
                      : "Search ads...",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: _isLocationSearchMode
                          ? AppColors.primaryColor
                          : Colors.grey,
                      width: _isLocationSearchMode ? 2 : 1,
                    ),
                  ),
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 5, horizontal: 12),
                  prefixIcon: Image.asset(
                    'assets/images/search-icon.png',
                    color: _isLocationSearchMode
                        ? AppColors.primaryColor
                        : AppColors.greyColor,
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
            ),
            const SizedBox(width: 10),
            Container(
              decoration: BoxDecoration(
                color: _isLocationSearchMode
                    ? AppColors.primaryColor.withOpacity(0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                onPressed: () {
                  // Handle location button tap
                  _handleLocationTap();
                },
                icon: Image.asset(
                  'assets/images/location.png',
                  width: 24,
                  height: 24,
                  color: _isLocationSearchMode
                      ? AppColors.primaryColor
                      : AppColors.greyColor,
                ),
              ),
            ),
          ],
        ),
      ),
      body: GestureDetector(
        onTap: () {
          // Hide suggestions when tapping outside
          if (_showSuggestions) {
            setState(() {
              _showSuggestions = false;
            });
          }
        },
        child: Stack(
          children: [
            BlocConsumer<AdvertisementBloc, AdvertisementState>(
              listener: (context, state) {
                state.when(
                  initial: () {},
                  loading: () {},
                  listingsLoaded: (listings, hasMore) {
                    setState(() {
                      allAds = listings;
                      // Always update filteredAds when new listings are loaded
                      // If not currently searching, show all ads
                      if (!_isSearching || _searchController.text.isEmpty) {
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
            // Address suggestions overlay
            if (_showSuggestions && _isLocationSearchMode)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: _addressSuggestions.map((suggestion) {
                      return ListTile(
                        leading: const Icon(Icons.location_on,
                            color: AppColors.primaryColor),
                        title: Text(suggestion),
                        onTap: () => _selectAddressSuggestion(suggestion),
                        dense: true,
                      );
                    }).toList(),
                  ),
                ),
              ),
          ],
        ),
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
