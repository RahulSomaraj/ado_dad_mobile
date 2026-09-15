import 'package:ado_dad_user/common/ad_category.dart';
import 'package:ado_dad_user/common/ad_format.dart';
import 'package:ado_dad_user/common/app_colors.dart';
import 'package:ado_dad_user/common/app_spacing.dart';
import 'package:ado_dad_user/common/app_textstyle.dart';
import 'package:ado_dad_user/models/advertisement_model/add_model.dart';
import 'package:flutter/material.dart';

/// A labelled value in the Overview / Documents tables.
class SpecRow {
  const SpecRow(this.label, this.value, {this.positive});

  final String label;
  final String value;

  /// true → green check, false → muted "Not available" styling,
  /// null → plain value.
  final bool? positive;
}

/// One cell of the 4-up key facts grid.
class KeyFact {
  const KeyFact(this.icon, this.value, this.label);

  final IconData icon;
  final String value;
  final String label;
}

/// Everything the detail page shows about an ad's specifications, chosen per
/// category. Rows with no value are dropped here, so widgets never render
/// "-", "null" or "No Parking".
class AdDetailSpecs {
  AdDetailSpecs(this.ad) : category = AdCategory.fromApi(ad.category);

  final AddModel ad;
  final AdCategory category;

  String? get _brand => AdFormat.titleCase(
      AdFormat.clean(ad.manufacturer?.displayName) ??
          AdFormat.clean(ad.manufacturer?.name));

  String? get _model => AdFormat.titleCase(
      AdFormat.clean(ad.model?.displayName) ?? AdFormat.clean(ad.model?.name));

  String? get _year =>
      (ad.year != null && ad.year! > 0) ? '${ad.year}' : null;

  String? get _fuel => AdFormat.titleCase(AdFormat.clean(ad.fuelType));

  String? get _gearbox => AdFormat.titleCase(AdFormat.clean(ad.transmission));

  String? get _ownership {
    if (ad.isFirstOwner == null) return null;
    return ad.isFirstOwner! ? '1st owner' : '2nd owner or more';
  }

  String? get _payload {
    if (ad.payloadCapacity == null || ad.payloadCapacity! <= 0) return null;
    final unit = AdFormat.clean(ad.payloadUnit) ?? 'kg';
    return '${AdFormat.groupIndian(ad.payloadCapacity!)} $unit';
  }

  String? get _area {
    if (ad.areaSqft == null || ad.areaSqft! <= 0) return null;
    return '${AdFormat.groupIndian(ad.areaSqft!)} sq ft';
  }

  String? get _floor {
    if (ad.floor == null) return null;
    if (ad.floor == 0) return 'Ground';
    return AdFormat.ordinal(ad.floor!);
  }

  /// "Maruti Suzuki Swift VXi · 2019" — used when the seller left no title,
  /// and for the share text.
  String get fallbackTitle {
    if (category.isProperty) {
      final parts = <String>[
        if (ad.bedrooms != null && ad.bedrooms! > 0) '${ad.bedrooms} BHK',
        if (AdFormat.clean(ad.propertyType) != null)
          AdFormat.titleCase(ad.propertyType)!,
        if (_area != null) _area!,
      ];
      return parts.isEmpty ? 'Property' : parts.join(' · ');
    }
    final name = [
      if (_brand != null) _brand!,
      if (_model != null) _model!,
      if (AdFormat.clean(ad.variant) != null) ad.variant!.trim(),
    ].join(' ');
    if (name.isEmpty) return category.label;
    return _year == null ? name : '$name · $_year';
  }

  // ---------------------------------------------------------------- key facts

  List<KeyFact> get keyFacts {
    final km = AdFormat.km(ad.mileage);
    List<KeyFact?> cells = const [];
    switch (category) {
      case AdCategory.property:
        cells = [
          (ad.bedrooms != null && ad.bedrooms! > 0)
              ? KeyFact(Icons.bed_outlined, '${ad.bedrooms}', 'Beds')
              : null,
          (ad.bathrooms != null && ad.bathrooms! > 0)
              ? KeyFact(Icons.bathtub_outlined, '${ad.bathrooms}', 'Baths')
              : null,
          (ad.areaSqft != null && ad.areaSqft! > 0)
              ? KeyFact(Icons.square_foot, AdFormat.groupIndian(ad.areaSqft!),
                  'sq ft')
              : null,
          _floor != null
              ? KeyFact(Icons.apartment_outlined, _floor!, 'Floor')
              : null,
        ];
        break;
      case AdCategory.commercialVehicle:
        cells = [
          _year != null ? KeyFact(Icons.event_outlined, _year!, 'Year') : null,
          km != null
              ? KeyFact(Icons.speed, km.replaceAll(' km', ''), 'km')
              : null,
          _payload != null
              ? KeyFact(Icons.inventory_2_outlined, _payload!, 'Payload')
              : null,
          (ad.axleCount != null && ad.axleCount! > 0)
              ? KeyFact(Icons.linear_scale, '${ad.axleCount}', 'Axles')
              : (_fuel != null
                  ? KeyFact(Icons.local_gas_station_outlined, _fuel!, 'Fuel')
                  : null),
        ];
        break;
      case AdCategory.twoWheeler:
        cells = [
          _year != null ? KeyFact(Icons.event_outlined, _year!, 'Year') : null,
          km != null
              ? KeyFact(Icons.speed, km.replaceAll(' km', ''), 'km')
              : null,
          _fuel != null
              ? KeyFact(Icons.local_gas_station_outlined, _fuel!, 'Fuel')
              : null,
          _ownership != null
              ? KeyFact(Icons.person_outline,
                  ad.isFirstOwner! ? '1st' : '2nd+', 'Owner')
              : null,
        ];
        break;
      case AdCategory.privateVehicle:
      case AdCategory.unknown:
        cells = [
          _year != null ? KeyFact(Icons.event_outlined, _year!, 'Year') : null,
          km != null
              ? KeyFact(Icons.speed, km.replaceAll(' km', ''), 'km')
              : null,
          _fuel != null
              ? KeyFact(Icons.local_gas_station_outlined, _fuel!, 'Fuel')
              : null,
          _gearbox != null
              ? KeyFact(Icons.settings_outlined, _gearbox!, 'Gearbox')
              : null,
        ];
        break;
    }
    return cells.whereType<KeyFact>().toList();
  }

  // ----------------------------------------------------------------- overview

  List<SpecRow> get overview {
    final rows = <SpecRow?>[];
    SpecRow? row(String label, String? value) =>
        value == null ? null : SpecRow(label, value);

    if (category.isProperty) {
      final listing = AdFormat.clean(ad.listingType)?.toLowerCase();
      rows.addAll([
        row('Property type', AdFormat.titleCase(AdFormat.clean(ad.propertyType))),
        row('Listed for',
            listing == null ? null : (listing == 'rent' ? 'Rent' : 'Sale')),
        row('Bedrooms', (ad.bedrooms ?? 0) > 0 ? '${ad.bedrooms}' : null),
        row('Bathrooms', (ad.bathrooms ?? 0) > 0 ? '${ad.bathrooms}' : null),
        // The schema stores one area figure; label it honestly until carpet
        // and built-up area are captured separately.
        row('Area', _area),
        row('Floor', _floor),
        row('Furnishing', ad.isFurnished == null
            ? null
            : (ad.isFurnished! ? 'Furnished' : 'Unfurnished')),
        row('Parking', ad.hasParking == null
            ? null
            : (ad.hasParking! ? 'Available' : 'No')),
      ]);
    } else {
      rows.addAll([
        row('Brand', _brand),
        row('Model', _model),
        row('Variant', AdFormat.clean(ad.variant)),
        if (category == AdCategory.commercialVehicle) ...[
          row('Vehicle type',
              AdFormat.titleCase(AdFormat.clean(ad.commercialVehicleType))),
          row('Body type', AdFormat.titleCase(AdFormat.clean(ad.bodyType))),
          row('Payload', _payload),
          row('Axles', (ad.axleCount ?? 0) > 0 ? '${ad.axleCount}' : null),
          row('Seats',
              (ad.seatingCapacity ?? 0) > 0 ? '${ad.seatingCapacity}' : null),
        ],
        row('Registration year', _year),
        row('Kms driven', AdFormat.km(ad.mileage)),
        row('Fuel', _fuel),
        if (category != AdCategory.twoWheeler) row('Transmission', _gearbox),
        row('Colour', AdFormat.titleCase(AdFormat.clean(ad.color))),
        row('Ownership', _ownership),
      ]);
    }
    return rows.whereType<SpecRow>().toList();
  }

  // ---------------------------------------------------------------- documents

  List<SpecRow> get documents {
    if (category.isProperty) return const [];
    SpecRow? doc(String label, bool? value, String yes) => value == null
        ? null
        : SpecRow(label, value ? yes : 'Not available', positive: value);
    return <SpecRow?>[
      doc('RC book', ad.hasRcBook, 'Available'),
      doc('Insurance', ad.hasInsurance, 'Active'),
      if (category == AdCategory.commercialVehicle) ...[
        doc('Fitness certificate', ad.hasFitness, 'Valid'),
        doc('Permit', ad.hasPermit, 'Valid'),
      ],
    ].whereType<SpecRow>().toList();
  }

  // ----------------------------------------------------------------- features

  /// Only things the listing actually has. Property booleans are included
  /// when true; "No Garden"-style negatives never appear.
  List<String> get features {
    final raw = <String>[
      ...(ad.additionalFeatures ?? const <String>[]),
      ...(ad.amenities ?? const <String>[]),
      if (category.isProperty && ad.hasGarden == true) 'Garden',
    ];
    final seen = <String>{};
    final out = <String>[];
    for (final f in raw) {
      final label = AdFormat.titleCase(AdFormat.clean(f));
      if (label == null) continue;
      if (seen.add(label.toLowerCase())) out.add(label);
    }
    return out;
  }
}

// ============================================================== widgets

/// Four equal cells with hairline dividers, value over label.
class AdDetailKeyFacts extends StatelessWidget {
  const AdDetailKeyFacts({super.key, required this.facts});

  final List<KeyFact> facts;

  @override
  Widget build(BuildContext context) {
    if (facts.isEmpty) return const SizedBox.shrink();
    final rule = AppColors.dividerColor;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: rule),
        borderRadius: BorderRadius.circular(AppRadius.control12),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < facts.length; i++) ...[
              if (i > 0) VerticalDivider(width: 1, thickness: 1, color: rule),
              Expanded(child: _FactCell(fact: facts[i])),
            ],
          ],
        ),
      ),
    );
  }
}

class _FactCell extends StatelessWidget {
  const _FactCell({required this.fact});

  final KeyFact fact;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${fact.label}: ${fact.value}',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(fact.icon, size: 18, color: AppColors.textMuted),
            const SizedBox(height: 2),
            Text(
              fact.value,
              style: AppTextstyle.specValue
                  .copyWith(fontSize: 13.5, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            Text(
              fact.label,
              style: AppTextstyle.micro,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Label column + value column, 40 dp minimum rows, hairline between rows.
class AdDetailSpecTable extends StatelessWidget {
  const AdDetailSpecTable({super.key, required this.rows});

  final List<SpecRow> rows;

  @override
  Widget build(BuildContext context) {
    final labelWidth = AppSpacing.s(context, 128);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < rows.length; i++)
          Container(
            constraints: const BoxConstraints(minHeight: 40),
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              border: i == rows.length - 1
                  ? null
                  : Border(bottom: BorderSide(color: AppColors.dividerColor)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: labelWidth,
                  child: Text(rows[i].label, style: AppTextstyle.specLabel),
                ),
                const SizedBox(width: AppSpacing.sm8),
                Expanded(child: _value(rows[i])),
              ],
            ),
          ),
      ],
    );
  }

  Widget _value(SpecRow r) {
    if (r.positive == true) {
      return Row(
        children: [
          Icon(Icons.check_circle_outline,
              size: 16, color: AppColors.positiveText),
          const SizedBox(width: AppSpacing.xs4),
          Flexible(
            child: Text(r.value,
                style:
                    AppTextstyle.specValue.copyWith(color: AppColors.positiveText)),
          ),
        ],
      );
    }
    if (r.positive == false) {
      return Text(r.value,
          style: AppTextstyle.specValue.copyWith(color: AppColors.textMuted));
    }
    return Text(r.value, style: AppTextstyle.specValue);
  }
}

/// Soft chips with a green check, only for features the listing has.
class AdDetailFeatureChips extends StatelessWidget {
  const AdDetailFeatureChips({super.key, required this.features});

  final List<String> features;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm8,
      runSpacing: AppSpacing.sm8,
      children: [
        for (final f in features)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.chipFill,
              borderRadius: BorderRadius.circular(AppRadius.chip8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check, size: 14, color: AppColors.positiveText),
                const SizedBox(width: 5),
                Text(f,
                    style: AppTextstyle.caption
                        .copyWith(color: AppColors.blackColor1)),
              ],
            ),
          ),
      ],
    );
  }
}
