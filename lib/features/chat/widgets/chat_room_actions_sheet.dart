// Screen 01 long-press: Mark as unread / read · Archive chat.
// Rows follow the screen 13 sheet rows (.lrow: 11.5px text, 12px icon → 15 / 16 dp).

import 'package:flutter/material.dart';

import '../data/chat_models.dart';
import 'chat_avatar.dart';
import 'chat_format.dart';
import 'chat_tokens.dart';

enum ChatRoomAction { markUnread, markRead, archive }

Future<ChatRoomAction?> showChatRoomActions(BuildContext context, ChatRoom room) {
  final c = ChatColors.of(context);
  return showModalBottomSheet<ChatRoomAction>(
    context: context,
    backgroundColor: c.surface,
    barrierColor: c.scrim,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(ChatSize.sheetRadius)),
    ),
    builder: (ctx) {
      Widget row(IconData icon, String label, ChatRoomAction action) => InkWell(
            key: ValueKey('chat-action-${action.name}'),
            onTap: () => Navigator.pop(ctx, action),
            child: Padding(
              padding: ChatSize.sheetRowPadding,
              child: Row(children: [
                Icon(icon, size: 20, color: c.muted),
                const SizedBox(width: 13),
                Expanded(
                  child: Text(label, style: TextStyle(fontSize: ChatSize.sheetRowFont, color: c.text)),
                ),
              ]),
            ),
          );

      final ad = room.ad;
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(21, 0, 21, 12),
              child: Row(children: [
                ChatAvatar(name: room.title, imageUrl: room.otherUser?.avatarUrl, size: ChatSize.avatarSm),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(room.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: ChatSize.headerName, fontWeight: FontWeight.w600, color: c.text)),
                    if (ad != null)
                      Text(
                        ad.price != null && ad.availability == AdAvailability.live
                            ? '${ad.title} · ${formatInr(ad.price!)}'
                            : ad.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: ChatSize.headerSub, color: c.muted),
                      ),
                  ]),
                ),
              ]),
            ),
            Divider(height: 0.7, thickness: 0.7, color: c.divider),
            if (room.hasUnread)
              row(Icons.mark_chat_read_outlined, 'Mark as read', ChatRoomAction.markRead)
            else
              row(Icons.mark_chat_unread_outlined, 'Mark as unread', ChatRoomAction.markUnread),
            row(Icons.archive_outlined, 'Archive chat', ChatRoomAction.archive),
            const SizedBox(height: 6),
          ],
        ),
      );
    },
  );
}
