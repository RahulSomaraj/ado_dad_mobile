import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/sell_flow_cubit.dart';
import '../../domain/sell_category.dart';
import '../../domain/sell_format.dart';
import '../../domain/sell_models.dart';
import '../widgets/sell_pickers.dart';
import '../widgets/sell_ui.dart';
import 'details_step.dart' show IndianGroupingFormatter;
import 'step_scroll.dart';

/// W06 · W12 — Step 3: price, location, title, description.
class PricePlaceStep extends StatefulWidget {
  const PricePlaceStep({super.key});

  @override
  State<PricePlaceStep> createState() => _PricePlaceStepState();
}

class _PricePlaceStepState extends State<PricePlaceStep> {
  late final TextEditingController _price;
  late final TextEditingController _title;
  late final TextEditingController _description;
  final StepScrollKeys _keys = StepScrollKeys();
  StreamSubscription<SellFlowState>? _sub;

  SellFlowCubit get _flow => context.read<SellFlowCubit>();

  @override
  void initState() {
    super.initState();
    final v = _flow.state.values;
    final price = v[SellKeys.price];
    _price = TextEditingController(text: price is num ? SellFormat.indianGroup(price) : '');
    _title = TextEditingController(text: '${v[SellKeys.title] ?? ''}');
    _description = TextEditingController(text: '${v[SellKeys.description] ?? ''}');
    // Keep an untouched title in sync with the generated suggestion.
    _sub = _flow.stream.listen((st) {
      final title = '${st.values[SellKeys.title] ?? ''}';
      if (st.values[SellKeys.titleEdited] != true && _title.text != title) {
        _title.text = title;
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _price.dispose();
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickLocation() async {
    final picked = await showLocationSheet(context);
    if (picked == null || !mounted) return;
    _flow.setValues({
      SellKeys.location: picked.label,
      SellKeys.latitude: picked.latitude,
      SellKeys.longitude: picked.longitude,
    });
  }

  void _appendPrompt(String prompt) {
    final text = _description.text.trimRight();
    final next = text.isEmpty ? '$prompt: ' : '$text\n$prompt: ';
    _description.value = TextEditingValue(text: next, selection: TextSelection.collapsed(offset: next.length));
    _flow.setValue(SellKeys.description, next);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SellFlowCubit>().state;
    _keys.scrollToFirstError(context, s);
    final v = s.values;
    final e = s.errors;
    final l = s.config.limits;
    final price = v[SellKeys.price];
    final rent = s.category == SellCategory.property && v[SellKeys.listingType] == 'rent';

    final descLength = _description.text.trim().length;
    const gap = SizedBox(height: 18);
    final prompts = s.category == SellCategory.property
        ? const ['Nearby', 'Water source', 'Road access']
        : const ['Service history', 'Why selling', 'Tyres'];

    return ListView(
      controller: _keys.controller,
      // Builds off-screen fields so "Fix ›" can scroll to them.
      // ignore: deprecated_member_use
      cacheExtent: 4000,
      padding: const EdgeInsets.fromLTRB(SellTokens.gutter, 4, SellTokens.gutter, 32),
      children: [
        _keys.wrap(SellKeys.price, Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SellLabel(rent ? 'Monthly rent' : 'Price'),
            SellInput(
              controller: _price,
              hint: rent ? 'e.g. 18,000' : 'e.g. 4,50,000',
              keyboardType: TextInputType.number,
              textStyle: SellTokens.money,
              prefix: Text('₹', style: SellTokens.money.copyWith(color: SellTokens.muted)),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, IndianGroupingFormatter()],
              error: e[SellKeys.price],
              helper: price is num && price > 0 ? SellFormat.rupeesInWords(price.round()) : null,
              onChanged: (t) => _flow.setValue(SellKeys.price, SellFormat.parseDigits(t)),
              onBlur: () => _flow.validateField(SellKeys.price),
            ),
          ],
        )),
        gap,
        _keys.wrap(SellKeys.location, Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SellLabel('Location'),
            SellPickerField(
              onTap: _pickLocation,
              placeholder: 'Choose area',
              leading: Icon(Icons.place_outlined, size: 20, color: SellTokens.accent),
              action: v[SellKeys.location] != null ? 'Change' : null,
              error: e[SellKeys.location],
              value: v[SellKeys.location] == null
                  ? null
                  : Text('${v[SellKeys.location]}', style: SellTokens.body, overflow: TextOverflow.ellipsis),
            ),
            if (v[SellKeys.latitude] != null) ...[
              const SizedBox(height: 8),
              _MapPreview(onTap: _pickLocation),
            ],
          ],
        )),
        gap,
        _keys.wrap(SellKeys.title, Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SellLabel('Title', trailing: v[SellKeys.titleEdited] == true ? '${_title.text.trim().length} / ${l.titleMax}' : 'written for you'),
            SellInput(
              controller: _title,
              hint: 'e.g. 2019 Maruti Suzuki Swift VXi',
              maxLength: l.titleMax,
              error: e[SellKeys.title],
              textInputAction: TextInputAction.next,
              onChanged: (t) => _flow.setValues({SellKeys.title: t, SellKeys.titleEdited: t.trim().isNotEmpty}),
              onBlur: () => _flow.validateField(SellKeys.title),
            ),
          ],
        )),
        gap,
        _keys.wrap(SellKeys.description, Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SellLabel('Description', trailing: '$descLength / ${l.descriptionMax}'),
            SellInput(
              controller: _description,
              hint: s.category == SellCategory.property
                  ? 'Tell buyers about the road, water, nearby schools…'
                  : 'Tell buyers about service history, tyres, why you’re selling',
              maxLines: 8,
              minLines: 4,
              maxLength: l.descriptionMax,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              error: e[SellKeys.description],
              onChanged: (t) => _flow.setValue(SellKeys.description, t),
              onBlur: () => _flow.validateField(SellKeys.description),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final p in prompts)
                  SellChip(label: '＋ $p', selected: false, onTap: () => _appendPrompt(p)),
              ],
            ),
          ],
        )),
      ],
    );
  }
}

class _MapPreview extends StatelessWidget {
  const _MapPreview({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Change location on map',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 96,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(SellTokens.rInput),
            border: Border.all(color: SellTokens.line),
          ),
          clipBehavior: Clip.antiAlias,
          child: CustomPaint(
            painter: _GridPainter(line: SellTokens.line, fill: SellTokens.input),
            child: Center(
              child: Icon(Icons.location_on_rounded, size: 30, color: SellTokens.accent),
            ),
          ),
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  _GridPainter({required this.line, required this.fill});
  final Color line;
  final Color fill;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = fill);
    final p = Paint()
      ..color = line
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 18) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (double y = 0; y < size.height; y += 18) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
    final road = Paint()
      ..color = line.withValues(alpha: 1)
      ..strokeWidth = 6;
    canvas.drawLine(Offset(0, size.height * 0.7), Offset(size.width, size.height * 0.35), road);
  }

  @override
  bool shouldRepaint(covariant _GridPainter old) => old.line != line || old.fill != fill;
}
