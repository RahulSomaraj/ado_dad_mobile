// Screen 01 row: avatar + listing thumb · name + time · ad line · preview + badge.

import 'package:flutter/material.dart';

import '../data/chat_models.dart';
import 'chat_avatar.dart';
import 'chat_format.dart';
import 'chat_pills.dart';
import 'chat_tokens.dart';

class ConversationTile extends StatelessWidget {
  const ConversationTile({
    super.key,
    required this.room,
    required this.myUserId,
    required this.onTap,
    this.onLongPress,
    this.highlight = '',
    this.pending,
  });

  final ChatRoom room;
  final String? myUserId;
  final VoidCallback onTap;

  /// Archive / mark unread sheet.
  final VoidCallback? onLongPress;

  /// Search text to highlight in name / ad title / preview (screen 05).
  final String highlight;

  /// My newest unsent message in this room, if any — shows "Not sent".
  final ChatMessage? pending;

  @override
  Widget build(BuildContext context) {
    final c = ChatColors.of(context);
    final unread = room.hasUnread;
    final dim = room.ad?.availability != AdAvailability.live && room.ad != null;
    final last = room.lastMessage;
    final time = room.sortTime;

    final nameStyle = TextStyle(
      fontSize: ChatSize.nameFont,
      fontWeight: unread ? FontWeight.w600 : FontWeight.w500,
      color: c.text,
      height: 1.25,
    );
    final previewStyle = TextStyle(
      fontSize: ChatSize.previewFont,
      color: unread ? c.text : c.muted,
      fontWeight: unread ? FontWeight.w500 : FontWeight.w400,
      height: 1.3,
    );

    return Material(
      color: c.surface,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Opacity(
          opacity: dim ? 0.62 : 1,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: ChatSize.gutter, vertical: ChatSize.rowVPad),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ChatAvatar(
                  name: room.title,
                  imageUrl: room.otherUser?.avatarUrl,
                  listingImageUrl: room.ad?.imageUrl,
                  showListingThumb: room.ad != null,
                ),
                const SizedBox(width: ChatSize.avatarGap),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Expanded(child: _Highlighted(room.title, highlight, nameStyle)),
                          const SizedBox(width: 8),
                          if (time != null)
                            Text(
                              formatListTime(time),
                              style: TextStyle(
                                fontSize: ChatSize.timeFont,
                                color: unread ? c.brandText : c.muted,
                                fontWeight: unread ? FontWeight.w600 : FontWeight.w400,
                                fontFeatures: const [FontFeature.tabularFigures()],
                              ),
                            ),
                        ],
                      ),
                      if (room.ad != null) ...[
                        const SizedBox(height: 1.5),
                        _AdLine(ad: room.ad!, highlight: highlight),
                      ],
                      const SizedBox(height: 2.5),
                      Row(
                        children: [
                          Expanded(child: _preview(context, c, last, previewStyle)),
                          if (unread) ...[
                            const SizedBox(width: 8),
                            UnreadBadge(count: room.unreadCount),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _preview(BuildContext context, ChatColors c, ChatLastMessage? last, TextStyle style) {
    if (pending != null && pending!.status == MessageStatus.failed) {
      return Row(children: [
        Icon(Icons.error_outline_rounded, size: ChatSize.adLineIcon, color: c.err),
        const SizedBox(width: 4),
        Flexible(
          child: Text('Not sent',
              maxLines: 1, overflow: TextOverflow.ellipsis, style: style.copyWith(color: c.err, fontWeight: FontWeight.w500)),
        ),
      ]);
    }
    if (last == null) {
      return Text('No messages yet', style: style.copyWith(color: c.muted, fontWeight: FontWeight.w400), maxLines: 1);
    }
    final mine = myUserId != null && last.senderId == myUserId;
    final icon = switch (last.type) {
      MessageType.image => Icons.image_outlined,
      MessageType.audio => Icons.mic_none_rounded,
      MessageType.file => Icons.attach_file_rounded,
      _ => null,
    };
    return Row(
      children: [
        if (mine) ...[
          // Double tick in brand once the other person has read it; single muted tick before.
          if (last.status == MessageStatus.read)
            Icon(Icons.done_all_rounded, size: ChatSize.adLineIcon + 1, color: c.brandText)
          else
            Icon(Icons.done_rounded, size: ChatSize.adLineIcon + 1, color: c.muted),
          const SizedBox(width: 3),
          Text('You: ', style: style.copyWith(color: c.muted, fontWeight: FontWeight.w400)),
        ],
        if (icon != null) ...[
          Icon(icon, size: ChatSize.adLineIcon + 1, color: style.color),
          const SizedBox(width: 3),
        ],
        Expanded(child: _Highlighted(last.preview, highlight, style)),
      ],
    );
  }
}

class _AdLine extends StatelessWidget {
  const _AdLine({required this.ad, required this.highlight});

  final ChatAd ad;
  final String highlight;

  @override
  Widget build(BuildContext context) {
    final c = ChatColors.of(context);
    final style = TextStyle(fontSize: ChatSize.adLineFont, color: c.muted, height: 1.3);
    // Sold / removed ads show the pill and title only (wireframe 01, last row).
    final live = ad.availability == AdAvailability.live;
    final label = live && ad.price != null ? '${ad.title} · ${formatInr(ad.price!)}' : ad.title;
    return Row(
      children: [
        if (ad.availability == AdAvailability.live)
          Icon(Icons.sell_outlined, size: ChatSize.adLineIcon, color: c.muted)
        else
          AdStatusPill(availability: ad.availability),
        const SizedBox(width: 5),
        Expanded(child: _Highlighted(label, highlight, style)),
      ],
    );
  }
}

/// Single-line text with case-insensitive match highlighting.
class _Highlighted extends StatelessWidget {
  const _Highlighted(this.text, this.query, this.style);

  final String text;
  final String query;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final q = query.trim();
    final idx = q.isEmpty ? -1 : text.toLowerCase().indexOf(q.toLowerCase());
    if (idx < 0) {
      return Text(text, style: style, maxLines: 1, overflow: TextOverflow.ellipsis);
    }
    final c = ChatColors.of(context);
    return Text.rich(
      TextSpan(style: style, children: [
        TextSpan(text: text.substring(0, idx)),
        TextSpan(
          text: text.substring(idx, idx + q.length),
          style: TextStyle(backgroundColor: c.highlight, color: c.onHighlight),
        ),
        TextSpan(text: text.substring(idx + q.length)),
      ]),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
