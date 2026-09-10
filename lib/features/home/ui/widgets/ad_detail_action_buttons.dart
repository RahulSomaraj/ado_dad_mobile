import 'package:ado_dad_user/common/get_responsive_size.dart';
import 'package:ado_dad_user/common/auth_guard.dart';
import 'package:ado_dad_user/common/widgets/dialog_util.dart';
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

class AdDetailFavoriteButton extends StatefulWidget {
  final AddModel ad;

  const AdDetailFavoriteButton({super.key, required this.ad});

  @override
  State<AdDetailFavoriteButton> createState() => _AdDetailFavoriteButtonState();
}

class _AdDetailFavoriteButtonState extends State<AdDetailFavoriteButton> {
  late bool _isFavorited;
  bool _pendingToggle = false;

  AddModel get ad => widget.ad;

  @override
  void initState() {
    super.initState();
    _isFavorited = widget.ad.isFavorited ?? false;
  }

  @override
  void didUpdateWidget(covariant AdDetailFavoriteButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Keep in sync if a different ad (or a refreshed copy) is supplied.
    if (oldWidget.ad.id != widget.ad.id ||
        oldWidget.ad.isFavorited != widget.ad.isFavorited) {
      _isFavorited = widget.ad.isFavorited ?? false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<FavoriteBloc, FavoriteState>(
      listener: (context, state) {
        // Revert the optimistic flip only when the bloc reports a failure
        // for this exact ad.
        if (state is FavoriteToggleError && state.adId == ad.id) {
          if (_pendingToggle) {
            _pendingToggle = false;
            setState(() => _isFavorited = !_isFavorited);
          }
        } else if (state is FavoriteToggleSuccess && state.adId == ad.id) {
          _pendingToggle = false;
          if (_isFavorited != state.isFavorited) {
            setState(() => _isFavorited = state.isFavorited);
          }
        }
      },
      child: _buildButton(context),
    );
  }

  Widget _buildButton(BuildContext context) {
    return BlocBuilder<FavoriteBloc, FavoriteState>(
      builder: (context, state) {
        final bool isFavorited = _isFavorited;

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

        return InkWell(
          onTap: () async {
            // Check authentication before allowing favorite toggle
            final isAuthenticated = await AuthGuard.isAuthenticated();
            if (!isAuthenticated) {
              DialogUtil.showLoginPromptDialog(
                context,
                message: "Please login to add this ad to your favorites.",
                redirectPath: '/add-detail-page',
              );
              return;
            }
            if (!mounted) return;

            final wasFavorited = _isFavorited;
            // Optimistic flip; reverted by the listener if the toggle fails.
            _pendingToggle = true;
            setState(() => _isFavorited = !wasFavorited);

            context.read<FavoriteBloc>().add(
                  FavoriteEvent.toggleFavorite(
                    adId: ad.id,
                    isCurrentlyFavorited: wasFavorited,
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
            child: Center(
              child: SizedBox(
                width: GetResponsiveSize.getResponsiveSize(
                  context,
                  mobile: 20,
                  tablet: 20,
                  largeTablet: 24,
                  desktop: 28,
                ),
                height: GetResponsiveSize.getResponsiveSize(
                  context,
                  mobile: 20,
                  tablet: 20,
                  largeTablet: 24,
                  desktop: 28,
                ),
                child: Image.asset(
                  isFavorited
                      ? 'assets/images/heart-3-fill.png'
                      : 'assets/images/heart-3-line.png',
                  fit: BoxFit.contain,
                ),
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

  Future<void> _shareAd(BuildContext context) async {
    // Check authentication before allowing share
    final isAuthenticated = await AuthGuard.isAuthenticated();
    if (!isAuthenticated) {
      DialogUtil.showLoginPromptDialog(
        context,
        message: "Please login to share this ad.",
        redirectPath: '/add-detail-page',
      );
      return;
    }

    String title;
    if (ad.category == 'property') {
      title =
          '${ad.propertyType ?? ''} • ${ad.bedrooms ?? 0} BHK • ${ad.areaSqft ?? 0} sqft';
    } else {
      title =
          '${ad.manufacturer?.displayName ?? ad.manufacturer?.name ?? ''} ${ad.model?.displayName ?? ad.model?.name ?? ''} (${ad.year ?? ''})';
    }

    final shareText = '''
🚗 Check out this amazing listing on Adodad!

${toTitleCase(title)}
📍 Location: ${ad.location}
💰 Price: ₹${ad.price}
📝 Description: ${ad.description}

🔗 Visit: https://adodad.com/

Download Adodad app to contact the seller and view more details!
''';

    Share.share(
      shareText,
      subject: 'Amazing listing on Adodad - ${toTitleCase(title)}',
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
