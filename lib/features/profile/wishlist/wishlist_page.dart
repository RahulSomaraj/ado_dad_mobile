import 'package:ado_dad_user/common/app_colors.dart';
import 'package:ado_dad_user/common/app_textstyle.dart';
import 'package:ado_dad_user/common/get_responsive_size.dart';
import 'package:ado_dad_user/features/home/favorite/bloc/favorite_bloc.dart';
import 'package:ado_dad_user/models/advertisement_model/add_model.dart';
import 'package:ado_dad_user/repositories/favorite_repo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class WishlistPage extends StatefulWidget {
  const WishlistPage({super.key});

  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  @override
  void initState() {
    super.initState();
    // Load favorites when the page initializes
    context.read<FavoriteBloc>().add(const FavoriteEvent.loadFavorites());
  }

  // Convert FavoriteAd to AddModel for navigation
  AddModel _convertFavoriteAdToAddModel(FavoriteAd favorite) {
    return AddModel(
      id: favorite.id,
      description: favorite.description,
      price: favorite.price,
      images: favorite.images,
      location: favorite.location,
      category: favorite.category,
      isActive: favorite.isActive,
      updatedAt: favorite.updatedAt,
      user: AdUser(
        id: favorite.user.id,
        name: favorite.user.name,
        email: favorite.user.email,
        phone: favorite.user.phone,
      ),
      // Vehicle details if available
      vehicleType: favorite.vehicleDetails?.vehicleType,
      year: favorite.vehicleDetails?.year,
      mileage: favorite.vehicleDetails?.mileage,
      color: favorite.vehicleDetails?.color,
      isFirstOwner: favorite.vehicleDetails?.isFirstOwner,
      hasInsurance: favorite.vehicleDetails?.hasInsurance,
      hasRcBook: favorite.vehicleDetails?.hasRcBook,
      additionalFeatures: favorite.vehicleDetails?.additionalFeatures,
      transmissionId: favorite.vehicleDetails?.transmissionTypeId,
      fuelTypeId: favorite.vehicleDetails?.fuelTypeId,
      // Favorite fields
      isFavorited: true, // Since it's from favorites
      favoriteId: favorite.favoriteId,
      favoritedAt: favorite.favoritedAt,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<FavoriteBloc, FavoriteState>(
      listener: (context, state) {
        if (state is FavoriteToggleSuccess) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              duration: const Duration(seconds: 2),
            ),
          );

          // Refresh the favorites list to show updated data
          context
              .read<FavoriteBloc>()
              .add(const FavoriteEvent.refreshFavorites());
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
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: AppColors.primaryColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: Colors.white,
              size: GetResponsiveSize.getResponsiveSize(
                context,
                mobile: 24,
                tablet: 30,
                largeTablet: 32,
                desktop: 36,
              ),
            ),
            onPressed: () => context.pop(),
          ),
          title: Text(
            'My Wishlist',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: GetResponsiveSize.getResponsiveFontSize(
                context,
                mobile: 20,
                tablet: 24,
                largeTablet: 28,
                desktop: 32,
              ),
            ),
          ),
        ),
        body: BlocBuilder<FavoriteBloc, FavoriteState>(
          builder: (context, state) {
            if (state is FavoriteLoading || state is FavoriteToggleLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                ),
              );
            } else if (state is FavoriteError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icon(
                    //   Icons.favorite_border,
                    //   size: 64,
                    //   color: Colors.grey[400],
                    // ),
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
                      'Failed to load wishlist',
                      style: TextStyle(
                        fontSize: GetResponsiveSize.getResponsiveFontSize(
                          context,
                          mobile: 18,
                          tablet: 22,
                          largeTablet: 26,
                          desktop: 30,
                        ),
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
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
                      state.message,
                      style: TextStyle(
                        fontSize: GetResponsiveSize.getResponsiveFontSize(
                          context,
                          mobile: 14,
                          tablet: 18,
                          largeTablet: 20,
                          desktop: 24,
                        ),
                        color: Colors.grey[500],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(
                      height: GetResponsiveSize.getResponsiveSize(
                        context,
                        mobile: 24,
                        tablet: 32,
                        largeTablet: 40,
                        desktop: 48,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        context
                            .read<FavoriteBloc>()
                            .add(const FavoriteEvent.refreshFavorites());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        foregroundColor: Colors.white,
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
              );
            } else if (state is FavoriteLoaded) {
              if (state.favorites.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Icon(
                      //   Icons.favorite_border,
                      //   size: 64,
                      //   color: Colors.grey[400],
                      // ),
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
                        'Your wishlist is empty',
                        style: TextStyle(
                          fontSize: GetResponsiveSize.getResponsiveFontSize(
                            context,
                            mobile: 18,
                            tablet: 22,
                            largeTablet: 26,
                            desktop: 30,
                          ),
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  context
                      .read<FavoriteBloc>()
                      .add(const FavoriteEvent.refreshFavorites());
                },
                child: ListView.builder(
                  padding: EdgeInsets.all(
                    GetResponsiveSize.getResponsivePadding(
                      context,
                      mobile: 16,
                      tablet: 24,
                      largeTablet: 32,
                      desktop: 40,
                    ),
                  ),
                  itemCount: state.favorites.length,
                  itemBuilder: (context, index) {
                    final favorite = state.favorites[index];
                    return buildFavoriteCard(favorite);
                  },
                ),
              );
            } else if (state is FavoriteToggleSuccess) {
              // Show loading while refreshing after toggle success
              return const Center(
                child: CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                ),
              );
            }

            return const Center(
              child: Text('No data available'),
            );
          },
        ),
      ),
    );
  }

  Widget buildFavoriteCard(favorite) {
    final addModel = _convertFavoriteAdToAddModel(favorite);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: GetResponsiveSize.getResponsivePadding(context,
            mobile: 10, tablet: 14, largeTablet: 18, desktop: 22),
        vertical: GetResponsiveSize.getResponsivePadding(context,
            mobile: 5, tablet: 8, largeTablet: 12, desktop: 16),
      ),
      child: GestureDetector(
        onTap: () {
          context.push('/add-detail-page', extra: addModel);
        },
        child: Card(
          color: AppColors.whiteColor,
          elevation: 5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              GetResponsiveSize.getResponsiveBorderRadius(
                context,
                mobile: 15,
                tablet: 18,
                largeTablet: 22,
                desktop: 26,
              ),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(
              GetResponsiveSize.getResponsivePadding(context,
                  mobile: 12, tablet: 16, largeTablet: 20, desktop: 24),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(
                    GetResponsiveSize.getResponsiveBorderRadius(
                      context,
                      mobile: 12,
                      tablet: 14,
                      largeTablet: 16,
                      desktop: 18,
                    ),
                  ),
                  child: favorite.images.isNotEmpty
                      ? Image.network(
                          favorite.images[0],
                          height: GetResponsiveSize.getResponsiveSize(
                            context,
                            mobile: 98,
                            tablet: 140,
                            largeTablet: 180,
                            desktop: 220,
                          ),
                          width: GetResponsiveSize.getResponsiveSize(
                            context,
                            mobile: 98,
                            tablet: 140,
                            largeTablet: 180,
                            desktop: 220,
                          ),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: GetResponsiveSize.getResponsiveSize(
                                context,
                                mobile: 98,
                                tablet: 140,
                                largeTablet: 180,
                                desktop: 220,
                              ),
                              width: GetResponsiveSize.getResponsiveSize(
                                context,
                                mobile: 98,
                                tablet: 140,
                                largeTablet: 180,
                                desktop: 220,
                              ),
                              color: Colors.grey[300],
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
                          height: GetResponsiveSize.getResponsiveSize(
                            context,
                            mobile: 100,
                            tablet: 140,
                            largeTablet: 180,
                            desktop: 220,
                          ),
                          width: GetResponsiveSize.getResponsiveSize(
                            context,
                            mobile: 100,
                            tablet: 140,
                            largeTablet: 180,
                            desktop: 220,
                          ),
                          color: Colors.grey[300],
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
                        mobile: 15, tablet: 20, largeTablet: 26, desktop: 32)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '₹ ${favorite.price.toString()}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: GetResponsiveSize.getResponsiveFontSize(
                                context,
                                mobile: 16,
                                tablet: 22,
                                largeTablet: 28,
                                desktop: 34,
                              ),
                            ),
                          ),
                          const Spacer(),
                          BlocBuilder<FavoriteBloc, FavoriteState>(
                            builder: (context, state) {
                              bool isFavorited =
                                  true; // This is a favorite item

                              if (state is FavoriteToggleLoading &&
                                  state.adId == favorite.id) {
                                return SizedBox(
                                  width: GetResponsiveSize.getResponsiveSize(
                                    context,
                                    mobile: 24,
                                    tablet: 32,
                                    largeTablet: 38,
                                    desktop: 44,
                                  ),
                                  height: GetResponsiveSize.getResponsiveSize(
                                    context,
                                    mobile: 24,
                                    tablet: 32,
                                    largeTablet: 38,
                                    desktop: 44,
                                  ),
                                  child: Center(
                                    child: SizedBox(
                                      width:
                                          GetResponsiveSize.getResponsiveSize(
                                        context,
                                        mobile: 16,
                                        tablet: 22,
                                        largeTablet: 26,
                                        desktop: 30,
                                      ),
                                      height:
                                          GetResponsiveSize.getResponsiveSize(
                                        context,
                                        mobile: 16,
                                        tablet: 22,
                                        largeTablet: 26,
                                        desktop: 30,
                                      ),
                                      child: CircularProgressIndicator(
                                        strokeWidth:
                                            GetResponsiveSize.getResponsiveSize(
                                          context,
                                          mobile: 2,
                                          tablet: 2.5,
                                          largeTablet: 3,
                                          desktop: 3.5,
                                        ),
                                        valueColor:
                                            const AlwaysStoppedAnimation<Color>(
                                                Colors.grey),
                                      ),
                                    ),
                                  ),
                                );
                              }

                              // Update the favorite status if we have a toggle success state for this ad
                              if (state is FavoriteToggleSuccess &&
                                  state.adId == favorite.id) {
                                isFavorited = state.isFavorited;
                              }

                              return GestureDetector(
                                onTap: () {
                                  context.read<FavoriteBloc>().add(
                                        FavoriteEvent.toggleFavorite(
                                          adId: favorite.id,
                                          isCurrentlyFavorited: isFavorited,
                                        ),
                                      );
                                },
                                child: Image.asset(
                                  'assets/images/favorite_icon_filled.png',
                                  width: GetResponsiveSize.getResponsiveSize(
                                    context,
                                    mobile: 24,
                                    tablet: 32,
                                    largeTablet: 38,
                                    desktop: 44,
                                  ),
                                  height: GetResponsiveSize.getResponsiveSize(
                                    context,
                                    mobile: 24,
                                    tablet: 32,
                                    largeTablet: 38,
                                    desktop: 44,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      SizedBox(
                          height: GetResponsiveSize.getResponsiveSize(context,
                              mobile: 5,
                              tablet: 8,
                              largeTablet: 12,
                              desktop: 16)),
                      Text(
                        _getAdTitle(addModel),
                        style: TextStyle(
                          fontSize: GetResponsiveSize.getResponsiveFontSize(
                            context,
                            mobile: 16,
                            tablet: 22,
                            largeTablet: 28,
                            desktop: 34,
                          ),
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        favorite.location,
                        style: AppTextstyle.categoryLabelTextStyle.copyWith(
                          fontSize: GetResponsiveSize.getResponsiveFontSize(
                            context,
                            mobile:
                                AppTextstyle.categoryLabelTextStyle.fontSize ??
                                    14,
                            tablet: 18,
                            largeTablet: 22,
                            desktop: 26,
                          ),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(
                          height: GetResponsiveSize.getResponsiveSize(context,
                              mobile: 5,
                              tablet: 8,
                              largeTablet: 12,
                              desktop: 16)),
                      Text(
                        _getAdSubtitle(addModel),
                        style: AppTextstyle.categoryLabelTextStyle.copyWith(
                          fontSize: GetResponsiveSize.getResponsiveFontSize(
                            context,
                            mobile:
                                AppTextstyle.categoryLabelTextStyle.fontSize ??
                                    14,
                            tablet: 18,
                            largeTablet: 22,
                            desktop: 26,
                          ),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getAdTitle(AddModel ad) {
    if (ad.vehicleType != null) {
      return '${ad.manufacturer?.name ?? ''} ${ad.model?.name ?? ''} ${ad.year ?? ''}'
          .trim();
    } else if (ad.propertyType != null) {
      return '${ad.propertyType} - ${ad.bedrooms ?? 0} BHK';
    } else {
      return ad.description.length > 50
          ? '${ad.description.substring(0, 50)}...'
          : ad.description;
    }
  }

  String _getAdSubtitle(AddModel ad) {
    if (ad.vehicleType != null) {
      return '${ad.mileage ?? 0} KM • ${ad.fuelType ?? 'N/A'} • ${ad.transmission ?? 'N/A'}';
    } else if (ad.propertyType != null) {
      return '${ad.areaSqft ?? 0} sq ft • ${ad.bathrooms ?? 0} bathrooms';
    } else {
      return ''; // Don't show category for other ad types
    }
  }
}
