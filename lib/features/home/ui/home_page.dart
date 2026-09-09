import 'package:ado_dad_user/common/app_colors.dart';
import 'package:ado_dad_user/common/widgets/ado_dad_logo.dart';
import 'package:ado_dad_user/common/widgets/app_network_image.dart';
import 'package:ado_dad_user/common/widgets/rich_ad_card.dart';
import 'package:ado_dad_user/common/widgets/skeleton.dart';
import 'package:ado_dad_user/common/notification_badge_service.dart';
import 'package:ado_dad_user/common/app_textstyle.dart';
import 'package:ado_dad_user/common/google_places_service.dart';
import 'package:ado_dad_user/config/app_config.dart';
import 'package:ado_dad_user/features/home/banner_bloc/banner_bloc.dart';
import 'package:ado_dad_user/features/home/bloc/advertisement_bloc.dart';
import 'package:ado_dad_user/features/home/favorite/bloc/favorite_bloc.dart';
import 'package:ado_dad_user/models/advertisement_model/add_model.dart';
import 'package:ado_dad_user/models/cayegory_model.dart';
import 'package:ado_dad_user/common/auth_guard.dart';
import 'package:ado_dad_user/common/widgets/dialog_util.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ado_dad_user/common/get_responsive_size.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.showLoginPromptForNotifications = false});

  final bool showLoginPromptForNotifications;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final CarouselSliderController _carouselController =
      CarouselSliderController();

  String? _userLocation;
  final ScrollController _scrollController = ScrollController();
  late final GooglePlacesService _placesService;
  bool _isLocationRecommendationsMode = false;

  @override
  void initState() {
    super.initState();

    // Initialize Google Places service
    _placesService = GooglePlacesService(apiKey: AppConfig.googlePlacesApiKey);

    // iOS-specific scrolling configurations
    _scrollController.addListener(_onScroll);

    // Opened from notification shade while not logged in: show login popup on home (do not open notifications page)
    if (widget.showLoginPromptForNotifications) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _showLoginPromptIfNeeded());
    }

    Future.microtask(() async {
      context.read<BannerBloc>().add(const BannerEvent.fetchBanners());

      // Show cached address immediately while we fetch fresh location
      final prefs = await SharedPreferences.getInstance();
      final savedLocation = prefs.getString('user_location');
      if (savedLocation != null && mounted) {
        setState(() {
          _userLocation = savedLocation;
        });
      }

      // Try GPS first with short timeout — so ads load with distance baked in
      Position? position;
      try {
        final serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (serviceEnabled) {
          final permission = await Geolocator.checkPermission();
          if (permission != LocationPermission.denied &&
              permission != LocationPermission.deniedForever) {
            position = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.low,
              timeLimit: const Duration(seconds: 6),
            );
          }
        }
      } catch (_) {}

      if (!mounted) return;

      if (position != null) {
        // GPS available — load ads with location so distance shows on cards
        setState(() {
          _isLocationRecommendationsMode = true;
        });
        context.read<AdvertisementBloc>().add(
              AdvertisementEvent.searchByLocation(
                latitude: position.latitude,
                longitude: position.longitude,
              ),
            );
        // Reverse geocode for address display without blocking the ad load
        _updateAddressDisplay(position);
      } else if (savedLocation != null) {
        // No fresh GPS but have a saved address — geocode it to get coords
        await _applyLocationBasedRecommendations(savedLocation);
      } else {
        // No location at all — load without distance, request permission in background
        context
            .read<AdvertisementBloc>()
            .add(const AdvertisementEvent.fetchAllListings());
        _getLocationAndAddress();
      }
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      print(
          "🧭 Scroll Position: ${_scrollController.position.pixels} / ${_scrollController.position.maxScrollExtent}");

      // Trigger next page load when nearing bottom
      context
          .read<AdvertisementBloc>()
          .add(const AdvertisementEvent.fetchNextPage());
    }
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
    _scrollController.dispose();
    super.dispose();
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied.');
    }

    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  Future<void> _getLocationAndAddress() async {
    try {
      final position = await _determinePosition();

      // First try to get detailed address using Google Places reverse geocoding
      try {
        final placeDetails = await _getDetailedAddressFromCoordinates(
            position.latitude, position.longitude);

        if (placeDetails != null && placeDetails.isNotEmpty) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_location', placeDetails);

          setState(() {
            _userLocation = placeDetails;
          });
          await _applyLocationBasedRecommendations(placeDetails);
          return;
        }
      } catch (e) {
        print("Google Places reverse geocoding failed: $e");
      }

      // Fallback to standard geocoding
      final placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);
      final place = placemarks[0];

      // Create a more detailed address format
      final addressComponents = <String>[];

      if (place.locality?.isNotEmpty == true) {
        addressComponents.add(place.locality!);
      }
      if (place.subAdministrativeArea?.isNotEmpty == true &&
          place.subAdministrativeArea != place.locality) {
        addressComponents.add(place.subAdministrativeArea!);
      }
      if (place.administrativeArea?.isNotEmpty == true) {
        addressComponents.add(place.administrativeArea!);
      }

      final newAddress = addressComponents.join(', ');

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_location', newAddress);

      setState(() {
        _userLocation = newAddress;
      });
      await _applyLocationBasedRecommendations(newAddress);
    } catch (e) {
      print("Location error: $e");
      setState(() {
        _userLocation = "Location not available";
        _isLocationRecommendationsMode = false;
      });
    }
  }

  /// Reverse-geocode [position] and update the address chip without reloading ads.
  Future<void> _updateAddressDisplay(Position position) async {
    try {
      final address = await _getDetailedAddressFromCoordinates(
          position.latitude, position.longitude);
      if (address != null && address.isNotEmpty && mounted) {
        setState(() {
          _userLocation = address;
        });
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_location', address);
      }
    } catch (_) {}
  }

  Future<void> _applyLocationBasedRecommendations(String location) async {
    final query = location.trim();
    if (query.isEmpty || query == "Location not available") {
      if (mounted) {
        setState(() {
          _isLocationRecommendationsMode = false;
        });
      }
      context
          .read<AdvertisementBloc>()
          .add(const AdvertisementEvent.fetchAllListings());
      return;
    }

    try {
      final predictions = await _placesService.getPlacePredictions(
        input: query,
        region: 'in',
        language: 'en',
      );

      if (predictions.isNotEmpty) {
        final selectedPrediction = predictions.firstWhere(
          (prediction) =>
              prediction.description.toLowerCase() == query.toLowerCase(),
          orElse: () => predictions.first,
        );

        final placeDetails = await _placesService.getPlaceDetails(
          selectedPrediction.placeId,
        );
        final point = placeDetails?.geometry?.location;
        if (point != null) {
          if (mounted) {
            setState(() {
              _isLocationRecommendationsMode = true;
            });
          }
          print("🔍 Searching by location: ${point.lat}, ${point.lng}");
          context.read<AdvertisementBloc>().add(
                AdvertisementEvent.searchByLocation(
                  latitude: point.lat,
                  longitude: point.lng,
                ),
              );
          return;
        }
      }
    } catch (e) {
      print('Error applying location recommendations: $e');
    }

    if (mounted) {
      setState(() {
        _isLocationRecommendationsMode = false;
      });
    }
    context
        .read<AdvertisementBloc>()
        .add(const AdvertisementEvent.fetchAllListings());
  }

  /// Get detailed address using Google reverse geocoding
  Future<String?> _getDetailedAddressFromCoordinates(
      double lat, double lng) async {
    try {
      // Use Google Geocoding API for reverse geocoding
      final formattedAddress = await _placesService.reverseGeocode(
        latitude: lat,
        longitude: lng,
      );

      if (formattedAddress != null && formattedAddress.isNotEmpty) {
        return _formatAddressFromGooglePlaces(formattedAddress);
      }

      return null;
    } catch (e) {
      print("Error getting detailed address: $e");
      return null;
    }
  }

  /// Format Google Places address to show locality, district, state format
  String _formatAddressFromGooglePlaces(String formattedAddress) {
    // Parse the formatted address to extract relevant components
    // Google Places typically returns: "Street, Area, City/Place, District, State, Pincode, Country"
    final parts = formattedAddress.split(',').map((e) => e.trim()).toList();

    // Helper function to check if a string is a pincode (6 digits)
    bool isPincode(String str) {
      final cleaned = str.replaceAll(RegExp(r'[^0-9]'), '');
      return cleaned.length == 6 && RegExp(r'^\d{6}$').hasMatch(cleaned);
    }

    // Filter out country, pincode, and other unwanted parts
    final filteredParts = parts.where((part) {
      final lowerPart = part.toLowerCase();
      return !lowerPart.contains('india') &&
          !lowerPart.contains('pin') &&
          !lowerPart.contains('postal') &&
          !isPincode(part);
    }).toList();

    // For Indian addresses, we want: Place, District, State
    // Take the last 3 meaningful parts (excluding pincode and country)
    if (filteredParts.length >= 3) {
      final relevantParts = filteredParts.sublist(filteredParts.length - 3);
      return relevantParts.join(', ');
    } else if (filteredParts.length == 2) {
      // If only 2 parts, return as is (likely Place, State)
      return filteredParts.join(', ');
    } else if (filteredParts.isNotEmpty) {
      return filteredParts.join(', ');
    }

    return formattedAddress;
  }

  Future<String?> _showLocationInputDialog() async {
    final controller = TextEditingController(text: _userLocation ?? '');
    List<String> suggestions = [];
    bool isLoadingSuggestions = false;

    return await showDialog<String>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Enter Your Location'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: controller,
                      decoration: const InputDecoration(
                        hintText: 'e.g. Perunnad, Pathanmathitta, Kerala',
                        prefixIcon: Icon(Icons.location_on),
                      ),
                      onChanged: (value) async {
                        if (value.length >= 2) {
                          setDialogState(() {
                            isLoadingSuggestions = true;
                          });

                          try {
                            final predictions =
                                await _placesService.getPlacePredictions(
                              input: value,
                              region: 'in',
                              language: 'en',
                            );

                            setDialogState(() {
                              suggestions = predictions
                                  .take(5)
                                  .map((p) => p.description)
                                  .toList();
                              isLoadingSuggestions = false;
                            });
                          } catch (e) {
                            setDialogState(() {
                              suggestions = [];
                              isLoadingSuggestions = false;
                            });
                          }
                        } else {
                          setDialogState(() {
                            suggestions = [];
                            isLoadingSuggestions = false;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 10),

                    // Show suggestions
                    if (isLoadingSuggestions)
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(),
                      )
                    else if (suggestions.isNotEmpty)
                      Container(
                        height: 120,
                        child: ListView.builder(
                          itemCount: suggestions.length,
                          itemBuilder: (context, index) {
                            final suggestion = suggestions[index];
                            return ListTile(
                              dense: true,
                              leading: const Icon(Icons.location_on, size: 16),
                              title: Text(
                                suggestion,
                                style: const TextStyle(fontSize: 12),
                              ),
                              onTap: () {
                                controller.text = suggestion;
                                setDialogState(() {
                                  suggestions = [];
                                });
                              },
                            );
                          },
                        ),
                      ),

                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.my_location),
                      label: const Text('Use Current Location'),
                      onPressed: () async {
                        try {
                          setDialogState(() {
                            isLoadingSuggestions = true;
                          });

                          final position = await _determinePosition();

                          // Try to get detailed address first
                          final detailedAddress =
                              await _getDetailedAddressFromCoordinates(
                                  position.latitude, position.longitude);

                          String gpsAddress;
                          if (detailedAddress != null &&
                              detailedAddress.isNotEmpty) {
                            gpsAddress = detailedAddress;
                          } else {
                            // Fallback to standard geocoding
                            final placemarks = await placemarkFromCoordinates(
                                position.latitude, position.longitude);
                            final place = placemarks[0];

                            final addressComponents = <String>[];
                            if (place.locality?.isNotEmpty == true) {
                              addressComponents.add(place.locality!);
                            }
                            if (place.subAdministrativeArea?.isNotEmpty ==
                                    true &&
                                place.subAdministrativeArea != place.locality) {
                              addressComponents
                                  .add(place.subAdministrativeArea!);
                            }
                            if (place.administrativeArea?.isNotEmpty == true) {
                              addressComponents.add(place.administrativeArea!);
                            }
                            gpsAddress = addressComponents.join(', ');
                          }

                          setDialogState(() {
                            controller.text = gpsAddress;
                            isLoadingSuggestions = false;
                          });
                        } catch (e) {
                          setDialogState(() {
                            isLoadingSuggestions = false;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text("Failed to fetch location: $e")),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final input = controller.text.trim();
                    if (input.isNotEmpty) {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setString('user_location', input);
                      Navigator.pop(context, input); // Return location
                    } else {
                      Navigator.pop(context); // No update
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final width = screenSize.width;
    final isTablet = GetResponsiveSize.isTablet(context);
    final isLargeTablet = GetResponsiveSize.isLargeTablet(context);
    final scale = GetResponsiveSize.getResponsiveSize(
      context,
      mobile: 1.0,
      tablet: 1.18,
      largeTablet: 1.35,
      desktop: 1.5,
    );
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
                backgroundColor: Colors.red.shade300.withOpacity(0.9),
              ),
            );
          }
        }
      },
      child: Scaffold(
        body: Column(
          children: [
            // 🔷 STICKY HEADER — logo, location, notifications + search bar
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppColors.primaryColor,
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 8,
                bottom: 12,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  buildTopBar(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                    child: _buildHomeSearchBar(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  if (_isLocationRecommendationsMode &&
                      (_userLocation?.trim().isNotEmpty ?? false)) {
                    await _applyLocationBasedRecommendations(_userLocation!);
                  } else {
                    context
                        .read<AdvertisementBloc>()
                        .add(const AdvertisementEvent.fetchAllListings());
                  }
                },
                color: AppColors.primaryColor,
                backgroundColor: Colors.white,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 🔷 PROMO BANNER
                      Padding(
                        padding: const EdgeInsets.only(top: 14),
                        child: _buildPromoBanner(),
                      ),
                      const SizedBox(height: 8),

                  // 🔷 CATEGORIES
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: buildSectionTitle("Categories"),
                  ),
                  const SizedBox(height: 5),
                  buildCategories(context),

                  // extra space above Recommendations on larger devices
                  SizedBox(
                    height: GetResponsiveSize.getResponsiveSize(
                      context,
                      mobile: 0, // unchanged for phones
                      tablet: 25,
                      largeTablet: 30,
                      desktop: 30,
                    ),
                  ),

                  // 🔷 RECOMMENDATIONS TITLE
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(child: buildSectionTitle("Fresh near you")),
                        GestureDetector(
                          onTap: () => context.push('/search?from=/home'),
                          child: Text(
                            "See all",
                            style: TextStyle(
                              color: AppColors.primaryColor,
                              fontWeight: FontWeight.w500,
                              fontSize: GetResponsiveSize.getResponsiveFontSize(
                                context,
                                mobile: 12,
                                tablet: 16,
                                largeTablet: 18,
                                desktop: 18,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // 🔷 MAIN GRIDVIEW - now uses regular GridView for proper scrolling
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: buildGridView(),
                  ),
                  // Clear the floating bottom nav bar so the last row of ads
                  // and the load-more indicator are not hidden behind it.
                  const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        // Bottom navigation is now provided by the persistent shell.
      ),
    );
  }

  Widget _buildPromoBanner() {
    return BlocBuilder<BannerBloc, BannerState>(
      builder: (context, state) {
        return state.when(
          initial: () => const SizedBox(),
          loading: () => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SkeletonBox(
              height: GetResponsiveSize.getResponsiveSize(
                context,
                mobile: 140,
                tablet: 250,
                largeTablet: 320,
                desktop: 360,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          error: (message) => const SizedBox(),
          loaded: (banners) => Column(
            children: [
              CarouselSlider(
                carouselController: _carouselController,
                options: CarouselOptions(
                  height: GetResponsiveSize.getResponsiveSize(
                    context,
                    mobile: 140,
                    tablet: 250,
                    largeTablet: 320,
                    desktop: 360,
                  ),
                  autoPlay: true,
                  enlargeCenterPage: true,
                  viewportFraction: 0.9,
                  onPageChanged: (index, _) {
                    setState(() {
                      BuildIndicator.currentIndex = index;
                    });
                  },
                ),
                items: banners.map((banner) {
                  return buildPromoCard(banner.phoneImage, banner.link);
                }).toList(),
              ),
              SizedBox(
                height: GetResponsiveSize.getResponsiveSize(
                  context,
                  mobile: 10,
                  tablet: 24,
                  largeTablet: 30,
                  desktop: 30,
                ),
              ),
              BuildIndicator(
                controller: _carouselController,
                itemCount: banners.length,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget buildTopBar() {
    final width = MediaQuery.of(context).size.width;
    final isTablet = GetResponsiveSize.isTablet(context);
    final isLargeTablet = GetResponsiveSize.isLargeTablet(context);
    final double locationFont = GetResponsiveSize.getResponsiveFontSize(
      context,
      mobile: 12,
      tablet: 22,
      largeTablet: 25,
      desktop: 25,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // White mark + wordmark sized by height so it is clearly visible on
          // the purple header.
          AdoDadLogo(
            height: GetResponsiveSize.getResponsiveSize(
              context,
              mobile: 28,
              tablet: 44,
              largeTablet: 52,
              desktop: 56,
            ),
          ),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ValueListenableBuilder<bool>(
                        valueListenable: NotificationBadgeService.hasUnread,
                        builder: (context, hasUnread, _) {
                          final bool isTab =
                              GetResponsiveSize.isTablet(context);
                          final double iconSize =
                              GetResponsiveSize.getResponsiveSize(
                            context,
                            mobile: 22,
                            tablet: 28,
                            largeTablet: 30,
                            desktop: 30,
                          );
                          return GestureDetector(
                            onTap: () async {
                              // Do not clear badge here – clear only when user opens the notifications page
                              final isAuthenticated =
                                  await AuthGuard.isAuthenticated();
                              if (isAuthenticated) {
                                context.push('/notifications');
                              } else {
                                DialogUtil.showLoginPromptDialog(
                                  context,
                                  message:
                                      'Please login to view notifications.',
                                  redirectPath: '/notifications',
                                );
                              }
                            },
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Icon(
                                  Icons.notifications_outlined,
                                  color: AppColors.whiteColor,
                                  size: isTab ? iconSize : 22,
                                ),
                                if (hasUnread)
                                  Positioned(
                                    top: -2,
                                    right: -2,
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                      SizedBox(width: 12),
                      GestureDetector(
                        onTap: () async {
                          final updatedLocation =
                              await _showLocationInputDialog();
                          if (updatedLocation != null) {
                            setState(() {
                              _userLocation =
                                  updatedLocation; // 🔁 updates UI immediately
                            });
                            await _applyLocationBasedRecommendations(
                                updatedLocation);
                          }
                        },
                        child: Builder(
                          builder: (context) {
                            final bool isTab =
                                GetResponsiveSize.isTablet(context);
                            final double iconSize =
                                GetResponsiveSize.getResponsiveSize(
                              context,
                              mobile: 22,
                              tablet: 28,
                              largeTablet: 30,
                              desktop: 30,
                            );
                            return Image.asset(
                              'assets/images/Frame.png',
                              width: isTab ? iconSize : 22,
                              height: isTab ? iconSize : 22,
                              fit: BoxFit.contain,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  if (_userLocation != null) ...[
                    SizedBox(height: 4),
                    Tooltip(
                      message: _userLocation!,
                      child: Text(
                        _userLocation!,
                        style: TextStyle(
                          color: AppColors.whiteColor,
                          fontSize: locationFont,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                        softWrap: true,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildPromoCard(String imagePath, String link) {
    return GestureDetector(
      onTap: () {
        _launchURL(link);
        print('$link clickkedddd..........');
      },
      child: Padding(
        // padding: const EdgeInsets.symmetric(horizontal: 12),
        padding: EdgeInsets.zero,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            height: 150,
            width: double.infinity,
            // color: Colors.red,
            // alignment: Alignment.center,
            child: AppNetworkImage(
              url: imagePath,
              fit: BoxFit.fill,
              height: 150,
              width: double.infinity,
            ),
          ),
        ),
      ),
    );
  }

  void _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      print("❌ Could not launch $url");
    }
  }

  Widget buildSectionTitle(String title) {
    final baseSize = AppTextstyle.sectionTitleTextStyle.fontSize ?? 16;
    final responsiveSize = GetResponsiveSize.getResponsiveFontSize(
      context,
      mobile: baseSize, // keep phone unchanged
      tablet: baseSize + 15,
      largeTablet: baseSize + 18,
      desktop: baseSize + 18,
    );
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: AppTextstyle.sectionTitleTextStyle
            .copyWith(fontSize: responsiveSize),
      ),
    );
  }

  // Tappable search pill on Home; opens the full search screen in one tap.
  Widget _buildHomeSearchBar(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/search?from=/home'),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.whiteColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.dividerColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.search, color: AppColors.greyColor),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Search cars, bikes, property…',
                style: TextStyle(color: AppColors.greyColor, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildCategories(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Calculate item width to show multiple items per row
    // Increased mobile width to prevent word breaking (especially for "Commercial")
    // With reduced padding and spacing, we can use more width
    final itemWidth = GetResponsiveSize.isTablet(context)
        ? GetResponsiveSize.getResponsiveSize(
            context,
            mobile: screenWidth * 0.2, // not used on tablets
            tablet: screenWidth * 0.20,
            largeTablet: screenWidth * 0.26,
            desktop: screenWidth * 0.28,
          )
        : (screenWidth * 0.24).clamp(90.0,
            double.infinity); // Increased to 24% with min 90px for better fit

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: GetResponsiveSize.isTablet(context)
            ? GetResponsiveSize.getResponsivePadding(
                context,
                mobile: 12.0, // Not used on tablets
                tablet: 8.0, // Decreased left/right padding for tablets
                largeTablet: 8.0,
                desktop: 8.0,
              )
            : 8.0, // Reduced from 12.0 to give more width to categories
        vertical: 10,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: categories.map((category) {
            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: SizedBox(
                width: itemWidth,
                child: GestureDetector(
              onTap: () async {
                // Special handling for Showroom category
                if (category.categoryId == 'showroom') {
                  // Navigate to showroom users - page handles both authenticated and unauthenticated access
                  context.push('/showroom-users');
                  return;
                }

                // context.read<AdvertisementBloc>().add(
                //       AdvertisementEvent.fetchByCategory(
                //           categoryId: category.categoryId),
                //     );
                // context.push(
                //     '/category-list-page?categoryId=${category.categoryId}&title=${category.name}');

                final result = await context.push(
                  '/category-list-page?categoryId=${category.categoryId}&title=${category.name}',
                );

                // ✅ If coming back with "true", refresh Home list
                if (context.mounted && result == true) {
                  context
                      .read<AdvertisementBloc>()
                      .add(const AdvertisementEvent.fetchAllListings());
                }
              },
              child: Column(
                children: [
                  Container(
                    height: GetResponsiveSize.getResponsiveSize(
                      context,
                      mobile: 70, // unchanged for phones
                      tablet: 110,
                      largeTablet: 135,
                      desktop: 150,
                    ),
                    padding: EdgeInsets.all(GetResponsiveSize.getResponsiveSize(
                      context,
                      mobile: 16,
                      tablet: 20,
                      largeTablet: 22,
                      desktop: 22,
                    )),
                    decoration: BoxDecoration(
                      color: AppColors.whiteColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(color: Colors.black12, blurRadius: 2)
                      ],
                    ),
                    child: SizedBox(
                      width: GetResponsiveSize.getResponsiveSize(
                        context,
                        mobile: 38, // leave phone small as before
                        tablet: 60,
                        largeTablet: 75,
                        desktop: 80,
                      ),
                      height: GetResponsiveSize.getResponsiveSize(
                        context,
                        mobile: 38,
                        tablet: 60,
                        largeTablet: 70,
                        desktop: 80,
                      ),
                      child: Image.asset(category.image, fit: BoxFit.contain),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Builder(
                    builder: (context) {
                      final double baseSize =
                          AppTextstyle.categoryLabelTextStyle.fontSize ?? 12;
                      final double labelSize =
                          GetResponsiveSize.getResponsiveFontSize(
                        context,
                        mobile: baseSize, // keep phone unchanged
                        tablet: baseSize + 10,
                        largeTablet: baseSize + 13,
                        desktop: baseSize + 13,
                      );
                      // Allow multi-line text but ensure words don't break
                      // Text widget naturally wraps at word boundaries (not mid-word)
                      // Use ConstrainedBox to limit width, allowing natural word wrapping
                      return ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: itemWidth),
                        child: Text(
                          category.name,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          softWrap: true, // Wraps at word boundaries only
                          style: AppTextstyle.categoryLabelTextStyle
                              .copyWith(fontSize: labelSize),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // 1) Helpers: decide columns and compute a responsive card height
  int _columnsForWidth(double w) {
    if (w >= 1200) return 5; // keep desktop dense
    if (w >= 900) return 2; // large tablets: 2 per row
    if (w >= 600) return 2; // tablets: 2 per row
    return 2; // phones unchanged
  }

  double _cardMainAxisExtent(BuildContext context, int columns) {
    final screenWidth = MediaQuery.of(context).size.width;
    const horizontalPagePadding = 15.0;
    const spacing = 15.0;

    final available =
        screenWidth - (horizontalPagePadding * 2) - (spacing * (columns - 1));
    final cardWidth = available / columns;

    final aspectRatio =
        GetResponsiveSize.isTablet(context) ? (16 / 9) : (16 / 10);
    final imageHeight = cardWidth / aspectRatio;

    // Matches RichAdCard: padding + price + title + chips + footer, where the
    // footer is now two lines (place, then distance/time). Includes a small
    // safety buffer so font-metric rounding can't overflow.
    const textBlockHeight = 15 + 18 + 3 + 16 + 6 + 22 + 14 + 18 + 6 + 10;

    return imageHeight + textBlockHeight;
  }

  Widget buildGridView() {
    return BlocBuilder<AdvertisementBloc, AdvertisementState>(
      builder: (context, state) {
        if (state is AdvertisementLoading) {
          // Skeleton grid that matches the real card layout for a fast feel.
          return LayoutBuilder(
            builder: (context, constraints) {
              final cols = _columnsForWidth(constraints.maxWidth);
              final mainExtent = _cardMainAxisExtent(context, cols);
              return SkeletonAdGrid(
                crossAxisCount: cols,
                mainAxisExtent: mainExtent,
                itemCount: cols * 3,
              );
            },
          );
        } else if (state is ListingsLoaded) {
          final listings = state.listings;
          final hasMore = state.hasMore;

          return RefreshIndicator(
            onRefresh: () async {
              context
                  .read<AdvertisementBloc>()
                  .add(const AdvertisementEvent.fetchAllListings());
            },
            // iOS-specific refresh indicator configurations
            color: AppColors.primaryColor,
            backgroundColor: Colors.white,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final cols = _columnsForWidth(constraints.maxWidth);
                final mainExtent = _cardMainAxisExtent(context, cols);

                return GridView.builder(
                  shrinkWrap: true,
                  physics:
                      const NeverScrollableScrollPhysics(), // Disable GridView scrolling
                  padding: EdgeInsets.zero,
                  // iOS-specific scrolling configurations
                  cacheExtent: 1000, // Cache more items for smooth scrolling
                  itemCount: listings.length + (hasMore ? 1 : 0),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                    mainAxisExtent: mainExtent, // ✅ explicit, responsive height
                  ),
                  itemBuilder: (context, index) {
                    if (index < listings.length) {
                      final ad = listings[index];
                      return RichAdCard(ad: ad);
                    }
                    return hasMore
                        ? const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        : const SizedBox.shrink();
                  },
                );
              },
            ),
          );
        } else if (state is AdvertisementError) {
          return Padding(
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
          );
        } else {
          return const Center(child: Text("No data available"));
        }
      },
    );
  }

}

class BuildIndicator extends StatefulWidget {
  final CarouselSliderController controller;
  final int itemCount;
  const BuildIndicator(
      {super.key, required this.controller, required this.itemCount});

  static int currentIndex = 0;

  @override
  State<BuildIndicator> createState() => _BuildIndicatorState();
}

class _BuildIndicatorState extends State<BuildIndicator> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BannerBloc, BannerState>(
      builder: (context, state) {
        return state.when(
          initial: () => SizedBox(),
          loading: () => SizedBox(),
          error: (message) => SizedBox(),
          loaded: (banners) => Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(banners.length, (index) {
              final bool isTablet = GetResponsiveSize.isTablet(context);
              // Compute responsive indicator sizes
              final double activeWidth = GetResponsiveSize.getResponsiveSize(
                context,
                mobile: 15,
                tablet: 20,
                largeTablet: 24,
                desktop: 24,
              );
              final double inactiveWidth = GetResponsiveSize.getResponsiveSize(
                context,
                mobile: 6,
                tablet: 8,
                largeTablet: 10,
                desktop: 10,
              );
              final double dotHeight = GetResponsiveSize.getResponsiveSize(
                context,
                mobile: 6,
                tablet: 10,
                largeTablet: 10,
                desktop: 10,
              );
              final double dotMargin = GetResponsiveSize.getResponsiveSize(
                context,
                mobile: 5,
                tablet: 8,
                largeTablet: 7,
                desktop: 7,
              );
              return GestureDetector(
                onTap: () {
                  setState(() {
                    BuildIndicator.currentIndex = index;
                  });
                  widget.controller.jumpToPage(index);
                },
                child: Container(
                  width: BuildIndicator.currentIndex == index
                      ? (isTablet ? activeWidth : 15)
                      : (isTablet ? inactiveWidth : 6),
                  height: isTablet ? dotHeight : 6,
                  margin: EdgeInsets.symmetric(
                      horizontal: isTablet ? dotMargin : 5),
                  decoration: BoxDecoration(
                    shape: BoxShape.rectangle,
                    color: BuildIndicator.currentIndex == index
                        ? AppColors.primaryColor
                        : AppColors.greyColor,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              );
            }),
          ),
        );
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
            color: Colors.black.withOpacity(0.10),
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
              icon: Icons.person_outline,
              label: 'Profile',
              route: '/profile'),
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
    final Color color = active ? AppColors.primaryColor : AppColors.greyColor;
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
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
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
                color: AppColors.primaryColor,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.whiteColor, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryColor.withOpacity(0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 26),
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

