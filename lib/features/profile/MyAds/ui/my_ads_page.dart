import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
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
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 20,
                color: Color(0xFF16181B),
              ),
            );
          },
        ),
        centerTitle: false,
      ),
      body: BlocBuilder<MyAdsBloc, MyAdsState>(
        builder: (context, state) {
          return state.maybeMap(
            loading: (_) => const Center(child: CircularProgressIndicator()),
            initial: (_) => const Center(child: CircularProgressIndicator()),
            error: (e) => Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red.shade300,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading your ads',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      e.message,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context.read<MyAdsBloc>().add(const MyAdsEvent.load());
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
            loaded: (loaded) {
              if (loaded.ads.isEmpty) {
                return const Center(child: Text('No ads yet'));
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: loaded.ads.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, i) => _AdTile(ad: loaded.ads[i]),
              );
            },
            orElse: () => const SizedBox.shrink(),
          );
        },
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
    final radius = BorderRadius.circular(18);
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
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Thumb(
                url: ad.images.isNotEmpty ? ad.images.first : '',
                isSold: isSold,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 92,
                  child: Stack(
                    children: [
                      // Main texts
                      Positioned.fill(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Price
                            Text(
                              _formatINR(ad.price),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: isSold
                                    ? Colors.grey.shade500
                                    : const Color(0xFF1C1F23),
                              ),
                            ),
                            const SizedBox(height: 2),
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
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: isSold
                                          ? Colors.grey.shade500
                                          : const Color(0xFF1C1F23),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),

                            // KM / Fuel
                            Text(
                              _metaLine(ad),
                              style: TextStyle(
                                fontSize: 13,
                                color: isSold
                                    ? Colors.grey.shade400
                                    : const Color(0xFF6B7280),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            // Location
                            Text(
                              ad.location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: isSold
                                    ? Colors.grey.shade400
                                    : const Color(0xFFA0A4AB),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
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
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: 98,
        height: 98,
        child: Stack(
          children: [
            Image.network(
              url,
              fit: BoxFit.cover,
              loadingBuilder: (c, child, progress) =>
                  progress == null ? child : const _ShimmerBox(),
              errorBuilder: (_, __, ___) => const _BrokenImage(),
            ),
            if (isSold)
              Container(
                color: Colors.black.withOpacity(0.4),
                child: const Center(
                  child: Icon(
                    Icons.sell,
                    color: Colors.white,
                    size: 24,
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
      color: const Color(0xFFF0F2F6),
      alignment: Alignment.center,
      child: const Icon(Icons.image, size: 22, color: Color(0xFFB9C0CC)),
    );
  }
}

class _BrokenImage extends StatelessWidget {
  const _BrokenImage();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF0F2F6),
      alignment: Alignment.center,
      child: const Icon(Icons.broken_image_outlined,
          size: 22, color: Color(0xFFB9C0CC)),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w800,
          fontSize: 12,
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
    final bhk = ad.propertyDetails?.bedrooms ?? 0;
    final area = ad.propertyDetails?.areaSqft ?? 0;
    return '$type • ${bhk}BHK • ${area}sqft';
  }
  final year = ad.year ?? ad.vehicleDetails?.year ?? 0;
  return '${ad.description} (${year == 0 ? '' : year})';
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
