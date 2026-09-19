import 'sell_config.dart';
import 'sell_variant.dart';

/// Where a derived answer came from, so the UI can say so.
enum SellDerivedFrom {
  /// The chosen variant names exactly one value.
  variant,

  /// Every real variant of this model shares one value.
  modelVariants,

  /// `VehicleModel.fuelTypes` / `transmissionTypes` names exactly one value.
  modelCatalogue,

  /// Nothing narrowed it — the seller picks from the category list.
  category,
}

/// The options a field may offer, and where that came from.
///
/// An Activa is gearless and a Dominar is geared. Those are facts about the
/// bike, not opinions the seller holds, so the flow should state them rather
/// than offer a menu. [options] with a single entry is a fact; two or more is
/// a real choice.
class SellDerived {
  const SellDerived(this.options, this.from, this.sourceLabel);

  final List<SellOption> options;
  final SellDerivedFrom from;

  /// "6G DLX" or "Activa 6G" — what to name in "FROM … ✓". Null for [category].
  final String? sourceLabel;

  bool get isFact => options.length == 1 && from != SellDerivedFrom.category;
  bool get isEmpty => options.isEmpty;
  SellOption? get only => options.length == 1 ? options.first : null;
}

/// Resolves fuel and gearbox from the catalogue, narrowest source first.
class SellDerive {
  SellDerive._();

  static String _flat(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '');

  static List<SellOption> _byIds(List<SellOption> all, Set<String> ids) =>
      all.where((o) => ids.contains(o.id)).toList();

  static List<SellOption> _byNames(List<SellOption> all, List<String> names) {
    if (names.isEmpty) return const [];
    final wanted = names.map(_flat).toSet();
    return all
        .where((o) => wanted.contains(_flat(o.name)) || wanted.contains(_flat(o.label)))
        .toList();
  }

  /// [variants] should already have seeder scaffolding filtered out — a
  /// generic row's fuel and gearbox are random, so letting them into the union
  /// would claim an Activa can be Diesel.
  static SellDerived fuel({
    required List<SellOption> catalogue,
    required List<SellVariant> variants,
    required SellVariant? chosen,
    required List<String> modelNames,
    required String? modelLabel,
  }) =>
      _resolve(
        catalogue: catalogue,
        variantIds: variants.map((v) => v.fuelTypeId).whereType<String>().toSet(),
        chosenId: chosen?.fuelTypeId,
        chosenLabel: chosen?.displayName,
        modelNames: modelNames,
        modelLabel: modelLabel,
      );

  static SellDerived transmission({
    required List<SellOption> catalogue,
    required List<SellVariant> variants,
    required SellVariant? chosen,
    required List<String> modelNames,
    required String? modelLabel,
  }) =>
      _resolve(
        catalogue: catalogue,
        variantIds:
            variants.map((v) => v.transmissionTypeId).whereType<String>().toSet(),
        chosenId: chosen?.transmissionTypeId,
        chosenLabel: chosen?.displayName,
        modelNames: modelNames,
        modelLabel: modelLabel,
      );

  static SellDerived _resolve({
    required List<SellOption> catalogue,
    required Set<String> variantIds,
    required String? chosenId,
    required String? chosenLabel,
    required List<String> modelNames,
    required String? modelLabel,
  }) {
    // 1. A chosen variant is exact: it carries one fuel and one gearbox.
    if (chosenId != null) {
      final match = _byIds(catalogue, {chosenId});
      if (match.isNotEmpty) {
        return SellDerived(match, SellDerivedFrom.variant, chosenLabel);
      }
    }

    // 2. Every real variant of this model agrees, or between them they name
    //    the only combinations that exist.
    if (variantIds.isNotEmpty) {
      final match = _byIds(catalogue, variantIds);
      if (match.isNotEmpty) {
        return SellDerived(match, SellDerivedFrom.modelVariants, modelLabel);
      }
    }

    // 3. The model document says so directly.
    final byName = _byNames(catalogue, modelNames);
    if (byName.isNotEmpty) {
      return SellDerived(byName, SellDerivedFrom.modelCatalogue, modelLabel);
    }

    // 4. Nothing known — the category list, already narrowed server-side.
    return SellDerived(catalogue, SellDerivedFrom.category, null);
  }

  /// Colour names the catalogue knows for this bike: the chosen variant's, or
  /// the union across its model's real variants. Order is preserved and
  /// duplicates are dropped case-insensitively.
  static List<String> colors({
    required List<SellVariant> variants,
    required SellVariant? chosen,
  }) {
    final source = chosen != null ? [chosen] : variants;
    final out = <String>[];
    final seen = <String>{};
    for (final v in source) {
      for (final c in v.colors) {
        final name = c.trim();
        if (name.isEmpty) continue;
        if (seen.add(name.toLowerCase())) out.add(name);
      }
    }
    return out;
  }
}
