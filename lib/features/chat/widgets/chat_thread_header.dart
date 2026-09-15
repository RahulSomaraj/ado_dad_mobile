// Screen 06 header + listing strip.

import 'package:ado_dad_user/common/widgets/app_network_image.dart';
import 'package:flutter/material.dart';

import '../data/chat_models.dart';
import 'chat_avatar.dart';
import 'chat_format.dart';
import 'chat_pills.dart';
import 'chat_tokens.dart';

class ChatThreadHeader extends StatelessWidget {
  const ChatThreadHeader({
    super.key,
    required this.room,
    required this.onBack,
    required this.onOpenDetails,
    this.onCall,
    this.fallbackTitle,
  });

  final ChatRoom? room;
  final VoidCallback onBack;
  final VoidCallback onOpenDetails;
  final VoidCallback? onCall;
  final String? fallbackTitle;

  @override
  Widget build(BuildContext context) {
    final c = ChatColors.of(context);
    final r = room;
    final name = r?.title ?? fallbackTitle ?? 'Chat';
    final sub = r == null
        ? null
        : [
            r.myRole == ChatRole.buying ? 'Buying' : 'Selling',
            if (r.ad != null) r.ad!.title,
          ].join(' · ');

    return Material(
      color: c.surface,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: ChatSize.headerPadding,
          child: Row(
            children: [
              _HeaderIcon(icon: Icons.arrow_back_rounded, color: c.text2, onTap: onBack, label: 'Back'),
              const SizedBox(width: 2),
              Expanded(
                child: InkWell(
                  onTap: r == null ? null : onOpenDetails,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                    child: Row(
                      children: [
                        ChatAvatar(name: name, imageUrl: r?.otherUser?.avatarUrl, size: ChatSize.avatarSm),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: ChatSize.headerName,
                                  fontWeight: FontWeight.w600,
                                  color: c.text,
                                  height: 1.2,
                                ),
                              ),
                              if (sub != null)
                                Text(
                                  sub,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: ChatSize.headerSub, color: c.muted, height: 1.3),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (onCall != null) _HeaderIcon(icon: Icons.call_outlined, color: c.call, onTap: onCall!, label: 'Call'),
              if (r != null)
                _HeaderIcon(icon: Icons.more_vert_rounded, color: c.text2, onTap: onOpenDetails, label: 'Chat details'),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon({required this.icon, required this.color, required this.onTap, required this.label});

  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: ChatSize.headerIconButton + 4,
        height: ChatSize.headerIconButton + 4,
        child: IconButton(
          tooltip: label,
          onPressed: onTap,
          icon: Icon(icon, size: ChatSize.headerIcon, color: color),
        ),
      );
}

/// Full-width strip under the header: thumb · title · price + status · View ›.
class ChatListingStrip extends StatelessWidget {
  const ChatListingStrip({super.key, required this.ad, required this.role, required this.onTap});

  final ChatAd ad;
  final ChatRole role;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = ChatColors.of(context);
    return Material(
      color: c.surface,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: ChatSize.stripPadding,
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: c.divider, width: 0.7), bottom: BorderSide(color: c.divider, width: 0.7)),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(ChatSize.stripThumbRadius),
                child: SizedBox.fromSize(
                  size: ChatSize.stripThumb,
                  child: ad.imageUrl != null
                      ? AppNetworkImage(url: ad.imageUrl!, width: ChatSize.stripThumb.width, height: ChatSize.stripThumb.height)
                      : ColoredBox(color: c.chip, child: Icon(Icons.sell_outlined, size: 18, color: c.muted)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      ad.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: ChatSize.stripTitle, color: c.text2, height: 1.3),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (ad.price != null) ...[
                          Flexible(
                            child: Text(
                              formatInr(ad.price!),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: ChatSize.stripPrice, fontWeight: FontWeight.w600, color: c.text),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        AdStatusPill(availability: ad.availability),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('View', style: TextStyle(fontSize: ChatSize.stripView, color: c.brandText, fontWeight: FontWeight.w500)),
                  Icon(Icons.chevron_right_rounded, size: 17, color: c.brandText),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
