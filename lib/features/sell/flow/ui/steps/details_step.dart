import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/sell_flow_cubit.dart';
import '../../data/sell_repository.dart';
import '../../domain/sell_category.dart';
import '../../domain/sell_config.dart';
import '../../domain/sell_derive.dart';
import '../../domain/sell_format.dart';
import '../../domain/sell_models.dart';
import '../../domain/sell_variant.dart';
import '../widgets/sell_color_field.dart';
import '../widgets/sell_pickers.dart';
import '../widgets/sell_section.dart';
import '../widgets/sell_ui.dart';
import '../widgets/variant_sheet.dart';
import 'step_scroll.dart';

/// W04 · W05 · W15 — Step 2, rendered per category from the same controls.
///
/// CAR-2/3/4: the car branch is three labelled sections that narrow — identify
/// the car, then its trim (which answers fuel and transmission for the
/// seller), then colour and condition. Bike, commercial and property keep the
/// original flat layout in [_legacyVehicle] and [_property].
class DetailsStep extends StatefulWidget {
  const DetailsStep({super.key, required this.repository});
  final SellRepository repository;

  @override
  State<DetailsStep> createState() => _DetailsStepState();
}

class _DetailsStepState extends State<DetailsStep> {
  late final TextEditingController _km;
  late final TextEditingController _payload;
  late final TextEditingController _built;
  late final TextEditingController _land;
  late final TextEditingController _color;
  final FocusNode _colorFocus = FocusNode();
  final StepScrollKeys _keys = StepScrollKeys();

  List<SellVariant>? _variants;
  bool _variantsFailed = false;
  String? _variantsFor;
  bool _showMore = false;

  /// Manufacturer colours for the chosen variant, empty when none are known.
  List<String> _variantColors = const [];

  /// The identity section shows a one-line summary once brand, model, year and
  /// km are in. Used by car and bike.
  bool _identityCollapsed = false;

  /// Tapping Edit keeps it open for the rest of the step.
  bool _identityPinnedOpen = false;

  /// The seller asked to override a fact the catalogue settled — a converted
  /// or imported bike. Opens the full category list for that one field.
  bool _fuelOverride = false;
  bool _gearsOverride = false;

  SellFlowCubit get _flow => context.read<SellFlowCubit>();

  @override
  void initState() {
    super.initState();
    final v = _flow.state.values;
    String n(String k, {bool grouped = false}) {
      final x = v[k];
      if (x is! num) return '';
      return grouped ? SellFormat.indianGroup(x) : SellFormat.trimNum(x.toDouble());
    }

    _km = TextEditingController(text: n(SellKeys.mileage, grouped: true));
    _payload = TextEditingController(text: n(SellKeys.payloadCapacity));
    _built = TextEditingController(text: n(SellKeys.builtArea));
    _land = TextEditingController(text: n(SellKeys.landArea));
    _color = TextEditingController(text: '${v[SellKeys.color] ?? ''}');
    _showMore = [SellKeys.hasInsurance, SellKeys.hasRcBook, SellKeys.hasFitness, SellKeys.hasPermit]
            .any((k) => v[k] != null) ||
        ((v[SellKeys.features] as List?)?.isNotEmpty ?? false);
    // A resumed draft opens with the identity block already summarised.
    _identityCollapsed = _sectioned(_flow.state.category) && _identityComplete(v);
    final modelId = v[SellKeys.modelId] as String?;
    // BIKE-3: variants are loaded for bikes too now. Whether the control is
    // shown is decided by what comes back, not by the category.
    if (modelId != null && _flow.state.category != SellCategory.property) {
      _loadVariants(modelId, fromInit: true);
    }
  }

  /// Categories rendered as labelled, collapsing sections.
  static bool _sectioned(SellCategory c) =>
      c == SellCategory.car || c == SellCategory.bike;

  @override
  void dispose() {
    _km.dispose();
    _payload.dispose();
    _built.dispose();
    _land.dispose();
    _color.dispose();
    _colorFocus.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------- lookups

  Future<void> _loadVariants(String modelId, {bool fromInit = false}) async {
    void reset() {
      _variantsFor = modelId;
      _variants = null;
      _variantsFailed = false;
    }

    fromInit ? reset() : setState(reset);
    try {
      final list = await widget.repository.variants(modelId);
      if (!mounted || _variantsFor != modelId) return;
      setState(() => _variants = list);
      _applyDerivedDefaults();
      await _syncVariantColors(_flow.state.values[SellKeys.variantId] as String?);
    } catch (_) {
      if (!mounted || _variantsFor != modelId) return;
      setState(() => _variantsFailed = true);
    }
  }

  /// The colours the catalogue knows for this bike.
  ///
  /// A chosen variant names its own; with none chosen the union across the
  /// model's real variants still beats the generic ten, because those are the
  /// colours this model was actually sold in. Falls back to the variant detail
  /// endpoint for servers whose list response does not project `colors`.
  Future<void> _syncVariantColors(String? variantId) async {
    if (!mounted) return;
    final chosen = _chosenVariant(_flow.state);
    final known = SellDerive.colors(variants: _usableVariants, chosen: chosen);
    if (known.isNotEmpty) {
      setState(() => _variantColors = known);
      return;
    }
    if (variantId == null || variantId.isEmpty) {
      if (_variantColors.isNotEmpty) setState(() => _variantColors = const []);
      return;
    }
    final fetched = await widget.repository.variantColors(variantId);
    if (!mounted) return;
    setState(() => _variantColors = fetched);
  }

  // ------------------------------------------------------------- pickers

  Future<void> _pickBrandModel() async {
    final result = await showBrandModelSheet(context, config: _flow.state.config, repository: widget.repository);
    if (result == null || !mounted) return;
    _flow.setValues({
      SellKeys.brandId: result.brand.id,
      SellKeys.brandName: result.brand.displayName,
      SellKeys.modelId: result.model.id,
      SellKeys.modelName: result.model.displayName,
      SellKeys.variantId: null,
      SellKeys.variantName: null,
      SellKeys.fuelSource: null,
      SellKeys.transmissionSource: null,
      // What the catalogue says this model is built with. Kept with the draft
      // so a resumed ad can still state the fact without re-opening the sheet.
      SellKeys.modelFuelNames:
          result.model.fuelTypes.isEmpty ? null : result.model.fuelTypes,
      SellKeys.modelTransmissionNames: result.model.transmissionTypes.isEmpty
          ? null
          : result.model.transmissionTypes,
    });
    setState(() {
      _variantColors = const [];
      _fuelOverride = false;
      _gearsOverride = false;
    });
    if (_flow.state.category != SellCategory.property) _loadVariants(result.model.id);
    _applyDerivedDefaults();
    _maybeCollapseIdentity();
  }

  Future<void> _pickYear() async {
    final l = _flow.state.config.limits;
    final picked = await showYearSheet(context, min: l.yearMin, max: l.yearMax, selected: _flow.state.values[SellKeys.year] as int?);
    if (picked != null) _flow.setValue(SellKeys.year, picked);
    _maybeCollapseIdentity();
  }

  /// Variants worth offering: the seeder's `"<Model> <Fuel> <Transmission>"`
  /// rows carry no trim information, so they are filtered out. A variant the
  /// draft already holds always stays, so a resumed ad can still be changed.
  List<SellVariant> get _usableVariants {
    final list = _variants;
    if (list == null) return const [];
    final modelName = _flow.state.values[SellKeys.modelName] as String?;
    final selected = _flow.state.values[SellKeys.variantId] as String?;
    return list
        .where((v) => (selected != null && v.id == selected) || !v.isGenericFor(modelName))
        .toList();
  }

  /// CAR-3 / BIKE-3: the sheet, then fill fuel and transmission from the trim.
  Future<void> _pickVariant() async {
    final list = _usableVariants;
    if (list.isEmpty) return;
    final v = _flow.state.values;
    final choice = await showVariantSheet(
      context,
      modelName: '${v[SellKeys.brandName] ?? ''} ${v[SellKeys.modelName] ?? ''}'.trim(),
      variants: list,
      selectedId: v[SellKeys.variantId] as String?,
    );
    if (choice == null || !mounted) return;

    final picked = choice.variant;
    if (picked == null) {
      // "I'm not sure" — '' keeps the answer, and buildPayload omits the key.
      _flow.setValues({
        SellKeys.variantId: '',
        SellKeys.variantName: null,
        SellKeys.fuelSource: null,
        SellKeys.transmissionSource: null,
      });
      setState(() => _variantColors = const []);
      return;
    }

    final cfg = _flow.state.config;
    final changes = <String, dynamic>{
      SellKeys.variantId: picked.id,
      SellKeys.variantName: picked.displayName,
    };

    // Only fill a slot that is empty or was itself variant-derived, and only
    // with an id this category's config actually offers — an id the chip row
    // cannot show would also fail the server's reference check.
    void adopt(String valueKey, String sourceKey, String? id, List<SellOption> options) {
      if (id == null || !options.any((o) => o.id == id)) return;
      final current = _flow.state.values;
      final free = current[valueKey] == null || current[sourceKey] != null;
      if (!free) return;
      changes[valueKey] = id;
      changes[sourceKey] = picked.displayName;
    }

    adopt(SellKeys.fuelTypeId, SellKeys.fuelSource, picked.fuelTypeId, cfg.fuelTypes);
    adopt(SellKeys.transmissionTypeId, SellKeys.transmissionSource, picked.transmissionTypeId, cfg.transmissionTypes);

    _flow.setValues(changes);
    setState(() {
      _fuelOverride = false;
      _gearsOverride = false;
    });
    await _syncVariantColors(picked.id);
  }

  // ------------------------------------------------------ derived answers

  /// The seller reveals the bike; the catalogue answers what follows from it.
  SellVariant? _chosenVariant(SellFlowState s) {
    final id = s.values[SellKeys.variantId] as String?;
    if (id == null || id.isEmpty) return null;
    final match = (_variants ?? const <SellVariant>[]).where((x) => x.id == id);
    return match.isEmpty ? null : match.first;
  }

  static List<String> _names(dynamic raw) =>
      raw is List ? raw.map((e) => '$e').toList() : const <String>[];

  SellDerived _derivedFuel(SellFlowState s) => SellDerive.fuel(
        catalogue: s.config.fuelTypes,
        variants: _usableVariants,
        chosen: _chosenVariant(s),
        modelNames: _names(s.values[SellKeys.modelFuelNames]),
        modelLabel: s.values[SellKeys.modelName] as String?,
      );

  SellDerived _derivedTransmission(SellFlowState s) => SellDerive.transmission(
        catalogue: s.config.transmissionTypes,
        variants: _usableVariants,
        chosen: _chosenVariant(s),
        modelNames: _names(s.values[SellKeys.modelTransmissionNames]),
        modelLabel: s.values[SellKeys.modelName] as String?,
      );

  /// Writes the values the catalogue settled. Only fills a slot that is empty
  /// or was itself derived — a seller's own answer is never overwritten.
  void _applyDerivedDefaults() {
    if (!mounted || _flow.state.category != SellCategory.bike) return;
    final s = _flow.state;
    final changes = <String, dynamic>{};

    void fill(SellDerived d, String valueKey, String sourceKey) {
      if (!d.isFact) return;
      final free = s.values[valueKey] == null || s.values[sourceKey] != null;
      if (!free) return;
      if (s.values[valueKey] == d.only!.id && s.values[sourceKey] != null) return;
      changes[valueKey] = d.only!.id;
      changes[sourceKey] = d.sourceLabel;
    }

    fill(_derivedFuel(s), SellKeys.fuelTypeId, SellKeys.fuelSource);
    fill(_derivedTransmission(s), SellKeys.transmissionTypeId, SellKeys.transmissionSource);
    if (changes.isNotEmpty) _flow.setValues(changes);
  }

  // ------------------------------------------------------- collapse logic

  bool _identityComplete(Map<String, dynamic> v) =>
      v[SellKeys.brandId] != null &&
      v[SellKeys.modelId] != null &&
      v[SellKeys.year] is num &&
      v[SellKeys.mileage] is num;

  bool _identityHasError(Map<String, String> e) =>
      e.containsKey(SellKeys.brandId) || e.containsKey(SellKeys.year) || e.containsKey(SellKeys.mileage);

  /// Collapsing is driven by blur and by the pickers closing, never by typing,
  /// so the km field is never pulled away mid-keystroke.
  void _maybeCollapseIdentity() {
    if (!mounted || _identityPinnedOpen || _identityCollapsed) return;
    if (!_sectioned(_flow.state.category)) return;
    final s = _flow.state;
    if (_identityComplete(s.values) && !_identityHasError(s.errors)) {
      setState(() => _identityCollapsed = true);
    }
  }

  // --------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final state = context.watch<SellFlowCubit>().state;
    _keys.scrollToFirstError(context, state);
    final c = state.category;
    return ListView(
      controller: _keys.controller,
      // Builds off-screen fields so "Fix ›" can scroll to them. The sections
      // roughly halved the car form, so this no longer needs 4000.
      // ignore: deprecated_member_use
      cacheExtent: 2000,
      padding: const EdgeInsets.fromLTRB(SellTokens.gutter, 4, SellTokens.gutter, 32),
      children: [
        if (c == SellCategory.property)
          ..._property(state)
        else if (c == SellCategory.car)
          ..._car(state)
        else if (c == SellCategory.bike)
          ..._bike(state)
        else
          ..._legacyVehicle(state),
      ],
    );
  }

  // ------------------------------------------------------------------ car

  List<Widget> _car(SellFlowState s) {
    final cfg = s.config;
    final v = s.values;
    final e = s.errors;
    const gap = SizedBox(height: 18);

    final brand = v[SellKeys.brandName] as String?;
    final model = v[SellKeys.modelName] as String?;
    final km = v[SellKeys.mileage];
    final hasModel = v[SellKeys.modelId] != null;
    final collapsed = _identityCollapsed && !_identityHasError(e) && _identityComplete(v);

    return [
      SellSection(
        first: true,
        label: 'The car',
        collapsed: collapsed,
        summaryTitle: collapsed ? _identityHeadline(v) : null,
        summarySubtitle: km is num ? '${SellFormat.indianGroup(km)} km' : null,
        onExpand: () => setState(() {
          _identityCollapsed = false;
          _identityPinnedOpen = true;
        }),
        children: [
          _keys.wrap(SellKeys.brandId, Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SellLabel('Brand & model'),
              SellPickerField(
                onTap: _pickBrandModel,
                placeholder: 'Choose brand and model',
                action: brand != null ? 'Change' : null,
                error: e[SellKeys.brandId],
                value: brand == null
                    ? null
                    : Text.rich(
                        TextSpan(children: [
                          TextSpan(text: brand, style: const TextStyle(fontWeight: FontWeight.w600)),
                          if (model != null) TextSpan(text: ' · $model'),
                        ]),
                        style: SellTokens.body,
                        overflow: TextOverflow.ellipsis,
                      ),
              ),
            ],
          )),
          gap,
          _yearAndKm(v, e),
        ],
      ),
      if (!hasModel) ...[
        const SizedBox(height: 18),
        Divider(height: 1, thickness: 1, color: SellTokens.line),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Icon(Icons.circle_outlined, size: 15, color: SellTokens.muted),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                'Trim, fuel, transmission and colour appear once you’ve picked the model — most of them fill themselves in.',
                style: SellTokens.caption.copyWith(height: 1.45),
              ),
            ),
          ],
        ),
      ],
      if (hasModel) ...[
        SellSection(
          label: 'Trim & drivetrain',
          children: [
            ..._variantField(v),
            _keys.wrap(SellKeys.fuelTypeId, Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _fieldLabel('Fuel', fromVariant: v[SellKeys.fuelSource] as String?),
                cfg.fuelTypes.isEmpty
                    ? (cfg.isFallback ? const _LookupPending() : Text('No fuel options for this category.', style: SellTokens.caption))
                    : cfg.fuelTypes.length <= 3
                        ? SellSegmented<String>(
                            options: [for (final f in cfg.fuelTypes) SellOptionItem(f.id, f.label)],
                            selected: v[SellKeys.fuelTypeId] as String?,
                            onChanged: (x) => _flow.setValues({SellKeys.fuelTypeId: x, SellKeys.fuelSource: null}),
                            error: e[SellKeys.fuelTypeId],
                          )
                        : SellChips<String>(
                            options: [for (final f in cfg.fuelTypes) SellOptionItem(f.id, f.label)],
                            isSelected: (x) => v[SellKeys.fuelTypeId] == x,
                            onTap: (x) => _flow.setValues({SellKeys.fuelTypeId: x, SellKeys.fuelSource: null}),
                            error: e[SellKeys.fuelTypeId],
                          ),
              ],
            )),
            gap,
            _keys.wrap(SellKeys.transmissionTypeId, Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _fieldLabel('Transmission',
                    fromVariant: v[SellKeys.transmissionSource] as String?),
                cfg.transmissionTypes.isEmpty
                    ? (cfg.isFallback ? const _LookupPending() : Text('No transmission options for this category.', style: SellTokens.caption))
                    : cfg.transmissionTypes.length <= 3
                        ? SellSegmented<String>(
                            options: [for (final t in cfg.transmissionTypes) SellOptionItem(t.id, t.label)],
                            selected: v[SellKeys.transmissionTypeId] as String?,
                            onChanged: (x) => _flow.setValues({SellKeys.transmissionTypeId: x, SellKeys.transmissionSource: null}),
                            error: e[SellKeys.transmissionTypeId],
                          )
                        : SellChips<String>(
                            options: [for (final t in cfg.transmissionTypes) SellOptionItem(t.id, t.label)],
                            isSelected: (x) => v[SellKeys.transmissionTypeId] == x,
                            onTap: (x) => _flow.setValues({SellKeys.transmissionTypeId: x, SellKeys.transmissionSource: null}),
                            error: e[SellKeys.transmissionTypeId],
                          ),
              ],
            )),
          ],
        ),
        SellSection(
          label: 'Colour & condition',
          children: [
            _keys.wrap(SellKeys.color, SellColorField(
              controller: _color,
              focusNode: _colorFocus,
              palette: cfg.colors,
              variantColors: _variantColors,
              variantName: v[SellKeys.variantName] as String?,
              error: e[SellKeys.color],
              onChanged: (t) => _flow.setValue(SellKeys.color, t.trim().isEmpty ? null : t),
              onBlur: () => _flow.validateField(SellKeys.color),
            )),
            gap,
            _fieldLabel('Previous owners', trailing: 'optional'),
            SellChips<int>(
              options: const [
                SellOptionItem(1, '1st'),
                SellOptionItem(2, '2nd'),
                SellOptionItem(3, '3rd'),
                SellOptionItem(4, '4 or more'),
              ],
              isSelected: (x) => v[SellKeys.ownerCount] == x,
              onTap: (x) => _flow.setValue(SellKeys.ownerCount, v[SellKeys.ownerCount] == x ? null : x),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _moreDetailsToggle(open: 'Hide papers & features', closed: 'Papers & features'),
        if (_showMore) ...[
          const SizedBox(height: 8),
          _yesNo('Insurance valid', SellKeys.hasInsurance, v),
          const SizedBox(height: 14),
          _yesNo('RC book available', SellKeys.hasRcBook, v),
          const SizedBox(height: 18),
          const SellLabel('Features', trailing: 'optional'),
          _features(cfg, v),
        ],
      ],
    ];
  }

  String _identityHeadline(Map<String, dynamic> v) {
    final parts = [
      if (v[SellKeys.year] != null) '${v[SellKeys.year]}',
      if (v[SellKeys.brandName] != null) '${v[SellKeys.brandName]}',
      if (v[SellKeys.modelName] != null) '${v[SellKeys.modelName]}',
    ];
    if (parts.isNotEmpty) return parts.join(' ');
    return _flow.state.category == SellCategory.bike ? 'Your bike' : 'Your car';
  }

  Widget _yearAndKm(Map<String, dynamic> v, Map<String, String> e) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _keys.wrap(SellKeys.year, Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SellLabel('Year'),
              SellPickerField(
                onTap: _pickYear,
                placeholder: 'Year',
                error: e[SellKeys.year],
                value: v[SellKeys.year] == null ? null : Text('${v[SellKeys.year]}', style: SellTokens.body),
              ),
            ],
          )),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _keys.wrap(SellKeys.mileage, Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SellLabel('KM driven'),
              SellInput(
                controller: _km,
                hint: 'e.g. 42,500',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, _IndianGroupingFormatter()],
                error: e[SellKeys.mileage],
                textInputAction: TextInputAction.done,
                onChanged: (t) => _flow.setValue(SellKeys.mileage, SellFormat.parseDigits(t)),
                onBlur: () {
                  _flow.validateField(SellKeys.mileage);
                  _maybeCollapseIdentity();
                },
              ),
            ],
          )),
        ),
      ],
    );
  }

  /// Hidden when the catalogue has no variants for this model, so the section
  /// never shows an empty control.
  List<Widget> _variantField(Map<String, dynamic> v) {
    const gap = SizedBox(height: 18);
    final modelId = v[SellKeys.modelId] as String?;
    if (_variantsFailed) {
      return [
        _fieldLabel('Variant', trailing: 'optional'),
        Row(children: [
          Expanded(child: Text('Couldn’t load variants.', style: SellTokens.caption)),
          SellButton(
            label: 'Retry',
            kind: SellButtonKind.ghost,
            expand: false,
            onPressed: modelId == null ? null : () => _loadVariants(modelId),
          ),
        ]),
        gap,
      ];
    }
    if (_variants == null) {
      return [_fieldLabel('Variant', trailing: 'optional'), const _LookupPending(), gap];
    }
    final usable = _usableVariants;
    if (usable.isEmpty) return const [];

    final id = v[SellKeys.variantId] as String?;
    final chosen = (id != null && id.isNotEmpty) ? usable.where((x) => x.id == id).toList() : const <SellVariant>[];
    final notSure = id != null && id.isEmpty;

    Widget? value;
    if (chosen.isNotEmpty) {
      final x = chosen.first;
      value = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(x.displayName, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: SellTokens.body.copyWith(fontWeight: FontWeight.w600)),
          if (x.summary != x.displayName) ...[
            const SizedBox(height: 1),
            Text(
              [if (x.fuelLabel != null) x.fuelLabel!, x.spec].where((s) => s.isNotEmpty).join(' · '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: SellTokens.caption,
            ),
          ],
        ],
      );
    } else if (notSure) {
      value = Text('Not sure', style: SellTokens.body.copyWith(color: SellTokens.ink2));
    }

    return [
      _fieldLabel('Variant', trailing: 'optional'),
      SellPickerField(
        onTap: _pickVariant,
        placeholder: 'Choose a variant',
        action: value != null ? 'Change' : null,
        value: value,
      ),
      gap,
    ];
  }

  /// Label row that can carry either a hint ("optional") or the variant tag.
  Widget _fieldLabel(String text, {String? trailing, String? fromVariant}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(child: Text(text, style: SellTokens.label)),
          if (fromVariant != null && fromVariant.isNotEmpty)
            SellSourceTag(source: fromVariant)
          else if (trailing != null)
            Text(trailing, style: SellTokens.caption),
        ],
      ),
    );
  }

  /// A field the catalogue may already have settled.
  ///
  /// One possible value is a fact and is stated, with a quiet Change for the
  /// converted or imported bike that breaks the rule. Several is a real choice,
  /// narrowed to what this model is built with. Nothing known falls through to
  /// the category list.
  Widget _derivedField({
    required String label,
    required SellDerived derived,
    required String valueKey,
    required String sourceKey,
    required String? selected,
    required String? activeSource,
    required String? error,
    required List<SellOption> catalogue,
    required bool isFallback,
    required bool overridden,
    required VoidCallback onOverride,
    required String emptyMessage,
    String? trailing,
    String? helper,
    bool clearable = false,
  }) {
    if (catalogue.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _fieldLabel(label, trailing: trailing),
          isFallback
              ? const _LookupPending()
              : Text(emptyMessage, style: SellTokens.caption),
        ],
      );
    }

    if (derived.isFact && !overridden) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _fieldLabel(label, trailing: trailing),
          SellFactRow(
            value: derived.only!.label,
            source: derived.sourceLabel ?? 'the catalogue',
            onOverride: onOverride,
          ),
          SellFieldNote(error: error),
        ],
      );
    }

    final options = overridden ? catalogue : derived.options;
    void choose(String x) => _flow.setValues({
          valueKey: clearable && selected == x ? null : x,
          sourceKey: null,
        });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _fieldLabel(label, trailing: trailing, fromVariant: activeSource),
        if (!clearable && options.length <= 3)
          SellSegmented<String>(
            options: [for (final o in options) SellOptionItem(o.id, o.label)],
            selected: selected,
            onChanged: choose,
            error: error,
          )
        else
          SellChips<String>(
            options: [for (final o in options) SellOptionItem(o.id, o.label)],
            isSelected: (x) => selected == x,
            onTap: choose,
            error: error,
          ),
        if (helper != null) ...[
          const SizedBox(height: 5),
          Text(helper, style: SellTokens.caption),
        ],
      ],
    );
  }

  // ----------------------------------------------------------------- bike

  /// BIKE-1/2/3/5. Same narrowing as the car, with three differences the audit
  /// found: transmission is optional and never pre-filled, the variant section
  /// renames itself when the catalogue has no trims, and there is no
  /// commercial block.
  List<Widget> _bike(SellFlowState s) {
    final cfg = s.config;
    final v = s.values;
    final e = s.errors;
    const gap = SizedBox(height: 18);

    final brand = v[SellKeys.brandName] as String?;
    final model = v[SellKeys.modelName] as String?;
    final km = v[SellKeys.mileage];
    final hasModel = v[SellKeys.modelId] != null;
    final collapsed = _identityCollapsed && !_identityHasError(e) && _identityComplete(v);
    final variantRows = _variantField(v);
    final fuel = _derivedFuel(s);
    final gears = _derivedTransmission(s);

    return [
      SellSection(
        first: true,
        label: 'The bike',
        collapsed: collapsed,
        summaryTitle: collapsed ? _identityHeadline(v) : null,
        summarySubtitle: km is num ? '${SellFormat.indianGroup(km)} km' : null,
        onExpand: () => setState(() {
          _identityCollapsed = false;
          _identityPinnedOpen = true;
        }),
        children: [
          _keys.wrap(SellKeys.brandId, Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SellLabel('Brand & model'),
              SellPickerField(
                onTap: _pickBrandModel,
                placeholder: 'Choose brand and model',
                action: brand != null ? 'Change' : null,
                error: e[SellKeys.brandId],
                value: brand == null
                    ? null
                    : Text.rich(
                        TextSpan(children: [
                          TextSpan(text: brand, style: const TextStyle(fontWeight: FontWeight.w600)),
                          if (model != null) TextSpan(text: ' · $model'),
                        ]),
                        style: SellTokens.body,
                        overflow: TextOverflow.ellipsis,
                      ),
              ),
            ],
          )),
          gap,
          _yearAndKm(v, e),
        ],
      ),
      if (!hasModel) ...[
        const SizedBox(height: 18),
        Divider(height: 1, thickness: 1, color: SellTokens.line),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Icon(Icons.circle_outlined, size: 15, color: SellTokens.muted),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                'Fuel, gears and colour appear once you’ve picked the model.',
                style: SellTokens.caption.copyWith(height: 1.45),
              ),
            ),
          ],
        ),
      ],
      if (hasModel) ...[
        SellSection(
          // No trims in the catalogue for this model → the section says so by
          // its name instead of showing an empty control.
          label: variantRows.isEmpty ? 'Fuel & drive' : 'Variant & drive',
          children: [
            ...variantRows,
            _keys.wrap(SellKeys.fuelTypeId, _derivedField(
              label: 'Fuel',
              derived: fuel,
              valueKey: SellKeys.fuelTypeId,
              sourceKey: SellKeys.fuelSource,
              selected: v[SellKeys.fuelTypeId] as String?,
              activeSource: v[SellKeys.fuelSource] as String?,
              error: e[SellKeys.fuelTypeId],
              catalogue: cfg.fuelTypes,
              isFallback: cfg.isFallback,
              overridden: _fuelOverride,
              onOverride: () => setState(() => _fuelOverride = true),
              emptyMessage: 'No fuel options for this category.',
            )),
            gap,
            // Optional server-side for two-wheelers, and nothing guesses it any
            // more. Where the catalogue knows it — an Activa is gearless, a
            // Dominar is geared — it is stated rather than asked.
            _keys.wrap(SellKeys.transmissionTypeId, _derivedField(
              label: 'Gears',
              trailing: 'optional',
              derived: gears,
              valueKey: SellKeys.transmissionTypeId,
              sourceKey: SellKeys.transmissionSource,
              selected: v[SellKeys.transmissionTypeId] as String?,
              activeSource: v[SellKeys.transmissionSource] as String?,
              error: e[SellKeys.transmissionTypeId],
              catalogue: cfg.transmissionTypes,
              isFallback: cfg.isFallback,
              overridden: _gearsOverride,
              onOverride: () => setState(() => _gearsOverride = true),
              emptyMessage: 'No gearbox options for this category.',
              clearable: true,
              helper: 'Scooters are usually automatic. Leave it out if you’re not sure.',
            )),
          ],
        ),
        SellSection(
          label: 'Colour & condition',
          children: [
            _keys.wrap(SellKeys.color, SellColorField(
              controller: _color,
              focusNode: _colorFocus,
              palette: cfg.colors,
              variantColors: _variantColors,
              variantName: v[SellKeys.variantName] as String?,
              error: e[SellKeys.color],
              onChanged: (t) => _flow.setValue(SellKeys.color, t.trim().isEmpty ? null : t),
              onBlur: () => _flow.validateField(SellKeys.color),
            )),
            gap,
            _fieldLabel('Previous owners', trailing: 'optional'),
            SellChips<int>(
              options: const [
                SellOptionItem(1, '1st'),
                SellOptionItem(2, '2nd'),
                SellOptionItem(3, '3rd'),
                SellOptionItem(4, '4 or more'),
              ],
              isSelected: (x) => v[SellKeys.ownerCount] == x,
              onTap: (x) => _flow.setValue(SellKeys.ownerCount, v[SellKeys.ownerCount] == x ? null : x),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _moreDetailsToggle(open: 'Hide papers & features', closed: 'Papers & features'),
        if (_showMore) ...[
          const SizedBox(height: 8),
          _yesNo('Insurance valid', SellKeys.hasInsurance, v),
          const SizedBox(height: 14),
          _yesNo('RC book available', SellKeys.hasRcBook, v),
          const SizedBox(height: 18),
          const SellLabel('Features', trailing: 'optional'),
          _features(cfg, v),
        ],
      ],
    ];
  }

  // ------------------------------------------------ commercial (unchanged)

  List<Widget> _legacyVehicle(SellFlowState s) {
    final c = s.category;
    final cfg = s.config;
    final v = s.values;
    final e = s.errors;
    final gap = const SizedBox(height: 18);
    final brand = v[SellKeys.brandName] as String?;
    final model = v[SellKeys.modelName] as String?;

    return [
      if (c == SellCategory.commercial) ...[
        _keys.wrap(SellKeys.commercialType, Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SellLabel('Vehicle type'),
            cfg.commercialVehicleTypes.isEmpty && cfg.isFallback
                ? const _LookupPending()
                : SellChips<String>(
                    options: [for (final t in cfg.commercialVehicleTypes) SellOptionItem(t.name, t.label)],
                    isSelected: (x) => v[SellKeys.commercialType] == x,
                    onTap: (x) => _flow.setValue(SellKeys.commercialType, x),
                    error: e[SellKeys.commercialType],
                  ),
          ],
        )),
        gap,
      ],
      _keys.wrap(SellKeys.brandId, Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SellLabel('Brand & model'),
          SellPickerField(
            onTap: _pickBrandModel,
            placeholder: 'Choose brand and model',
            action: brand != null ? 'Change' : null,
            error: e[SellKeys.brandId],
            value: brand == null
                ? null
                : Text.rich(
                    TextSpan(children: [
                      TextSpan(text: brand, style: const TextStyle(fontWeight: FontWeight.w600)),
                      if (model != null) TextSpan(text: ' · $model'),
                    ]),
                    style: SellTokens.body,
                    overflow: TextOverflow.ellipsis,
                  ),
          ),
        ],
      )),
      if (c != SellCategory.bike && v[SellKeys.modelId] != null) ...[
        gap,
        const SellLabel('Variant', trailing: 'optional'),
        if (_variantsFailed)
          Row(children: [
            Expanded(child: Text('Couldn’t load variants.', style: SellTokens.caption)),
            SellButton(label: 'Retry', kind: SellButtonKind.ghost, expand: false, onPressed: () => _loadVariants(v[SellKeys.modelId] as String)),
          ])
        else if (_variants == null)
          const _LookupPending()
        else
          SellChips<String>(
            options: [
              for (final x in _variants!) SellOptionItem(x.id, x.displayName),
              const SellOptionItem('', 'Not sure'),
            ],
            isSelected: (id) => v[SellKeys.variantId] == id,
            onTap: (id) => _flow.setValues({
              SellKeys.variantId: id,
              SellKeys.variantName: id.isEmpty ? null : _variants!.firstWhere((x) => x.id == id).displayName,
            }),
          ),
      ],
      gap,
      _yearAndKm(v, e),
      gap,
      _keys.wrap(SellKeys.fuelTypeId, Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SellLabel('Fuel'),
          cfg.fuelTypes.isEmpty
              ? (cfg.isFallback ? const _LookupPending() : Text('No fuel options for this category.', style: SellTokens.caption))
              : SellChips<String>(
                  options: [for (final f in cfg.fuelTypes) SellOptionItem(f.id, f.label)],
                  isSelected: (x) => v[SellKeys.fuelTypeId] == x,
                  onTap: (x) => _flow.setValue(SellKeys.fuelTypeId, x),
                  error: e[SellKeys.fuelTypeId],
                ),
        ],
      )),
      gap,
      _keys.wrap(SellKeys.transmissionTypeId, Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SellLabel('Transmission'),
          cfg.transmissionTypes.isEmpty
              ? (cfg.isFallback ? const _LookupPending() : Text('No transmission options for this category.', style: SellTokens.caption))
              : cfg.transmissionTypes.length <= 3
                  ? SellSegmented<String>(
                      options: [for (final t in cfg.transmissionTypes) SellOptionItem(t.id, t.label)],
                      selected: v[SellKeys.transmissionTypeId] as String?,
                      onChanged: (x) => _flow.setValue(SellKeys.transmissionTypeId, x),
                      error: e[SellKeys.transmissionTypeId],
                    )
                  : SellChips<String>(
                      options: [for (final t in cfg.transmissionTypes) SellOptionItem(t.id, t.label)],
                      isSelected: (x) => v[SellKeys.transmissionTypeId] == x,
                      onTap: (x) => _flow.setValue(SellKeys.transmissionTypeId, x),
                      error: e[SellKeys.transmissionTypeId],
                    ),
        ],
      )),
      gap,
      _keys.wrap(SellKeys.color, Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SellLabel('Colour'),
          SellColorSwatches(
            colors: [for (final col in cfg.colors) (value: col.value, label: col.label, color: Color(col.argb))],
            selected: v[SellKeys.color] as String?,
            onChanged: (x) => _flow.setValue(SellKeys.color, x),
            error: e[SellKeys.color],
          ),
        ],
      )),
      gap,
      const SellLabel('Owner'),
      SellChips<int>(
        options: const [SellOptionItem(1, '1st'), SellOptionItem(2, '2nd'), SellOptionItem(3, '3rd'), SellOptionItem(4, '4+')],
        isSelected: (x) => v[SellKeys.ownerCount] == x,
        onTap: (x) => _flow.setValue(SellKeys.ownerCount, v[SellKeys.ownerCount] == x ? null : x),
      ),
      if (c == SellCategory.commercial) ...[
        gap,
        const SellLabel('Body type', trailing: 'optional'),
        SellChips<String>(
          options: [for (final b in cfg.bodyTypes) SellOptionItem(b.name, b.label)],
          isSelected: (x) => v[SellKeys.bodyType] == x,
          onTap: (x) => _flow.setValue(SellKeys.bodyType, v[SellKeys.bodyType] == x ? null : x),
        ),
        gap,
        _keys.wrap(SellKeys.payloadCapacity, Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SellLabel('Payload', trailing: 'optional'),
            SellInput(
              controller: _payload,
              hint: 'e.g. 1500',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
              error: e[SellKeys.payloadCapacity],
              onChanged: (t) => _flow.setValue(SellKeys.payloadCapacity, SellFormat.parseDecimal(t)),
              suffix: SizedBox(
                width: 132,
                child: SellSegmented<String>(
                  compact: true,
                  options: const [SellOptionItem('kg', 'kg'), SellOptionItem('tonne', 'tonne')],
                  selected: (v[SellKeys.payloadUnit] as String?) ?? 'kg',
                  onChanged: (x) => _flow.setValue(SellKeys.payloadUnit, x),
                ),
              ),
            ),
          ],
        )),
        gap,
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _keys.wrap(SellKeys.axleCount, Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SellLabel('Axles'),
                  SellStepper(
                    value: v[SellKeys.axleCount] as int?,
                    min: 1,
                    max: 10,
                    semanticLabel: 'Axles',
                    error: e[SellKeys.axleCount],
                    onChanged: (x) => _flow.setValue(SellKeys.axleCount, x),
                  ),
                ],
              )),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SellLabel('Seats'),
                  SellStepper(
                    value: v[SellKeys.seatingCapacity] as int?,
                    min: 1,
                    max: 80,
                    semanticLabel: 'Seats',
                    onChanged: (x) => _flow.setValue(SellKeys.seatingCapacity, x),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
      const SizedBox(height: 14),
      _moreDetailsToggle(),
      if (_showMore) ...[
        const SizedBox(height: 8),
        _yesNo('Insurance valid', SellKeys.hasInsurance, v),
        const SizedBox(height: 14),
        _yesNo('RC book available', SellKeys.hasRcBook, v),
        if (c == SellCategory.commercial) ...[
          const SizedBox(height: 14),
          _yesNo('Fitness certificate', SellKeys.hasFitness, v),
          const SizedBox(height: 14),
          _yesNo('Permit', SellKeys.hasPermit, v),
        ],
        const SizedBox(height: 18),
        const SellLabel('Features', trailing: 'optional'),
        _features(cfg, v),
      ],
    ];
  }

  Widget _moreDetailsToggle({String? open, String? closed}) {
    final label = _showMore
        ? (open ?? 'Hide extra details')
        : (closed ??
            (_flow.state.category == SellCategory.property
                ? 'Add more details (parking, amenities)'
                : 'Add more details (insurance, RC, features)'));
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: () => setState(() => _showMore = !_showMore),
        style: TextButton.styleFrom(foregroundColor: SellTokens.accentText, padding: EdgeInsets.zero, minimumSize: const Size(48, 44)),
        icon: Icon(_showMore ? Icons.remove_rounded : Icons.add_rounded, size: 18),
        label: Text(
          label,
          style: SellTokens.label.copyWith(color: SellTokens.accentText, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  Widget _yesNo(String label, String key, Map<String, dynamic> v) {
    return Row(
      children: [
        Expanded(child: Text(label, style: SellTokens.body.copyWith(fontSize: 14))),
        SizedBox(
          width: 150,
          child: SellSegmented<bool>(
            options: const [SellOptionItem(true, 'Yes'), SellOptionItem(false, 'No')],
            selected: v[key] as bool?,
            onChanged: (x) => _flow.setValue(key, v[key] == x ? null : x),
          ),
        ),
      ],
    );
  }

  Widget _features(SellConfig cfg, Map<String, dynamic> v) {
    final selected = List<String>.from((v[SellKeys.features] as List?) ?? const []);
    return SellChips<String>(
      multi: true,
      options: [for (final f in cfg.features) SellOptionItem(f, f)],
      isSelected: selected.contains,
      onTap: (f) {
        final next = [...selected];
        next.contains(f) ? next.remove(f) : next.add(f);
        _flow.setValue(SellKeys.features, next);
      },
    );
  }

  // ------------------------------------------------------------- property

  List<Widget> _property(SellFlowState s) {
    final cfg = s.config;
    final v = s.values;
    final e = s.errors;
    const gap = SizedBox(height: 18);
    final type = v[SellKeys.propertyType] as String?;
    final isPlot = type == 'plot';
    final residential = cfg.isResidential(type);

    Widget areaField(String label, String valueKey, String unitKey, TextEditingController ctrl, String defaultUnit) {
      final unit = (v[unitKey] as String?) ?? defaultUnit;
      final n = v[valueKey];
      final hint = (n is num && unit == 'cent') ? '≈ ${SellFormat.indianGroup(SellFormat.toSqft(n.toDouble(), 'cent'))} sqft' : null;
      return _keys.wrap(valueKey, Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SellLabel(label),
          SellInput(
            controller: ctrl,
            hint: unit == 'cent' ? 'e.g. 6.5' : 'e.g. 1,650',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
            textStyle: SellTokens.body.copyWith(fontWeight: FontWeight.w600),
            error: e[valueKey],
            helper: hint,
            onChanged: (t) => _flow.setValue(valueKey, SellFormat.parseDecimal(t)),
            onBlur: () => _flow.validateField(valueKey),
            suffix: SizedBox(
              width: 132,
              child: SellSegmented<String>(
                compact: true,
                options: const [SellOptionItem('sqft', 'sqft'), SellOptionItem('cent', 'cent')],
                selected: unit,
                onChanged: (x) => _flow.setValue(unitKey, x),
              ),
            ),
          ),
        ],
      ));
    }

    return [
      if (!isPlot) ...[
        SellSegmented<String>(
          options: const [SellOptionItem('sell', 'Sell'), SellOptionItem('rent', 'Rent')],
          selected: (v[SellKeys.listingType] as String?) ?? 'sell',
          onChanged: (x) => _flow.setValue(SellKeys.listingType, x),
        ),
        gap,
      ],
      _keys.wrap(SellKeys.propertyType, Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SellLabel('Type'),
          SellChips<String>(
            options: [for (final p in cfg.propertyTypes) SellOptionItem(p.value, p.label)],
            isSelected: (x) => type == x,
            onTap: (x) {
              final changes = <String, dynamic>{SellKeys.propertyType: x};
              if (!cfg.isResidential(x)) {
                changes[SellKeys.bedrooms] = null;
                changes[SellKeys.bathrooms] = null;
              }
              if (x == 'plot') changes[SellKeys.listingType] = 'sell';
              _flow.setValues(changes);
            },
            error: e[SellKeys.propertyType],
          ),
        ],
      )),
      if (type != null) ...[
        if (residential) ...[
          gap,
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _keys.wrap(SellKeys.bedrooms, Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SellLabel('Bedrooms'),
                    SellStepper(value: v[SellKeys.bedrooms] as int?, min: 0, max: 20, semanticLabel: 'Bedrooms', error: e[SellKeys.bedrooms],
                        onChanged: (x) => _flow.setValue(SellKeys.bedrooms, x)),
                  ],
                )),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _keys.wrap(SellKeys.bathrooms, Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SellLabel('Bathrooms'),
                    SellStepper(value: v[SellKeys.bathrooms] as int?, min: 0, max: 20, semanticLabel: 'Bathrooms', error: e[SellKeys.bathrooms],
                        onChanged: (x) => _flow.setValue(SellKeys.bathrooms, x)),
                  ],
                )),
              ),
            ],
          ),
        ],
        if (!isPlot) ...[
          gap,
          areaField('Built-up area', SellKeys.builtArea, SellKeys.builtUnit, _built, 'sqft'),
        ],
        gap,
        areaField(isPlot ? 'Plot area' : 'Land area', SellKeys.landArea, SellKeys.landUnit, _land, 'cent'),
        if (type == 'apartment') ...[
          gap,
          const SellLabel('Floor', trailing: 'optional'),
          SellStepper(value: v[SellKeys.floor] as int?, min: 0, max: 99, semanticLabel: 'Floor', onChanged: (x) => _flow.setValue(SellKeys.floor, x)),
        ],
        if (!isPlot) ...[
          gap,
          const SellLabel('Furnishing'),
          SellChips<String>(
            options: const [SellOptionItem('unfurnished', 'Unfurnished'), SellOptionItem('semi', 'Semi'), SellOptionItem('full', 'Full')],
            isSelected: (x) => v[SellKeys.furnishing] == x,
            onTap: (x) => _flow.setValue(SellKeys.furnishing, v[SellKeys.furnishing] == x ? null : x),
          ),
          const SizedBox(height: 14),
          _moreDetailsToggle(),
          if (_showMore) ...[
            const SizedBox(height: 8),
            _yesNo('Parking', SellKeys.hasParking, v),
            const SizedBox(height: 14),
            _yesNo('Garden', SellKeys.hasGarden, v),
            const SizedBox(height: 18),
            const SellLabel('Amenities', trailing: 'optional'),
            _features(cfg, v),
          ],
        ],
      ],
    ];
  }
}

class _LookupPending extends StatelessWidget {
  const _LookupPending();
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(
        4,
        (i) => Container(
          width: 64 + (i * 9.0),
          height: 40,
          decoration: BoxDecoration(color: SellTokens.input, borderRadius: BorderRadius.circular(SellTokens.rChip)),
        ),
      ),
    );
  }
}

/// Keeps "4,50,000"-style grouping while typing digits.
class _IndianGroupingFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return const TextEditingValue(text: '');
    final n = int.tryParse(digits);
    if (n == null) return oldValue;
    final text = SellFormat.indianGroup(n);
    return TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
  }
}

class IndianGroupingFormatter extends _IndianGroupingFormatter {}
