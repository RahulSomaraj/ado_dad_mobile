// Screen 13 — chat details. Only actions the backend supports today are shown
// (Call, seller profile, view ad, report via the ad-report sheet). Mute / block / shared
// media need new APIs and stay off until those exist.

import 'package:flutter/material.dart';

import '../data/chat_models.dart';
import 'chat_avatar.dart';
import 'chat_format.dart';
import 'chat_tokens.dart';

Future<void> showChatDetailsSheet(
  BuildContext context, {
  required ChatRoom room,
  VoidCallback? onCall,
  VoidCallback? onViewProfile,
  VoidCallback? onViewAd,
  VoidCallback? onReport,
}) {
  final c = ChatColors.of(context);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: c.surface,
    barrierColor: c.scrim,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(ChatSize.sheetRadius)),
    ),
    builder: (ctx) {
      void run(VoidCallback? f) {
        Navigator.pop(ctx);
        f?.call();
      }

      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ChatAvatar(name: room.title, imageUrl: room.otherUser?.avatarUrl, size: ChatSize.avatarLg),
            const SizedBox(height: 10),
            Text(room.title, style: TextStyle(fontSize: ChatSize.sheetName, fontWeight: FontWeight.w600, color: c.text)),
            const SizedBox(height: 2),
            Text(
              room.myRole == ChatRole.buying ? 'Seller' : 'Interested buyer',
              style: TextStyle(fontSize: ChatSize.sheetSub, color: c.muted),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (onCall != null) _Action(icon: Icons.call_outlined, label: 'Call', iconColor: c.call, onTap: () => run(onCall)),
                if (onViewProfile != null)
                  _Action(icon: Icons.person_outline_rounded, label: 'Profile', onTap: () => run(onViewProfile)),
                if (room.ad != null && onViewAd != null)
                  _Action(icon: Icons.sell_outlined, label: 'View ad', onTap: () => run(onViewAd)),
              ],
            ),
            const SizedBox(height: 14),
            Divider(height: 0.7, thickness: 0.7, color: c.divider),
            if (onReport != null)
              InkWell(
                onTap: () => run(onReport),
                child: Padding(
                  padding: ChatSize.sheetRowPadding,
                  child: Row(children: [
                    Icon(Icons.flag_outlined, size: 20, color: c.err),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Text('Report ${firstName(room.title)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: ChatSize.sheetRowFont, color: c.err)),
                    ),
                  ]),
                ),
              ),
            Divider(height: 0.7, thickness: 0.7, color: c.divider),
            Padding(
              padding: ChatSize.sheetRowPadding,
              child: Text(
                [
                  if (room.createdAt != null) 'Chat started ${formatDateLabel(room.createdAt!)}',
                  if (room.ad != null) 'about ${room.ad!.title}',
                ].join(' '),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: ChatSize.sheetSub, color: c.muted),
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _Action extends StatelessWidget {
  const _Action({required this.icon, required this.label, required this.onTap, this.iconColor});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final c = ChatColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Column(children: [
            Container(
              width: ChatSize.actionCircle,
              height: ChatSize.actionCircle,
              decoration: BoxDecoration(color: c.chip, shape: BoxShape.circle),
              child: Icon(icon, size: 21, color: iconColor ?? c.brandText),
            ),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(fontSize: ChatSize.actionLabel, color: c.text2)),
          ]),
        ),
      ),
    );
  }
}
