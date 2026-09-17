import 'dart:io';

import 'package:ado_dad_user/common/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Sell-flow tokens (CREATE-05). Built on AppColors so light/dark follow the
/// app theme; only the states AppColors lacks are defined here.
class SellTokens {
  SellTokens._();

  static const Color brand = Color(0xFF4F48EC);
  static Color get accent => AppColors.isDark ? const Color(0xFF8C87FF) : brand;
  static Color get accentText => AppColors.isDark ? const Color(0xFFA9A5FF) : const Color(0xFF3E37D6);
  static Color get soft => AppColors.primarySoft;
  static Color get bg => AppColors.scaffoldBackground;
  static Color get surface => AppColors.whiteColor;
  static Color get input => AppColors.chipFill;
  static Color get line => AppColors.dividerColor;
  static Color get ink => AppColors.blackColor;
  static Color get ink2 => AppColors.isDark ? const Color(0xFFC2C7D0) : const Color(0xFF424242);
  static Color get muted => AppColors.textMuted;
  static Color get track => AppColors.isDark ? const Color(0xFF2F3442) : const Color(0xFFDCDDEA);
  static Color get disabledBrand => AppColors.isDark ? const Color(0xFF3A3870) : const Color(0xFFC9C8F5);

  static Color get errorText => AppColors.isDark ? const Color(0xFFFF8A80) : const Color(0xFFC62828);
  static Color get errorBorder => AppColors.isDark ? const Color(0xFFFF8A80) : const Color(0xFFD93838);
  static Color get errorFill => AppColors.isDark ? const Color(0xFF3A1D1D) : const Color(0xFFFFF6F6);
  static Color get okText => AppColors.positiveText;

  static Color get infoBg => soft;
  static Color get infoFg => AppColors.isDark ? const Color(0xFFC9C6FF) : const Color(0xFF2F29A8);
  static Color get warnBg => AppColors.isDark ? const Color(0xFF3A2A14) : const Color(0xFFFFF1E0);
  static Color get warnFg => AppColors.isDark ? const Color(0xFFFFB35C) : const Color(0xFF8A4B00);
  static Color get errBg => AppColors.isDark ? const Color(0xFF3A1D1D) : const Color(0xFFFDECEC);
  static Color get errFg => AppColors.isDark ? const Color(0xFFFF8A80) : const Color(0xFF9B1C1C);
  static Color get okBg => AppColors.isDark ? const Color(0xFF153428) : const Color(0xFFE3F4EC);
  static Color get okFg => AppColors.isDark ? const Color(0xFF5FD3A2) : const Color(0xFF0D6446);

  static const double gutter = 16;
  static const double rChip = 8;
  static const double rInput = 12;
  static const double rButton = 12;
  static const double rCard = 16;
  static const double rSheet = 20;
  static const double rTile = 12;

  static const Duration fast = Duration(milliseconds: 120);
  static const Duration step = Duration(milliseconds: 250);

  static TextStyle _p(double size, FontWeight w, Color c, {double? height}) =>
      GoogleFonts.poppins(fontSize: size, fontWeight: w, color: c, height: height);

  static TextStyle get display => _p(24, FontWeight.w600, ink, height: 32 / 24);
  static TextStyle get heading => _p(18, FontWeight.w600, ink, height: 26 / 18);
  static TextStyle get title => _p(16, FontWeight.w600, ink, height: 24 / 16)
      .copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
  static TextStyle get body => _p(15, FontWeight.w400, ink, height: 22 / 15);
  static TextStyle get label => _p(13, FontWeight.w500, ink2, height: 18 / 13);
  static TextStyle get caption => _p(12, FontWeight.w400, muted, height: 16 / 12);
  static TextStyle get button => _p(15, FontWeight.w600, Colors.white);
  static TextStyle get money => _p(22, FontWeight.w600, ink)
      .copyWith(fontFeatures: const [FontFeature.tabularFigures()]);

  static bool reduceMotion(BuildContext context) =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;
}

/// "Brand & model" … "optional"
class SellLabel extends StatelessWidget {
  const SellLabel(this.text, {super.key, this.trailing});
  final String text;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(child: Text(text, style: SellTokens.label)),
          if (trailing != null) Text(trailing!, style: SellTokens.caption),
        ],
      ),
    );
  }
}

/// Error / success / hint line under a field.
class SellFieldNote extends StatelessWidget {
  const SellFieldNote({super.key, this.error, this.ok, this.hint});
  final String? error;
  final String? ok;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final String? text = error ?? ok ?? hint;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 150),
      child: text == null
          ? const SizedBox.shrink()
          : Padding(
              key: ValueKey('${error != null}$text'),
              padding: const EdgeInsets.only(top: 5),
              child: Text(
                error != null ? text : (ok != null ? '✓ $text' : text),
                style: SellTokens.caption.copyWith(
                  color: error != null
                      ? SellTokens.errorText
                      : ok != null
                          ? SellTokens.okText
                          : SellTokens.muted,
                  fontWeight: error != null || ok != null ? FontWeight.w500 : FontWeight.w400,
                ),
              ),
            ),
    );
  }
}

/// Filled input: fill → white + primary border + halo on focus → red on error.
class SellInput extends StatefulWidget {
  const SellInput({
    super.key,
    this.controller,
    this.hint,
    this.error,
    this.helper,
    this.ok,
    this.keyboardType,
    this.inputFormatters,
    this.prefix,
    this.suffix,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.onChanged,
    this.onBlur,
    this.textStyle,
    this.textInputAction,
    this.enabled = true,
    this.semanticLabel,
  });

  final TextEditingController? controller;
  final String? hint;
  final String? error;
  final String? helper;
  final String? ok;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? prefix;
  final Widget? suffix;
  final int maxLines;
  final int? minLines;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onBlur;
  final TextStyle? textStyle;
  final TextInputAction? textInputAction;
  final bool enabled;
  final String? semanticLabel;

  @override
  State<SellInput> createState() => _SellInputState();
}

class _SellInputState extends State<SellInput> {
  final FocusNode _focus = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (_focused == _focus.hasFocus) return;
      setState(() => _focused = _focus.hasFocus);
      if (!_focus.hasFocus) widget.onBlur?.call();
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.error != null;
    final border = hasError
        ? SellTokens.errorBorder
        : _focused
            ? SellTokens.accent
            : Colors.transparent;
    final fill = hasError
        ? SellTokens.errorFill
        : _focused
            ? SellTokens.surface
            : SellTokens.input;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnimatedContainer(
          duration: SellTokens.fast,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(SellTokens.rInput),
            border: Border.all(color: border),
            boxShadow: _focused && !hasError
                ? [BoxShadow(color: SellTokens.soft, spreadRadius: 3)]
                : const [],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            crossAxisAlignment: widget.maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
            children: [
              if (widget.prefix != null)
                Padding(padding: const EdgeInsets.only(right: 6), child: widget.prefix),
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focus,
                  enabled: widget.enabled,
                  keyboardType: widget.keyboardType,
                  inputFormatters: widget.inputFormatters,
                  maxLines: widget.maxLines,
                  minLines: widget.minLines,
                  maxLength: widget.maxLength,
                  textInputAction: widget.textInputAction,
                  onChanged: widget.onChanged,
                  onSubmitted: (_) => widget.onBlur?.call(),
                  style: widget.textStyle ?? SellTokens.body,
                  cursorColor: SellTokens.accent,
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    counterText: '',
                    hintText: widget.hint,
                    hintStyle: SellTokens.body.copyWith(color: SellTokens.muted),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              if (widget.suffix != null)
                Padding(padding: const EdgeInsets.only(left: 6), child: widget.suffix),
            ],
          ),
        ),
        SellFieldNote(error: widget.error, ok: widget.ok, hint: widget.helper),
      ],
    );
  }
}

/// Read-only row that opens a picker ("2019 ▾", "Maruti Suzuki · Swift  Change").
class SellPickerField extends StatelessWidget {
  const SellPickerField({
    super.key,
    required this.onTap,
    this.value,
    this.placeholder = 'Choose',
    this.action,
    this.error,
    this.leading,
  });

  final VoidCallback? onTap;
  final Widget? value;
  final String placeholder;
  final String? action;
  final String? error;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final hasError = error != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: hasError ? SellTokens.errorFill : SellTokens.input,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(SellTokens.rInput),
            side: BorderSide(color: hasError ? SellTokens.errorBorder : Colors.transparent),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(SellTokens.rInput),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 50),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Row(
                  children: [
                    if (leading != null) Padding(padding: const EdgeInsets.only(right: 8), child: leading),
                    Expanded(
                      child: value ??
                          Text(placeholder, style: SellTokens.body.copyWith(color: SellTokens.muted)),
                    ),
                    if (action != null)
                      Text(action!, style: SellTokens.label.copyWith(color: SellTokens.accentText, fontWeight: FontWeight.w600))
                    else
                      Icon(Icons.keyboard_arrow_down_rounded, color: SellTokens.muted),
                  ],
                ),
              ),
            ),
          ),
        ),
        SellFieldNote(error: error),
      ],
    );
  }
}

class SellOptionItem<T> {
  const SellOptionItem(this.value, this.label);
  final T value;
  final String label;
}

/// Wrap of selectable chips; single or multi select.
class SellChips<T> extends StatelessWidget {
  const SellChips({
    super.key,
    required this.options,
    required this.isSelected,
    required this.onTap,
    this.error,
    this.multi = false,
  });

  final List<SellOptionItem<T>> options;
  final bool Function(T value) isSelected;
  final ValueChanged<T> onTap;
  final String? error;
  final bool multi;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final o in options)
              SellChip(
                label: o.label,
                selected: isSelected(o.value),
                showCheck: multi,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onTap(o.value);
                },
              ),
          ],
        ),
        SellFieldNote(error: error),
      ],
    );
  }
}

class SellChip extends StatefulWidget {
  const SellChip({super.key, required this.label, required this.selected, required this.onTap, this.showCheck = false, this.icon});
  final String label;
  final bool selected;
  final bool showCheck;
  final IconData? icon;
  final VoidCallback onTap;

  @override
  State<SellChip> createState() => _SellChipState();
}

class _SellChipState extends State<SellChip> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final sel = widget.selected;
    return Semantics(
      button: true,
      selected: sel,
      label: widget.label,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _down && !SellTokens.reduceMotion(context) ? 0.96 : 1,
          duration: SellTokens.fast,
          child: AnimatedContainer(
            duration: SellTokens.fast,
            constraints: const BoxConstraints(minHeight: 40),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: sel ? SellTokens.soft : SellTokens.surface,
              borderRadius: BorderRadius.circular(SellTokens.rChip),
              border: Border.all(color: sel ? SellTokens.accent : SellTokens.line),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, size: 16, color: sel ? SellTokens.accentText : SellTokens.ink2),
                  const SizedBox(width: 6),
                ],
                if (widget.showCheck && sel) ...[
                  Icon(Icons.check_rounded, size: 15, color: SellTokens.accentText),
                  const SizedBox(width: 4),
                ],
                Text(
                  widget.label,
                  style: SellTokens.label.copyWith(
                    color: sel ? SellTokens.accentText : SellTokens.ink,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Two/three-way segmented control ("Manual | Automatic", "Sell | Rent").
class SellSegmented<T> extends StatelessWidget {
  const SellSegmented({super.key, required this.options, required this.selected, required this.onChanged, this.error, this.compact = false});
  final List<SellOptionItem<T>> options;
  final T? selected;
  final ValueChanged<T> onChanged;
  final String? error;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: SellTokens.input,
            borderRadius: BorderRadius.circular(SellTokens.rInput),
            border: Border.all(color: error != null ? SellTokens.errorBorder : Colors.transparent),
          ),
          child: Row(
            children: [
              for (final o in options)
                _segment(context, o),
            ],
          ),
        ),
        SellFieldNote(error: error),
      ],
    );
  }

  Widget _segment(BuildContext context, SellOptionItem<T> o) {
    final on = o.value == selected;
    final child = Semantics(
      button: true,
      selected: on,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          onChanged(o.value);
        },
        child: AnimatedContainer(
          duration: SellTokens.fast,
          padding: EdgeInsets.symmetric(vertical: compact ? 6 : 10, horizontal: compact ? 10 : 8),
          decoration: BoxDecoration(
            color: on ? (AppColors.isDark ? const Color(0xFF2F3442) : Colors.white) : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: on && !AppColors.isDark
                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 3, offset: const Offset(0, 1))]
                : const [],
          ),
          alignment: Alignment.center,
          child: Text(
            o.label,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.fade,
            style: SellTokens.label.copyWith(
              color: on ? SellTokens.ink : SellTokens.muted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
    return Expanded(child: child);
  }
}

/// − 3 ＋  (48 dp targets).
class SellStepper extends StatelessWidget {
  const SellStepper({super.key, required this.value, required this.onChanged, this.min = 0, this.max = 20, this.error, this.semanticLabel});
  final int? value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  final String? error;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final v = value;
    Widget btn(IconData icon, bool enabled, VoidCallback onTap) => SizedBox(
          width: 48,
          height: 48,
          child: IconButton(
            onPressed: enabled ? () {
              HapticFeedback.selectionClick();
              onTap();
            } : null,
            icon: Icon(icon, size: 20),
            color: SellTokens.accent,
            disabledColor: SellTokens.muted.withValues(alpha: 0.4),
          ),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          label: semanticLabel,
          value: v?.toString() ?? 'not set',
          child: Container(
            decoration: BoxDecoration(
              color: error != null ? SellTokens.errorFill : SellTokens.input,
              borderRadius: BorderRadius.circular(SellTokens.rInput),
              border: Border.all(color: error != null ? SellTokens.errorBorder : Colors.transparent),
            ),
            child: Row(
              children: [
                btn(Icons.remove_rounded, v != null && v > min, () => onChanged(v! - 1)),
                Expanded(
                  child: Text(v?.toString() ?? '–', textAlign: TextAlign.center, style: SellTokens.title),
                ),
                btn(Icons.add_rounded, v == null || v < max, () => onChanged(v == null ? (min > 0 ? min : 1) : v + 1)),
              ],
            ),
          ),
        ),
        SellFieldNote(error: error),
      ],
    );
  }
}

class SellColorSwatches extends StatelessWidget {
  const SellColorSwatches({super.key, required this.colors, required this.selected, required this.onChanged, this.error});
  final List<({String value, String label, Color color})> colors;
  final String? selected;
  final ValueChanged<String> onChanged;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final c in colors)
              Tooltip(
                message: c.label,
                child: Semantics(
                  button: true,
                  selected: c.value == selected,
                  label: c.label,
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onChanged(c.value);
                    },
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: Center(
                        child: AnimatedContainer(
                          duration: SellTokens.fast,
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: c.color,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.black.withValues(alpha: 0.12)),
                            boxShadow: c.value == selected
                                ? [
                                    BoxShadow(color: SellTokens.surface, spreadRadius: 2),
                                    BoxShadow(color: SellTokens.accent, spreadRadius: 3.5),
                                  ]
                                : const [],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        if (selected != null && error == null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              colors.where((c) => c.value == selected).map((c) => c.label).firstOrNull ?? '',
              style: SellTokens.caption,
            ),
          ),
        SellFieldNote(error: error),
      ],
    );
  }
}

enum SellBannerKind { info, warn, error, ok }

class SellBanner extends StatelessWidget {
  const SellBanner({super.key, required this.kind, required this.icon, this.title, this.body, this.child});
  final SellBannerKind kind;
  final IconData icon;
  final String? title;
  final String? body;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (kind) {
      SellBannerKind.info => (SellTokens.infoBg, SellTokens.infoFg),
      SellBannerKind.warn => (SellTokens.warnBg, SellTokens.warnFg),
      SellBannerKind.error => (SellTokens.errBg, SellTokens.errFg),
      SellBannerKind.ok => (SellTokens.okBg, SellTokens.okFg),
    };
    return Semantics(
      liveRegion: kind == SellBannerKind.error || kind == SellBannerKind.warn,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(SellTokens.rInput)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(padding: const EdgeInsets.only(top: 1), child: Icon(icon, size: 18, color: fg)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null || body != null)
                    Text.rich(
                      TextSpan(children: [
                        if (title != null)
                          TextSpan(text: body != null ? '$title ' : title, style: const TextStyle(fontWeight: FontWeight.w600)),
                        if (body != null) TextSpan(text: body),
                      ]),
                      style: SellTokens.label.copyWith(color: fg, fontWeight: FontWeight.w400),
                    ),
                  if (child != null) ...[
                    if (title != null || body != null) const SizedBox(height: 8),
                    child!,
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum SellButtonKind { primary, tonal, ghost, danger }

class SellButton extends StatelessWidget {
  const SellButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.kind = SellButtonKind.primary,
    this.busy = false,
    this.expand = true,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final SellButtonKind kind;
  final bool busy;
  final bool expand;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !busy;
    Color bg;
    Color fg;
    BorderSide side = BorderSide.none;
    switch (kind) {
      case SellButtonKind.primary:
        bg = enabled ? (AppColors.isDark ? const Color(0xFF6F69F2) : SellTokens.brand) : SellTokens.disabledBrand;
        fg = Colors.white;
        break;
      case SellButtonKind.tonal:
        bg = SellTokens.soft;
        fg = SellTokens.accentText;
        break;
      case SellButtonKind.ghost:
        bg = Colors.transparent;
        fg = SellTokens.accentText;
        break;
      case SellButtonKind.danger:
        bg = Colors.transparent;
        fg = SellTokens.errorText;
        side = BorderSide(color: SellTokens.errorBorder.withValues(alpha: 0.35));
        break;
    }
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (busy) ...[
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: fg),
          ),
          const SizedBox(width: 10),
        ] else if (icon != null) ...[
          Icon(icon, size: 18, color: fg),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(label, overflow: TextOverflow.ellipsis, style: SellTokens.button.copyWith(color: fg)),
        ),
      ],
    );
    final button = Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SellTokens.rButton), side: side),
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(SellTokens.rButton),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 52),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: kind == SellButtonKind.ghost ? 12 : 20),
              child: Center(child: content),
            ),
          ),
        ),
      ),
    );
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// Grab handle + rounded top used by every sheet in the flow.
class SellSheetFrame extends StatelessWidget {
  const SellSheetFrame({super.key, required this.child, this.padding = const EdgeInsets.fromLTRB(16, 8, 16, 16)});
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: BoxDecoration(
        color: SellTokens.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(SellTokens.rSheet)),
      ),
      padding: padding.copyWith(bottom: padding.bottom + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(color: SellTokens.line, borderRadius: BorderRadius.circular(4)),
            ),
          ),
          Flexible(child: child),
        ],
      ),
    );
  }
}

Future<T?> showSellSheet<T>(BuildContext context, WidgetBuilder builder, {bool dismissible = true}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    isDismissible: dismissible,
    enableDrag: dismissible,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x610A0A14),
    builder: (ctx) => SellSheetFrame(child: builder(ctx)),
  );
}

/// Photo from a local file or URL.
class SellPhoto extends StatelessWidget {
  const SellPhoto({super.key, this.localPath, this.url, this.fit = BoxFit.cover});
  final String? localPath;
  final String? url;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      color: SellTokens.input,
      alignment: Alignment.center,
      child: Icon(Icons.image_outlined, color: SellTokens.muted),
    );
    if (localPath != null && File(localPath!).existsSync()) {
      return Image.file(
        File(localPath!),
        fit: fit,
        cacheWidth: 600,
        errorBuilder: (_, __, ___) => placeholder,
      );
    }
    if (url != null && url!.isNotEmpty) {
      return Image.network(url!, fit: fit, cacheWidth: 600, errorBuilder: (_, __, ___) => placeholder);
    }
    return placeholder;
  }
}

/// The ad as a buyer sees it in the feed (W07, W10).
class SellPreviewCard extends StatelessWidget {
  const SellPreviewCard({
    super.key,
    required this.price,
    required this.title,
    this.subtitle,
    this.localPath,
    this.url,
    this.photoCount,
    this.pill,
    this.badge,
  });

  final String price;
  final String title;
  final String? subtitle;
  final String? localPath;
  final String? url;
  final int? photoCount;
  final String? pill;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: SellTokens.surface,
        borderRadius: BorderRadius.circular(SellTokens.rCard),
        border: Border.all(color: SellTokens.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                SellPhoto(localPath: localPath, url: url),
                if (badge != null || (photoCount != null && photoCount! > 0))
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(6)),
                      child: Text(badge ?? '1/$photoCount', style: SellTokens.caption.copyWith(color: Colors.white)),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (pill != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: SellTokens.warnBg, borderRadius: BorderRadius.circular(999)),
                    child: Text(pill!, style: SellTokens.caption.copyWith(color: SellTokens.warnFg, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 6),
                ],
                Text(price, style: SellTokens.title.copyWith(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: SellTokens.body.copyWith(fontSize: 14)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis, style: SellTokens.caption),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Section card with a heading and optional "Edit" link (Review).
class SellSectionCard extends StatelessWidget {
  const SellSectionCard({super.key, required this.title, required this.child, this.onEdit});
  final String title;
  final Widget child;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 8, 12),
      decoration: BoxDecoration(
        color: SellTokens.surface,
        borderRadius: BorderRadius.circular(SellTokens.rCard),
        border: Border.all(color: SellTokens.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: SellTokens.label.copyWith(color: SellTokens.ink, fontWeight: FontWeight.w600, fontSize: 14))),
              if (onEdit != null)
                TextButton(
                  onPressed: onEdit,
                  style: TextButton.styleFrom(foregroundColor: SellTokens.accentText, minimumSize: const Size(48, 40)),
                  child: Text('Edit', style: SellTokens.label.copyWith(color: SellTokens.accentText, fontWeight: FontWeight.w600)),
                ),
            ],
          ),
          Padding(padding: const EdgeInsets.only(right: 6), child: child),
        ],
      ),
    );
  }
}

class SellKeyValue extends StatelessWidget {
  const SellKeyValue(this.label, this.value, {super.key, this.last = false});
  final String label;
  final String value;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 7),
      decoration: BoxDecoration(
        border: last ? null : Border(bottom: BorderSide(color: SellTokens.line.withValues(alpha: 0.6))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: Text(label, style: SellTokens.label.copyWith(color: SellTokens.muted, fontWeight: FontWeight.w400))),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Text(value, textAlign: TextAlign.right, style: SellTokens.label.copyWith(color: SellTokens.ink, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
