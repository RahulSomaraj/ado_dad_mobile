import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:ado_dad_user/common/app_colors.dart';
import 'package:ado_dad_user/common/widgets/rich_ad_card.dart';
import 'package:ado_dad_user/common/widgets/skeleton.dart';
import 'package:ado_dad_user/common/app_textstyle.dart';
import 'package:ado_dad_user/common/get_responsive_size.dart';
import 'package:ado_dad_user/features/showroom/bloc/showroom_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
  String get _dealerInitials {
    final n = widget.userName?.trim() ?? '';
    if (n.isEmpty) return 'S';
    final parts = n.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

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
            initial: () => const SkeletonList(itemCount: 4),
            loading: () => const SkeletonList(itemCount: 4),
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
                          'This showroom doesn\'t have active listings yet.',
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
                  // Dealer header (wireframe: "Showroom — dealer's ads")
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      GetResponsiveSize.getResponsivePadding(context,
                          mobile: 16, tablet: 20, largeTablet: 24, desktop: 28),
                      GetResponsiveSize.getResponsivePadding(context,
                          mobile: 10, tablet: 12, largeTablet: 14, desktop: 16),
                      GetResponsiveSize.getResponsivePadding(context,
                          mobile: 16, tablet: 20, largeTablet: 24, desktop: 28),
                      0,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: GetResponsiveSize.getResponsiveSize(context,
                              mobile: 48,
                              tablet: 58,
                              largeTablet: 68,
                              desktop: 78),
                          height: GetResponsiveSize.getResponsiveSize(context,
                              mobile: 48,
                              tablet: 58,
                              largeTablet: 68,
                              desktop: 78),
                          decoration: BoxDecoration(
                            color:
                                AppColors.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _dealerInitials,
                            style: TextStyle(
                              color: AppColors.primaryColor,
                              fontWeight: FontWeight.w700,
                              fontSize: GetResponsiveSize.getResponsiveFontSize(
                                  context,
                                  mobile: 17,
                                  tablet: 21,
                                  largeTablet: 25,
                                  desktop: 29),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.userName ?? 'Showroom',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize:
                                      GetResponsiveSize.getResponsiveFontSize(
                                          context,
                                          mobile: 15,
                                          tablet: 19,
                                          largeTablet: 23,
                                          desktop: 27),
                                ),
                              ),
                              Text(
                                '${ads.length} listing${ads.length == 1 ? '' : 's'}${hasMore ? '+' : ''}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.greyColor,
                                  fontSize:
                                      GetResponsiveSize.getResponsiveFontSize(
                                          context,
                                          mobile: 11.5,
                                          tablet: 14,
                                          largeTablet: 16,
                                          desktop: 18),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      GetResponsiveSize.getResponsivePadding(context,
                          mobile: 16, tablet: 20, largeTablet: 24, desktop: 28),
                      GetResponsiveSize.getResponsivePadding(context,
                          mobile: 14, tablet: 18, largeTablet: 22, desktop: 26),
                      GetResponsiveSize.getResponsivePadding(context,
                          mobile: 16, tablet: 20, largeTablet: 24, desktop: 28),
                      0,
                    ),
                    child: Text(
                      'Showroom products (${ads.length})',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: GetResponsiveSize.getResponsiveFontSize(
                            context,
                            mobile: 15,
                            tablet: 20,
                            largeTablet: 24,
                            desktop: 28),
                      ),
                    ),
                  ),
                  // Product list
                  Expanded(
                    child: GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 15,
                        mainAxisSpacing: 15,
                        mainAxisExtent:
                            richAdCardMainAxisExtent(context, columns: 2),
                      ),
                      padding: const EdgeInsets.fromLTRB(15, 10, 15, 100),
                      itemCount: ads.length,
                      itemBuilder: (context, index) =>
                          RichAdCard(ad: ads[index]),
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
                            backgroundColor: AppColors.primaryColor,
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
                            'Load more products',
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
