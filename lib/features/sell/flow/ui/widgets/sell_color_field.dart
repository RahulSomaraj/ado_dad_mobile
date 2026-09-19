import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/sell_color_match.dart';
import '../../domain/sell_config.dart';
import 'sell_ui.dart';

/// CAR-4: colour as a typed field with a live swatch.
///
/// `vehicle.color` is a free string (≤ 40 chars, no enum), so the control is
/// too. The ten-swatch grid was a constraint the backend never imposed, and it
/// could not express "Pearl Arctic White" or "Nexa Aurora".
///
/// Suggestions merge the chosen variant's own `colors[]` with the palette from
/// `GET /v2/sell/config`; the swatch fills in whenever the text resolves to one
/// of the config's hexes, and stays a dashed ring when it does not.
class SellColorField extends StatefulWidget {
  const SellColorField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.palette,
    required this.onChanged,
    this.variantColors = const [],
    this.variantName,
    this.label = 'Colour',
    this.error,
    this.onBlur,
    this.maxLength = 40,
  });

  final TextEditingController controller;
  final FocusNode focusNode;

  /// `config.colors` — the only source of hexes in the app.
  final List<SellColor> palette;

  /// `VehicleVariant.colors[]` for the chosen variant, if any.
  final List<String> variantColors;
  final String? variantName;

  final String label;
  final String? error;
  final ValueChanged<String> onChanged;
  final VoidCallback? onBlur;

  /// Mirrors the server's `color.length > 40` rule.
  final int maxLength;

  @override
  State<SellColorField> createState() => _SellColorFieldState();
}

class _ColorSuggestion {
  const _ColorSuggestion(this.label, this.swatch, this.source);
  final String label;
  final SellColor? swatch;

  /// Variant name when the colour came from the catalogue, else null.
  final String? source;
}

class _SellColorFieldState extends State<SellColorField> {
  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocus);
    widget.controller.addListener(_onText);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocus);
    widget.controller.removeListener(_onText);
    super.dispose();
  }

  void _onFocus() {
    if (mounted) setState(() {});
  }

  void _onText() {
    if (mounted) setState(() {});
  }

  String get _text => widget.controller.text;

  List<_ColorSuggestion> get _all {
    final out = <_ColorSuggestion>[];
    final seen = <String>{};
    String key(String s) => s.toLowerCase().trim();

    for (final name in widget.variantColors) {
      if (name.isEmpty || !seen.add(key(name))) continue;
      out.add(_ColorSuggestion(
        name,
        SellColorMatch.match(name, widget.palette),
        widget.variantName,
      ));
    }
    for (final c in widget.palette) {
      if (!seen.add(key(c.label))) continue;
      out.add(_ColorSuggestion(c.label, c, null));
    }
    return out;
  }

  List<_ColorSuggestion> get _filtered {
    final q = _text.trim().toLowerCase();
    final all = _all;
    if (q.isEmpty) return all;
    return all.where((s) => s.label.toLowerCase().contains(q)).toList();
  }

  void _choose(String label) {
    widget.controller.value = TextEditingValue(
      text: label,
      selection: TextSelection.collapsed(offset: label.length),
    );
    widget.onChanged(label);
    widget.focusNode.unfocus();
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    final trimmed = _text.trim();
    final matched = SellColorMatch.match(trimmed, widget.palette);
    final focused = widget.focusNode.hasFocus;
    final suggestions = _filtered.take(5).toList();
    final exact = suggestions.any((s) => s.label.toLowerCase() == trimmed.toLowerCase());
    final showList = focused && (suggestions.isNotEmpty || trimmed.isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SellLabel(
          widget.label,
          trailing: trimmed.isEmpty ? null : '${trimmed.length} / ${widget.maxLength}',
        ),
        SellInput(
          controller: widget.controller,
          focusNode: widget.focusNode,
          hint: 'Type or pick a colour',
          error: widget.error,
          helper: widget.error == null && trimmed.isNotEmpty && matched == null
              ? 'Saved as typed'
              : null,
          maxLength: widget.maxLength,
          textInputAction: TextInputAction.done,
          semanticLabel: widget.label,
          onChanged: widget.onChanged,
          onBlur: widget.onBlur,
          prefix: _Swatch(color: matched, empty: trimmed.isEmpty),
          suffix: trimmed.isEmpty
              ? null
              : Semantics(
                  button: true,
                  label: 'Clear colour',
                  child: IconButton(
                    onPressed: () {
                      widget.controller.clear();
                      widget.onChanged('');
                    },
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    padding: EdgeInsets.zero,
                    icon: Icon(Icons.cancel_rounded, size: 18, color: SellTokens.muted),
                  ),
                ),
        ),
        if (showList) ...[
          const SizedBox(height: 8),
          _SuggestionList(
            suggestions: suggestions,
            typed: exact ? null : trimmed,
            onChoose: _choose,
          ),
        ] else if (!focused) ...[
          const SizedBox(height: 10),
          _QuickPicks(
            suggestions: _all.where((s) => s.label.toLowerCase() != trimmed.toLowerCase()).take(6).toList(),
            onChoose: _choose,
          ),
        ],
      ],
    );
  }
}

/// 24 px circle: filled when the name resolved to a config hex, a dashed ring
/// when it did not. A colour is never invented for an unmatched name.
class _Swatch extends StatelessWidget {
  const _Swatch({required this.color, required this.empty});
  final SellColor? color;
  final bool empty;

  @override
  Widget build(BuildContext context) {
    if (color == null) {
      return SizedBox(
        width: 24,
        height: 24,
        child: CustomPaint(
          painter: _DashedRingPainter(SellTokens.muted.withValues(alpha: 0.55)),
          child: empty
              ? Center(
                  child: Text(
                    '?',
                    style: SellTokens.caption.copyWith(
                      fontSize: 11,
                      color: SellTokens.muted,
                      height: 1,
                    ),
                  ),
                )
              : null,
        ),
      );
    }
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: Color(color!.argb),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black.withValues(alpha: 0.18)),
      ),
    );
  }
}

class _DashedRingPainter extends CustomPainter {
  _DashedRingPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    final radius = (math.min(size.width, size.height) / 2) - 1;
    final center = Offset(size.width / 2, size.height / 2);
    const segments = 10;
    const sweep = (2 * math.pi) / segments;
    for (var i = 0; i < segments; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        i * sweep,
        sweep * 0.55,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRingPainter old) => old.color != color;
}

class _SuggestionList extends StatelessWidget {
  const _SuggestionList({
    required this.suggestions,
    required this.typed,
    required this.onChoose,
  });

  final List<_ColorSuggestion> suggestions;

  /// Non-null when the typed text is not already one of [suggestions].
  final String? typed;
  final ValueChanged<String> onChoose;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (final s in suggestions) {
      if (rows.isNotEmpty) rows.add(Divider(height: 1, color: SellTokens.line.withValues(alpha: 0.6)));
      rows.add(_row(
        label: s.label,
        swatch: s.swatch,
        tag: s.source,
        onTap: () => onChoose(s.label),
      ));
    }
    if (typed != null && typed!.isNotEmpty) {
      if (rows.isNotEmpty) rows.add(Divider(height: 1, color: SellTokens.line.withValues(alpha: 0.6)));
      rows.add(_row(
        label: 'Use “$typed” as typed',
        swatch: null,
        tag: null,
        muted: true,
        onTap: () => onChoose(typed!),
      ));
    }
    if (rows.isEmpty) return const SizedBox.shrink();
    return Container(
      decoration: BoxDecoration(
        color: SellTokens.surface,
        borderRadius: BorderRadius.circular(SellTokens.rInput),
        border: Border.all(color: SellTokens.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(mainAxisSize: MainAxisSize.min, children: rows),
    );
  }

  Widget _row({
    required String label,
    required SellColor? swatch,
    required String? tag,
    required VoidCallback onTap,
    bool muted = false,
  }) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 46),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: swatch == null
                      ? CustomPaint(painter: _DashedRingPainter(SellTokens.muted.withValues(alpha: 0.5)))
                      : Container(
                          decoration: BoxDecoration(
                            color: Color(swatch.argb),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.black.withValues(alpha: 0.18)),
                          ),
                        ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SellTokens.body.copyWith(
                      fontSize: 14,
                      color: muted ? SellTokens.ink2 : SellTokens.ink,
                    ),
                  ),
                ),
                if (tag != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: SellTokens.okBg,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      tag,
                      style: SellTokens.caption.copyWith(
                        fontSize: 10,
                        height: 1.2,
                        fontWeight: FontWeight.w600,
                        color: SellTokens.okFg,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Horizontal pills under the field. Scrolls rather than wraps, so the field's
/// height never changes as suggestions come and go.
class _QuickPicks extends StatelessWidget {
  const _QuickPicks({required this.suggestions, required this.onChoose});
  final List<_ColorSuggestion> suggestions;
  final ValueChanged<String> onChoose;

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: suggestions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final s = suggestions[i];
          return Semantics(
            button: true,
            label: s.label,
            excludeSemantics: true,
            child: Material(
              color: SellTokens.input,
              borderRadius: BorderRadius.circular(999),
              child: InkWell(
                onTap: () => onChoose(s.label),
                borderRadius: BorderRadius.circular(999),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 11),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: s.swatch == null
                            ? CustomPaint(painter: _DashedRingPainter(SellTokens.muted.withValues(alpha: 0.5)))
                            : Container(
                                decoration: BoxDecoration(
                                  color: Color(s.swatch!.argb),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.black.withValues(alpha: 0.18)),
                                ),
                              ),
                      ),
                      const SizedBox(width: 7),
                      Text(
                        s.label,
                        style: SellTokens.label.copyWith(color: SellTokens.ink, fontWeight: FontWeight.w400),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
