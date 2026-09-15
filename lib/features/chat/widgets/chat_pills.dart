import 'package:flutter/material.dart';

import '../data/chat_models.dart';
import 'chat_tokens.dart';

/// Unread count pill (list rows, chips, nav bar). 99+ cap.
class UnreadBadge extends StatelessWidget {
  const UnreadBadge({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();
    final c = ChatColors.of(context);
    return Container(
      constraints: const BoxConstraints(minWidth: ChatSize.badgeHeight),
      height: ChatSize.badgeHeight,
      padding: const EdgeInsets.symmetric(horizontal: 6.5),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: c.brand, borderRadius: BorderRadius.circular(ChatSize.badgeHeight / 2)),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: TextStyle(color: c.onBrand, fontSize: ChatSize.badgeFont, fontWeight: FontWeight.w600, height: 1),
      ),
    );
  }
}

/// Live · Sold · Unavailable
class AdStatusPill extends StatelessWidget {
  const AdStatusPill({super.key, required this.availability});

  final AdAvailability availability;

  @override
  Widget build(BuildContext context) {
    final c = ChatColors.of(context);
    final (label, bg, fg) = switch (availability) {
      AdAvailability.live => ('Live', c.okBg, c.ok),
      AdAvailability.sold => ('Ad sold', c.chip, c.muted),
      AdAvailability.unavailable => ('Unavailable', c.chip, c.muted),
    };
    return Container(
      padding: ChatSize.pillPadding,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(ChatSize.pillRadius)),
      child: Text(label, style: TextStyle(color: fg, fontSize: ChatSize.pillFont, fontWeight: FontWeight.w600, height: 1.2)),
    );
  }
}
