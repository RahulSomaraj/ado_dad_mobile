import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:ado_dad_user/common/app_colors.dart';
import 'package:ado_dad_user/common/app_textstyle.dart';
import 'package:ado_dad_user/common/get_responsive_size.dart';
import 'package:ado_dad_user/features/showroom/bloc/showroom_bloc.dart';
import 'package:ado_dad_user/models/advertisement_model/add_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class ShowroomUserAdsPage extends StatefulWidget {
  final String userId;
  final String? userName;

  const ShowroomUserAdsPage({
    super.key,
    required this.userId,
    this.userName,
  });

  @override
  State<ShowroomUserAdsPage> createState() => _ShowroomUserAdsPageState();
}

class _ShowroomUserAdsPageState extends State<ShowroomUserAdsPage> {
  @override
  void initState() {
    super.initState();
    // Always fetch fresh data when the page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShowroomBloc>().add(
            ShowroomEvent.fetchShowroomUserAds(userId: widget.userId),
          );
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh data when returning to this page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShowroomBloc>().add(
            ShowroomEvent.fetchShowroomUserAds(userId: widget.userId),
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
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
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.userName ?? 'Showroom',
          style: AppTextstyle.appbarText.copyWith(
            fontSize: GetResponsiveSize.getResponsiveFontSize(
              context,
              mobile: AppTextstyle.appbarText.fontSize ?? 20,
              tablet: 24,
              largeTablet: 28,
              desktop: 32,
            ),
          ),
        ),
        backgroundColor: AppColors.whiteColor,
        elevation: 0,
      ),
      body: BlocBuilder<ShowroomBloc, ShowroomState>(
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
            adsLoaded: (ads, hasMore, userId) {
              // Check if showroom user has no ads
              if (ads.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.store_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No Products Available',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'This showroom doesn\'t have any products listed yet.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[500],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Padding(
                  //   padding:
                  //       const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  //   child: Text(
                  //     'Showroom Products (${ads.length})',
                  //     style: theme.textTheme.titleMedium?.copyWith(
                  //       fontWeight: FontWeight.w700,
                  //     ),
                  //   ),
                  // ),
                  SizedBox(
                      height: GetResponsiveSize.getResponsiveSize(context,
                          mobile: 20,
                          tablet: 28,
                          largeTablet: 36,
                          desktop: 44)),
                  // Product list
                  Expanded(
                    child: ListView.separated(
                      padding: EdgeInsets.symmetric(
                        horizontal: GetResponsiveSize.getResponsivePadding(
                            context,
                            mobile: 16,
                            tablet: 24,
                            largeTablet: 32,
                            desktop: 40),
                      ),
                      itemCount: ads.length,
                      separatorBuilder: (_, __) => SizedBox(
                          height: GetResponsiveSize.getResponsiveSize(context,
                              mobile: 12,
                              tablet: 18,
                              largeTablet: 24,
                              desktop: 30)),
                      itemBuilder: (context, index) => _ProductTile(
                        ad: ads[index],
                        onTap: () {
                          context.push('/add-detail-page', extra: ads[index]);
                        },
                      ),
                    ),
                  ),
                  // Load more button
                  if (hasMore) ...[
                    SizedBox(
                        height: GetResponsiveSize.getResponsiveSize(context,
                            mobile: 16,
                            tablet: 20,
                            largeTablet: 24,
                            desktop: 28)),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: GetResponsiveSize.getResponsivePadding(
                            context,
                            mobile: 16,
                            tablet: 24,
                            largeTablet: 32,
                            desktop: 40),
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        height: GetResponsiveSize.getResponsiveSize(context,
                            mobile: 48,
                            tablet: 65,
                            largeTablet: 75,
                            desktop: 85),
                        child: ElevatedButton(
                          onPressed: () {
                            context.read<ShowroomBloc>().add(
                                  const ShowroomEvent.fetchNextPage(),
                                );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6366F1),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              vertical: GetResponsiveSize.getResponsivePadding(
                                  context,
                                  mobile: 12,
                                  tablet: 16,
                                  largeTablet: 20,
                                  desktop: 24),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                GetResponsiveSize.getResponsiveBorderRadius(
                                    context,
                                    mobile: 12,
                                    tablet: 14,
                                    largeTablet: 16,
                                    desktop: 18),
                              ),
                            ),
                          ),
                          child: Text(
                            'Load More Products',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: GetResponsiveSize.getResponsiveFontSize(
                                context,
                                mobile: 16,
                                tablet: 20,
                                largeTablet: 24,
                                desktop: 28,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                        height: GetResponsiveSize.getResponsiveSize(context,
                            mobile: 16,
                            tablet: 20,
                            largeTablet: 24,
                            desktop: 28)),
                  ],
                ],
              );
            },
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
                        context.read<ShowroomBloc>().add(
                              ShowroomEvent.fetchShowroomUserAds(
                                  userId: widget.userId),
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
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      child: InkWell(
        borderRadius: BorderRadius.circular(
          GetResponsiveSize.getResponsiveBorderRadius(context,
              mobile: 20, tablet: 24, largeTablet: 28, desktop: 32),
        ),
        onTap: onTap,
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.all(
                GetResponsiveSize.getResponsivePadding(context,
                    mobile: 10, tablet: 16, largeTablet: 22, desktop: 28),
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
                                tablet: 140,
                                largeTablet: 180,
                                desktop: 220),
                            height: GetResponsiveSize.getResponsiveSize(context,
                                mobile: 80,
                                tablet: 140,
                                largeTablet: 180,
                                desktop: 220),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: GetResponsiveSize.getResponsiveSize(
                                    context,
                                    mobile: 80,
                                    tablet: 140,
                                    largeTablet: 180,
                                    desktop: 220),
                                height: GetResponsiveSize.getResponsiveSize(
                                    context,
                                    mobile: 80,
                                    tablet: 140,
                                    largeTablet: 180,
                                    desktop: 220),
                                color: Colors.grey.shade200,
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
                            width: GetResponsiveSize.getResponsiveSize(context,
                                mobile: 80,
                                tablet: 140,
                                largeTablet: 180,
                                desktop: 220),
                            height: GetResponsiveSize.getResponsiveSize(context,
                                mobile: 80,
                                tablet: 140,
                                largeTablet: 180,
                                desktop: 220),
                            color: Colors.grey.shade200,
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
                          mobile: 12,
                          tablet: 20,
                          largeTablet: 26,
                          desktop: 32)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Showroom label for SR users
                        Image.asset(
                          'assets/images/showroom copy 2.png',
                          height: GetResponsiveSize.getResponsiveSize(context,
                              mobile: 16,
                              tablet: 24,
                              largeTablet: 30,
                              desktop: 36),
                          width: GetResponsiveSize.getResponsiveSize(context,
                              mobile: 80,
                              tablet: 140,
                              largeTablet: 180,
                              desktop: 220),
                          fit: BoxFit.contain,
                        ),
                        SizedBox(
                            height: GetResponsiveSize.getResponsiveSize(context,
                                mobile: 4,
                                tablet: 8,
                                largeTablet: 12,
                                desktop: 16)),
                        Text(
                          '₹ ${_formatINR(ad.price)}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: GetResponsiveSize.getResponsiveFontSize(
                              context,
                              mobile:
                                  theme.textTheme.titleMedium?.fontSize ?? 16,
                              tablet: 22,
                              largeTablet: 28,
                              desktop: 34,
                            ),
                          ),
                        ),
                        SizedBox(
                            height: GetResponsiveSize.getResponsiveSize(context,
                                mobile: 2,
                                tablet: 6,
                                largeTablet: 10,
                                desktop: 14)),
                        Text(
                          title.trim().isNotEmpty ? title : 'Ad',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: GetResponsiveSize.getResponsiveFontSize(
                              context,
                              mobile: theme.textTheme.bodyLarge?.fontSize ?? 16,
                              tablet: 22,
                              largeTablet: 28,
                              desktop: 34,
                            ),
                          ),
                        ),
                        SizedBox(
                            height: GetResponsiveSize.getResponsiveSize(context,
                                mobile: 2,
                                tablet: 6,
                                largeTablet: 10,
                                desktop: 14)),
                        Text(
                          ad.location,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF6B7280),
                            fontWeight: FontWeight.w600,
                            fontSize: GetResponsiveSize.getResponsiveFontSize(
                              context,
                              mobile: theme.textTheme.bodySmall?.fontSize ?? 14,
                              tablet: 18,
                              largeTablet: 22,
                              desktop: 26,
                            ),
                          ),
                        ),
                        if (subtitle.isNotEmpty) ...[
                          SizedBox(
                              height: GetResponsiveSize.getResponsiveSize(
                                  context,
                                  mobile: 2,
                                  tablet: 6,
                                  largeTablet: 10,
                                  desktop: 14)),
                          Text(
                            subtitle,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF6B7280),
                              fontWeight: FontWeight.w600,
                              fontSize: GetResponsiveSize.getResponsiveFontSize(
                                context,
                                mobile:
                                    theme.textTheme.bodySmall?.fontSize ?? 14,
                                tablet: 18,
                                largeTablet: 22,
                                desktop: 26,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: const Color(0xFF9CA3AF),
                    size: GetResponsiveSize.getResponsiveSize(
                      context,
                      mobile: 24,
                      tablet: 30,
                      largeTablet: 36,
                      desktop: 42,
                    ),
                  ),
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
