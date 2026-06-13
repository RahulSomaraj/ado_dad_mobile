import 'package:ado_dad_user/common/app_colors.dart';
import 'package:ado_dad_user/common/auth_guard.dart';
import 'package:ado_dad_user/common/get_responsive_size.dart';
import 'package:ado_dad_user/common/widgets/app_network_image.dart';
import 'package:ado_dad_user/common/widgets/dialog_util.dart';
import 'package:ado_dad_user/features/home/favorite/bloc/favorite_bloc.dart';
import 'package:ado_dad_user/models/advertisement_model/add_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// The single, shared "rich" advertisement card used across the whole app
/// (home grid, search, category lists, similar-ads, seller/showroom, wishlist).
/// Designed to sit inside a fixed-extent grid cell — use
/// [richAdCardMainAxisExtent] to size the cell.
class RichAdCard extends StatelessWidget {
  final AddModel ad;

  /// Where the favourite login prompt should redirect back to.
  final String favoriteRedirect;

  const RichAdCard({
    super.key,
    required this.ad,
    this.favoriteRedirect = '/home',
  });

  // ---- formatting helpers ----
  static String inr(int n) {
    final str = n.abs().toString();
    if (str.length <= 3) return n.toString();
    final last3 = str.substring(str.length - 3);
    String rest = str.substring(0, str.length - 3);
    final parts = <String>[];
    while (rest.length > 2) {
      parts.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) parts.insert(0, rest);
    return '${n < 0 ? '-' : ''}${parts.join(',')},$last3';
  }

  bool get _isProperty => ad.category.toLowerCase().contains('propert');
  bool get _isRent => (ad.listingType ?? '').toLowerCase() == 'rent';

  String get _priceText {
    final base = '₹ ${inr(ad.price)}';
    return _isRent ? '$base/mo' : base;
  }

  String _emiText(int price) => '₹${inr((price * 0.018).round())}/mo';

  String get _cardTitle {
    if ((ad.title ?? '').trim().isNotEmpty) return ad.title!.trim();
    final parts = <String>[];
    if ((ad.manufacturer?.name ?? '').isNotEmpty) {
      parts.add(ad.manufacturer!.name!);
    }
    if ((ad.model?.name ?? '').isNotEmpty) parts.add(ad.model!.name);
    if (ad.year != null) parts.add('${ad.year}');
    if (parts.isNotEmpty) return parts.join(' ');
    if ((ad.propertyType ?? '').isNotEmpty) return ad.propertyType!;
    return 'Listing';
  }

  bool get _isNew {
    final dt = DateTime.tryParse(ad.postedAt);
    if (dt == null) return false;
    return DateTime.now().difference(dt).inDays < 3;
  }

  String _relTime(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    final d = DateTime.now().difference(dt);
    if (d.inDays >= 365) return '${(d.inDays / 365).floor()}y';
    if (d.inDays >= 30) return '${(d.inDays / 30).floor()}mo';
    if (d.inDays >= 7) return '${(d.inDays / 7).floor()}w';
    if (d.inDays >= 1) return '${d.inDays}d';
    if (d.inHours >= 1) return '${d.inHours}h';
    if (d.inMinutes >= 1) return '${d.inMinutes}m';
    return 'now';
  }

  Widget _chip(IconData icon, String label) {
    final display = label.length > 14 ? '${label.substring(0, 14)}…' : label;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.scaffoldBackground,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.dividerColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: AppColors.greyColor),
          const SizedBox(width: 3),
          Text(
            display,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 9.5, color: AppColors.blackColor1),
          ),
        ],
      ),
    );
  }

  Widget _specChips() {
    final chips = <Widget>[];
    if (_isProperty) {
      if (ad.bedrooms != null) {
        chips.add(_chip(Icons.bed_outlined, '${ad.bedrooms} Bed'));
      }
      if (ad.bathrooms != null) {
        chips.add(_chip(Icons.bathtub_outlined, '${ad.bathrooms} Bath'));
      }
      if (ad.areaSqft != null) {
        chips.add(_chip(Icons.straighten, '${inr(ad.areaSqft!)} sqft'));
      }
      if (ad.isFurnished == true) {
        chips.add(_chip(Icons.chair_outlined, 'Furnished'));
      }
    } else {
      if (ad.mileage != null) {
        chips.add(_chip(Icons.route_outlined, '${inr(ad.mileage!)} km'));
      }
      if ((ad.fuelType ?? '').trim().isNotEmpty) {
        chips.add(_chip(Icons.local_gas_station_outlined, ad.fuelType!));
      }
      if ((ad.transmission ?? '').trim().isNotEmpty) {
        chips.add(_chip(Icons.settings_outlined, ad.transmission!));
      }
      if (ad.isFirstOwner == true) {
        chips.add(_chip(Icons.person_outline, '1st owner'));
      }
    }
    if (chips.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 22,
      child: ClipRect(
        child: Align(
          alignment: Alignment.centerLeft,
          child: Row(
            children: [
              for (var i = 0; i < chips.length && i < 2; i++) ...[
                if (i > 0) const SizedBox(width: 5),
                Flexible(child: chips[i]),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _imgTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(5)),
      child: Text(text,
          style: const TextStyle(
              color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.w600)),
    );
  }

  Widget _imgPill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.55),
          borderRadius: BorderRadius.circular(5)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: Colors.white),
          const SizedBox(width: 3),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 9)),
        ],
      ),
    );
  }

  Widget _favorite() {
    return BlocBuilder<FavoriteBloc, FavoriteState>(
      builder: (context, state) {
        final bool isFav = ad.isFavorited ?? false;
        final bool loading =
            state is FavoriteToggleLoading && state.adId == ad.id;
        return GestureDetector(
          onTap: () async {
            final isAuth = await AuthGuard.isAuthenticated();
            if (!context.mounted) return;
            if (!isAuth) {
              DialogUtil.showLoginPromptDialog(
                context,
                message: "Please login to add this ad to your favorites.",
                redirectPath: favoriteRedirect,
              );
              return;
            }
            context.read<FavoriteBloc>().add(
                  FavoriteEvent.toggleFavorite(
                    adId: ad.id,
                    isCurrentlyFavorited: isFav,
                  ),
                );
          },
          child: Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
                color: Colors.white, shape: BoxShape.circle),
            child: loading
                ? const Padding(
                    padding: EdgeInsets.all(7),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    isFav ? Icons.favorite : Icons.favorite_border,
                    size: 16,
                    color: isFav ? AppColors.redColor : AppColors.greyColor,
                  ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isPremium = ad.manufacturer?.isPremium == true;
    final bool property = _isProperty;
    return GestureDetector(
      onTap: () => context.push('/add-detail-page', extra: ad),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.whiteColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.dividerColor),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio:
                  GetResponsiveSize.isTablet(context) ? (16 / 9) : (16 / 10),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ad.images.isNotEmpty
                      ? AppNetworkImage(url: ad.images.first, fit: BoxFit.cover)
                      : Container(
                          color: AppColors.scaffoldBackground,
                          child: Icon(Icons.image_not_supported_outlined,
                              color: AppColors.greyColor),
                        ),
                  if (isPremium)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: _imgTag('PREMIUM', AppColors.primaryColor),
                    )
                  else if (property)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: _imgTag(_isRent ? 'FOR RENT' : 'FOR SALE',
                          const Color(0xFF1565C0)),
                    )
                  else if (_isNew)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: _imgTag('NEW', const Color(0xFF19A463)),
                    ),
                  Positioned(top: 5, right: 5, child: _favorite()),
                  if (ad.images.length > 1)
                    Positioned(
                      bottom: 6,
                      right: 6,
                      child: _imgPill(
                          Icons.photo_library_outlined, '${ad.images.length}'),
                    ),
                  if ((ad.link ?? '').trim().isNotEmpty)
                    Positioned(
                      bottom: 6,
                      left: 6,
                      child: _imgPill(Icons.play_circle_outline, 'Video'),
                    ),
                  if (ad.soldOut == true)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withOpacity(0.45),
                        alignment: Alignment.center,
                        child: const Text('SOLD',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                letterSpacing: 1.5)),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(9, 7, 9, 8),
                child: ClipRect(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              _priceText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: AppColors.blackColor),
                            ),
                          ),
                          if (!property && ad.price > 0) ...[
                            const SizedBox(width: 4),
                            Text(
                              'EMI ${_emiText(ad.price)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 9, color: AppColors.greyColor),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _cardTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 12.5, color: AppColors.blackColor),
                            ),
                          ),
                          if (ad.user?.isVerified == true) ...[
                            const SizedBox(width: 3),
                            Icon(Icons.verified,
                                size: 13, color: AppColors.primaryColor),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      _specChips(),
                      const Spacer(),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined,
                              size: 12, color: AppColors.greyColor),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              ad.location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 10, color: AppColors.greyColor),
                            ),
                          ),
                          if (ad.distance != null) ...[
                            const SizedBox(width: 4),
                            Text(
                              '${ad.distance!.toStringAsFixed(1)} km',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 9.5, color: AppColors.greyColor),
                            ),
                            Text(' · ',
                                style: TextStyle(
                                    fontSize: 9.5, color: AppColors.greyColor)),
                          ],
                          Text(
                            _relTime(ad.postedAt),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 9.5, color: AppColors.greyColor),
                          ),
                        ],
                      ),
                    ],
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

/// Height of a [RichAdCard] cell for a grid with [columns] columns and
/// [horizontalPadding] page padding + [spacing] between cells. Mirrors the
/// card's internal layout so the grid cell never overflows.
double richAdCardMainAxisExtent(
  BuildContext context, {
  int columns = 2,
  double horizontalPadding = 15.0,
  double spacing = 15.0,
}) {
  final screenWidth = MediaQuery.of(context).size.width;
  final available =
      screenWidth - (horizontalPadding * 2) - (spacing * (columns - 1));
  final cardWidth = available / columns;
  final aspectRatio = GetResponsiveSize.isTablet(context) ? (16 / 9) : (16 / 10);
  final imageHeight = cardWidth / aspectRatio;
  const textBlockHeight = 15 + 18 + 3 + 16 + 6 + 22 + 14 + 6 + 10;
  return imageHeight + textBlockHeight;
}
