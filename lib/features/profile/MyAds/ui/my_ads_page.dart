import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ado_dad_user/features/profile/MyAds/bloc/my_ads_bloc.dart';
import 'package:ado_dad_user/models/my_ads_model.dart';

class MyAdsPage extends StatelessWidget {
  const MyAdsPage({super.key});

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
            error: (e) => Center(child: Text('Error: ${e.message}')),
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

    return InkWell(
      onTap: () {}, // TODO: navigate to ad detail/edit
      borderRadius: radius,
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white,
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
              _Thumb(url: ad.images.isNotEmpty ? ad.images.first : ''),
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
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1C1F23),
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
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1C1F23),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (false) ...[
                              const SizedBox(height: 6),
                              const _InfoPill(text: 'Showroom'),
                            ] else
                              const SizedBox(height: 6),

                            // KM / Fuel
                            Text(
                              _metaLine(ad),
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF6B7280),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            // Location
                            Text(
                              ad.location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFFA0A4AB),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Status chip (right side)
                      // Align(
                      //   alignment: Alignment.topRight,
                      //   child: _StatusChip(status: AdStatus.listed),
                      // ),
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
}

/* ------------------------------ Sub-widgets ----------------------------- */

class _Thumb extends StatelessWidget {
  const _Thumb({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: 98,
        height: 98,
        child: Image.network(
          url,
          fit: BoxFit.cover,
          loadingBuilder: (c, child, progress) =>
              progress == null ? child : const _ShimmerBox(),
          errorBuilder: (_, __, ___) => const _BrokenImage(),
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

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFEDEBFF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF5A55F5),
          fontWeight: FontWeight.w700,
          fontSize: 11.5,
          height: 1,
        ),
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
      AdStatus.listed => (const Color(0xFFFF6F6F), Colors.white, 'Listed'),
      AdStatus.soldOut => (
          const Color(0xFFE9EAED),
          const Color(0xFF111827),
          'Sold out'
        ),
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
