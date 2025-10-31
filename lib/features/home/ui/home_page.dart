import 'package:ado_dad_user/common/app_colors.dart';
import 'package:ado_dad_user/common/app_textstyle.dart';
import 'package:ado_dad_user/common/google_places_service.dart';
import 'package:ado_dad_user/config/app_config.dart';
import 'package:ado_dad_user/features/home/banner_bloc/banner_bloc.dart';
import 'package:ado_dad_user/features/home/bloc/advertisement_bloc.dart';
import 'package:ado_dad_user/features/home/favorite/bloc/favorite_bloc.dart';
import 'package:ado_dad_user/models/advertisement_model/add_model.dart';
import 'package:ado_dad_user/models/cayegory_model.dart';
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
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final CarouselSliderController _carouselController =
      CarouselSliderController();

  String? _userLocation;
  final ScrollController _scrollController = ScrollController();
  late final GooglePlacesService _placesService;

  @override
  void initState() {
    super.initState();

    // Initialize Google Places service
    _placesService = GooglePlacesService(apiKey: AppConfig.googlePlacesApiKey);

    // iOS-specific scrolling configurations
    _scrollController.addListener(_onScroll);

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
    } catch (e) {
      print("Location error: $e");
      setState(() {
        _userLocation = "Location not available";
      });
    }
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
              content: Text(state.message),
              duration: const Duration(seconds: 2),
            ),
          );
        } else if (state is FavoriteToggleError) {
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              duration: const Duration(seconds: 2),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Scaffold(
        body: RefreshIndicator(
          onRefresh: () async {
            context
                .read<AdvertisementBloc>()
                .add(const AdvertisementEvent.fetchAllListings());
          },
          color: AppColors.primaryColor,
          backgroundColor: Colors.white,
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(), // iOS-style bouncing scroll

            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 🔷 HEADER PART
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // 🔹 Blue curved header with content
                      Container(
                        height: GetResponsiveSize.getResponsiveSize(
                              context,
                              mobile: (110 * scale),
                              tablet: 300,
                              largeTablet: 350,
                              desktop: 400,
                            ) +
                            MediaQuery.of(context).padding.top,
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          color: AppColors.primaryColor,
                          borderRadius: BorderRadius.vertical(
                            bottom: Radius.circular(30),
                          ),
                        ),
                        padding: EdgeInsets.only(
                          top: MediaQuery.of(context).padding.top +
                              8, // Add status bar height
                          bottom: GetResponsiveSize.getResponsiveSize(
                            context,
                            mobile: 80,
                            tablet: 140,
                            largeTablet: 170,
                            desktop: 190,
                          ),
                        ),
                        child: buildTopBar(), // 🔹 AdoDad logo + location
                      ),

                      // 🔹 Positioned Banner (slightly below blue container)
                      Positioned(
                        bottom: GetResponsiveSize.getResponsiveSize(
                          context,
                          mobile: -85,
                          tablet: -100,
                          largeTablet: -115,
                          desktop: -130,
                        ), // Controls how much overlaps
                        left: 0,
                        right: 0,
                        child: BlocBuilder<BannerBloc, BannerState>(
                          builder: (context, state) {
                            return state.when(
                              initial: () => const SizedBox(),
                              loading: () => const Center(
                                  child: CircularProgressIndicator()),
                              error: (message) => Text("Error: $message"),
                              loaded: (banners) => Column(
                                children: [
                                  CarouselSlider(
                                    carouselController: _carouselController,
                                    options: CarouselOptions(
                                      height:
                                          GetResponsiveSize.getResponsiveSize(
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
                                      return buildPromoCard(
                                          banner.phoneImage, banner.link);
                                    }).toList(),
                                  ),
                                  SizedBox(
                                    height: GetResponsiveSize.getResponsiveSize(
                                      context,
                                      mobile: 10, // unchanged on phones
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
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                      height: GetResponsiveSize.getResponsiveSize(
                    context,
                    mobile: 100, // unchanged for phones
                    tablet: 150,
                    largeTablet: 180,
                    desktop: 200,
                  )),

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
                    child: buildSectionTitle("Recommendations"),
                  ),
                  const SizedBox(height: 10),

                  // 🔷 MAIN GRIDVIEW - now uses regular GridView for proper scrolling
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: buildGridView(),
                  ),
                ],
              ),
            ),
          ),
        ),
        floatingActionButton: const BottomNavBar(),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      ),
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
              final bool isTab = GetResponsiveSize.isTablet(context);
              final double logoWidth = GetResponsiveSize.getResponsiveSize(
                context,
                mobile: 0, // keep phone layout unchanged
                tablet: 200,
                largeTablet: 230,
                desktop: 230,
              );
              return Image.asset(
                'assets/images/Ado-dad-home.png',
                width: isTab ? logoWidth : null,
                fit: BoxFit.contain,
              );
            },
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // GestureDetector(
                //   child: Image.asset('assets/images/notification.png'),
                // ),
                if (_userLocation != null)
                  Expanded(
                    child: Text(
                      _userLocation!,
                      style: TextStyle(
                          color: AppColors.whiteColor, fontSize: locationFont),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                    ),
                  ),
                SizedBox(width: 10),
                GestureDetector(
                  onTap: () async {
                    final updatedLocation = await _showLocationInputDialog();
                    if (updatedLocation != null) {
                      setState(() {
                        _userLocation =
                            updatedLocation; // 🔁 updates UI immediately
                      });
                    }
                  },
                  child: Builder(
                    builder: (context) {
                      final bool isTab = GetResponsiveSize.isTablet(context);
                      final double iconSize =
                          GetResponsiveSize.getResponsiveSize(
                        context,
                        mobile: 0, // keep phone layout unchanged
                        tablet: 30,
                        largeTablet: 34,
                        desktop: 34,
                      );
                      return Image.asset(
                        'assets/images/Frame.png',
                        width: isTab ? iconSize : null,
                        height: isTab ? iconSize : null,
                        fit: BoxFit.contain,
                      );
                    },
                  ),
                )
              ],
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

  Widget buildCategories(BuildContext context) {
    String categoryNameText(String text) {
      return text.replaceAll(' ', '\n');
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = GetResponsiveSize.isTablet(context);
    final isLargeTablet = GetResponsiveSize.isLargeTablet(context);
    final scale = GetResponsiveSize.getResponsiveSize(
      context,
      mobile: 1.0,
      tablet: 1.18,
      largeTablet: 1.35,
      desktop: 1.5,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10),
      child: SizedBox(
        height: GetResponsiveSize.getResponsiveSize(
          context,
          mobile: 120,
          tablet: 180,
          largeTablet: 210,
          desktop: 230,
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: categories.map((category) {
              return Padding(
                padding: const EdgeInsets.only(right: 15),
                child: GestureDetector(
                  onTap: () async {
                    // Special handling for Showroom category
                    if (category.categoryId == 'showroom') {
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
                        padding:
                            EdgeInsets.all(GetResponsiveSize.getResponsiveSize(
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
                          child:
                              Image.asset(category.image, fit: BoxFit.contain),
                        ),
                      ),
                      const SizedBox(height: 5),
                      SizedBox(
                        width: GetResponsiveSize.isTablet(context)
                            ? GetResponsiveSize.getResponsiveSize(
                                context,
                                mobile:
                                    screenWidth * 0.2, // not used on tablets
                                tablet: screenWidth * 0.24,
                                largeTablet: screenWidth * 0.26,
                                desktop: screenWidth * 0.28,
                              )
                            : screenWidth * 0.2,
                        child: Builder(
                          builder: (context) {
                            final double baseSize =
                                AppTextstyle.categoryLabelTextStyle.fontSize ??
                                    12;
                            final double labelSize =
                                GetResponsiveSize.getResponsiveFontSize(
                              context,
                              mobile: baseSize, // keep phone unchanged
                              tablet: baseSize + 10,
                              largeTablet: baseSize + 13,
                              desktop: baseSize + 13,
                            );
                            return Text(
                              categoryNameText(
                                category.name,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextstyle.categoryLabelTextStyle
                                  .copyWith(fontSize: labelSize),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
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
    final textScale = MediaQuery.of(context).textScaleFactor.clamp(1.0, 1.3);
    const horizontalPagePadding = 15.0; // matches your padding
    const spacing = 15.0;

    // available width for grid content
    final available =
        screenWidth - (horizontalPagePadding * 2) - (spacing * (columns - 1));

    final cardWidth = available / columns;

    // make image height proportional to width for a stable look
    final imageHeight = cardWidth * 0.60; // base estimate for image area

    // estimate text height (3 lines: price, 2-line desc, location)
    const baseLine = 16.0; // base font size used in your Texts
    // 1 line price + 2 lines desc + 1 line location = 4 lines
    final textBlockHeight = (baseLine * 4) * textScale;

    // paddings + image + text + extra breathing space
    const outerPadding = 8.0 /* card inner */ + 8.0 /* bottom padding */;
    final extra = GetResponsiveSize.getResponsiveSize(
      context,
      mobile: 10.0,
      tablet: 40.0,
      largeTablet: 60.0,
      desktop: 60.0,
    ); // more space for larger content on tablets

    return imageHeight + textBlockHeight + outerPadding + extra;
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
            child: Center(child: Text("Error: ${state.message}")),
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
          return const Center(child: CircularProgressIndicator());
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
                      return buildAdCard(ad);
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
          return Center(child: Text("Error: ${state.message}"));
        } else {
          return const Center(child: Text("No data available"));
        }
      },
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
                  child: Image.network(
                    ad.images.first,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const ColoredBox(color: Colors.black12),
                  ),
                ),
              ),
            Padding(
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
                              return const SizedBox(
                                width: 24,
                                height: 24,
                                child: Center(
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.grey),
                                    ),
                                  ),
                                ),
                              );
                            }

                            return GestureDetector(
                              onTap: () {
                                context.read<FavoriteBloc>().add(
                                      FavoriteEvent.toggleFavorite(
                                        adId: ad.id,
                                        isCurrentlyFavorited: isFavorited,
                                      ),
                                    );
                              },
                              child: Image.asset(
                                isFavorited
                                    ? 'assets/images/favorite_icon_filled.png'
                                    : 'assets/images/favorite_icon_unfilled.png',
                                width: GetResponsiveSize.getResponsiveSize(
                                  context,
                                  mobile: 24,
                                  tablet: 30,
                                  largeTablet: 34,
                                  desktop: 34,
                                ),
                                height: GetResponsiveSize.getResponsiveSize(
                                  context,
                                  mobile: 24,
                                  tablet: 30,
                                  largeTablet: 34,
                                  desktop: 34,
                                ),
                              ),
                            );
                          },
                        )
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      ad.description,
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
                    const SizedBox(height: 2),
                    Text(
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
                  ],
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
  static const double _vPad = 10;

  @override
  Widget build(BuildContext context) {
    // Responsive sizes for bar and icons (phones unchanged)
    final double screenWidth = MediaQuery.of(context).size.width;
    final double horizontalMargin = GetResponsiveSize.getResponsiveSize(
      context,
      mobile: 0,
      tablet: 24,
      largeTablet: 32,
      desktop: 40,
    );
    final double barWidth = GetResponsiveSize.getResponsiveSize(
      context,
      mobile: 300,
      tablet: screenWidth - (horizontalMargin * 2),
      largeTablet: screenWidth - (horizontalMargin * 2),
      desktop: screenWidth - (horizontalMargin * 2),
    );
    final double barHeight = GetResponsiveSize.getResponsiveSize(
      context,
      mobile: 60,
      tablet: 80,
      largeTablet: 85,
      desktop: 90,
    );
    final double baseIconSize = GetResponsiveSize.getResponsiveSize(
      context,
      mobile: 20,
      tablet: 35,
      largeTablet: 40,
      desktop: 40,
    );
    final double addIconSize = GetResponsiveSize.getResponsiveSize(
      context,
      mobile: 36,
      tablet: 50,
      largeTablet: 50,
      desktop: 54,
    );
    return Container(
      height: barHeight,
      width: barWidth,
      decoration: BoxDecoration(
        color: AppColors.primaryColor,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 10,
          vertical: GetResponsiveSize.getResponsiveSize(
            context,
            mobile: _vPad,
            tablet: 15,
            largeTablet: 17,
            desktop: 17,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _navItem(context, 'assets/images/home-icon.png', '/home',
                iconSize: baseIconSize),
            _navItem(
                context, 'assets/images/search-icon.png', '/search?from=/home',
                iconSize: baseIconSize),
            _navItem(context, 'assets/images/add-icon.png', '/seller',
                iconSize: addIconSize),
            _navItem(
                context, 'assets/images/chat-icon.png', '/chat-rooms?from=home',
                iconSize: baseIconSize),
            _navItem(context, 'assets/images/profile-icon.png', '/profile',
                iconSize: baseIconSize),
          ],
        ),
      ),
    );
  }

  Widget _navItem(
    BuildContext context,
    String image,
    String? route, {
    double iconSize = 20,
  }) {
    return GestureDetector(
      onTap: () {
        if (route != null && route.contains('/chat-rooms')) {
          context.go(route);
        } else if (route != null) {
          context.push(route);
        }
      },
      child: Center(
        // Fix the rendered size exactly
        child: SizedBox.square(
          dimension: iconSize,
          child: Image.asset(
            image,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
