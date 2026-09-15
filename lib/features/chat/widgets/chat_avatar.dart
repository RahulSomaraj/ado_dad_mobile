import 'package:ado_dad_user/common/widgets/app_network_image.dart';
import 'package:flutter/material.dart';

import 'chat_tokens.dart';

/// Circle avatar with initial fallback, optional listing thumb (bottom-right,
/// rounded square with a surface ring) and optional online dot.
class ChatAvatar extends StatelessWidget {
  const ChatAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.listingImageUrl,
    this.showListingThumb = false,
    this.online = false,
    this.size = ChatSize.avatar,
    this.ringColor,
  });

  final String name;
  final String? imageUrl;
  final String? listingImageUrl;
  final bool showListingThumb;
  final bool online;
  final double size;
  final Color? ringColor;

  @override
  Widget build(BuildContext context) {
    final c = ChatColors.of(context);
    final ring = ringColor ?? c.surface;
    final initial = name.trim().isEmpty ? '?' : String.fromCharCode(name.trim().runes.first).toUpperCase();

    Widget circle = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: c.soft, shape: BoxShape.circle),
      alignment: Alignment.center,
      clipBehavior: Clip.antiAlias,
      child: imageUrl != null
          ? AppNetworkImage(url: imageUrl!, width: size, height: size)
          : Text(
              initial,
              style: TextStyle(
                color: c.brandText,
                fontSize: size * (ChatSize.avatarInitialFont / ChatSize.avatar),
                fontWeight: FontWeight.w600,
                height: 1,
              ),
            ),
    );

    if (!showListingThumb && !online) return circle;

    final thumb = ChatSize.avatarThumb * (size / ChatSize.avatar);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          circle,
          if (showListingThumb)
            Positioned(
              right: -ChatSize.avatarThumbOffset * (size / ChatSize.avatar),
              bottom: -ChatSize.avatarThumbOffset * (size / ChatSize.avatar),
              child: Container(
                width: thumb,
                height: thumb,
                decoration: BoxDecoration(
                  color: c.chip,
                  borderRadius: BorderRadius.circular(ChatSize.avatarThumbRadius),
                  border: Border.all(color: ring, width: ChatSize.avatarRing),
                ),
                clipBehavior: Clip.antiAlias,
                child: listingImageUrl != null
                    ? AppNetworkImage(url: listingImageUrl!, width: thumb, height: thumb)
                    : Icon(Icons.sell_outlined, size: thumb * 0.5, color: c.muted),
              ),
            ),
          if (online)
            Positioned(
              right: 0,
              bottom: 1,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: c.call,
                  shape: BoxShape.circle,
                  border: Border.all(color: ring, width: ChatSize.avatarRing),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
