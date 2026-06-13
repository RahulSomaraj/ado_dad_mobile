import 'package:ado_dad_user/common/app_colors.dart';
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
      context
          .read<AdvertisementBloc>()
          .add(const AdvertisementEvent.fetchAllListings());

      context.read<BannerBloc>().add(const BannerEvent.fetchBanners());

      final prefs = await SharedPreferences.getInstance();
      final savedLocation = prefs.getString('user_location');
      if (savedLocation != null) {
        setState(() {
          _userLocation = savedLocation;
        });
        await _applyLocationBasedRecommendations(savedLocation);
      } else {
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
        floatingActionButton: SafeArea(
          minimum: const EdgeInsets.only(bottom: 20),
          child: const BottomNavBar(),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
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
          Builder(
            builder: (context) {
              // White wordmark sized by height so it is clearly visible on the
              // purple header (the old asset was only 108x16 and rendered tiny).
              return Image.asset(
                'assets/images/Ado-dad-white.png',
                height: GetResponsiveSize.getResponsiveSize(
                  context,
                  mobile: 28,
                  tablet: 44,
                  largeTablet: 52,
                  desktop: 56,
                ),
                fit: BoxFit.contain,
              );
            },
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
            child: Image.network(
              imagePath,
              fit: BoxFit.fill,
              errorBuilder: (_, __, ___) =>
                  const ColoredBox(color: Colors.black12),
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

    // Matches _buildRichAdCard: padding + price + title + chips + footer
    const textBlockHeight = 15 + 18 + 3 + 16 + 6 + 22 + 14 + 6;

    return imageHeight + textBlockHeight;
  }

  Widget buildSliverGridView() {
    return BlocBuilder<AdvertisementBloc, AdvertisementState>(
      builder: (context, state) {
        if (state is AdvertisementLoading) {
          return const SliverToBoxAdapter(
            child: Center(child: CircularProgressIndicator()),
          );
        } else if (state is ListingsLoaded) {
          final listings = state.listings;
          final hasMore = state.hasMore;

          return SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount:
                  _columnsForWidth(MediaQuery.of(context).size.width),
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              mainAxisExtent: _cardMainAxisExtent(
                  context, _columnsForWidth(MediaQuery.of(context).size.width)),
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index < listings.length) {
                  final ad = listings[index];
                  return buildAdCard(ad);
                }
                return hasMore
                    ? const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : const SizedBox.shrink();
              },
              childCount: listings.length + (hasMore ? 1 : 0),
            ),
          );
        } else if (state is AdvertisementError) {
          return SliverToBoxAdapter(
            child: Padding(
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
            ),
          );
        } else {
          return const SliverToBoxAdapter(
            child: Center(child: Text("No data available")),
          );
        }
      },
    );
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
                      return _buildRichAdCard(ad);
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

  // Compact per-category spec line built from fields the API already returns.
  String _adSpecLine(AddModel ad) {
    final parts = <String>[];
    final cat = ad.category.toLowerCase();
    if (cat.contains('propert')) {
      if (ad.bedrooms != null) parts.add('${ad.bedrooms} BHK');
      if (ad.areaSqft != null) parts.add('${ad.areaSqft} sqft');
      if (ad.isFurnished == true) parts.add('Furnished');
    } else {
      if (ad.year != null) parts.add('${ad.year}');
      if (ad.mileage != null) parts.add('${ad.mileage} km');
      if (ad.fuelType != null && ad.fuelType!.trim().isNotEmpty) {
        parts.add(ad.fuelType!);
      }
      if (ad.transmission != null && ad.transmission!.trim().isNotEmpty) {
        parts.add(ad.transmission!);
      }
    }
    return parts.join(' · ');
  }

  // ---- Detailed (wireframe) ad card helpers ----

  String _inr(int n) {
    final str = n.abs().toString();
    if (str.length <= 3) return n.toString();
    final last3 = str.substring(str.length - 3);
    String rest = str.substring(0, str.length - 3);
    final parts = <String>[];
    while (rest.length > 2) {
      parts.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) parts.insert(0, rest);
    return '${n < 0 ? '-' : ''}${parts.join(',')},$last3';
  }

  bool _isProperty(AddModel ad) => ad.category.toLowerCase().contains('propert');

  bool _isRent(AddModel ad) => (ad.listingType ?? '').toLowerCase() == 'rent';

  String _priceText(AddModel ad) {
    final base = '₹ ${_inr(ad.price)}';
    return _isRent(ad) ? '$base/mo' : base;
  }

  String _emiText(int price) => '₹${_inr((price * 0.018).round())}/mo';

  String _cardTitle(AddModel ad) {
    if ((ad.title ?? '').trim().isNotEmpty) return ad.title!.trim();
    final parts = <String>[];
    if ((ad.manufacturer?.name ?? '').isNotEmpty) parts.add(ad.manufacturer!.name!);
    if ((ad.model?.name ?? '').isNotEmpty) parts.add(ad.model!.name);
    if (ad.year != null) parts.add('${ad.year}');
    if (parts.isNotEmpty) return parts.join(' ');
    if ((ad.propertyType ?? '').isNotEmpty) return ad.propertyType!;
    return 'Listing';
  }

  bool _isNew(AddModel ad) {
    final dt = DateTime.tryParse(ad.postedAt);
    if (dt == null) return false;
    return DateTime.now().difference(dt).inDays < 3;
  }

  String _relTime(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    final d = DateTime.now().difference(dt);
    if (d.inDays >= 365) return '${(d.inDays / 365).floor()}y';
    if (d.inDays >= 30) return '${(d.inDays / 30).floor()}mo';
    if (d.inDays >= 7) return '${(d.inDays / 7).floor()}w';
    if (d.inDays >= 1) return '${d.inDays}d';
    if (d.inHours >= 1) return '${d.inHours}h';
    if (d.inMinutes >= 1) return '${d.inMinutes}m';
    return 'now';
  }

  Widget _chip(IconData icon, String label) {
    final display = label.length > 14 ? '${label.substring(0, 14)}…' : label;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.scaffoldBackground,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.dividerColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: AppColors.greyColor),
          const SizedBox(width: 3),
          Text(
            display,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 9.5, color: AppColors.blackColor1),
          ),
        ],
      ),
    );
  }

  Widget _cardSpecChips(AddModel ad) {
    final chips = <Widget>[];
    if (_isProperty(ad)) {
      if (ad.bedrooms != null) chips.add(_chip(Icons.bed_outlined, '${ad.bedrooms} Bed'));
      if (ad.bathrooms != null) chips.add(_chip(Icons.bathtub_outlined, '${ad.bathrooms} Bath'));
      if (ad.areaSqft != null) chips.add(_chip(Icons.straighten, '${_inr(ad.areaSqft!)} sqft'));
      if (ad.isFurnished == true) chips.add(_chip(Icons.chair_outlined, 'Furnished'));
    } else {
      if (ad.mileage != null) chips.add(_chip(Icons.route_outlined, '${_inr(ad.mileage!)} km'));
      if ((ad.fuelType ?? '').trim().isNotEmpty) chips.add(_chip(Icons.local_gas_station_outlined, ad.fuelType!));
      if ((ad.transmission ?? '').trim().isNotEmpty) chips.add(_chip(Icons.settings_outlined, ad.transmission!));
      if (ad.isFirstOwner == true) chips.add(_chip(Icons.person_outline, '1st owner'));
    }
    if (chips.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 22,
      child: ClipRect(
        child: Align(
          alignment: Alignment.centerLeft,
          child: Row(
            children: [
              for (var i = 0; i < chips.length && i < 2; i++) ...[
                if (i > 0) const SizedBox(width: 5),
                Flexible(child: chips[i]),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _imgTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
          color: color, borderRadius: BorderRadius.circular(5)),
      child: Text(text,
          style: const TextStyle(
              color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.w600)),
    );
  }

  Widget _imgPill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.55),
          borderRadius: BorderRadius.circular(5)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: Colors.white),
          const SizedBox(width: 3),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 9)),
        ],
      ),
    );
  }

  Widget _richFavorite(AddModel ad) {
    return BlocBuilder<FavoriteBloc, FavoriteState>(
      builder: (context, state) {
        final bool isFav = ad.isFavorited ?? false;
        final bool loading =
            state is FavoriteToggleLoading && state.adId == ad.id;
        return GestureDetector(
          onTap: () async {
            final isAuth = await AuthGuard.isAuthenticated();
            if (!context.mounted) return;
            if (!isAuth) {
              DialogUtil.showLoginPromptDialog(
                context,
                message: "Please login to add this ad to your favorites.",
                redirectPath: '/home',
              );
              return;
            }
            context.read<FavoriteBloc>().add(
                  FavoriteEvent.toggleFavorite(
                    adId: ad.id,
                    isCurrentlyFavorited: isFav,
                  ),
                );
          },
          child: Container(
            width: 28,
            height: 28,
            decoration:
                const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: loading
                ? const Padding(
                    padding: EdgeInsets.all(7),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    isFav ? Icons.favorite : Icons.favorite_border,
                    size: 16,
                    color: isFav ? AppColors.redColor : AppColors.greyColor,
                  ),
          ),
        );
      },
    );
  }

  Widget _buildRichAdCard(AddModel ad) {
    final bool isPremium = ad.manufacturer?.isPremium == true;
    final bool property = _isProperty(ad);
    return GestureDetector(
      onTap: () => context.push('/add-detail-page', extra: ad),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.whiteColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.dividerColor),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: GetResponsiveSize.isTablet(context) ? (16 / 9) : (16 / 10),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ad.images.isNotEmpty
                      ? Image.network(
                          ad.images.first,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: AppColors.scaffoldBackground,
                            child: Icon(Icons.image_not_supported_outlined,
                                color: AppColors.greyColor),
                          ),
                        )
                      : Container(
                          color: AppColors.scaffoldBackground,
                          child: Icon(Icons.image_not_supported_outlined,
                              color: AppColors.greyColor),
                        ),
                  if (isPremium)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: _imgTag('PREMIUM', AppColors.primaryColor),
                    )
                  else if (property)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: _imgTag(
                          _isRent(ad) ? 'FOR RENT' : 'FOR SALE',
                          const Color(0xFF1565C0)),
                    )
                  else if (_isNew(ad))
                    Positioned(
                      top: 6,
                      left: 6,
                      child: _imgTag('NEW', const Color(0xFF19A463)),
                    ),
                  Positioned(top: 5, right: 5, child: _richFavorite(ad)),
                  if (ad.images.length > 1)
                    Positioned(
                      bottom: 6,
                      right: 6,
                      child: _imgPill(
                          Icons.photo_library_outlined, '${ad.images.length}'),
                    ),
                  if ((ad.link ?? '').trim().isNotEmpty)
                    Positioned(
                      bottom: 6,
                      left: 6,
                      child: _imgPill(Icons.play_circle_outline, 'Video'),
                    ),
                  if (ad.soldOut == true)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withOpacity(0.45),
                        alignment: Alignment.center,
                        child: const Text('SOLD',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                letterSpacing: 1.5)),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(9, 7, 9, 8),
                child: ClipRect(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              _priceText(ad),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: AppColors.blackColor),
                            ),
                          ),
                          if (!property && ad.price > 0) ...[
                            const SizedBox(width: 4),
                            Text(
                              'EMI ${_emiText(ad.price)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 9, color: AppColors.greyColor),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _cardTitle(ad),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 12.5, color: AppColors.blackColor),
                            ),
                          ),
                          if (ad.user?.isVerified == true) ...[
                            const SizedBox(width: 3),
                            Icon(Icons.verified,
                                size: 13, color: AppColors.primaryColor),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      _cardSpecChips(ad),
                      const Spacer(),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined,
                              size: 12, color: AppColors.greyColor),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              ad.location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 10, color: AppColors.greyColor),
                            ),
                          ),
                          if (ad.distance != null) ...[
                            const SizedBox(width: 4),
                            Text(
                              '${ad.distance!.toStringAsFixed(1)} km',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 9.5, color: AppColors.greyColor),
                            ),
                            Text(' · ',
                                style: TextStyle(
                                    fontSize: 9.5, color: AppColors.greyColor)),
                          ],
                          Text(
                            _relTime(ad.postedAt),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 9.5, color: AppColors.greyColor),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildAdCard(AddModel ad) {
    return GestureDetector(
      onTap: () {
        // context.push('/add-detail-page', extra: ad.id);
        context.push('/add-detail-page', extra: ad);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (ad.images.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20), bottom: Radius.circular(20)),
                child: AspectRatio(
                  // keep image area stable, but slightly taller on tablets
                  aspectRatio: GetResponsiveSize.isTablet(context)
                      ? (16 / 9)
                      : (16 / 10),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        ad.images.first,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const ColoredBox(color: Colors.black12),
                      ),
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
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: DefaultTextStyle(
                  style: TextStyle(
                    fontSize: GetResponsiveSize.getResponsiveFontSize(
                      context,
                      mobile: 13,
                      tablet: 16,
                      largeTablet: 18,
                      desktop: 18,
                    ),
                    color: Colors.black,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("₹${ad.price}",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: GetResponsiveSize.getResponsiveFontSize(
                                context,
                                mobile: 16,
                                tablet: 25,
                                largeTablet: 30,
                                desktop: 30,
                              ),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        BlocBuilder<FavoriteBloc, FavoriteState>(
                          builder: (context, state) {
                            bool isFavorited = ad.isFavorited ?? false;

                            // Check if this ad is currently being toggled
                            if (state is FavoriteToggleLoading &&
                                state.adId == ad.id) {
                              return Container(
                                width: GetResponsiveSize.getResponsiveSize(
                                  context,
                                  mobile: 28,
                                  tablet: 48,
                                  largeTablet: 56,
                                  desktop: 64,
                                ),
                                height: GetResponsiveSize.getResponsiveSize(
                                  context,
                                  mobile: 28,
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
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  ),
                                ),
                              );
                            }

                            return GestureDetector(
                              onTap: () async {
                                // Check authentication before allowing favorite toggle
                                final isAuthenticated =
                                    await AuthGuard.isAuthenticated();
                                if (!isAuthenticated) {
                                  DialogUtil.showLoginPromptDialog(
                                    context,
                                    message:
                                        "Please login to add this ad to your favorites.",
                                    redirectPath: '/home',
                                  );
                                  return;
                                }

                                context.read<FavoriteBloc>().add(
                                      FavoriteEvent.toggleFavorite(
                                        adId: ad.id,
                                        isCurrentlyFavorited: isFavorited,
                                      ),
                                    );
                              },
                              child: Container(
                                width: GetResponsiveSize.getResponsiveSize(
                                  context,
                                  mobile: 28,
                                  tablet: 48,
                                  largeTablet: 56,
                                  desktop: 64,
                                ),
                                height: GetResponsiveSize.getResponsiveSize(
                                  context,
                                  mobile: 28,
                                  tablet: 48,
                                  largeTablet: 56,
                                  desktop: 64,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.whiteColor,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: SizedBox(
                                    width: GetResponsiveSize.getResponsiveSize(
                                      context,
                                      mobile: 16,
                                      tablet: 18,
                                      largeTablet: 20,
                                      desktop: 24,
                                    ),
                                    height: GetResponsiveSize.getResponsiveSize(
                                      context,
                                      mobile: 16,
                                      tablet: 18,
                                      largeTablet: 20,
                                      desktop: 24,
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
                        )
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      ad.title ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: GetResponsiveSize.getResponsiveFontSize(
                          context,
                          mobile: 13,
                          tablet: 25,
                          largeTablet: 30,
                          desktop: 30,
                        ),
                      ),
                    ),
                    Builder(builder: (context) {
                      final spec = _adSpecLine(ad);
                      if (spec.isEmpty) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(
                          spec,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.greyColor,
                            fontWeight: FontWeight.w400,
                            fontSize: GetResponsiveSize.getResponsiveFontSize(
                              context,
                              mobile: 11,
                              tablet: 16,
                              largeTablet: 18,
                              desktop: 18,
                            ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: GetResponsiveSize.getResponsiveSize(
                            context,
                            mobile: 12,
                            tablet: 18,
                            largeTablet: 20,
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
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: GetResponsiveSize.getResponsiveFontSize(
                                context,
                                mobile: 12,
                                tablet: 20,
                                largeTablet: 22,
                                desktop: 22,
                              ),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            ),
          ],
        ),
      ),
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
