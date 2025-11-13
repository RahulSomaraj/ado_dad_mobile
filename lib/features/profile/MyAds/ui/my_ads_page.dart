import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ado_dad_user/common/get_responsive_size.dart';
import 'package:ado_dad_user/features/profile/MyAds/bloc/my_ads_bloc.dart';
import 'package:ado_dad_user/models/my_ads_model.dart';
import 'package:ado_dad_user/models/advertisement_model/add_model.dart';
import 'package:ado_dad_user/common/shared_pref.dart';
import 'package:go_router/go_router.dart';

class MyAdsPage extends StatefulWidget {
  const MyAdsPage({super.key});

  @override
  State<MyAdsPage> createState() => _MyAdsPageState();
}

class _MyAdsPageState extends State<MyAdsPage> {
  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    final token = await getToken();
    if (token == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please login to view your ads'),
            backgroundColor: Colors.red,
          ),
        );
        context.go('/login');
      }
      return;
    }

    // Load ads if authenticated
    if (mounted) {
      context.read<MyAdsBloc>().add(const MyAdsEvent.load());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F4FC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF6F4FC),
        leading: IconButton(
          icon: Icon(
            (!kIsWeb && Platform.isIOS)
                ? Icons.arrow_back_ios
                : Icons.arrow_back,
            size: GetResponsiveSize.getResponsiveSize(
              context,
              mobile: 24,
              tablet: 30,
              largeTablet: 32,
              desktop: 36,
            ),
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: BlocBuilder<MyAdsBloc, MyAdsState>(
          builder: (context, state) {
            final count = state.maybeMap(
              loaded: (s) => s.ads.length,
              orElse: () => 0,
            );
            return Text(
              'My Ads ($count)',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: GetResponsiveSize.getResponsiveFontSize(
                  context,
                  mobile: 20,
                  tablet: 24,
                  largeTablet: 28,
                  desktop: 32,
                ),
                color: const Color(0xFF16181B),
              ),
            );
          },
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 20),
        child: BlocBuilder<MyAdsBloc, MyAdsState>(
          builder: (context, state) {
            return state.maybeMap(
              loading: (_) => const Center(child: CircularProgressIndicator()),
              initial: (_) => const Center(child: CircularProgressIndicator()),
              error: (e) => Center(
                child: Padding(
                  padding: EdgeInsets.all(
                    GetResponsiveSize.getResponsivePadding(
                      context,
                      mobile: 16,
                      tablet: 24,
                      largeTablet: 32,
                      desktop: 40,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: GetResponsiveSize.getResponsiveSize(
                          context,
                          mobile: 64,
                          tablet: 80,
                          largeTablet: 96,
                          desktop: 112,
                        ),
                        color: Colors.red.shade300,
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
                        'Error loading your ads',
                        style: TextStyle(
                          fontSize: GetResponsiveSize.getResponsiveFontSize(
                            context,
                            mobile: 18,
                            tablet: 22,
                            largeTablet: 26,
                            desktop: 30,
                          ),
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      SizedBox(
                        height: GetResponsiveSize.getResponsiveSize(
                          context,
                          mobile: 8,
                          tablet: 12,
                          largeTablet: 16,
                          desktop: 20,
                        ),
                      ),
                      Text(
                        e.message,
                        style: TextStyle(
                          fontSize: GetResponsiveSize.getResponsiveFontSize(
                            context,
                            mobile: 14,
                            tablet: 18,
                            largeTablet: 20,
                            desktop: 24,
                          ),
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(
                        height: GetResponsiveSize.getResponsiveSize(
                          context,
                          mobile: 16,
                          tablet: 24,
                          largeTablet: 32,
                          desktop: 40,
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          context
                              .read<MyAdsBloc>()
                              .add(const MyAdsEvent.load());
                        },
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: GetResponsiveSize.getResponsivePadding(
                              context,
                              mobile: 16,
                              tablet: 24,
                              largeTablet: 32,
                              desktop: 40,
                            ),
                            vertical: GetResponsiveSize.getResponsivePadding(
                              context,
                              mobile: 12,
                              tablet: 16,
                              largeTablet: 20,
                              desktop: 24,
                            ),
                          ),
                        ),
                        child: Text(
                          'Retry',
                          style: TextStyle(
                            fontSize: GetResponsiveSize.getResponsiveFontSize(
                              context,
                              mobile: 14,
                              tablet: 18,
                              largeTablet: 20,
                              desktop: 24,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              loaded: (loaded) {
                if (loaded.ads.isEmpty) {
                  return Center(
                    child: Text(
                      'No ads yet',
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
                  );
                }
                return ListView.separated(
                  padding: EdgeInsets.fromLTRB(
                    GetResponsiveSize.getResponsivePadding(
                      context,
                      mobile: 16,
                      tablet: 24,
                      largeTablet: 32,
                      desktop: 40,
                    ),
                    GetResponsiveSize.getResponsivePadding(
                      context,
                      mobile: 8,
                      tablet: 12,
                      largeTablet: 16,
                      desktop: 20,
                    ),
                    GetResponsiveSize.getResponsivePadding(
                      context,
                      mobile: 16,
                      tablet: 24,
                      largeTablet: 32,
                      desktop: 40,
                    ),
                    GetResponsiveSize.getResponsivePadding(
                      context,
                      mobile: 24,
                      tablet: 32,
                      largeTablet: 40,
                      desktop: 48,
                    ),
                  ),
                  itemCount: loaded.ads.length,
                  separatorBuilder: (_, __) => SizedBox(
                    height: GetResponsiveSize.getResponsiveSize(
                      context,
                      mobile: 16,
                      tablet: 22,
                      largeTablet: 28,
                      desktop: 34,
                    ),
                  ),
                  itemBuilder: (context, i) => _AdTile(ad: loaded.ads[i]),
                );
              },
              orElse: () => const SizedBox.shrink(),
            );
          },
        ),
      ),
    );
  }
}

/* ----------------------------- Tile Widget ----------------------------- */

class _AdTile extends StatelessWidget {
  const _AdTile({required this.ad});
  final MyAd ad;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(
      GetResponsiveSize.getResponsiveBorderRadius(
        context,
        mobile: 18,
        tablet: 22,
        largeTablet: 26,
        desktop: 30,
      ),
    );
    final isSold = ad.soldOut == true;

    return InkWell(
      onTap: isSold ? null : () => _navigateToDetail(context),
      borderRadius: radius,
      child: Ink(
        decoration: BoxDecoration(
          color: isSold ? Colors.grey.shade300 : Colors.white,
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: GetResponsiveSize.getResponsiveSize(
                context,
                mobile: 12,
                tablet: 16,
                largeTablet: 20,
                desktop: 24,
              ),
              offset: Offset(
                0,
                GetResponsiveSize.getResponsiveSize(
                  context,
                  mobile: 4,
                  tablet: 6,
                  largeTablet: 8,
                  desktop: 10,
                ),
              ),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(
            GetResponsiveSize.getResponsivePadding(
              context,
              mobile: 14,
              tablet: 20,
              largeTablet: 26,
              desktop: 32,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Thumb(
                url: ad.images.isNotEmpty ? ad.images.first : '',
                isSold: isSold,
              ),
              SizedBox(
                width: GetResponsiveSize.getResponsiveSize(
                  context,
                  mobile: 12,
                  tablet: 18,
                  largeTablet: 24,
                  desktop: 30,
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    // Main texts
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Price
                        Text(
                          _formatINR(ad.price),
                          style: TextStyle(
                            fontSize: GetResponsiveSize.getResponsiveFontSize(
                              context,
                              mobile: 16,
                              tablet: 22,
                              largeTablet: 28,
                              desktop: 34,
                            ),
                            fontWeight: FontWeight.w800,
                            color: isSold
                                ? Colors.grey.shade500
                                : const Color(0xFF1C1F23),
                          ),
                        ),
                        SizedBox(
                          height: GetResponsiveSize.getResponsiveSize(
                            context,
                            mobile: 2,
                            tablet: 4,
                            largeTablet: 6,
                            desktop: 8,
                          ),
                        ),
                        // Title + optional showroom pill
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text(
                                _titleFor(ad),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize:
                                      GetResponsiveSize.getResponsiveFontSize(
                                    context,
                                    mobile: 15,
                                    tablet: 21,
                                    largeTablet: 27,
                                    desktop: 33,
                                  ),
                                  fontWeight: FontWeight.w600,
                                  color: isSold
                                      ? Colors.grey.shade500
                                      : const Color(0xFF1C1F23),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: GetResponsiveSize.getResponsiveSize(
                            context,
                            mobile: 6,
                            tablet: 10,
                            largeTablet: 14,
                            desktop: 18,
                          ),
                        ),

                        // KM / Fuel
                        Text(
                          _metaLine(ad),
                          style: TextStyle(
                            fontSize: GetResponsiveSize.getResponsiveFontSize(
                              context,
                              mobile: 13,
                              tablet: 19,
                              largeTablet: 23,
                              desktop: 27,
                            ),
                            color: isSold
                                ? Colors.grey.shade400
                                : const Color(0xFF6B7280),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(
                          height: GetResponsiveSize.getResponsiveSize(
                            context,
                            mobile: 2,
                            tablet: 4,
                            largeTablet: 6,
                            desktop: 8,
                          ),
                        ),
                        // Location
                        Text(
                          ad.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: GetResponsiveSize.getResponsiveFontSize(
                              context,
                              mobile: 12,
                              tablet: 18,
                              largeTablet: 22,
                              desktop: 26,
                            ),
                            color: isSold
                                ? Colors.grey.shade400
                                : const Color(0xFFA0A4AB),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    // Status chip (right side)
                    Align(
                      alignment: Alignment.topRight,
                      child: _StatusChip(
                        status: ad.soldOut == true
                            ? AdStatus.soldOut
                            : AdStatus.listed,
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

  void _navigateToDetail(BuildContext context) {
    // Convert MyAd to AddModel for navigation
    final addModel = _convertMyAdToAddModel(ad);
    context.push('/add-detail-page', extra: addModel);
  }

  AddModel _convertMyAdToAddModel(MyAd myAd) {
    // Convert MyAdUser to AdUser
    AdUser? adUser;
    if (myAd.user != null) {
      adUser = AdUser(
        id: myAd.user!.id,
        name: myAd.user!.name,
        email: myAd.user!.email,
      );
    }

    // Convert vehicle details if available
    Manufacturer? manufacturer;
    Model? model;
    if (myAd.vehicleDetails != null) {
      // Note: These would need to be populated from your manufacturer/model repositories
      // For now, using placeholder values
      manufacturer = Manufacturer(
        id: myAd.vehicleDetails!.manufacturerId,
        name: 'Manufacturer', // This should be fetched from your data
      );
      model = Model(
        id: myAd.vehicleDetails!.modelId,
        name: 'Model', // This should be fetched from your data
      );
    }

    return AddModel(
      id: myAd.id,
      description: myAd.description,
      price: myAd.price,
      images: myAd.images,
      location: myAd.location,
      category: myAd.category,
      isActive: myAd.isActive,
      updatedAt: myAd.updatedAt,
      user: adUser,
      year: myAd.year ?? myAd.vehicleDetails?.year,
      soldOut: myAd.soldOut,
      // Vehicle details
      vehicleType: myAd.vehicleDetails?.vehicleType,
      manufacturer: manufacturer,
      model: model,
      mileage: myAd.vehicleDetails?.mileage,
      transmissionId: myAd.vehicleDetails?.transmissionTypeId,
      fuelTypeId: myAd.vehicleDetails?.fuelTypeId,
      color: myAd.vehicleDetails?.color,
      isFirstOwner: myAd.vehicleDetails?.isFirstOwner,
      hasInsurance: myAd.vehicleDetails?.hasInsurance,
      hasRcBook: myAd.vehicleDetails?.hasRcBook,
      additionalFeatures: myAd.vehicleDetails?.additionalFeatures,
      // Property details
      propertyType: myAd.propertyDetails?.propertyType,
      bedrooms: myAd.propertyDetails?.bedrooms,
      bathrooms: myAd.propertyDetails?.bathrooms,
      areaSqft: myAd.propertyDetails?.areaSqft,
      floor: myAd.propertyDetails?.floor,
      isFurnished: myAd.propertyDetails?.isFurnished,
      hasParking: myAd.propertyDetails?.hasParking,
      hasGarden: myAd.propertyDetails?.hasGarden,
      amenities: myAd.propertyDetails?.amenities,
    );
  }
}

/* ------------------------------ Sub-widgets ----------------------------- */

class _Thumb extends StatelessWidget {
  const _Thumb({required this.url, this.isSold = false});
  final String url;
  final bool isSold;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(
        GetResponsiveSize.getResponsiveBorderRadius(
          context,
          mobile: 14,
          tablet: 18,
          largeTablet: 22,
          desktop: 26,
        ),
      ),
      child: SizedBox(
        width: GetResponsiveSize.getResponsiveSize(
          context,
          mobile: 98,
          tablet: 140,
          largeTablet: 180,
          desktop: 220,
        ),
        height: GetResponsiveSize.getResponsiveSize(
          context,
          mobile: 98,
          tablet: 140,
          largeTablet: 180,
          desktop: 220,
        ),
        child: Stack(
          children: [
            if (url.isNotEmpty)
              Image.network(
                url,
                width: GetResponsiveSize.getResponsiveSize(
                  context,
                  mobile: 98,
                  tablet: 140,
                  largeTablet: 180,
                  desktop: 220,
                ),
                height: GetResponsiveSize.getResponsiveSize(
                  context,
                  mobile: 98,
                  tablet: 140,
                  largeTablet: 180,
                  desktop: 220,
                ),
                fit: BoxFit.cover,
                loadingBuilder: (c, child, progress) =>
                    progress == null ? child : _ShimmerBox(),
                errorBuilder: (_, __, ___) => const _BrokenImage(),
              )
            else
              const _BrokenImage(),
            if (isSold)
              Container(
                color: Colors.black.withOpacity(0.4),
                child: Center(
                  child: Icon(
                    Icons.sell,
                    color: Colors.white,
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
          ],
        ),
      ),
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  const _ShimmerBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: GetResponsiveSize.getResponsiveSize(
        context,
        mobile: 98,
        tablet: 140,
        largeTablet: 180,
        desktop: 220,
      ),
      height: GetResponsiveSize.getResponsiveSize(
        context,
        mobile: 98,
        tablet: 140,
        largeTablet: 180,
        desktop: 220,
      ),
      color: const Color(0xFFF0F2F6),
      alignment: Alignment.center,
      child: Icon(
        Icons.image,
        size: GetResponsiveSize.getResponsiveSize(
          context,
          mobile: 22,
          tablet: 30,
          largeTablet: 38,
          desktop: 46,
        ),
        color: const Color(0xFFB9C0CC),
      ),
    );
  }
}

class _BrokenImage extends StatelessWidget {
  const _BrokenImage();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: GetResponsiveSize.getResponsiveSize(
        context,
        mobile: 98,
        tablet: 140,
        largeTablet: 180,
        desktop: 220,
      ),
      height: GetResponsiveSize.getResponsiveSize(
        context,
        mobile: 98,
        tablet: 140,
        largeTablet: 180,
        desktop: 220,
      ),
      color: const Color(0xFFF0F2F6),
      alignment: Alignment.center,
      child: Icon(
        Icons.broken_image_outlined,
        size: GetResponsiveSize.getResponsiveSize(
          context,
          mobile: 22,
          tablet: 30,
          largeTablet: 38,
          desktop: 46,
        ),
        color: const Color(0xFFB9C0CC),
      ),
    );
  }
}

enum AdStatus { listed, soldOut }

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final AdStatus status;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, text) = switch (status) {
      AdStatus.listed => (const Color(0xFF10B981), Colors.white, 'Listed'),
      AdStatus.soldOut => (const Color(0xFF6B7280), Colors.white, 'Sold Out'),
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: GetResponsiveSize.getResponsivePadding(
          context,
          mobile: 12,
          tablet: 16,
          largeTablet: 20,
          desktop: 24,
        ),
        vertical: GetResponsiveSize.getResponsivePadding(
          context,
          mobile: 6,
          tablet: 10,
          largeTablet: 14,
          desktop: 18,
        ),
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(
          GetResponsiveSize.getResponsiveBorderRadius(
            context,
            mobile: 20,
            tablet: 24,
            largeTablet: 28,
            desktop: 32,
          ),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w800,
          fontSize: GetResponsiveSize.getResponsiveFontSize(
            context,
            mobile: 12,
            tablet: 18,
            largeTablet: 22,
            desktop: 26,
          ),
          height: 1,
        ),
      ),
    );
  }
}

/* --------------------------------- Model -------------------------------- */

String _titleFor(MyAd ad) {
  if (ad.category == 'property') {
    final type = ad.propertyDetails?.propertyType ?? '';
    final capitalizedType = type.isNotEmpty
        ? '${type[0].toUpperCase()}${type.substring(1).toLowerCase()}'
        : '';
    final bhk = ad.propertyDetails?.bedrooms ?? 0;
    final area = ad.propertyDetails?.areaSqft ?? 0;
    return '$capitalizedType • ${bhk}BHK • ${area}sqft';
  }

  // For vehicles, show manufacturer and model names with year
  final year = ad.year ?? ad.vehicleDetails?.year ?? 0;

  // Use manufacturer and model information if available
  if (ad.manufacturer != null && ad.model != null) {
    final manufacturerName =
        ad.manufacturer!.displayName ?? ad.manufacturer!.name ?? '';
    final modelName = ad.model!.displayName ?? ad.model!.name;

    if (manufacturerName.isNotEmpty && modelName.isNotEmpty) {
      return year > 0
          ? '$manufacturerName $modelName ($year)'
          : '$manufacturerName $modelName';
    } else if (manufacturerName.isNotEmpty) {
      return year > 0 ? '$manufacturerName ($year)' : manufacturerName;
    } else if (modelName.isNotEmpty) {
      return year > 0 ? '$modelName ($year)' : modelName;
    }
  }

  // If we have manufacturer but no model, or vice versa
  if (ad.manufacturer != null) {
    final manufacturerName =
        ad.manufacturer!.displayName ?? ad.manufacturer!.name ?? '';
    if (manufacturerName.isNotEmpty) {
      return year > 0 ? '$manufacturerName ($year)' : manufacturerName;
    }
  }

  if (ad.model != null) {
    final modelName = ad.model!.displayName ?? ad.model!.name;
    if (modelName.isNotEmpty) {
      return year > 0 ? '$modelName ($year)' : modelName;
    }
  }

  // Fallback to description if manufacturer/model not available
  if (ad.description.isNotEmpty) {
    return year > 0 ? '${ad.description} ($year)' : ad.description;
  }

  // Ultimate fallback
  return year > 0 ? 'Vehicle ($year)' : 'Vehicle';
}

String _metaLine(MyAd ad) {
  if (ad.category == 'property') return 'Property';
  final km = ad.vehicleDetails?.mileage;
  return km != null ? '${_formatKM(km)} KM' : '-';
}

/* ------------------------------- Utilities ------------------------------ */

String _formatINR(int n) {
  // 7,50,000 style
  final s = n.toString();
  if (s.length <= 3) return '₹ $s';
  final last3 = s.substring(s.length - 3);
  String rest = s.substring(0, s.length - 3);
  final buf = StringBuffer();
  while (rest.length > 2) {
    buf.write(',${rest.substring(rest.length - 2)}');
    rest = rest.substring(0, rest.length - 2);
  }
  return '₹ $rest${buf.toString()},$last3';
}

String _formatKM(int km) {
  if (km >= 1000) {
    final v = (km / 1000.0);
    return v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 1) + 'K';
  }
  return km.toString();
}
