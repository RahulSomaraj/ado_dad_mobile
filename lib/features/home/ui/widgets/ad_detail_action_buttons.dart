import 'package:ado_dad_user/common/get_responsive_size.dart';
import 'package:ado_dad_user/models/advertisement_model/add_model.dart';
import 'package:ado_dad_user/features/home/favorite/bloc/favorite_bloc.dart';
import 'package:ado_dad_user/features/home/ui/widgets/ad_detail_circle_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';

String toTitleCase(String text) {
  if (text.isEmpty) return text;
  return text
      .split(' ')
      .map((word) => word.isEmpty
          ? word
          : word[0].toUpperCase() + word.substring(1).toLowerCase())
      .join(' ');
}

class AdDetailFavoriteButton extends StatelessWidget {
  final AddModel ad;

  const AdDetailFavoriteButton({super.key, required this.ad});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FavoriteBloc, FavoriteState>(
      builder: (context, state) {
        bool isFavorited = ad.isFavorited ?? false;

        if (state is FavoriteToggleLoading && state.adId == ad.id) {
          return Container(
            height: GetResponsiveSize.getResponsiveSize(
              context,
              mobile: 36,
              tablet: 48,
              largeTablet: 56,
              desktop: 64,
            ),
            width: GetResponsiveSize.getResponsiveSize(
              context,
              mobile: 36,
              tablet: 48,
              largeTablet: 56,
              desktop: 64,
            ),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.35),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: SizedBox(
                width: GetResponsiveSize.getResponsiveSize(
                  context,
                  mobile: 16,
                  tablet: 20,
                  largeTablet: 24,
                  desktop: 28,
                ),
                height: GetResponsiveSize.getResponsiveSize(
                  context,
                  mobile: 16,
                  tablet: 20,
                  largeTablet: 24,
                  desktop: 28,
                ),
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
          );
        }

        if (state is FavoriteToggleSuccess && state.adId == ad.id) {
          isFavorited = state.isFavorited;
        }

        return InkWell(
          onTap: () {
            context.read<FavoriteBloc>().add(
                  FavoriteEvent.toggleFavorite(
                    adId: ad.id,
                    isCurrentlyFavorited: isFavorited,
                  ),
                );
          },
          child: Container(
            height: GetResponsiveSize.getResponsiveSize(
              context,
              mobile: 36,
              tablet: 48,
              largeTablet: 56,
              desktop: 64,
            ),
            width: GetResponsiveSize.getResponsiveSize(
              context,
              mobile: 36,
              tablet: 48,
              largeTablet: 56,
              desktop: 64,
            ),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.35),
              shape: BoxShape.circle,
            ),
            child: Image.asset(
              isFavorited
                  ? 'assets/images/favorite_icon_filled.png'
                  : 'assets/images/favorite_icon_unfilled.png',
              width: GetResponsiveSize.getResponsiveSize(
                context,
                mobile: 20,
                tablet: 26,
                largeTablet: 30,
                desktop: 34,
              ),
              height: GetResponsiveSize.getResponsiveSize(
                context,
                mobile: 20,
                tablet: 26,
                largeTablet: 30,
                desktop: 34,
              ),
            ),
          ),
        );
      },
    );
  }
}

class AdDetailShareButton extends StatelessWidget {
  final AddModel ad;

  const AdDetailShareButton({super.key, required this.ad});

  void _shareAd(BuildContext context) {
    String title;
    if (ad.category == 'property') {
      title =
          '${ad.propertyType ?? ''} • ${ad.bedrooms ?? 0} BHK • ${ad.areaSqft ?? 0} sqft';
    } else {
      title =
          '${ad.manufacturer?.displayName ?? ad.manufacturer?.name ?? ''} ${ad.model?.displayName ?? ad.model?.name ?? ''} (${ad.year ?? ''})';
    }

    final shareText = '''
🚗 Check out this amazing listing on Ado Dad!

${toTitleCase(title)}
📍 Location: ${ad.location}
💰 Price: ₹${ad.price}
📝 Description: ${ad.description}

🔗 Visit: https://ado-dad.com/

Download Ado Dad app to contact the seller and view more details!
''';

    Share.share(
      shareText,
      subject: 'Amazing listing on Ado Dad - ${toTitleCase(title)}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdDetailCircleIconButton(
      icon: Icons.share,
      onTap: () => _shareAd(context),
    );
  }
}

class AdDetailOwnerShareButton extends StatelessWidget {
  final AddModel ad;
  final Future<bool> Function(AddModel) isCurrentUserOwner;

  const AdDetailOwnerShareButton({
    super.key,
    required this.ad,
    required this.isCurrentUserOwner,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: isCurrentUserOwner(ad),
      builder: (context, snapshot) {
        final isOwner = snapshot.data ?? false;

        if (!isOwner) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: EdgeInsets.fromLTRB(
            GetResponsiveSize.getResponsivePadding(context,
                mobile: 16, tablet: 20, largeTablet: 24, desktop: 28),
            GetResponsiveSize.getResponsivePadding(context,
                mobile: 8, tablet: 10, largeTablet: 12, desktop: 14),
            GetResponsiveSize.getResponsivePadding(context,
                mobile: 16, tablet: 20, largeTablet: 24, desktop: 28),
            0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              AdDetailShareButton(ad: ad),
            ],
          ),
        );
      },
    );
  }
}
