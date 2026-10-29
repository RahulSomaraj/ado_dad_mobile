// Screen 06 header + listing strip.

import 'package:ado_dad_user/common/app_colors.dart';
import 'package:ado_dad_user/common/brand_header.dart';
import 'package:ado_dad_user/common/widgets/app_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      child: BrandHeader(
        radius: 22,
        padding: const EdgeInsets.fromLTRB(6, 8, 10, 12),
        child: Row(
          children: [
            _HeaderIcon(icon: Icons.arrow_back_rounded, color: Colors.white, onTap: onBack, label: 'Back'),
            const SizedBox(width: 2),
            Expanded(
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  onTap: r == null ? null : onOpenDetails,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withValues(alpha: 0.7), width: 1.5),
                          ),
                          child: ChatAvatar(name: name, imageUrl: r?.otherUser?.avatarUrl, size: ChatSize.avatarSm - 4),
                        ),
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
                                style: const TextStyle(
                                  fontSize: ChatSize.headerName + 1,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  height: 1.2,
                                ),
                              ),
                              if (sub != null)
                                Text(
                                  sub,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: ChatSize.headerSub,
                                    color: HomeHeroPalette.soft,
                                    height: 1.3,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (onCall != null) ...[
              // Call is an action: action-orange round button.
              BrandHeaderIconButton(
                icon: Icons.call_rounded,
                tooltip: 'Call',
                size: 40,
                color: AppColors.onCta,
                background: c.call,
                onTap: onCall,
              ),
              const SizedBox(width: 4),
            ],
            if (r != null)
              _HeaderIcon(icon: Icons.more_vert_rounded, color: Colors.white, onTap: onOpenDetails, label: 'Chat details'),
          ],
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
    // Floating card under the blue header (Home card style).
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 2),
      child: Material(
      color: c.surface,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: ChatSize.stripPadding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.divider, width: 0.8),
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
                              style: TextStyle(fontSize: ChatSize.stripPrice, fontWeight: FontWeight.w700, color: c.text),
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
                  Text('View', style: TextStyle(fontSize: ChatSize.stripView, color: c.brandText, fontWeight: FontWeight.w600)),
                  Icon(Icons.chevron_right_rounded, size: 17, color: c.brandText),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }
}
