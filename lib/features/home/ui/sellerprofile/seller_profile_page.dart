import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ado_dad_user/models/advertisement_model/add_model.dart';
import 'package:ado_dad_user/features/home/ui/sellerprofile/bloc/bloc/seller_profile_bloc.dart';
import 'package:ado_dad_user/common/get_responsive_size.dart';

class SellerProfilePage extends StatefulWidget {
  final AdUser seller;

  const SellerProfilePage({super.key, required this.seller});

  @override
  State<SellerProfilePage> createState() => _SellerProfilePageState();
}

class _SellerProfilePageState extends State<SellerProfilePage> {
  @override
  void initState() {
    super.initState();
    // Always fetch fresh data when the page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SellerProfileBloc>().add(
            SellerProfileEvent.fetchUserAds(widget.seller.id),
          );
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh data when returning to this page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SellerProfileBloc>().add(
            SellerProfileEvent.fetchUserAds(widget.seller.id),
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF1EEFF), // Soft lavender background
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.maybePop(context),
                      icon: Icon(
                        (!kIsWeb && Platform.isIOS)
                            ? Icons.arrow_back_ios
                            : Icons.arrow_back,
                        size: GetResponsiveSize.getResponsiveSize(context,
                            mobile: 20,
                            tablet: 26,
                            largeTablet: 30,
                            desktop: 34),
                      ),
                    ),
                  ],
                ),
              ),

              // Seller section
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(
                  GetResponsiveSize.getResponsivePadding(context,
                      mobile: 16, tablet: 20, largeTablet: 24, desktop: 28),
                  GetResponsiveSize.getResponsivePadding(context,
                      mobile: 8, tablet: 10, largeTablet: 12, desktop: 14),
                  GetResponsiveSize.getResponsivePadding(context,
                      mobile: 16, tablet: 20, largeTablet: 24, desktop: 28),
                  GetResponsiveSize.getResponsivePadding(context,
                      mobile: 20, tablet: 24, largeTablet: 28, desktop: 32),
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1EEFF), // soft lavender bg
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(
                      GetResponsiveSize.getResponsiveBorderRadius(context,
                          mobile: 24, tablet: 28, largeTablet: 32, desktop: 36),
                    ),
                    bottomRight: Radius.circular(
                      GetResponsiveSize.getResponsiveBorderRadius(context,
                          mobile: 24, tablet: 28, largeTablet: 32, desktop: 36),
                    ),
                  ),
                ),
                child: _SellerCard(seller: widget.seller),
              ),

              const SizedBox(height: 5),

              // BlocBuilder for ads list
              BlocBuilder<SellerProfileBloc, SellerProfileState>(
                builder: (context, state) {
                  return state.when(
                    initial: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    loaded: (ads, hasNext, page, isPaging) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: GetResponsiveSize.getResponsivePadding(
                                context,
                                mobile: 16,
                                tablet: 20,
                                largeTablet: 24,
                                desktop: 28),
                          ),
                          child: Text(
                            'Seller Products (${ads.length})',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: GetResponsiveSize.getResponsiveFontSize(
                                  context,
                                  mobile:
                                      theme.textTheme.titleMedium?.fontSize ??
                                          16.0,
                                  tablet: 22,
                                  largeTablet: 26,
                                  desktop: 30),
                            ),
                          ),
                        ),
                        SizedBox(
                            height: GetResponsiveSize.getResponsiveSize(context,
                                mobile: 10,
                                tablet: 14,
                                largeTablet: 18,
                                desktop: 22)),
                        // Product list
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: EdgeInsets.symmetric(
                            horizontal: GetResponsiveSize.getResponsivePadding(
                                context,
                                mobile: 16,
                                tablet: 20,
                                largeTablet: 24,
                                desktop: 28),
                          ),
                          itemCount: ads.length,
                          separatorBuilder: (_, __) => SizedBox(
                              height: GetResponsiveSize.getResponsiveSize(
                                  context,
                                  mobile: 12,
                                  tablet: 16,
                                  largeTablet: 20,
                                  desktop: 24)),
                          itemBuilder: (context, index) => _ProductTile(
                            ad: ads[index],
                            onTap: ads[index].soldOut == true
                                ? null // Don't navigate if sold out
                                : () {
                                    context.push('/add-detail-page',
                                        extra: ads[index]);
                                  },
                          ),
                        ),
                        // Load more button
                        if (hasNext) ...[
                          SizedBox(
                              height: GetResponsiveSize.getResponsiveSize(
                                  context,
                                  mobile: 16,
                                  tablet: 20,
                                  largeTablet: 24,
                                  desktop: 28)),
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal:
                                  GetResponsiveSize.getResponsivePadding(
                                      context,
                                      mobile: 16,
                                      tablet: 20,
                                      largeTablet: 24,
                                      desktop: 28),
                            ),
                            child: SizedBox(
                              width: double.infinity,
                              height: GetResponsiveSize.getResponsiveSize(
                                  context,
                                  mobile: 48,
                                  tablet: 65,
                                  largeTablet: 75,
                                  desktop: 85),
                              child: ElevatedButton(
                                onPressed: isPaging
                                    ? null
                                    : () {
                                        context.read<SellerProfileBloc>().add(
                                              SellerProfileEvent.loadMore(
                                                  widget.seller.id),
                                            );
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF6366F1),
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(
                                    horizontal:
                                        GetResponsiveSize.getResponsivePadding(
                                            context,
                                            mobile: 16,
                                            tablet: 20,
                                            largeTablet: 24,
                                            desktop: 28),
                                    vertical:
                                        GetResponsiveSize.getResponsivePadding(
                                            context,
                                            mobile: 12,
                                            tablet: 16,
                                            largeTablet: 20,
                                            desktop: 24),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      GetResponsiveSize
                                          .getResponsiveBorderRadius(context,
                                              mobile: 12,
                                              tablet: 14,
                                              largeTablet: 16,
                                              desktop: 18),
                                    ),
                                  ),
                                ),
                                child: isPaging
                                    ? SizedBox(
                                        height:
                                            GetResponsiveSize.getResponsiveSize(
                                                context,
                                                mobile: 20,
                                                tablet: 26,
                                                largeTablet: 30,
                                                desktop: 34),
                                        width:
                                            GetResponsiveSize.getResponsiveSize(
                                                context,
                                                mobile: 20,
                                                tablet: 26,
                                                largeTablet: 30,
                                                desktop: 34),
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white),
                                        ),
                                      )
                                    : Text(
                                        'Load More Products',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: GetResponsiveSize
                                              .getResponsiveFontSize(context,
                                                  mobile: 14,
                                                  tablet: 18,
                                                  largeTablet: 22,
                                                  desktop: 26),
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    error: (message) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            const Icon(Icons.error_outline,
                                size: 48, color: Colors.red),
                            const SizedBox(height: 16),
                            Text(
                              'Error loading ads',
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              message,
                              style: theme.textTheme.bodySmall,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                context.read<SellerProfileBloc>().add(
                                      SellerProfileEvent.fetchUserAds(
                                          widget.seller.id),
                                    );
                              },
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SellerCard extends StatelessWidget {
  const _SellerCard({required this.seller});
  final AdUser seller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          GetResponsiveSize.getResponsiveBorderRadius(context,
              mobile: 20, tablet: 24, largeTablet: 28, desktop: 32),
        ),
      ),
      padding: EdgeInsets.all(
        GetResponsiveSize.getResponsivePadding(context,
            mobile: 14, tablet: 18, largeTablet: 22, desktop: 26),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: GetResponsiveSize.getResponsiveSize(context,
                mobile: 32, tablet: 42, largeTablet: 52, desktop: 62),
            backgroundImage: seller.profilePic?.trim().isNotEmpty == true
                ? NetworkImage(seller.profilePic!)
                : null,
          ),
          SizedBox(
              width: GetResponsiveSize.getResponsiveSize(context,
                  mobile: 12, tablet: 16, largeTablet: 20, desktop: 24)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  seller.name?.trim().isNotEmpty == true
                      ? seller.name!
                      : 'Seller',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: GetResponsiveSize.getResponsiveFontSize(context,
                        mobile: theme.textTheme.titleMedium?.fontSize ?? 16.0,
                        tablet: 22,
                        largeTablet: 26,
                        desktop: 30),
                  ),
                ),
                SizedBox(
                    height: GetResponsiveSize.getResponsiveSize(context,
                        mobile: 4, tablet: 6, largeTablet: 8, desktop: 10)),
                if (seller.email?.trim().isNotEmpty == true) ...[
                  Text(
                    seller.email!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF111827),
                      fontSize: GetResponsiveSize.getResponsiveFontSize(context,
                          mobile: theme.textTheme.bodyMedium?.fontSize ?? 14.0,
                          tablet: 18,
                          largeTablet: 22,
                          desktop: 26),
                    ),
                  ),
                  SizedBox(
                      height: GetResponsiveSize.getResponsiveSize(context,
                          mobile: 2, tablet: 3, largeTablet: 4, desktop: 5)),
                ],
                if (seller.phone?.trim().isNotEmpty == true) ...[
                  Text(
                    seller.phone!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF111827),
                      fontSize: GetResponsiveSize.getResponsiveFontSize(context,
                          mobile: theme.textTheme.bodyMedium?.fontSize ?? 14.0,
                          tablet: 18,
                          largeTablet: 22,
                          desktop: 26),
                    ),
                  ),
                  SizedBox(
                      height: GetResponsiveSize.getResponsiveSize(context,
                          mobile: 2, tablet: 3, largeTablet: 4, desktop: 5)),
                ],
                SizedBox(
                    height: GetResponsiveSize.getResponsiveSize(context,
                        mobile: 12, tablet: 16, largeTablet: 20, desktop: 24)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({required this.ad, this.onTap});
  final AddModel ad;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Generate title - for vehicles: "ManufacturerName ModelName (Year)"
    String title;
    if (ad.category == 'property') {
      title =
          '${_toTitleCase(ad.propertyType)} • ${ad.bedrooms ?? 0} BHK • ${ad.areaSqft ?? 0} sqft';
    } else {
      // Vehicle format: ManufacturerName ModelName (Year)
      final manufacturerName = ad.manufacturer?.displayName ??
          ad.manufacturer?.name ??
          'Unknown Brand';
      final modelName =
          ad.model?.displayName ?? ad.model?.name ?? 'Unknown Model';
      final year = ad.year ?? '';

      // Clean up the title - remove extra spaces and handle empty values
      final cleanManufacturer = manufacturerName.trim();
      final cleanModel = modelName.trim();
      final cleanYear = year.toString().trim();

      if (cleanManufacturer.isNotEmpty && cleanModel.isNotEmpty) {
        title = cleanYear.isNotEmpty
            ? '$cleanManufacturer $cleanModel ($cleanYear)'
            : '$cleanManufacturer $cleanModel';
      } else if (cleanManufacturer.isNotEmpty) {
        title = cleanYear.isNotEmpty
            ? '$cleanManufacturer ($cleanYear)'
            : cleanManufacturer;
      } else if (cleanModel.isNotEmpty) {
        title = cleanYear.isNotEmpty ? '$cleanModel ($cleanYear)' : cleanModel;
      } else {
        title = cleanYear.isNotEmpty ? 'Vehicle ($cleanYear)' : 'Vehicle';
      }
    }

    // Generate subtitle with fuel/mileage info
    String subtitle = '';
    if (ad.category != 'property') {
      if (ad.mileage != null && ad.fuelType != null) {
        subtitle = '${ad.mileage} KM / ${ad.fuelType}';
      } else if (ad.fuelType != null) {
        subtitle = ad.fuelType!;
      }
    }

    return Material(
      color: Colors.white, // White tiles on lavender background
      borderRadius: BorderRadius.circular(
        GetResponsiveSize.getResponsiveBorderRadius(context,
            mobile: 20, tablet: 24, largeTablet: 28, desktop: 32),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(
          GetResponsiveSize.getResponsiveBorderRadius(context,
              mobile: 20, tablet: 24, largeTablet: 28, desktop: 32),
        ),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(
            GetResponsiveSize.getResponsivePadding(context,
                mobile: 10, tablet: 14, largeTablet: 18, desktop: 22),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(
                  GetResponsiveSize.getResponsiveBorderRadius(context,
                      mobile: 14, tablet: 16, largeTablet: 18, desktop: 20),
                ),
                child: ad.images.isNotEmpty
                    ? Image.network(
                        ad.images.first,
                        width: GetResponsiveSize.getResponsiveSize(context,
                            mobile: 80,
                            tablet: 110,
                            largeTablet: 140,
                            desktop: 170),
                        height: GetResponsiveSize.getResponsiveSize(context,
                            mobile: 80,
                            tablet: 110,
                            largeTablet: 140,
                            desktop: 170),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: GetResponsiveSize.getResponsiveSize(context,
                                mobile: 80,
                                tablet: 110,
                                largeTablet: 140,
                                desktop: 170),
                            height: GetResponsiveSize.getResponsiveSize(context,
                                mobile: 80,
                                tablet: 110,
                                largeTablet: 140,
                                desktop: 170),
                            color: Colors.grey.shade200,
                            child: Icon(
                              Icons.image_not_supported,
                              size: GetResponsiveSize.getResponsiveSize(context,
                                  mobile: 24,
                                  tablet: 32,
                                  largeTablet: 40,
                                  desktop: 48),
                            ),
                          );
                        },
                      )
                    : Container(
                        width: GetResponsiveSize.getResponsiveSize(context,
                            mobile: 80,
                            tablet: 110,
                            largeTablet: 140,
                            desktop: 170),
                        height: GetResponsiveSize.getResponsiveSize(context,
                            mobile: 80,
                            tablet: 110,
                            largeTablet: 140,
                            desktop: 170),
                        color: Colors.grey.shade200,
                        child: Icon(
                          Icons.image_not_supported,
                          size: GetResponsiveSize.getResponsiveSize(context,
                              mobile: 24,
                              tablet: 32,
                              largeTablet: 40,
                              desktop: 48),
                        ),
                      ),
              ),
              SizedBox(
                  width: GetResponsiveSize.getResponsiveSize(context,
                      mobile: 12, tablet: 16, largeTablet: 20, desktop: 24)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '₹ ${_formatINR(ad.price)}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: GetResponsiveSize.getResponsiveFontSize(
                            context,
                            mobile:
                                theme.textTheme.titleMedium?.fontSize ?? 16.0,
                            tablet: 22,
                            largeTablet: 26,
                            desktop: 30),
                      ),
                    ),
                    SizedBox(
                        height: GetResponsiveSize.getResponsiveSize(context,
                            mobile: 2, tablet: 4, largeTablet: 6, desktop: 8)),
                    Text(
                      title.trim().isNotEmpty ? title : 'Ad',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: GetResponsiveSize.getResponsiveFontSize(
                            context,
                            mobile: theme.textTheme.bodyLarge?.fontSize ?? 16.0,
                            tablet: 20,
                            largeTablet: 24,
                            desktop: 28),
                      ),
                    ),
                    SizedBox(
                        height: GetResponsiveSize.getResponsiveSize(context,
                            mobile: 2, tablet: 4, largeTablet: 6, desktop: 8)),
                    Text(
                      ad.location,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF6B7280),
                        fontWeight: FontWeight.w600,
                        fontSize: GetResponsiveSize.getResponsiveFontSize(
                            context,
                            mobile: theme.textTheme.bodySmall?.fontSize ?? 12.0,
                            tablet: 16,
                            largeTablet: 20,
                            desktop: 24),
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      SizedBox(
                          height: GetResponsiveSize.getResponsiveSize(context,
                              mobile: 2,
                              tablet: 4,
                              largeTablet: 6,
                              desktop: 8)),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF6B7280),
                          fontWeight: FontWeight.w600,
                          fontSize: GetResponsiveSize.getResponsiveFontSize(
                              context,
                              mobile:
                                  theme.textTheme.bodySmall?.fontSize ?? 12.0,
                              tablet: 16,
                              largeTablet: 20,
                              desktop: 24),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: const Color(0xFF9CA3AF),
                size: GetResponsiveSize.getResponsiveSize(context,
                    mobile: 24, tablet: 28, largeTablet: 32, desktop: 36),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatINR(int amount) {
  // simple Indian grouping (##,##,###)
  final s = amount.toString();
  if (s.length <= 3) return s;
  final last3 = s.substring(s.length - 3);
  String rest = s.substring(0, s.length - 3);
  final buf = StringBuffer();
  while (rest.length > 2) {
    buf.write(',${rest.substring(rest.length - 2)}');
    rest = rest.substring(0, rest.length - 2);
  }
  return '$rest${buf.toString()},$last3';
}

String _toTitleCase(String? input) {
  if (input == null) return '';
  final s = input.toLowerCase().trim();
  if (s.isEmpty) return '';
  return s
      .split(' ')
      .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}
