import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'sell_ui.dart';

/// A labelled block inside a step: a small-caps label over a hairline, and an
/// optional one-line summary that replaces the fields once they are all
/// answered (CAR-2).
///
/// Hierarchy without cards: the label and the rule carry it, so the step gains
/// structure without gaining borders.
class SellSection extends StatelessWidget {
  const SellSection({
    super.key,
    required this.label,
    required this.children,
    this.first = false,
    this.collapsed = false,
    this.summaryTitle,
    this.summarySubtitle,
    this.onExpand,
  });

  final String label;
  final List<Widget> children;

  /// No rule above the first section in a step.
  final bool first;

  /// Show [summaryTitle] instead of [children]. Ignored when
  /// [summaryTitle] is null, so a section can never collapse into nothing.
  final bool collapsed;
  final String? summaryTitle;
  final String? summarySubtitle;
  final VoidCallback? onExpand;

  bool get _isCollapsed => collapsed && summaryTitle != null;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!first) ...[
          const SizedBox(height: 18),
          Divider(height: 1, thickness: 1, color: SellTokens.line),
          const SizedBox(height: 16),
        ],
        Semantics(
          header: true,
          child: Text(
            label.toUpperCase(),
            style: SellTokens.caption.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
              color: SellTokens.muted,
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (_isCollapsed)
          _SummaryRow(
            title: summaryTitle!,
            subtitle: summarySubtitle,
            onTap: onExpand,
          )
        else
          ...children,
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.title, this.subtitle, this.onTap});
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$title${subtitle == null ? '' : ', $subtitle'}. Edit',
      excludeSemantics: true,
      child: Material(
        color: SellTokens.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SellTokens.rInput),
          side: BorderSide(color: SellTokens.line),
        ),
        child: InkWell(
          onTap: onTap == null
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  onTap!();
                },
          borderRadius: BorderRadius.circular(SellTokens.rInput),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: SellTokens.body.copyWith(fontWeight: FontWeight.w600),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: SellTokens.caption,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Edit',
                    style: SellTokens.label.copyWith(
                      color: SellTokens.accentText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// "FROM ACTIVA 6G ✓" — marks a field the catalogue answered for the seller,
/// naming the variant or the model it came from.
class SellSourceTag extends StatelessWidget {
  const SellSourceTag({super.key, required this.source});
  final String source;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Filled in from $source',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: SellTokens.okBg,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          'FROM ${source.toUpperCase()} ✓',
          style: SellTokens.caption.copyWith(
            fontSize: 10,
            height: 1.2,
            fontWeight: FontWeight.w600,
            color: SellTokens.okFg,
          ),
        ),
      ),
    );
  }
}

/// A field the catalogue settled: stated, not asked.
///
/// An Activa is gearless; a Dominar is geared. Where the data names exactly
/// one value there is no question to put to the seller, so the row reads as a
/// fact with the source beside it. [onOverride] is the escape hatch for the
/// genuine exceptions — a converted or imported bike — and is deliberately
/// quiet.
class SellFactRow extends StatelessWidget {
  const SellFactRow({
    super.key,
    required this.value,
    required this.source,
    this.onOverride,
    this.overrideLabel = 'Change',
  });

  final String value;
  final String source;
  final VoidCallback? onOverride;
  final String overrideLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$value, from $source',
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: SellTokens.input,
          borderRadius: BorderRadius.circular(SellTokens.rInput),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle_rounded, size: 17, color: SellTokens.okText),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SellTokens.body.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    'from $source',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SellTokens.caption,
                  ),
                ],
              ),
            ),
            if (onOverride != null) ...[
              const SizedBox(width: 8),
              Semantics(
                button: true,
                label: '$overrideLabel $value',
                excludeSemantics: true,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onOverride!();
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    child: Text(
                      overrideLabel,
                      style: SellTokens.caption.copyWith(
                        color: SellTokens.accentText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
