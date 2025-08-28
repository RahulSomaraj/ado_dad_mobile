import 'package:ado_dad_user/common/app_colors.dart';
import 'package:ado_dad_user/features/home/ad_detail/ad_detail_bloc.dart';
import 'package:ado_dad_user/models/advertisement_model/add_model.dart';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class AdDetailPage extends StatefulWidget {
  // final String adId;
  final AddModel ad;
  const AdDetailPage({super.key, required this.ad});

  @override
  State<AdDetailPage> createState() => _AdDetailPageState();
}

class _AdDetailPageState extends State<AdDetailPage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocBuilder<AdDetailBloc, AdDetailState>(
        builder: (context, state) {
          return state.when(
            initial: () => const Center(child: Text('Waiting for details...')),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e) => Center(child: Text('Error: $e')),
            loaded: (ad) => CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _headerCarousel(ad)),
                SliverToBoxAdapter(child: _dots(ad.images.length)),
                SliverToBoxAdapter(child: _titlePriceMeta(ad)),
                SliverToBoxAdapter(child: Divider()),

                SliverToBoxAdapter(child: _pillTabs(ad)),
                SliverToBoxAdapter(child: _description(ad)),
                // SliverToBoxAdapter(child: _sellerTile(ad)),
                // SliverToBoxAdapter(child: _recommendationsSection()),
                // const SliverPadding(padding: EdgeInsets.only(bottom: 90)),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: _secondaryBtn('Chat', onTap: () {}),
        //  Row(
        //   children: [
        //     Expanded(
        //       child: _primaryBtn('Make an offer', onTap: () {}),
        //     ),
        //     const SizedBox(width: 12),
        //     Expanded(
        //       child: _secondaryBtn('Chat', onTap: () {}),
        //     ),
        //   ],
        // ),
      ),
    );
  }

  // ======= Header (Carousel + overlay controls) =======
  Widget _headerCarousel(AddModel ad) {
    return Stack(
      children: [
        AspectRatio(
          aspectRatio: 16 / 10,
          child: CarouselSlider(
            options: CarouselOptions(
              viewportFraction: 1,
              height: double.infinity,
              autoPlay: true,
              onPageChanged: (i, _) => setState(() => _currentIndex = i),
            ),
            items: ad.images.map((img) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(img, fit: BoxFit.cover),
                  // dark gradient overlay (top+bottom)
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x99000000),
                          Color(0x00000000),
                          Color(0xAA000000),
                        ],
                        stops: [0.0, 0.55, 1.0],
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
        // floating top actions
        Positioned(
          top: 50,
          left: 12,
          right: 12,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _circleIconButton(
                Icons.arrow_back,
                onTap: () => Navigator.of(context).maybePop(),
              ),
              Row(
                children: [
                  _circleIconButton(Icons.edit, onTap: () {
                    _goToEdit(context, ad);
                  }),
                  const SizedBox(width: 8),
                  _circleIconButton(Icons.favorite_border, onTap: () {}),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _goToEdit(BuildContext context, AddModel ad) async {
    final route = _editRouteFor(ad.category);
    if (route == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Editing not available for this category')),
      );
      return;
    }

    // Navigate and wait for result (edit page should: Navigator.pop(true) on success)
    final changed = await context.push<bool>(route, extra: ad);

    if (!context.mounted) return;
    if (changed == true) {
      // re-fetch detail to reflect saved changes
      context.read<AdDetailBloc>().add(AdDetailEvent.fetch(ad.id));
    }
  }

  String? _editRouteFor(String category) {
    switch (category) {
      case 'two_wheeler':
        return '/edit-two-wheeler';
      case 'private_vehicle':
        return '/edit-private-vehicle';
      case 'commercial_vehicle':
        return '/edit-commercial-vehicle';
      case 'property':
        return '/edit-property';
      default:
        return null;
    }
  }

  // page indicators (small pills)
  Widget _dots(int count) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(count, (i) {
          final isActive = i == _currentIndex;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            height: 6,
            width: isActive ? 14 : 6,
            decoration: BoxDecoration(
              color: isActive ? Colors.indigo : Colors.grey.shade400,
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }),
      ),
    );
  }

  String _normalize(String s) => s
      .replaceAll(RegExp(r'[_\-]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  String toTitleCase(String? input) {
    if (input == null) return '';
    final s = _normalize(input.toLowerCase());
    if (s.isEmpty) return '';
    return s
        .split(' ')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  /// If you really want strict camelCase (no spaces), use this:
  String toCamelCase(String? input) {
    final t = toTitleCase(input).replaceAll(' ', '');
    if (t.isEmpty) return '';
    return '${t[0].toLowerCase()}${t.substring(1)}';
  }

  // ======= Title / Price / Meta =======
  Widget _titlePriceMeta(AddModel ad) {
    String title;
    if (ad.category == 'property') {
      title =
          '${ad.propertyType ?? ''} • ${ad.bedrooms ?? 0} BHK • ${ad.areaSqft ?? 0} sqft';
    } else {
      title =
          '${ad.manufacturer?.name ?? ''} ${ad.model?.name ?? ''} (${ad.year ?? ''})';
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
      child: Container(
        height: 50,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  // '${ad.manufacturer?.name} ${ad.model?.name ?? ''} (${ad.year ?? ''})',
                  toTitleCase(title),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  'Posted on ${_niceDate(ad.updatedAt)}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
            const VerticalDivider(
              thickness: 1,
              width: 32, // spacing around divider
              color: Colors.grey,
            ),
            Text(
              '₹ ${(ad.price)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ======= Tabs (Pill segmented) + content =======
  Widget _pillTabs(AddModel ad) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            Container(
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFFF2F3F6),
                borderRadius: BorderRadius.circular(28),
              ),
              padding: const EdgeInsets.all(4),
              child: TabBar(
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  // boxShadow: [
                  //   BoxShadow(
                  //     color: Colors.black.withOpacity(0.06),
                  //     blurRadius: 8,
                  //   )
                  // ],
                ),
                indicatorColor: Colors.transparent, // removes default underline
                dividerColor: Colors.transparent,
                labelColor: Colors.black,
                unselectedLabelColor: Colors.grey.shade600,
                tabs: const [
                  Tab(text: 'Specifications'),
                  Tab(text: 'Other Details'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: _contentHeightForSpecs(ad),
              child: TabBarView(
                children: [
                  _specsCard(ad),
                  _showroomCard(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _specsCard(AddModel ad) {
    if (ad.category == 'property') {
      // PROPERTY SPECS
      final items = <_Spec>[
        _Spec('Property Type', ad.propertyType ?? '-', icon: Icons.home_work),
        _Spec('Bedrooms', ad.bedrooms?.toString() ?? '-', icon: Icons.bed),
        _Spec('Bathrooms', ad.bathrooms?.toString() ?? '-',
            icon: Icons.bathtub),
        _Spec('Area (sqft)', ad.areaSqft?.toString() ?? '-',
            icon: Icons.square_foot),
        _Spec('Floor', ad.floor?.toString() ?? '-', icon: Icons.apartment),
        _Spec('Furnished', ad.isFurnished == true ? 'Yes' : 'No',
            icon: Icons.chair_alt),
        _Spec('Parking', ad.hasParking == true ? 'Yes' : 'No',
            icon: Icons.local_parking),
        _Spec('Garden', ad.hasGarden == true ? 'Yes' : 'No', icon: Icons.park),
      ];

      return _cardShell(
        child: GridView.builder(
          padding: const EdgeInsets.all(12),
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisExtent: 55,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: items.length,
          itemBuilder: (_, i) => _specTile(items[i]),
        ),
      );
    }

    // VEHICLE SPECS (default)
    final items = <_Spec>[
      _Spec('Brand Name', toTitleCase(ad.manufacturer?.name ?? '-'),
          icon: Icons.factory_outlined),
      _Spec('Model Name', toTitleCase(ad.model?.name ?? '-'),
          icon: Icons.directions_car),
      _Spec('Transmission', ad.transmission ?? '-', icon: Icons.settings),
      _Spec('Fuel Type', ad.fuelType ?? '-', icon: Icons.local_gas_station),
      _Spec('Registration Year', (ad.year ?? 0).toString(),
          icon: Icons.calendar_today),
      _Spec('Mileage', (ad.mileage != null) ? '${ad.mileage} Kmpl' : '-',
          icon: Icons.speed),
    ];

    return _cardShell(
      child: GridView.builder(
        padding: const EdgeInsets.all(12),
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisExtent: 64,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: items.length,
        itemBuilder: (_, i) => _specTile(items[i]),
      ),
    );
  }

  Widget _showroomCard() {
    // placeholder structure like the second tab
    return _cardShell(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            _KeyValRow(label: 'Dealer', value: 'Hyundai MotorHub'),
            SizedBox(height: 8),
            _KeyValRow(label: 'Address', value: 'Kakkanad, Ernakulam'),
            SizedBox(height: 8),
            _KeyValRow(label: 'Open Hours', value: 'Mon–Sat, 9:30 AM – 7 PM'),
            SizedBox(height: 8),
            _KeyValRow(label: 'Contact', value: '+91 98xx‑xxx‑xxx'),
          ],
        ),
      ),
    );
  }

  // ======= Description =======
  Widget _description(AddModel ad) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: _cardShell(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            ad.description,
            style: TextStyle(color: Colors.grey.shade800, height: 1.35),
          ),
        ),
      ),
    );
  }

  // ======= Seller Tile =======
  Widget _sellerTile(AddModel ad) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: _cardShell(
        child: ListTile(
          leading: const CircleAvatar(
            radius: 24,
            backgroundImage: AssetImage('assets/images/dealer.jpg'),
          ),
          title: const Text(
            'Hyundai MotorHub',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(ad.location),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {},
        ),
      ),
    );
  }

  // ======= Recommendations =======
  Widget _recommendationsSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Recommendations',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 12),
          SizedBox(
            height: 170,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(right: 16),
              itemCount: 4,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) => _recommendationCard(i),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _recommendationCard(int i) {
    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.network(
                    'https://picsum.photos/seed/rec$i/400/240',
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: _glassIcon(Icons.favorite_border),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('₹ 7,50,000  •  Ertiga LXi (2018)',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.w700)),
                SizedBox(height: 4),
                Text('12700 KM  /  Petrol',
                    style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ======= Small helpers =======
  Widget _circleIconButton(IconData icon, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 36,
        width: 36,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.35),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _glassIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 16),
    );
  }

  Widget _primaryBtn(String label, {required VoidCallback onTap}) {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        onPressed: onTap,
        child: Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.w700, color: AppColors.whiteColor)),
      ),
    );
  }

  Widget _secondaryBtn(String label, {required VoidCallback onTap}) {
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AppColors.primaryColor),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        onPressed: onTap,
        child: Text(label,
            style: TextStyle(
                color: AppColors.primaryColor, fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _cardShell({required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _specTile(_Spec spec) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          height: 36,
          width: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFF4F6FA),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(spec.icon, size: 18, color: const Color(0xFF475569)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(spec.label,
                  style:
                      const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
              const SizedBox(height: 2),
              Text(spec.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
        )
      ],
    );
  }

  double _contentHeightForSpecs(AddModel ad) {
    // enough room for grid + showroom; adjust if you add more rows
    return 260;
  }

  // String _vehicleTitle(AddModel ad) {
  //   // e.g. "Hyundai i20 (2020), Magna"
  //   final brand = ad.manufacturer ?? '';
  //   final model = ad.model ?? '';
  //   final variant = ad.variant != null ? ', ${ad.variant}' : '';
  //   final year = ad.year != null ? ' (${ad.year})' : '';
  //   return '${brand.isNotEmpty ? brand : ''} ${model.isNotEmpty ? model : ''}$year$variant'
  //       .trim();
  // }

  String _niceDate(String iso) {
    // expects your ad.updatedAt string; fallback
    try {
      final dt = DateTime.tryParse(iso) ?? DateTime.now();
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return iso;
    }
  }
}

class _Spec {
  final String label;
  final String value;
  final IconData icon;
  const _Spec(this.label, this.value, {required this.icon});
}

class _KeyValRow extends StatelessWidget {
  final String label;
  final String value;
  const _KeyValRow({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
            width: 110,
            child: Text(label,
                style:
                    const TextStyle(fontSize: 12, color: Color(0xFF6B7280)))),
        const SizedBox(width: 8),
        Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13))),
      ],
    );
  }
}
