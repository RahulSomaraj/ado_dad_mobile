import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/sell_flow_cubit.dart';
import '../../bloc/sell_media_cubit.dart';
import '../../domain/sell_category.dart';
import '../../domain/sell_config.dart';
import '../../domain/sell_format.dart';
import '../../domain/sell_models.dart';
import '../../domain/sell_rules.dart';
import '../widgets/sell_ui.dart';

/// W07 · W08 · W09 — Step 4: the ad as buyers see it, with per-section edit.
class ReviewStep extends StatelessWidget {
  const ReviewStep({super.key});

  static String priceLabel(Map<String, dynamic> v, SellCategory c) {
    final price = v[SellKeys.price];
    if (price is! num) return '₹ —';
    final rent = c == SellCategory.property && v[SellKeys.listingType] == 'rent';
    return '${SellFormat.rupees(price)}${rent ? ' / month' : ''}';
  }

  static String titleLabel(Map<String, dynamic> v, SellCategory c) {
    final t = '${v[SellKeys.title] ?? ''}'.trim();
    return t.isNotEmpty ? t : SellRules.suggestedTitle(c, v);
  }

  static String subtitleLabel(Map<String, dynamic> v, SellFlowState s) {
    String? label(List<SellOption> list, dynamic id) =>
        list.where((o) => o.id == id).map((o) => o.label).firstOrNull;
    final place = '${v[SellKeys.location] ?? ''}'.split(',').first.trim();
    final parts = <String>[];
    if (s.category.isVehicle) {
      final km = v[SellKeys.mileage];
      if (km is num) parts.add('${SellFormat.indianGroup(km)} km');
      final fuel = label(s.config.fuelTypes, v[SellKeys.fuelTypeId]);
      if (fuel != null) parts.add(fuel);
      final tr = label(s.config.transmissionTypes, v[SellKeys.transmissionTypeId]);
      if (tr != null) parts.add(tr);
    } else {
      final area = v[SellKeys.builtArea] ?? v[SellKeys.landArea];
      final unit = v[SellKeys.builtArea] != null ? v[SellKeys.builtUnit] : v[SellKeys.landUnit];
      if (area is num) parts.add('${SellFormat.trimNum(area.toDouble())} ${unit ?? 'sqft'}');
      final f = v[SellKeys.furnishing];
      if (f != null) parts.add(f == 'semi' ? 'Semi-furnished' : f == 'full' ? 'Furnished' : 'Unfurnished');
    }
    if (place.isNotEmpty) parts.add(place);
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SellFlowCubit>().state;
    final media = context.watch<SellMediaCubit>().state;
    final flow = context.read<SellFlowCubit>();
    final v = s.values;
    final cover = media.photos.isEmpty ? null : media.photos.first;
    final posting = s.isPosting;

    return AbsorbPointer(
      absorbing: posting,
      child: AnimatedOpacity(
        duration: SellTokens.fast,
        opacity: posting ? 0.55 : 1,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(SellTokens.gutter, 4, SellTokens.gutter, 32),
          children: [
            if (s.submission == SubmissionStatus.failed && s.failure != null) ...[
              _FailureBanner(state: s),
              const SizedBox(height: 12),
            ],
            SellPreviewCard(
              price: priceLabel(v, s.category),
              title: titleLabel(v, s.category),
              subtitle: subtitleLabel(v, s),
              localPath: cover?.localPath,
              url: cover?.url,
              photoCount: media.photoCount,
            ),
            const SizedBox(height: 12),
            SellSectionCard(
              title: 'Photos',
              onEdit: () => flow.editStep(SellStep.photos),
              child: Text(
                SellMediaCubit.summary(media) + (media.video != null ? ' · video added' : ''),
                style: SellTokens.label.copyWith(color: SellTokens.ink2, fontWeight: FontWeight.w400),
              ),
            ),
            const SizedBox(height: 10),
            SellSectionCard(
              title: s.category == SellCategory.property ? 'Property details' : '${s.category.label == 'Commercial' ? 'Vehicle' : s.category.label} details',
              onEdit: () => flow.editStep(SellStep.details),
              child: Column(children: _detailRows(s)),
            ),
            const SizedBox(height: 10),
            SellSectionCard(
              title: 'Price & place',
              onEdit: () => flow.editStep(SellStep.pricePlace),
              child: Column(children: [
                SellKeyValue(s.category == SellCategory.property && v[SellKeys.listingType] == 'rent' ? 'Monthly rent' : 'Price', priceLabel(v, s.category)),
                SellKeyValue('Location', '${v[SellKeys.location] ?? '—'}', last: true),
              ]),
            ),
            const SizedBox(height: 10),
            SellSectionCard(
              title: 'Description',
              onEdit: () => flow.editStep(SellStep.pricePlace, focusKey: SellKeys.description),
              child: Text(
                '${v[SellKeys.description] ?? ''}'.trim().isEmpty ? '—' : '${v[SellKeys.description]}'.trim(),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: SellTokens.label.copyWith(color: SellTokens.ink2, fontWeight: FontWeight.w400),
              ),
            ),
            const SizedBox(height: 12),
            const SellBanner(
              kind: SellBannerKind.info,
              icon: Icons.info_outline_rounded,
              body: 'Our team reviews new ads, usually within a few hours. We’ll notify you when it’s live.',
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _detailRows(SellFlowState s) {
    final v = s.values;
    final cfg = s.config;
    final rows = <(String, String)>[];
    String? opt(List<SellOption> list, dynamic id) => list.where((o) => o.id == id || o.name == id).map((o) => o.label).firstOrNull;
    String? yesNo(dynamic b) => b == true ? 'Yes' : b == false ? 'No' : null;
    void add(String label, String? value) {
      if (value != null && value.trim().isNotEmpty) rows.add((label, value));
    }

    if (s.category.isVehicle) {
      if (s.category == SellCategory.commercial) add('Type', opt(cfg.commercialVehicleTypes, v[SellKeys.commercialType]));
      add('Brand & model', [v[SellKeys.brandName], v[SellKeys.modelName]].whereType<String>().join(' '));
      add('Variant', v[SellKeys.variantName] as String?);
      add('Year', v[SellKeys.year]?.toString());
      final km = v[SellKeys.mileage];
      add('KM driven', km is num ? SellFormat.indianGroup(km) : null);
      add('Fuel', opt(cfg.fuelTypes, v[SellKeys.fuelTypeId]));
      add('Transmission', opt(cfg.transmissionTypes, v[SellKeys.transmissionTypeId]));
      add('Colour', cfg.colors.where((c) => c.value == v[SellKeys.color]).map((c) => c.label).firstOrNull);
      final owner = v[SellKeys.ownerCount];
      add('Owner', owner == null ? null : const {1: '1st', 2: '2nd', 3: '3rd', 4: '4+'}[owner]);
      if (s.category == SellCategory.commercial) {
        add('Body type', opt(cfg.bodyTypes, v[SellKeys.bodyType]));
        final payload = v[SellKeys.payloadCapacity];
        add('Payload', payload is num ? '${SellFormat.trimNum(payload.toDouble())} ${v[SellKeys.payloadUnit] ?? 'kg'}' : null);
        add('Axles', v[SellKeys.axleCount]?.toString());
        add('Seats', v[SellKeys.seatingCapacity]?.toString());
        add('Fitness certificate', yesNo(v[SellKeys.hasFitness]));
        add('Permit', yesNo(v[SellKeys.hasPermit]));
      }
      add('Insurance', yesNo(v[SellKeys.hasInsurance]));
      add('RC book', yesNo(v[SellKeys.hasRcBook]));
    } else {
      add('Listing', v[SellKeys.listingType] == 'rent' ? 'For rent' : 'For sale');
      add('Type', cfg.propertyTypes.where((p) => p.value == v[SellKeys.propertyType]).map((p) => p.label).firstOrNull);
      add('Bedrooms', v[SellKeys.bedrooms]?.toString());
      add('Bathrooms', v[SellKeys.bathrooms]?.toString());
      String? area(String k, String u) {
        final n = v[k];
        return n is num ? '${SellFormat.trimNum(n.toDouble())} ${v[u] ?? 'sqft'}' : null;
      }
      add('Built-up area', area(SellKeys.builtArea, SellKeys.builtUnit));
      add(v[SellKeys.propertyType] == 'plot' ? 'Plot area' : 'Land area', area(SellKeys.landArea, SellKeys.landUnit));
      add('Floor', v[SellKeys.floor]?.toString());
      final f = v[SellKeys.furnishing];
      add('Furnishing', f == null ? null : const {'unfurnished': 'Unfurnished', 'semi': 'Semi-furnished', 'full': 'Furnished'}[f]);
      add('Parking', yesNo(v[SellKeys.hasParking]));
    }
    final features = (v[SellKeys.features] as List?)?.join(', ');
    add(s.category == SellCategory.property ? 'Amenities' : 'Features', features);

    return [
      for (var i = 0; i < rows.length; i++) SellKeyValue(rows[i].$1, rows[i].$2, last: i == rows.length - 1),
    ];
  }
}

class _FailureBanner extends StatelessWidget {
  const _FailureBanner({required this.state});
  final SellFlowState state;

  @override
  Widget build(BuildContext context) {
    final f = state.failure!;
    final flow = context.read<SellFlowCubit>();
    switch (f) {
      case ValidationFailure(:final fields):
        final entries = fields.entries.toList();
        return SellBanner(
          kind: SellBannerKind.error,
          icon: Icons.error_outline_rounded,
          title: 'We couldn’t post this yet. Nothing you entered is lost.',
          child: entries.isEmpty
              ? null
              : Column(
                  children: [
                    for (final e in entries.take(5))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Material(
                          color: SellTokens.surface,
                          borderRadius: BorderRadius.circular(9),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(9),
                            onTap: () => flow.editStep(SellRules.stepForKey(e.key), focusKey: e.key),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text('${SellRules.labelFor(e.key)} · ${e.value}',
                                        style: SellTokens.label.copyWith(color: SellTokens.errFg, fontWeight: FontWeight.w400)),
                                  ),
                                  Text('Fix ›', style: SellTokens.label.copyWith(color: SellTokens.accentText, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
        );
      case NetworkFailure():
        return SellBanner(
          kind: SellBannerKind.error,
          icon: Icons.cloud_off_rounded,
          title: 'Couldn’t reach AdoDad.',
          body: 'Your ad is saved on this phone. Try again when your connection is steady.',
        );
      case SuspendedFailure(:final message):
        return SellBanner(kind: SellBannerKind.error, icon: Icons.block_rounded, title: 'You can’t post right now.', body: message);
      case RateLimitedFailure():
        return const SellBanner(
          kind: SellBannerKind.warn,
          icon: Icons.hourglass_bottom_rounded,
          title: 'You’ve posted a lot in a short time.',
          body: 'Your ad is saved. Try again in a little while.',
        );
      case AuthFailure():
        return const SellBanner(
          kind: SellBannerKind.warn,
          icon: Icons.lock_outline_rounded,
          title: 'Sign in again to post.',
          body: 'Your ad is saved.',
        );
      case InProgressFailure():
        return const SellBanner(
          kind: SellBannerKind.warn,
          icon: Icons.hourglass_top_rounded,
          title: 'Still finishing your last attempt.',
          body: 'Wait a few seconds and tap Post ad again. It won’t create a duplicate.',
        );
      case ServerFailure(:final message):
        return SellBanner(
          kind: SellBannerKind.error,
          icon: Icons.error_outline_rounded,
          title: 'We couldn’t post this right now.',
          body: 'Your information hasn’t been lost. $message',
        );
    }
  }
}
