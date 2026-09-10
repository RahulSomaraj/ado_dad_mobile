import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ado_dad_user/models/advertisement_model/add_model.dart';
import 'package:ado_dad_user/common/widgets/rich_ad_card.dart';
import 'package:ado_dad_user/common/widgets/skeleton.dart';
import 'package:ado_dad_user/features/home/ui/sellerprofile/bloc/bloc/seller_profile_bloc.dart';
import 'package:ado_dad_user/common/app_colors.dart';
import 'package:ado_dad_user/common/get_responsive_size.dart';
import 'package:url_launcher/url_launcher.dart';

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
                    Text(
                      'Seller',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: GetResponsiveSize.getResponsiveFontSize(
                            context,
                            mobile: 16,
                            tablet: 20,
                            largeTablet: 24,
                            desktop: 28),
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
                    initial: () => const SkeletonList(itemCount: 3),
                    loading: () => const SkeletonList(itemCount: 3),
                    loaded: (ads, hasNext, page, isPaging) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Stats strip (client-side, from the loaded ads)
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: GetResponsiveSize.getResponsivePadding(
                                context,
                                mobile: 16,
                                tablet: 20,
                                largeTablet: 24,
                                desktop: 28),
                          ),
                          child: Row(
                            children: [
                              _StatTile(label: 'Ads', value: ads.length),
                              const SizedBox(width: 10),
                              _StatTile(
                                label: 'Active',
                                value: ads.where((a) => a.isActive).length,
                              ),
                              const SizedBox(width: 10),
                              _StatTile(
                                label: 'Inactive',
                                value: ads.where((a) => !a.isActive).length,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                            height: GetResponsiveSize.getResponsiveSize(
                                context,
                                mobile: 14,
                                tablet: 18,
                                largeTablet: 22,
                                desktop: 26)),
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
                            'Seller products (${ads.length})',
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
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
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
                                  backgroundColor: AppColors.primaryColor,
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
                                        'Load more products',
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

  String _maskPhoneNumber(String phoneNumber) {
    final digitsOnly = phoneNumber.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.isEmpty) return '';
    final visible = digitsOnly.length >= 3
        ? digitsOnly.substring(digitsOnly.length - 3)
        : digitsOnly;
    final maskedCount = (digitsOnly.length - visible.length).clamp(0, 1000);
    return '${'*' * maskedCount}$visible';
  }

  String _formatPhoneNumber(String? countryCode, String phone) {
    final trimmedCountryCode = countryCode?.trim();
    if (trimmedCountryCode != null && trimmedCountryCode.isNotEmpty) {
      // Ensure country code starts with + if it doesn't already
      final formattedCountryCode = trimmedCountryCode.startsWith('+')
          ? trimmedCountryCode
          : '+$trimmedCountryCode';
      return '$formattedCountryCode $phone';
    }
    return phone;
  }

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
            backgroundColor: AppColors.primaryColor.withOpacity(0.1),
            backgroundImage: seller.profilePic?.trim().isNotEmpty == true
                ? NetworkImage(seller.profilePic!)
                : null,
            child: seller.profilePic?.trim().isNotEmpty == true
                ? null
                : Text(
                    _initials(seller.name),
                    style: TextStyle(
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.w700,
                      fontSize: GetResponsiveSize.getResponsiveFontSize(
                          context,
                          mobile: 20,
                          tablet: 26,
                          largeTablet: 32,
                          desktop: 38),
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
                    _formatPhoneNumber(
                      seller.countryCode,
                      _maskPhoneNumber(seller.phone!),
                    ),
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
                if (seller.phone?.trim().isNotEmpty == true)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _callSeller(seller.phone!),
                      icon: const Icon(Icons.phone, size: 16),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      label: Text(
                        'Call',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: GetResponsiveSize.getResponsiveFontSize(
                              context,
                              mobile: 13,
                              tablet: 16,
                              largeTablet: 18,
                              desktop: 20),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String? name) {
    final n = name?.trim() ?? '';
    if (n.isEmpty) return 'S';
    final parts = n.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  Future<void> _callSeller(String phone) async {
    final rawPhone = phone.trim();
    if (rawPhone.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: rawPhone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}

/// Small stat tile for the seller header (wireframe: "Seller profile").
class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE6E8EE)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              '$value',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: GetResponsiveSize.getResponsiveFontSize(context,
                    mobile: 15, tablet: 18, largeTablet: 21, desktop: 24),
                color: const Color(0xFF111827),
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: GetResponsiveSize.getResponsiveFontSize(context,
                    mobile: 10.5, tablet: 12, largeTablet: 13, desktop: 14),
                color: const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
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
      if (ad.propertyType?.toLowerCase() == 'plot') {
        title = '${_toTitleCase(ad.propertyType)} • ${ad.areaSqft ?? 0} sqft';
      } else {
        title =
            '${_toTitleCase(ad.propertyType)} • ${ad.bedrooms ?? 0} BHK • ${ad.areaSqft ?? 0} sqft';
      }
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
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: GetResponsiveSize.getResponsiveSize(
                            context,
                            mobile: 12,
                            tablet: 16,
                            largeTablet: 18,
                            desktop: 20,
                          ),
                          color: const Color(0xFF6B7280),
                        ),
                        SizedBox(
                          width: GetResponsiveSize.getResponsiveSize(
                            context,
                            mobile: 4,
                            tablet: 6,
                            largeTablet: 8,
                            desktop: 8,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            ad.location,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF6B7280),
                              fontWeight: FontWeight.w600,
                              fontSize: GetResponsiveSize.getResponsiveFontSize(
                                  context,
                                  mobile: theme.textTheme.bodySmall?.fontSize ??
                                      12.0,
                                  tablet: 16,
                                  largeTablet: 20,
                                  desktop: 24),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
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
