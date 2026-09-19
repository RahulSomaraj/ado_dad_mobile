import 'package:flutter/material.dart';

import '../../domain/sell_variant.dart';
import 'sell_ui.dart';

/// What the sheet returns. [variant] is null for "I'm not sure", which the
/// payload sends as no `variantId` at all.
class VariantChoice {
  const VariantChoice(this.variant);
  final SellVariant? variant;
}

/// CAR-3: the variant chip wall becomes a searchable, fuel-grouped sheet.
///
/// Every subtitle here — transmission, engine, seats — is already in the list
/// response, so this costs no extra call.
Future<VariantChoice?> showVariantSheet(
  BuildContext context, {
  required String modelName,
  required List<SellVariant> variants,
  String? selectedId,
}) {
  return showSellSheet<VariantChoice>(
    context,
    (ctx) => SizedBox(
      height: MediaQuery.of(ctx).size.height * 0.72,
      child: _VariantPicker(
        modelName: modelName,
        variants: variants,
        selectedId: selectedId,
      ),
    ),
  );
}

class _VariantPicker extends StatefulWidget {
  const _VariantPicker({
    required this.modelName,
    required this.variants,
    this.selectedId,
  });

  final String modelName;
  final List<SellVariant> variants;
  final String? selectedId;

  @override
  State<_VariantPicker> createState() => _VariantPickerState();
}

class _VariantPickerState extends State<_VariantPicker> {
  final TextEditingController _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<SellVariant> get _filtered {
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return widget.variants;
    return widget.variants
        .where((v) =>
            v.displayName.toLowerCase().contains(q) ||
            v.name.toLowerCase().contains(q) ||
            (v.fuelLabel ?? '').toLowerCase().contains(q) ||
            (v.transmissionLabel ?? '').toLowerCase().contains(q))
        .toList();
  }

  /// Groups in first-seen order, which is price order from the repository.
  Map<String, List<SellVariant>> _grouped(List<SellVariant> list) {
    final out = <String, List<SellVariant>>{};
    for (final v in list) {
      out.putIfAbsent(v.fuelGroup, () => <SellVariant>[]).add(v);
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final list = _filtered;
    final groups = _grouped(list);
    final showSearch = widget.variants.length > 6;
    final count = widget.variants.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Which variant?', style: SellTokens.heading),
                  const SizedBox(height: 2),
                  Text(
                    '${widget.modelName} · $count variant${count == 1 ? '' : 's'}',
                    style: SellTokens.caption,
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Close',
              onPressed: () => Navigator.of(context).pop(),
              icon: Icon(Icons.close_rounded, color: SellTokens.ink, size: 20),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (showSearch) ...[
          SellInput(
            controller: _search,
            hint: 'Search VXi, ZXi, CNG…',
            prefix: Icon(Icons.search_rounded, color: SellTokens.muted, size: 20),
            textInputAction: TextInputAction.search,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 6),
        ],
        Expanded(
          child: list.isEmpty
              ? Center(
                  child: Text(
                    'No variant matches “${_search.text.trim()}”.',
                    textAlign: TextAlign.center,
                    style: SellTokens.body.copyWith(color: SellTokens.muted),
                  ),
                )
              : ListView(
                  children: [
                    for (final entry in groups.entries) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
                        child: Text(
                          entry.key.toUpperCase(),
                          style: SellTokens.caption.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      for (final v in entry.value) _row(v),
                    ],
                    const SizedBox(height: 8),
                  ],
                ),
        ),
        const SizedBox(height: 8),
        SellButton(
          label: 'I’m not sure',
          kind: SellButtonKind.tonal,
          onPressed: () => Navigator.of(context).pop(const VariantChoice(null)),
        ),
      ],
    );
  }

  Widget _row(SellVariant v) {
    final selected = v.id == widget.selectedId;
    final spec = v.spec;
    return Semantics(
      button: true,
      selected: selected,
      label: '${v.displayName}${spec.isEmpty ? '' : ', $spec'}',
      excludeSemantics: true,
      child: Material(
        color: selected ? SellTokens.soft : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SellTokens.rTile),
          side: BorderSide(
            color: selected ? SellTokens.accent : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: InkWell(
          onTap: () => Navigator.of(context).pop(VariantChoice(v)),
          borderRadius: BorderRadius.circular(SellTokens.rTile),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 52),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          v.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: SellTokens.body.copyWith(
                            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                        if (spec.isNotEmpty) ...[
                          const SizedBox(height: 1),
                          Text(
                            spec,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: SellTokens.caption.copyWith(
                              color: selected ? SellTokens.accentText : SellTokens.muted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (selected)
                    Icon(Icons.check_rounded, size: 20, color: SellTokens.accent),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
