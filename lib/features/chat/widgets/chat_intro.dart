// Screen 08 — empty conversation: listing card, role-aware starters, safety tip.

import 'package:ado_dad_user/common/widgets/app_network_image.dart';
import 'package:flutter/material.dart';

import '../data/chat_models.dart';
import 'chat_copy.dart';
import 'chat_format.dart';
import 'chat_pills.dart';
import 'chat_tokens.dart';

class ChatIntro extends StatelessWidget {
  const ChatIntro({super.key, required this.room, required this.onStarter, required this.onOpenAd});

  final ChatRoom room;
  final ValueChanged<String> onStarter;
  final VoidCallback onOpenAd;

  @override
  Widget build(BuildContext context) {
    final c = ChatColors.of(context);
    final ad = room.ad;
    final buying = room.myRole == ChatRole.buying;

    return LayoutBuilder(
      builder: (context, box) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: (box.maxHeight - 34).clamp(0.0, double.infinity).toDouble()),
          child: Column(
            children: [
              if (ad != null)
                GestureDetector(
                  onTap: onOpenAd,
                  child: Container(
                    decoration: BoxDecoration(
                      color: c.surface,
                      borderRadius: BorderRadius.circular(ChatSize.introCardRadius),
                      border: Border.all(color: c.divider, width: 0.7),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: ChatSize.introImageHeight,
                          width: double.infinity,
                          child: ad.imageUrl != null
                              ? AppNetworkImage(url: ad.imageUrl!, height: ChatSize.introImageHeight)
                              : ColoredBox(color: c.chip, child: Icon(Icons.image_outlined, color: c.muted)),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 11, 14, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(ad.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: ChatSize.introSpecs, color: c.text2)),
                              const SizedBox(height: 3),
                              Row(children: [
                                if (ad.price != null) ...[
                                  Flexible(
                                    child: Text(formatInr(ad.price!),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(fontSize: ChatSize.introPrice, fontWeight: FontWeight.w600, color: c.text)),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                AdStatusPill(availability: ad.availability),
                              ]),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                buying ? 'Ask ${firstName(room.title)} about this listing' : 'Reply to ${firstName(room.title)}',
                style: TextStyle(fontSize: ChatSize.bannerFont + 0.5, color: c.muted),
              ),
              const SizedBox(height: 10),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final s in ChatCopy.starters(buying: buying))
                    ActionChip(
                      label: Text(s),
                      onPressed: () => onStarter(s),
                      labelStyle: TextStyle(fontSize: ChatSize.starterFont, color: c.brandText),
                      backgroundColor: Colors.transparent,
                      side: BorderSide(color: c.brand),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ChatSize.chipRadius)),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: ChatSize.safetyPadding,
                decoration: BoxDecoration(color: c.soft, borderRadius: BorderRadius.circular(ChatSize.safetyRadius)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.verified_user_outlined, size: 17, color: c.brandText),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(ChatCopy.safetyTip,
                          style: TextStyle(fontSize: ChatSize.safetyFont, color: c.text2, height: 1.4)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
