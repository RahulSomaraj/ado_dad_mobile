import 'package:ado_dad_user/common/app_colors.dart';
import 'package:ado_dad_user/features/home/favorite/bloc/favorite_bloc.dart';
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
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => context.pop(),
          ),
          title: const Text(
            'My Wishlist',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
        body: BlocBuilder<FavoriteBloc, FavoriteState>(
          builder: (context, state) {
            if (state is FavoriteLoading) {
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
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load wishlist',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.message,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        context
                            .read<FavoriteBloc>()
                            .add(const FavoriteEvent.refreshFavorites());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Retry'),
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
                      const SizedBox(height: 16),
                      Text(
                        'Your wishlist is empty',
                        style: TextStyle(
                          fontSize: 18,
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
                  padding: const EdgeInsets.all(16),
                  itemCount: state.favorites.length,
                  itemBuilder: (context, index) {
                    final favorite = state.favorites[index];
                    return buildFavoriteCard(favorite);
                  },
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Card(
        color: AppColors.whiteColor,
        elevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: ListTile(
          onTap: () {
            context.push('/add-detail-page', extra: favorite);
          },
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: favorite.images.isNotEmpty
                ? Image.network(
                    favorite.images[0],
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.image_not_supported,
                          size: 30,
                          color: Colors.grey,
                        ),
                      );
                    },
                  )
                : Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey[200],
                    child: const Icon(
                      Icons.image_not_supported,
                      size: 30,
                      color: Colors.grey,
                    ),
                  ),
          ),
          title: Text(
            "₹${favorite.price}",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                favorite.description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                favorite.location,
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
          trailing: BlocBuilder<FavoriteBloc, FavoriteState>(
            builder: (context, state) {
              bool isFavorited = true; // This is a favorite item

              if (state is FavoriteToggleLoading && state.adId == favorite.id) {
                return const SizedBox(
                  width: 24,
                  height: 24,
                  child: Center(
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                      ),
                    ),
                  ),
                );
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
                  width: 24,
                  height: 24,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
