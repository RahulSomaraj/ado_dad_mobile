import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:ado_dad_user/common/app_colors.dart';
import 'package:ado_dad_user/common/widgets/skeleton.dart';
import 'package:ado_dad_user/common/app_textstyle.dart';
import 'package:ado_dad_user/common/get_responsive_size.dart';
import 'package:ado_dad_user/common/google_places_service.dart';
import 'package:ado_dad_user/config/app_config.dart';
import 'package:ado_dad_user/common/shared_pref.dart';
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
  late ScrollController _scrollController;

  // Quick-search chips: persisted recents + a curated trending list.
  List<String> _recentSearches = [];
  static const List<String> _trendingSearches = [
    'Swift',
    'Activa',
    'Creta',
    'Royal Enfield',
    'Bolero',
    'Pulsar',
    '2BHK',
    'Scorpio',
  ];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    // Initialize Google Places service
    _placesService = GooglePlacesService(apiKey: AppConfig.googlePlacesApiKey);
    // Initialize with all ads from the bloc
    _loadAllAds();
    // Load saved recent searches for the quick-search chips
    _loadRecentSearches();
    // Ensure initial state shows all ads
    _isSearching = false;
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final threshold = 200; // px before bottom
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;

    if (maxScroll - currentScroll <= threshold) {
      final bloc = context.read<AdvertisementBloc>();
      final state = bloc.state;

      if (state is ListingsLoaded && state.hasMore) {
        if (_isSearching && !_isLocationSearchMode) {
          bloc.add(const SearchNextPageEvent());
        } else if (_isSearching && _isLocationSearchMode) {
          bloc.add(const FetchNextPageEvent());
        } else if (!_isSearching) {
          bloc.add(const FetchNextPageEvent());
        }
      }
    }
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
    // Navigate to the previous route only if it's a valid absolute path
    // (go_router requires a leading '/'); otherwise fall back to pop.
    final prev = widget.previousRoute;
    if (prev != null && prev.startsWith('/')) {
      context.go(prev);
    } else if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
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

        print(
            '🔍 Location suggestions for "$query": ${suggestions.length} found');
        for (int i = 0; i < suggestions.length; i++) {
          print('  ${i + 1}. ${suggestions[i]}');
        }

        setState(() {
          _addressSuggestions = suggestions;
          _showSuggestions = suggestions.isNotEmpty;
        });
      } else {
        // If no Google Places results, fall back to existing ad locations
        print('🔍 No Google Places results for "$query", using fallback');
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

    context.read<AdvertisementBloc>().add(
          AdvertisementEvent.searchAds(query: query),
        );
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

          // Print location data to console
          print('📍 Selected Location: $address');
          print('🌍 Latitude: ${location.lat}');
          print('🌍 Longitude: ${location.lng}');
          print('📍 Formatted Address: ${placeDetails.formattedAddress}');

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
    print('📍 Fallback Location Search: $address');
    print('⚠️ Coordinates not available, using text-based filtering');

    final filteredList = allAds.where((ad) {
      return ad.location.toLowerCase().contains(address.toLowerCase());
    }).toList();

    setState(() {
      filteredAds = filteredList;
      _isSearching = true;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRecentSearches() async {
    final raw = SharedPrefs().getString('recent_searches');
    if (raw != null && raw.trim().isNotEmpty) {
      if (!mounted) return;
      setState(() {
        _recentSearches =
            raw.split('|').where((e) => e.trim().isNotEmpty).toList();
      });
    }
  }

  Future<void> _saveRecentSearch(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;
    final list = List<String>.from(_recentSearches);
    list.removeWhere((e) => e.toLowerCase() == q.toLowerCase());
    list.insert(0, q);
    final trimmed = list.take(8).toList();
    setState(() => _recentSearches = trimmed);
    await SharedPrefs().setString('recent_searches', trimmed.join('|'));
  }

  void _applySearchChip(String value) {
    _searchController.text = value;
    _searchController.selection = TextSelection.fromPosition(
      TextPosition(offset: value.length),
    );
    _filterAds(value);
    _saveRecentSearch(value);
    setState(() {});
  }

  // Quick-search shortcuts shown when the field is empty (text mode only).
  Widget _buildSearchChips() {
    if (_isLocationSearchMode || _searchController.text.trim().isNotEmpty) {
      return const SizedBox.shrink();
    }

    Widget chip(String label, IconData icon) {
      return GestureDetector(
        onTap: () => _applySearchChip(label),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.whiteColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.dividerColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: AppColors.greyColor),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(fontSize: 13, color: AppColors.blackColor)),
            ],
          ),
        ),
      );
    }

    Widget section(String title, List<String> items, IconData icon) {
      if (items.isEmpty) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 14, 4, 8),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.greyColor,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items.map((e) => chip(e, icon)).toList(),
          ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          section('RECENT', _recentSearches, Icons.history),
          section('TRENDING', _trendingSearches, Icons.trending_up),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.whiteColor,
        toolbarHeight: GetResponsiveSize.getResponsiveSize(
          context,
          mobile: kToolbarHeight,
          tablet: 80,
          largeTablet: 95,
          desktop: 110,
        ),
        leading: IconButton(
          onPressed: () => _handleBackNavigation(),
          icon: Icon(
            (!kIsWeb && Platform.isIOS)
                ? Icons.arrow_back_ios
                : Icons.arrow_back,
            size: GetResponsiveSize.getResponsiveSize(
              context,
              mobile: 24,
              tablet: 32,
              largeTablet: 38,
              desktop: 44,
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                style: TextStyle(
                  fontSize: GetResponsiveSize.getResponsiveFontSize(
                    context,
                    mobile: 16,
                    tablet: 20,
                    largeTablet: 24,
                    desktop: 28,
                  ),
                ),
                decoration: InputDecoration(
                  fillColor:
                      _isLocationSearchMode ? Colors.blue[50] : Colors.grey[50],
                  hintText: _isLocationSearchMode
                      ? "Search by location..."
                      : "Search ads...",
                  hintStyle: TextStyle(
                    fontSize: GetResponsiveSize.getResponsiveFontSize(
                      context,
                      mobile: 16,
                      tablet: 20,
                      largeTablet: 24,
                      desktop: 28,
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      GetResponsiveSize.getResponsiveBorderRadius(
                        context,
                        mobile: 10,
                        tablet: 12,
                        largeTablet: 14,
                        desktop: 16,
                      ),
                    ),
                    borderSide: BorderSide(
                      color: _isLocationSearchMode
                          ? AppColors.primaryColor
                          : Colors.grey,
                      width: GetResponsiveSize.getResponsiveSize(
                        context,
                        mobile: _isLocationSearchMode ? 2 : 1,
                        tablet: _isLocationSearchMode ? 2.5 : 1.5,
                        largeTablet: _isLocationSearchMode ? 3 : 2,
                        desktop: _isLocationSearchMode ? 3.5 : 2.5,
                      ),
                    ),
                  ),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    vertical: GetResponsiveSize.getResponsivePadding(
                      context,
                      mobile: 5,
                      tablet: 14,
                      largeTablet: 18,
                      desktop: 22,
                    ),
                    horizontal: GetResponsiveSize.getResponsivePadding(
                      context,
                      mobile: 12,
                      tablet: 18,
                      largeTablet: 24,
                      desktop: 30,
                    ),
                  ),
                  prefixIcon: Padding(
                    padding: EdgeInsets.all(
                      GetResponsiveSize.getResponsivePadding(
                        context,
                        mobile: 12,
                        tablet: 14,
                        largeTablet: 16,
                        desktop: 18,
                      ),
                    ),
                    child: Image.asset(
                      'assets/images/search-icon.png',
                      width: GetResponsiveSize.getResponsiveSize(
                        context,
                        mobile: 20,
                        tablet: 28,
                        largeTablet: 34,
                        desktop: 40,
                      ),
                      height: GetResponsiveSize.getResponsiveSize(
                        context,
                        mobile: 20,
                        tablet: 28,
                        largeTablet: 34,
                        desktop: 40,
                      ),
                      color: _isLocationSearchMode
                          ? AppColors.primaryColor
                          : AppColors.greyColor,
                    ),
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? Padding(
                          padding: EdgeInsets.all(
                            GetResponsiveSize.getResponsivePadding(
                              context,
                              mobile: 12,
                              tablet: 14,
                              largeTablet: 16,
                              desktop: 18,
                            ),
                          ),
                          child: GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              _filterAds('');
                              setState(() {});
                            },
                            child: Image.asset(
                              'assets/images/close.png',
                              width: GetResponsiveSize.getResponsiveSize(
                                context,
                                mobile: 20,
                                tablet: 28,
                                largeTablet: 34,
                                desktop: 40,
                              ),
                              height: GetResponsiveSize.getResponsiveSize(
                                context,
                                mobile: 20,
                                tablet: 28,
                                largeTablet: 34,
                                desktop: 40,
                              ),
                            ),
                          ),
                        )
                      : null,
                ),
                onChanged: (value) {
                  _filterAds(value);
                  setState(() {});
                },
                onSubmitted: (value) {
                  if (!_isLocationSearchMode) _saveRecentSearch(value);
                },
              ),
            ),
            SizedBox(
                width: GetResponsiveSize.getResponsiveSize(context,
                    mobile: 10, tablet: 16, largeTablet: 22, desktop: 28)),
            Container(
              decoration: BoxDecoration(
                color: _isLocationSearchMode
                    ? AppColors.primaryColor.withOpacity(0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(
                  GetResponsiveSize.getResponsiveBorderRadius(
                    context,
                    mobile: 8,
                    tablet: 10,
                    largeTablet: 12,
                    desktop: 14,
                  ),
                ),
              ),
              child: IconButton(
                padding: EdgeInsets.all(
                  GetResponsiveSize.getResponsivePadding(
                    context,
                    mobile: 8,
                    tablet: 10,
                    largeTablet: 12,
                    desktop: 14,
                  ),
                ),
                iconSize: GetResponsiveSize.getResponsiveSize(
                  context,
                  mobile: 24,
                  tablet: 36,
                  largeTablet: 44,
                  desktop: 52,
                ),
                onPressed: () {
                  // Handle location button tap
                  _handleLocationTap();
                },
                icon: Image.asset(
                  'assets/images/location.png',
                  width: GetResponsiveSize.getResponsiveSize(
                    context,
                    mobile: 24,
                    tablet: 36,
                    largeTablet: 44,
                    desktop: 52,
                  ),
                  height: GetResponsiveSize.getResponsiveSize(
                    context,
                    mobile: 24,
                    tablet: 36,
                    largeTablet: 44,
                    desktop: 52,
                  ),
                  color: _isLocationSearchMode
                      ? AppColors.primaryColor
                      : AppColors.greyColor,
                ),
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 30),
        child: GestureDetector(
          onTap: () {
            // Hide suggestions when tapping outside
            if (_showSuggestions) {
              setState(() {
                _showSuggestions = false;
              });
            }
          },
          child: Column(
            children: [
              _buildSearchChips(),
              Expanded(
                child: Stack(
                  children: [
                    BlocConsumer<AdvertisementBloc, AdvertisementState>(
                listener: (context, state) {
                  state.when(
                    initial: () {},
                    loading: () {},
                    listingsLoaded: (listings, hasMore) {
                      setState(() {
                        // Update "all ads" only when not in search modes
                        if (!_isSearching && !_isLocationSearchMode) {
                          allAds = listings;
                          filteredAds = listings;
                        } else {
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
                    listingsLoaded: (listings, hasMore) =>
                        _buildAdsList(hasMore: hasMore),
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
                    margin: EdgeInsets.symmetric(
                      horizontal: GetResponsiveSize.getResponsivePadding(
                          context,
                          mobile: 16,
                          tablet: 24,
                          largeTablet: 32,
                          desktop: 40),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(
                        GetResponsiveSize.getResponsiveBorderRadius(context,
                            mobile: 8,
                            tablet: 10,
                            largeTablet: 12,
                            desktop: 14),
                      ),
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
                          leading: Icon(
                            Icons.location_on,
                            color: AppColors.primaryColor,
                            size: GetResponsiveSize.getResponsiveSize(
                              context,
                              mobile: 24,
                              tablet: 28,
                              largeTablet: 32,
                              desktop: 36,
                            ),
                          ),
                          title: Text(
                            suggestion,
                            style: TextStyle(
                              fontSize: GetResponsiveSize.getResponsiveFontSize(
                                context,
                                mobile: 16,
                                tablet: 20,
                                largeTablet: 24,
                                desktop: 28,
                              ),
                            ),
                          ),
                          onTap: () => _selectAddressSuggestion(suggestion),
                          dense: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: GetResponsiveSize.getResponsivePadding(
                                context,
                                mobile: 16,
                                tablet: 20,
                                largeTablet: 24,
                                desktop: 28),
                            vertical: GetResponsiveSize.getResponsivePadding(
                                context,
                                mobile: 8,
                                tablet: 12,
                                largeTablet: 16,
                                desktop: 20),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
            ],
          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const SkeletonList();
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

  Widget _buildAdsList({required bool hasMore}) {
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
      controller: _scrollController,
      // itemCount: filteredAds.length + 1,
      itemCount: hasMore ? filteredAds.length + 1 : filteredAds.length,
      itemBuilder: (BuildContext context, int index) {
        if (index >= filteredAds.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final ad = filteredAds[index];
        return _buildAdCard(ad);
      },
    );
  }

  Widget _buildAdCard(AddModel ad) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: GetResponsiveSize.getResponsivePadding(context,
            mobile: 10, tablet: 14, largeTablet: 18, desktop: 22),
        vertical: GetResponsiveSize.getResponsivePadding(context,
            mobile: 5, tablet: 8, largeTablet: 12, desktop: 16),
      ),
      child: GestureDetector(
        onTap: () {
          // Navigate to ad detail page
          context.push('/add-detail-page', extra: ad);
        },
        child: Card(
          color: AppColors.whiteColor,
          elevation: 5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              GetResponsiveSize.getResponsiveBorderRadius(
                context,
                mobile: 15,
                tablet: 18,
                largeTablet: 22,
                desktop: 26,
              ),
            ),
          ),
          child: Stack(
            children: [
              Padding(
                padding: EdgeInsets.all(
                  GetResponsiveSize.getResponsivePadding(context,
                      mobile: 12, tablet: 16, largeTablet: 20, desktop: 24),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(
                        GetResponsiveSize.getResponsiveBorderRadius(
                          context,
                          mobile: 12,
                          tablet: 14,
                          largeTablet: 16,
                          desktop: 18,
                        ),
                      ),
                      child: ad.images.isNotEmpty
                          ? Image.network(
                              ad.images[0],
                              height: GetResponsiveSize.getResponsiveSize(
                                context,
                                mobile: 98,
                                tablet: 140,
                                largeTablet: 180,
                                desktop: 220,
                              ),
                              width: GetResponsiveSize.getResponsiveSize(
                                context,
                                mobile: 98,
                                tablet: 140,
                                largeTablet: 180,
                                desktop: 220,
                              ),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: GetResponsiveSize.getResponsiveSize(
                                    context,
                                    mobile: 98,
                                    tablet: 140,
                                    largeTablet: 180,
                                    desktop: 220,
                                  ),
                                  width: GetResponsiveSize.getResponsiveSize(
                                    context,
                                    mobile: 98,
                                    tablet: 140,
                                    largeTablet: 180,
                                    desktop: 220,
                                  ),
                                  color: Colors.grey[300],
                                  child: Icon(
                                    Icons.image_not_supported,
                                    size: GetResponsiveSize.getResponsiveSize(
                                      context,
                                      mobile: 24,
                                      tablet: 32,
                                      largeTablet: 40,
                                      desktop: 48,
                                    ),
                                  ),
                                );
                              },
                            )
                          : Container(
                              height: GetResponsiveSize.getResponsiveSize(
                                context,
                                mobile: 100,
                                tablet: 140,
                                largeTablet: 180,
                                desktop: 220,
                              ),
                              width: GetResponsiveSize.getResponsiveSize(
                                context,
                                mobile: 100,
                                tablet: 140,
                                largeTablet: 180,
                                desktop: 220,
                              ),
                              color: Colors.grey[300],
                              child: Icon(
                                Icons.image_not_supported,
                                size: GetResponsiveSize.getResponsiveSize(
                                  context,
                                  mobile: 24,
                                  tablet: 32,
                                  largeTablet: 40,
                                  desktop: 48,
                                ),
                              ),
                            ),
                    ),
                    SizedBox(
                        width: GetResponsiveSize.getResponsiveSize(context,
                            mobile: 15,
                            tablet: 20,
                            largeTablet: 26,
                            desktop: 32)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '₹ ${ad.price.toString()}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize:
                                      GetResponsiveSize.getResponsiveFontSize(
                                    context,
                                    mobile: 16,
                                    tablet: 22,
                                    largeTablet: 28,
                                    desktop: 34,
                                  ),
                                ),
                              ),
                              const Spacer(),
                            ],
                          ),
                          SizedBox(
                              height: GetResponsiveSize.getResponsiveSize(
                                  context,
                                  mobile: 5,
                                  tablet: 8,
                                  largeTablet: 12,
                                  desktop: 16)),
                          Text(
                            _getAdTitle(ad),
                            style: TextStyle(
                              fontSize: GetResponsiveSize.getResponsiveFontSize(
                                context,
                                mobile: 16,
                                tablet: 22,
                                largeTablet: 28,
                                desktop: 34,
                              ),
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Builder(builder: (context) {
                            final sub = _getAdSubtitle(ad);
                            if (sub.isEmpty) return const SizedBox.shrink();
                            return Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: Text(
                                sub,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: AppColors.greyColor,
                                  fontSize:
                                      GetResponsiveSize.getResponsiveFontSize(
                                    context,
                                    mobile: 11,
                                    tablet: 16,
                                    largeTablet: 20,
                                    desktop: 24,
                                  ),
                                ),
                              ),
                            );
                          }),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: GetResponsiveSize.getResponsiveSize(
                                  context,
                                  mobile: 12,
                                  tablet: 16,
                                  largeTablet: 18,
                                  desktop: 20,
                                ),
                                color: Colors.black,
                              ),
                              SizedBox(
                                width: GetResponsiveSize.getResponsiveSize(
                                  context,
                                  mobile: 4,
                                  tablet: 6,
                                  largeTablet: 8,
                                  desktop: 8,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  ad.location,
                                  style: AppTextstyle.categoryLabelTextStyle
                                      .copyWith(
                                    fontSize:
                                        GetResponsiveSize.getResponsiveFontSize(
                                      context,
                                      mobile: AppTextstyle
                                              .categoryLabelTextStyle
                                              .fontSize ??
                                          14,
                                      tablet: 18,
                                      largeTablet: 22,
                                      desktop: 26,
                                    ),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                              height: GetResponsiveSize.getResponsiveSize(
                                  context,
                                  mobile: 5,
                                  tablet: 8,
                                  largeTablet: 12,
                                  desktop: 16)),
                          Text(
                            _getAdSubtitle(ad),
                            style: AppTextstyle.categoryLabelTextStyle.copyWith(
                              fontSize: GetResponsiveSize.getResponsiveFontSize(
                                context,
                                mobile: AppTextstyle
                                        .categoryLabelTextStyle.fontSize ??
                                    14,
                                tablet: 18,
                                largeTablet: 22,
                                desktop: 26,
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
                  right: GetResponsiveSize.getResponsiveSize(
                    context,
                    mobile: 8,
                    tablet: 10,
                    largeTablet: 12,
                    desktop: 14,
                  ),
                  child: Container(
                    width: GetResponsiveSize.getResponsiveSize(
                      context,
                      mobile: 32,
                      tablet: 40,
                      largeTablet: 48,
                      desktop: 56,
                    ),
                    height: GetResponsiveSize.getResponsiveSize(
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
}
