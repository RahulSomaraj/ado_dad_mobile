import 'package:ado_dad_user/common/app_colors.dart';
import 'package:ado_dad_user/common/app_textstyle.dart';
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
        title:
            Text(widget.userName ?? 'Showroom', style: AppTextstyle.appbarText),
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
                  SizedBox(height: 20),
                  // Product list
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: ads.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
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
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            context.read<ShowroomBloc>().add(
                                  const ShowroomEvent.fetchNextPage(),
                                );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6366F1),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Load More Products',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
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
      borderRadius: BorderRadius.circular(20),
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: ad.images.isNotEmpty
                    ? Image.network(
                        ad.images.first,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 80,
                            height: 80,
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.image_not_supported),
                          );
                        },
                      )
                    : Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.image_not_supported),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Showroom label for SR users
                    Image.asset(
                      'assets/images/showroom_label.png',
                      height: 16,
                      width: 80,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹ ${_formatINR(ad.price)}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title.trim().isNotEmpty ? title : 'Ad',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      ad.location,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF6B7280),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF6B7280),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF)),
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
