import 'package:ado_dad_user/common/app_colors.dart';
import 'package:ado_dad_user/common/app_textstyle.dart';
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

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 300) {
        print(
            "🧭 Scroll Position: ${_scrollController.position.pixels} / ${_scrollController.position.maxScrollExtent}");

        // Trigger next page load when nearing bottom
        context
            .read<AdvertisementBloc>()
            .add(const AdvertisementEvent.fetchNextPage());
      }
    });

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

      final placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);
      final place = placemarks[0];

      final newAddress = '${place.locality}, ${place.administrativeArea}';

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_location', newAddress);

      setState(() {
        // _userLocation =
        //     '${place.locality}, ${place.administrativeArea}'; // Or full address
        _userLocation = newAddress;
      });
    } catch (e) {
      print("Location error: $e");
      setState(() {
        _userLocation = "Location not available";
      });
    }
  }

  Future<String?> _showLocationInputDialog() async {
    final controller = TextEditingController(text: _userLocation ?? '');

    return await showDialog<String>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Enter Your Location'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      hintText: 'e.g. Bangalore, Karnataka',
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    icon: Icon(Icons.my_location),
                    label: Text('Use Current Location'),
                    onPressed: () async {
                      try {
                        final position = await _determinePosition();
                        final placemarks = await placemarkFromCoordinates(
                            position.latitude, position.longitude);
                        final place = placemarks[0];
                        final gpsAddress =
                            '${place.locality}, ${place.administrativeArea}';

                        setDialogState(() {
                          controller.text = gpsAddress;
                        });
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text("Failed to fetch location: $e")),
                        );
                      }
                    },
                  ),
                ],
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
        body: SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            children: [
              // 🔷 HEADER PART
              Stack(
                clipBehavior: Clip.none,
                children: [
                  // 🔹 Blue curved header with content
                  Container(
                    height: 150,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryColor,
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(30),
                      ),
                    ),
                    padding: const EdgeInsets.only(top: 8, bottom: 70),
                    child: buildTopBar(), // 🔹 AdoDad logo + location
                  ),

                  // 🔹 Positioned Banner (slightly below blue container)
                  Positioned(
                    bottom: -85, // Controls how much overlaps
                    left: 0,
                    right: 0,
                    child: BlocBuilder<BannerBloc, BannerState>(
                      builder: (context, state) {
                        return state.when(
                          initial: () => const SizedBox(),
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (message) => Text("Error: $message"),
                          loaded: (banners) => Column(
                            children: [
                              CarouselSlider(
                                carouselController: _carouselController,
                                options: CarouselOptions(
                                  height: 140,
                                  autoPlay: false,
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
                              const SizedBox(height: 10),
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
              const SizedBox(height: 100),

              // 🔷 CATEGORIES
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: buildSectionTitle("Categories"),
              ),
              const SizedBox(height: 5),
              buildCategories(context),

              // 🔷 RECOMMENDATIONS TITLE
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: buildSectionTitle("Recommendations"),
              ),
              const SizedBox(height: 10),

              // 🔷 MAIN GRIDVIEW - now participates in page scroll
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: buildGridView(),
              ),
            ],
          ),
        ),
        floatingActionButton: const BottomNavBar(),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      ),
    );
  }

  Widget buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Image.asset('assets/images/Ado-dad-home.png'),
          Row(
            children: [
              // GestureDetector(
              //   child: Image.asset('assets/images/notification.png'),
              // ),
              if (_userLocation != null)
                Text(
                  _userLocation!,
                  style: TextStyle(color: AppColors.whiteColor, fontSize: 15),
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
                child: Image.asset('assets/images/Frame.png'),
              )
            ],
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
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: AppTextstyle.sectionTitleTextStyle,
      ),
    );
  }

  Widget buildCategories(BuildContext context) {
    String categoryNameText(String text) {
      return text.replaceAll(' ', '\n');
    }

    final screenWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10),
      child: SizedBox(
        height: 120,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: categories.map((category) {
              return Padding(
                padding: const EdgeInsets.only(right: 15),
                child: GestureDetector(
                  onTap: () async {
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
                        height: 70,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.whiteColor,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(color: Colors.black12, blurRadius: 2)
                          ],
                        ),
                        child: Image.asset(category.image),
                      ),
                      const SizedBox(height: 5),
                      SizedBox(
                        width: screenWidth * 0.2,
                        child: Text(
                            categoryNameText(
                              category.name,
                            ),
                            textAlign: TextAlign.center,
                            style: AppTextstyle.categoryLabelTextStyle),
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
    if (w >= 1200) return 5;
    if (w >= 900) return 4;
    if (w >= 600) return 3;
    return 2;
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
    final imageHeight = cardWidth * 0.60; // tweak: 0.55..0.70

    // estimate text height (3 lines: price, 2-line desc, location)
    const baseLine = 16.0; // base font size used in your Texts
    // 1 line price + 2 lines desc + 1 line location = 4 lines
    final textBlockHeight = (baseLine * 4) * textScale;

    // paddings + image + text + extra breathing space
    const outerPadding = 8.0 /* card inner */ + 8.0 /* bottom padding */;
    final extra = 10.0; // small buffer for badges, rounding, etc.

    return imageHeight + textBlockHeight + outerPadding + extra;
  }

  // Widget buildGridView() {
  //   return BlocBuilder<AdvertisementBloc, AdvertisementState>(
  //     builder: (context, state) {
  //       if (state is AdvertisementLoading) {
  //         return const Center(child: CircularProgressIndicator());
  //       } else if (state is ListingsLoaded) {
  //         final listings = state.listings;
  //         final hasMore = state.hasMore;

  //         return RefreshIndicator(
  //           onRefresh: () async {
  //             context
  //                 .read<AdvertisementBloc>()
  //                 .add(const AdvertisementEvent.fetchAllListings());
  //           },
  //           child: GridView.builder(
  //             controller: _scrollController,
  //             physics: const AlwaysScrollableScrollPhysics(),
  //             padding: const EdgeInsets.symmetric(horizontal: 15),
  //             shrinkWrap: true,
  //             itemCount: listings.length + (hasMore ? 1 : 0),
  //             gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
  //               crossAxisCount: 2,
  //               crossAxisSpacing: 15,
  //               mainAxisSpacing: 15,
  //               childAspectRatio: 20 / 28,
  //             ),
  //             itemBuilder: (context, index) {
  //               if (index < listings.length) {
  //                 final ad = listings[index];
  //                 return buildAdCard(ad);
  //               } else {
  //                 return hasMore
  //                     ? const Padding(
  //                         padding: EdgeInsets.all(16.0),
  //                         child: Center(child: CircularProgressIndicator()),
  //                       )
  //                     : const SizedBox(); // no loader if no more
  //               }
  //             },
  //           ),
  //         );
  //       } else if (state is AdvertisementError) {
  //         return Center(child: Text("Error: ${state.message}"));
  //       } else {
  //         return const Center(child: Text("No data available"));
  //       }
  //     },
  //   );
  // }

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
            child: LayoutBuilder(
              builder: (context, constraints) {
                final cols = _columnsForWidth(constraints.maxWidth);
                final mainExtent = _cardMainAxisExtent(context, cols);

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
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

  // Widget buildAdCard(AddModel ad) {
  //   return GestureDetector(
  //     onTap: () {
  //       // Push to detail page if needed
  //       // context.push('/ad-detail', extra: ad);
  //     },
  //     child: Container(
  //       decoration: BoxDecoration(
  //         color: Colors.white,
  //         borderRadius: BorderRadius.circular(10),
  //         boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 2)],
  //       ),
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           if (ad.images.isNotEmpty)
  //             ClipRRect(
  //               borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
  //               child: Image.network(
  //                 ad.images.first,
  //                 height: 120,
  //                 width: double.infinity,
  //                 fit: BoxFit.cover,
  //               ),
  //             ),
  //           Padding(
  //             padding: const EdgeInsets.all(8.0),
  //             child: Column(
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 Text("₹${ad.price}",
  //                     style: const TextStyle(
  //                         fontWeight: FontWeight.bold, fontSize: 16)),
  //                 Text(ad.description,
  //                     maxLines: 2,
  //                     overflow: TextOverflow.ellipsis,
  //                     style: const TextStyle(fontSize: 13)),
  //                 Text(ad.location,
  //                     style: const TextStyle(
  //                         fontWeight: FontWeight.bold, fontSize: 12)),
  //               ],
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

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
                  // ✅ keeps image area stable
                  aspectRatio:
                      16 / 10, // ~0.625 height/width — matches 0.60 above
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
                style: const TextStyle(fontSize: 13, color: Colors.black),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("₹${ad.price}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
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
                                width: 24,
                                height: 24,
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
                    ),
                    const SizedBox(height: 2),
                    Text(
                      ad.location,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 12),
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
              return GestureDetector(
                onTap: () {
                  setState(() {
                    BuildIndicator.currentIndex = index;
                  });
                  widget.controller.jumpToPage(index);
                },
                child: Container(
                  width: BuildIndicator.currentIndex == index ? 15 : 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 5),
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
  static const double _barHeight = 60; // a bit taller to fit big icon
  static const double _vPad = 10;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _barHeight,
      width: 300,
      decoration: BoxDecoration(
        color: AppColors.primaryColor,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: _vPad),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _navItem(context, 'assets/images/home-icon.png', '/home'),
            _navItem(
                context, 'assets/images/search-icon.png', '/search?from=/home'),
            _navItem(context, 'assets/images/add-icon.png', '/seller',
                iconSize: 36),
            _navItem(
                context, 'assets/images/chat-icon.png', '/messages?from=/home'),
            _navItem(context, 'assets/images/profile-icon.png', '/profile'),
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
      onTap: () => context.push(route!),
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
