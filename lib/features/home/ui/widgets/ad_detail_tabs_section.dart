import 'package:ado_dad_user/common/get_responsive_size.dart';
import 'package:ado_dad_user/models/advertisement_model/add_model.dart';
import 'package:ado_dad_user/features/home/ui/widgets/ad_detail_card_shell.dart';
import 'package:ado_dad_user/features/home/ui/widgets/ad_detail_spec_tile.dart';
import 'package:ado_dad_user/features/home/ui/widgets/ad_detail_key_val_row.dart';
import 'package:ado_dad_user/features/home/ui/widgets/ad_detail_mark_as_sold_button.dart';
import 'package:flutter/material.dart';

String toTitleCase(String text) {
  if (text.isEmpty) return text;
  return text
      .split(' ')
      .map((word) => word.isEmpty
          ? word
          : word[0].toUpperCase() + word.substring(1).toLowerCase())
      .join(' ');
}

class AdDetailTabsSection extends StatelessWidget {
  final AddModel ad;
  final Future<bool> Function(AddModel) isCurrentUserOwner;

  const AdDetailTabsSection({
    super.key,
    required this.ad,
    required this.isCurrentUserOwner,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: GetResponsiveSize.getResponsivePadding(context,
            mobile: 12, tablet: 16, largeTablet: 20, desktop: 24),
        vertical: GetResponsiveSize.getResponsivePadding(context,
            mobile: 8, tablet: 10, largeTablet: 12, desktop: 14),
      ),
      child: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF4F6FA),
                borderRadius: BorderRadius.circular(
                  GetResponsiveSize.getResponsiveBorderRadius(context,
                      mobile: 24, tablet: 28, largeTablet: 32, desktop: 36),
                ),
              ),
              padding: EdgeInsets.all(
                GetResponsiveSize.getResponsiveSize(context,
                    mobile: 6, tablet: 8, largeTablet: 10, desktop: 12),
              ),
              child: TabBar(
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(
                    GetResponsiveSize.getResponsiveBorderRadius(context,
                        mobile: 24, tablet: 28, largeTablet: 32, desktop: 36),
                  ),
                ),
                indicatorColor: Colors.transparent,
                dividerColor: Colors.transparent,
                labelColor: const Color(0xFF6366F1),
                unselectedLabelColor: Colors.grey.shade600,
                labelStyle: TextStyle(
                  fontSize: GetResponsiveSize.getResponsiveFontSize(context,
                      mobile: 14, tablet: 22, largeTablet: 25, desktop: 27),
                ),
                tabs: const [
                  Tab(text: 'Specifications'),
                  Tab(text: 'Other Details'),
                ],
              ),
            ),
            SizedBox(
                height: GetResponsiveSize.getResponsiveSize(context,
                    mobile: 12, tablet: 16, largeTablet: 20, desktop: 24)),
            SizedBox(
              height: GetResponsiveSize.getResponsiveSize(context,
                  mobile: 320, tablet: 450, largeTablet: 550, desktop: 650),
              child: TabBarView(
                children: [
                  _SpecsCard(ad: ad),
                  _OtherDetailsCard(
                      ad: ad, isCurrentUserOwner: isCurrentUserOwner),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpecsCard extends StatelessWidget {
  final AddModel ad;

  const _SpecsCard({required this.ad});

  // Helper to check if amenities exist and need more space
  bool _hasAmenities() {
    return ad.amenities != null && ad.amenities!.isNotEmpty;
  }

  // Helper to get base grid item height
  double _getBaseGridItemHeight(BuildContext context) {
    return GetResponsiveSize.getResponsiveSize(context,
        mobile: 55, tablet: 90, largeTablet: 110, desktop: 130);
  }

  // Helper to get grid item height - taller when amenities exist
  double _getGridItemHeight(BuildContext context) {
    if (_hasAmenities()) {
      // Increased height when amenities are present to allow wrapping
      return GetResponsiveSize.getResponsiveSize(context,
          mobile: 80, tablet: 120, largeTablet: 140, desktop: 160);
    }
    return _getBaseGridItemHeight(context);
  }

  @override
  Widget build(BuildContext context) {
    if (ad.category == 'property') {
      // For plot, show: Property Type, Area, Description
      if (ad.propertyType == 'plot') {
        final plotItemHeight = _getBaseGridItemHeight(context);
        final plotPadding = GetResponsiveSize.getResponsivePadding(context,
            mobile: 12, tablet: 16, largeTablet: 20, desktop: 24);
        final plotMainAxisSpacing = GetResponsiveSize.getResponsiveSize(context,
            mobile: 8, tablet: 12, largeTablet: 16, desktop: 20);
        final plotCrossAxisSpacing = GetResponsiveSize.getResponsiveSize(
            context,
            mobile: 8,
            tablet: 12,
            largeTablet: 16,
            desktop: 20);

        // Use larger height for description to accommodate long text
        final descriptionItemHeight = GetResponsiveSize.getResponsiveSize(
            context,
            mobile: 120,
            tablet: 180,
            largeTablet: 220,
            desktop: 260);

        // Calculate total height: first row (2 items) + spacing + second row (1 item) + spacing + third row (description with larger height) + padding
        final plotTotalHeight = plotItemHeight +
            plotMainAxisSpacing +
            plotItemHeight +
            plotMainAxisSpacing +
            descriptionItemHeight +
            (plotPadding * 2);

        return AdDetailCardShell(
          child: SizedBox(
            height: plotTotalHeight,
            child: Padding(
              padding: EdgeInsets.all(plotPadding),
              child: Column(
                children: [
                  // First row: Property Type and Listing Type
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: plotItemHeight,
                          child: AdDetailSpecTile(
                            spec: AdDetailSpec(
                                'Property Type', ad.propertyType ?? '-',
                                icon: Icons.home_work),
                          ),
                        ),
                      ),
                      SizedBox(width: plotCrossAxisSpacing),
                      Expanded(
                        child: SizedBox(
                          height: plotItemHeight,
                          child: AdDetailSpecTile(
                            spec: AdDetailSpec('Listing Type',
                                toTitleCase(ad.listingType ?? '-'),
                                icon: Icons.sell),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: plotMainAxisSpacing),
                  // Second row: Area
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: plotItemHeight,
                          child: AdDetailSpecTile(
                            spec: AdDetailSpec(
                                'Area (sqft)', ad.areaSqft?.toString() ?? '-',
                                icon: Icons.square_foot),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: plotMainAxisSpacing),
                  // Third row: Description (spans full width with larger height, scrollable if needed)
                  SizedBox(
                    height: descriptionItemHeight,
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      child: AdDetailSpecTile(
                        spec: AdDetailSpec('Description',
                            ad.description.isNotEmpty ? ad.description : '-',
                            icon: Icons.description),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      // For warehouse, show only: Property Type, Area, Parking, Amenities
      if (ad.propertyType == 'warehouse') {
        final amenitiesText = (ad.amenities != null && ad.amenities!.isNotEmpty)
            ? ad.amenities!.join(', ')
            : '-';

        final items = <AdDetailSpec>[
          AdDetailSpec('Property Type', ad.propertyType ?? '-',
              icon: Icons.home_work),
          AdDetailSpec('Listing Type', toTitleCase(ad.listingType ?? '-'),
              icon: Icons.sell),
          AdDetailSpec('Area (sqft)', ad.areaSqft?.toString() ?? '-',
              icon: Icons.square_foot),
          AdDetailSpec('Parking', ad.hasParking == true ? 'Yes' : 'No',
              icon: Icons.local_parking),
          AdDetailSpec('Amenities', amenitiesText,
              icon: Icons.room_preferences),
        ];

        return AdDetailCardShell(
          child: GridView.builder(
            padding: EdgeInsets.all(
              GetResponsiveSize.getResponsivePadding(context,
                  mobile: 12, tablet: 16, largeTablet: 20, desktop: 24),
            ),
            physics: const ClampingScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisExtent: _getGridItemHeight(context),
              crossAxisSpacing: GetResponsiveSize.getResponsiveSize(context,
                  mobile: 8, tablet: 12, largeTablet: 16, desktop: 20),
              mainAxisSpacing: GetResponsiveSize.getResponsiveSize(context,
                  mobile: 8, tablet: 12, largeTablet: 16, desktop: 20),
            ),
            itemCount: items.length,
            itemBuilder: (_, i) => AdDetailSpecTile(spec: items[i]),
          ),
        );
      }

      // For shop, show only: Property Type, Area, Floor, Furnished, Parking, Garden, Amenities
      if (ad.propertyType == 'shop') {
        final amenitiesText = (ad.amenities != null && ad.amenities!.isNotEmpty)
            ? ad.amenities!.join(', ')
            : '-';

        final items = <AdDetailSpec>[
          AdDetailSpec('Property Type', ad.propertyType ?? '-',
              icon: Icons.home_work),
          AdDetailSpec('Area (sqft)', ad.areaSqft?.toString() ?? '-',
              icon: Icons.square_foot),
          AdDetailSpec('Floor', ad.floor?.toString() ?? '-',
              icon: Icons.apartment),
          AdDetailSpec('Furnished', ad.isFurnished == true ? 'Yes' : 'No',
              icon: Icons.chair_alt),
          AdDetailSpec('Parking', ad.hasParking == true ? 'Yes' : 'No',
              icon: Icons.local_parking),
          AdDetailSpec('Garden', ad.hasGarden == true ? 'Yes' : 'No',
              icon: Icons.park),
          AdDetailSpec('Amenities', amenitiesText,
              icon: Icons.room_preferences),
        ];

        return AdDetailCardShell(
          child: GridView.builder(
            padding: EdgeInsets.all(
              GetResponsiveSize.getResponsivePadding(context,
                  mobile: 12, tablet: 16, largeTablet: 20, desktop: 24),
            ),
            physics: const ClampingScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisExtent: _getGridItemHeight(context),
              crossAxisSpacing: GetResponsiveSize.getResponsiveSize(context,
                  mobile: 8, tablet: 12, largeTablet: 16, desktop: 20),
              mainAxisSpacing: GetResponsiveSize.getResponsiveSize(context,
                  mobile: 8, tablet: 12, largeTablet: 16, desktop: 20),
            ),
            itemCount: items.length,
            itemBuilder: (_, i) => AdDetailSpecTile(spec: items[i]),
          ),
        );
      }

      // For office, show only: Property Type, Area, Floor, Furnished, Parking, Garden, Amenities
      if (ad.propertyType == 'office') {
        final amenitiesText = (ad.amenities != null && ad.amenities!.isNotEmpty)
            ? ad.amenities!.join(', ')
            : '-';

        final items = <AdDetailSpec>[
          AdDetailSpec('Property Type', ad.propertyType ?? '-',
              icon: Icons.home_work),
          AdDetailSpec('Area (sqft)', ad.areaSqft?.toString() ?? '-',
              icon: Icons.square_foot),
          AdDetailSpec('Floor', ad.floor?.toString() ?? '-',
              icon: Icons.apartment),
          AdDetailSpec('Furnished', ad.isFurnished == true ? 'Yes' : 'No',
              icon: Icons.chair_alt),
          AdDetailSpec('Parking', ad.hasParking == true ? 'Yes' : 'No',
              icon: Icons.local_parking),
          AdDetailSpec('Garden', ad.hasGarden == true ? 'Yes' : 'No',
              icon: Icons.park),
          AdDetailSpec('Amenities', amenitiesText,
              icon: Icons.room_preferences),
        ];

        return AdDetailCardShell(
          child: GridView.builder(
            padding: EdgeInsets.all(
              GetResponsiveSize.getResponsivePadding(context,
                  mobile: 12, tablet: 16, largeTablet: 20, desktop: 24),
            ),
            physics: const ClampingScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisExtent: _getGridItemHeight(context),
              crossAxisSpacing: GetResponsiveSize.getResponsiveSize(context,
                  mobile: 8, tablet: 12, largeTablet: 16, desktop: 20),
              mainAxisSpacing: GetResponsiveSize.getResponsiveSize(context,
                  mobile: 8, tablet: 12, largeTablet: 16, desktop: 20),
            ),
            itemCount: items.length,
            itemBuilder: (_, i) => AdDetailSpecTile(spec: items[i]),
          ),
        );
      }

      // For commercial, show only: Property Type, Area, Floor, Furnished, Parking, Garden, Amenities
      if (ad.propertyType == 'commercial') {
        final amenitiesText = (ad.amenities != null && ad.amenities!.isNotEmpty)
            ? ad.amenities!.join(', ')
            : '-';

        final items = <AdDetailSpec>[
          AdDetailSpec('Property Type', ad.propertyType ?? '-',
              icon: Icons.home_work),
          AdDetailSpec('Area (sqft)', ad.areaSqft?.toString() ?? '-',
              icon: Icons.square_foot),
          AdDetailSpec('Floor', ad.floor?.toString() ?? '-',
              icon: Icons.apartment),
          AdDetailSpec('Furnished', ad.isFurnished == true ? 'Yes' : 'No',
              icon: Icons.chair_alt),
          AdDetailSpec('Parking', ad.hasParking == true ? 'Yes' : 'No',
              icon: Icons.local_parking),
          AdDetailSpec('Garden', ad.hasGarden == true ? 'Yes' : 'No',
              icon: Icons.park),
          AdDetailSpec('Amenities', amenitiesText,
              icon: Icons.room_preferences),
        ];

        return AdDetailCardShell(
          child: GridView.builder(
            padding: EdgeInsets.all(
              GetResponsiveSize.getResponsivePadding(context,
                  mobile: 12, tablet: 16, largeTablet: 20, desktop: 24),
            ),
            physics: const ClampingScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisExtent: _getGridItemHeight(context),
              crossAxisSpacing: GetResponsiveSize.getResponsiveSize(context,
                  mobile: 8, tablet: 12, largeTablet: 16, desktop: 20),
              mainAxisSpacing: GetResponsiveSize.getResponsiveSize(context,
                  mobile: 8, tablet: 12, largeTablet: 16, desktop: 20),
            ),
            itemCount: items.length,
            itemBuilder: (_, i) => AdDetailSpecTile(spec: items[i]),
          ),
        );
      }

      // For villa, show all fields plus amenities
      if (ad.propertyType == 'villa') {
        final amenitiesText = (ad.amenities != null && ad.amenities!.isNotEmpty)
            ? ad.amenities!.join(', ')
            : '-';

        final items = <AdDetailSpec>[
          AdDetailSpec('Property Type', ad.propertyType ?? '-',
              icon: Icons.home_work),
          AdDetailSpec('Listing Type', toTitleCase(ad.listingType ?? '-'),
              icon: Icons.sell),
          AdDetailSpec('Bedrooms', ad.bedrooms?.toString() ?? '-',
              icon: Icons.bed),
          AdDetailSpec('Bathrooms', ad.bathrooms?.toString() ?? '-',
              icon: Icons.bathtub),
          AdDetailSpec('Area (sqft)', ad.areaSqft?.toString() ?? '-',
              icon: Icons.square_foot),
          AdDetailSpec('Floor', ad.floor?.toString() ?? '-',
              icon: Icons.apartment),
          AdDetailSpec('Furnished', ad.isFurnished == true ? 'Yes' : 'No',
              icon: Icons.chair_alt),
          AdDetailSpec('Parking', ad.hasParking == true ? 'Yes' : 'No',
              icon: Icons.local_parking),
          AdDetailSpec('Garden', ad.hasGarden == true ? 'Yes' : 'No',
              icon: Icons.park),
          AdDetailSpec('Amenities', amenitiesText,
              icon: Icons.room_preferences),
        ];

        return AdDetailCardShell(
          child: GridView.builder(
            padding: EdgeInsets.all(
              GetResponsiveSize.getResponsivePadding(context,
                  mobile: 12, tablet: 16, largeTablet: 20, desktop: 24),
            ),
            physics: const ClampingScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisExtent: _getGridItemHeight(context),
              crossAxisSpacing: GetResponsiveSize.getResponsiveSize(context,
                  mobile: 8, tablet: 12, largeTablet: 16, desktop: 20),
              mainAxisSpacing: GetResponsiveSize.getResponsiveSize(context,
                  mobile: 8, tablet: 12, largeTablet: 16, desktop: 20),
            ),
            itemCount: items.length,
            itemBuilder: (_, i) => AdDetailSpecTile(spec: items[i]),
          ),
        );
      }

      // For house, show all fields plus amenities
      if (ad.propertyType == 'house') {
        final amenitiesText = (ad.amenities != null && ad.amenities!.isNotEmpty)
            ? ad.amenities!.join(', ')
            : '-';

        final items = <AdDetailSpec>[
          AdDetailSpec('Property Type', ad.propertyType ?? '-',
              icon: Icons.home_work),
          AdDetailSpec('Listing Type', toTitleCase(ad.listingType ?? '-'),
              icon: Icons.sell),
          AdDetailSpec('Bedrooms', ad.bedrooms?.toString() ?? '-',
              icon: Icons.bed),
          AdDetailSpec('Bathrooms', ad.bathrooms?.toString() ?? '-',
              icon: Icons.bathtub),
          AdDetailSpec('Area (sqft)', ad.areaSqft?.toString() ?? '-',
              icon: Icons.square_foot),
          AdDetailSpec('Floor', ad.floor?.toString() ?? '-',
              icon: Icons.apartment),
          AdDetailSpec('Furnished', ad.isFurnished == true ? 'Yes' : 'No',
              icon: Icons.chair_alt),
          AdDetailSpec('Parking', ad.hasParking == true ? 'Yes' : 'No',
              icon: Icons.local_parking),
          AdDetailSpec('Garden', ad.hasGarden == true ? 'Yes' : 'No',
              icon: Icons.park),
          AdDetailSpec('Amenities', amenitiesText,
              icon: Icons.room_preferences),
        ];

        return AdDetailCardShell(
          child: GridView.builder(
            padding: EdgeInsets.all(
              GetResponsiveSize.getResponsivePadding(context,
                  mobile: 12, tablet: 16, largeTablet: 20, desktop: 24),
            ),
            physics: const ClampingScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisExtent: _getGridItemHeight(context),
              crossAxisSpacing: GetResponsiveSize.getResponsiveSize(context,
                  mobile: 8, tablet: 12, largeTablet: 16, desktop: 20),
              mainAxisSpacing: GetResponsiveSize.getResponsiveSize(context,
                  mobile: 8, tablet: 12, largeTablet: 16, desktop: 20),
            ),
            itemCount: items.length,
            itemBuilder: (_, i) => AdDetailSpecTile(spec: items[i]),
          ),
        );
      }

      // For apartment, show all fields plus amenities
      if (ad.propertyType == 'apartment') {
        final amenitiesText = (ad.amenities != null && ad.amenities!.isNotEmpty)
            ? ad.amenities!.join(', ')
            : '-';

        final items = <AdDetailSpec>[
          AdDetailSpec('Property Type', ad.propertyType ?? '-',
              icon: Icons.home_work),
          AdDetailSpec('Listing Type', toTitleCase(ad.listingType ?? '-'),
              icon: Icons.sell),
          AdDetailSpec('Bedrooms', ad.bedrooms?.toString() ?? '-',
              icon: Icons.bed),
          AdDetailSpec('Bathrooms', ad.bathrooms?.toString() ?? '-',
              icon: Icons.bathtub),
          AdDetailSpec('Area (sqft)', ad.areaSqft?.toString() ?? '-',
              icon: Icons.square_foot),
          AdDetailSpec('Floor', ad.floor?.toString() ?? '-',
              icon: Icons.apartment),
          AdDetailSpec('Furnished', ad.isFurnished == true ? 'Yes' : 'No',
              icon: Icons.chair_alt),
          AdDetailSpec('Parking', ad.hasParking == true ? 'Yes' : 'No',
              icon: Icons.local_parking),
          AdDetailSpec('Garden', ad.hasGarden == true ? 'Yes' : 'No',
              icon: Icons.park),
          AdDetailSpec('Amenities', amenitiesText,
              icon: Icons.room_preferences),
        ];

        return AdDetailCardShell(
          child: GridView.builder(
            padding: EdgeInsets.all(
              GetResponsiveSize.getResponsivePadding(context,
                  mobile: 12, tablet: 16, largeTablet: 20, desktop: 24),
            ),
            physics: const ClampingScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisExtent: _getGridItemHeight(context),
              crossAxisSpacing: GetResponsiveSize.getResponsiveSize(context,
                  mobile: 8, tablet: 12, largeTablet: 16, desktop: 20),
              mainAxisSpacing: GetResponsiveSize.getResponsiveSize(context,
                  mobile: 8, tablet: 12, largeTablet: 16, desktop: 20),
            ),
            itemCount: items.length,
            itemBuilder: (_, i) => AdDetailSpecTile(spec: items[i]),
          ),
        );
      }

      // For other property types, show all fields
      final items = <AdDetailSpec>[
        AdDetailSpec('Property Type', ad.propertyType ?? '-',
            icon: Icons.home_work),
        AdDetailSpec('Listing Type', toTitleCase(ad.listingType ?? '-'),
            icon: Icons.sell),
        AdDetailSpec('Bedrooms', ad.bedrooms?.toString() ?? '-',
            icon: Icons.bed),
        AdDetailSpec('Bathrooms', ad.bathrooms?.toString() ?? '-',
            icon: Icons.bathtub),
        AdDetailSpec('Area (sqft)', ad.areaSqft?.toString() ?? '-',
            icon: Icons.square_foot),
        AdDetailSpec('Floor', ad.floor?.toString() ?? '-',
            icon: Icons.apartment),
        AdDetailSpec('Furnished', ad.isFurnished == true ? 'Yes' : 'No',
            icon: Icons.chair_alt),
        AdDetailSpec('Parking', ad.hasParking == true ? 'Yes' : 'No',
            icon: Icons.local_parking),
        AdDetailSpec('Garden', ad.hasGarden == true ? 'Yes' : 'No',
            icon: Icons.park),
      ];

      return AdDetailCardShell(
        child: GridView.builder(
          padding: EdgeInsets.all(
            GetResponsiveSize.getResponsivePadding(context,
                mobile: 12, tablet: 16, largeTablet: 20, desktop: 24),
          ),
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisExtent: GetResponsiveSize.getResponsiveSize(context,
                mobile: 55, tablet: 90, largeTablet: 110, desktop: 130),
            crossAxisSpacing: GetResponsiveSize.getResponsiveSize(context,
                mobile: 8, tablet: 12, largeTablet: 16, desktop: 20),
            mainAxisSpacing: GetResponsiveSize.getResponsiveSize(context,
                mobile: 8, tablet: 12, largeTablet: 16, desktop: 20),
          ),
          itemCount: items.length,
          itemBuilder: (_, i) => AdDetailSpecTile(spec: items[i]),
        ),
      );
    }

    // Helper to check if additional features exist and need more space
    final hasAdditionalFeatures =
        ad.additionalFeatures != null && ad.additionalFeatures!.isNotEmpty;

    // Helper to get grid item height - taller when additional features exist
    double getVehicleGridItemHeight(BuildContext context) {
      if (hasAdditionalFeatures) {
        // Increased height when additional features are present to allow wrapping
        return GetResponsiveSize.getResponsiveSize(context,
            mobile: 80, tablet: 120, largeTablet: 140, desktop: 160);
      }
      return GetResponsiveSize.getResponsiveSize(context,
          mobile: 64, tablet: 95, largeTablet: 110, desktop: 125);
    }

    final additionalFeaturesText =
        hasAdditionalFeatures ? ad.additionalFeatures!.join(', ') : '-';

    final items = <AdDetailSpec>[
      AdDetailSpec(
          'Brand Name',
          toTitleCase(
              ad.manufacturer?.displayName ?? ad.manufacturer?.name ?? '-'),
          icon: Icons.factory_outlined),
      AdDetailSpec('Model Name',
          toTitleCase(ad.model?.displayName ?? ad.model?.name ?? '-'),
          icon: Icons.directions_car),
      AdDetailSpec('Transmission', ad.transmission ?? '-',
          icon: Icons.settings),
      AdDetailSpec('Fuel Type', ad.fuelType ?? '-',
          icon: Icons.local_gas_station),
      AdDetailSpec('Registration Year', (ad.year ?? 0).toString(),
          icon: Icons.calendar_today),
      AdDetailSpec('Mileage', (ad.mileage != null) ? '${ad.mileage} Kmpl' : '-',
          icon: Icons.speed),
      // Additional vehicle specifications
      AdDetailSpec('Has Insurance',
          ad.hasInsurance != null ? (ad.hasInsurance! ? 'Yes' : 'No') : '-',
          icon: Icons.shield_outlined),
      AdDetailSpec('First Owner',
          ad.isFirstOwner != null ? (ad.isFirstOwner! ? 'Yes' : 'No') : '-',
          icon: Icons.person_outline),
      AdDetailSpec('Has RC Book',
          ad.hasRcBook != null ? (ad.hasRcBook! ? 'Yes' : 'No') : '-',
          icon: Icons.description_outlined),
      AdDetailSpec('Additional Features', additionalFeaturesText,
          icon: Icons.star_outline),
    ];

    return AdDetailCardShell(
      child: GridView.builder(
        padding: EdgeInsets.all(
          GetResponsiveSize.getResponsivePadding(context,
              mobile: 12, tablet: 16, largeTablet: 20, desktop: 24),
        ),
        physics: const ClampingScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisExtent: getVehicleGridItemHeight(context),
          crossAxisSpacing: GetResponsiveSize.getResponsiveSize(context,
              mobile: 8, tablet: 12, largeTablet: 16, desktop: 20),
          mainAxisSpacing: GetResponsiveSize.getResponsiveSize(context,
              mobile: 8, tablet: 12, largeTablet: 16, desktop: 20),
        ),
        itemCount: items.length,
        itemBuilder: (_, i) => AdDetailSpecTile(spec: items[i]),
      ),
    );
  }
}

class _OtherDetailsCard extends StatelessWidget {
  final AddModel ad;
  final Future<bool> Function(AddModel) isCurrentUserOwner;

  const _OtherDetailsCard({
    required this.ad,
    required this.isCurrentUserOwner,
  });

  @override
  Widget build(BuildContext context) {
    final sellerName = (ad.user?.name ?? '').trim();
    final sellerEmail = (ad.user?.email ?? '').trim();
    return AdDetailCardShell(
      child: Padding(
        padding: EdgeInsets.all(
          GetResponsiveSize.getResponsivePadding(context,
              mobile: 10, tablet: 20, largeTablet: 24, desktop: 28),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (sellerName.isNotEmpty) ...[
              Text('Seller Information',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: GetResponsiveSize.getResponsiveFontSize(context,
                        mobile: 16, tablet: 24, largeTablet: 28, desktop: 32),
                  )),
              SizedBox(
                  height: GetResponsiveSize.getResponsiveSize(context,
                      mobile: 10, tablet: 12, largeTablet: 14, desktop: 16)),
              AdDetailKeyValRow(label: 'Name', value: sellerName),
              if (sellerEmail.isNotEmpty) ...[
                SizedBox(
                    height: GetResponsiveSize.getResponsiveSize(context,
                        mobile: 8, tablet: 10, largeTablet: 12, desktop: 14)),
                AdDetailKeyValRow(label: 'Email', value: sellerEmail),
              ],
              SizedBox(
                  height: GetResponsiveSize.getResponsiveSize(context,
                      mobile: 10, tablet: 20, largeTablet: 24, desktop: 28)),
            ],
            Text('Ad Details',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: GetResponsiveSize.getResponsiveFontSize(context,
                      mobile: 16, tablet: 24, largeTablet: 28, desktop: 32),
                )),
            SizedBox(
                height: GetResponsiveSize.getResponsiveSize(context,
                    mobile: 10, tablet: 12, largeTablet: 14, desktop: 16)),
            AdDetailKeyValRow(label: 'Location', value: ad.location),
            SizedBox(
                height: GetResponsiveSize.getResponsiveSize(context,
                    mobile: 8, tablet: 10, largeTablet: 12, desktop: 14)),
            AdDetailKeyValRow(
                label: 'Category', value: toTitleCase(ad.category)),
            SizedBox(
                height: GetResponsiveSize.getResponsiveSize(context,
                    mobile: 8, tablet: 24, largeTablet: 32, desktop: 40)),
            FutureBuilder<bool>(
              future: isCurrentUserOwner(ad),
              builder: (context, snapshot) {
                final isOwner = snapshot.data ?? false;
                if (isOwner) {
                  return AdDetailMarkAsSoldButton(ad: ad);
                }
                return const SizedBox.shrink();
              },
            ),
            SizedBox(
                height: GetResponsiveSize.getResponsiveSize(context,
                    mobile: 0, tablet: 8, largeTablet: 12, desktop: 16)),
          ],
        ),
      ),
    );
  }
}
