import 'package:ado_dad_user/models/advertisement_post_model/vehicle_variant_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/sell_flow_cubit.dart';
import '../../data/sell_repository.dart';
import '../../domain/sell_category.dart';
import '../../domain/sell_config.dart';
import '../../domain/sell_format.dart';
import '../../domain/sell_models.dart';
import '../widgets/sell_pickers.dart';
import '../widgets/sell_ui.dart';
import 'step_scroll.dart';

/// W04 · W05 · W15 — Step 2, rendered per category from the same controls.
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
  final StepScrollKeys _keys = StepScrollKeys();

  List<VehicleVariant>? _variants;
  bool _variantsFailed = false;
  String? _variantsFor;
  bool _showMore = false;

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
    _showMore = [SellKeys.hasInsurance, SellKeys.hasRcBook, SellKeys.hasFitness, SellKeys.hasPermit]
            .any((k) => v[k] != null) ||
        ((v[SellKeys.features] as List?)?.isNotEmpty ?? false);
    final modelId = v[SellKeys.modelId] as String?;
    if (modelId != null && _flow.state.category != SellCategory.bike) _loadVariants(modelId, fromInit: true);
  }

  @override
  void dispose() {
    _km.dispose();
    _payload.dispose();
    _built.dispose();
    _land.dispose();
    super.dispose();
  }

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
    } catch (_) {
      if (!mounted || _variantsFor != modelId) return;
      setState(() => _variantsFailed = true);
    }
  }

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
    });
    if (_flow.state.category != SellCategory.bike) _loadVariants(result.model.id);
  }

  Future<void> _pickYear() async {
    final l = _flow.state.config.limits;
    final picked = await showYearSheet(context, min: l.yearMin, max: l.yearMax, selected: _flow.state.values[SellKeys.year] as int?);
    if (picked != null) _flow.setValue(SellKeys.year, picked);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<SellFlowCubit>().state;
    _keys.scrollToFirstError(context, state);
    final c = state.category;
    return ListView(
      controller: _keys.controller,
      // Builds off-screen fields so "Fix ›" can scroll to them.
      // ignore: deprecated_member_use
      cacheExtent: 4000,
      padding: const EdgeInsets.fromLTRB(SellTokens.gutter, 4, SellTokens.gutter, 32),
      children: [
        if (c == SellCategory.property) ..._property(state) else ..._vehicle(state),
      ],
    );
  }

  // ------------------------------------------------------------- vehicles

  List<Widget> _vehicle(SellFlowState s) {
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
              for (final x in _variants!) SellOptionItem(x.id, x.name),
              const SellOptionItem('', 'Not sure'),
            ],
            isSelected: (id) => v[SellKeys.variantId] == id,
            onTap: (id) => _flow.setValues({
              SellKeys.variantId: id,
              SellKeys.variantName: id.isEmpty ? null : _variants!.firstWhere((x) => x.id == id).name,
            }),
          ),
      ],
      gap,
      Row(
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
                  onBlur: () => _flow.validateField(SellKeys.mileage),
                ),
              ],
            )),
          ),
        ],
      ),
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

  Widget _moreDetailsToggle() {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: () => setState(() => _showMore = !_showMore),
        style: TextButton.styleFrom(foregroundColor: SellTokens.accentText, padding: EdgeInsets.zero, minimumSize: const Size(48, 44)),
        icon: Icon(_showMore ? Icons.remove_rounded : Icons.add_rounded, size: 18),
        label: Text(
          _showMore
              ? 'Hide extra details'
              : _flow.state.category == SellCategory.property
                  ? 'Add more details (parking, amenities)'
                  : 'Add more details (insurance, RC, features)',
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
