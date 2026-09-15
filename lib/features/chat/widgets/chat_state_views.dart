// Screens 03 (empty) and 04 (error), plus the inline banners used over data.

import 'package:flutter/material.dart';

import '../data/chat_models.dart';
import 'chat_copy.dart';
import 'chat_tokens.dart';

class ChatPrimaryButton extends StatelessWidget {
  const ChatPrimaryButton({super.key, required this.label, required this.onPressed, this.icon, this.ghost = false});

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool ghost;

  @override
  Widget build(BuildContext context) {
    final c = ChatColors.of(context);
    return Material(
      color: ghost ? Colors.transparent : c.brand,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ChatSize.buttonRadius),
        side: ghost ? BorderSide(color: c.divider) : BorderSide.none,
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(ChatSize.buttonRadius),
        child: Padding(
          padding: ChatSize.buttonPadding,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 17, color: ghost ? c.brandText : c.onBrand),
                const SizedBox(width: 7),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: ChatSize.buttonFont,
                    fontWeight: FontWeight.w500,
                    color: ghost ? c.brandText : c.onBrand,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Centered extends StatelessWidget {
  const _Centered({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, box) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: box.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(26),
                child: Column(mainAxisSize: MainAxisSize.min, children: children),
              ),
            ),
          ),
        ),
      );
}

TextStyle _title(ChatColors c) => TextStyle(fontSize: ChatSize.stateTitle, fontWeight: FontWeight.w600, color: c.text);
TextStyle _body(ChatColors c) => TextStyle(fontSize: ChatSize.stateBody, color: c.muted, height: 1.45);

/// Screen 03 — no chats at all.
class ChatListEmptyView extends StatelessWidget {
  const ChatListEmptyView({super.key, required this.onBrowse, required this.onPostAd});

  final VoidCallback onBrowse;
  final VoidCallback onPostAd;

  @override
  Widget build(BuildContext context) {
    final c = ChatColors.of(context);
    return _Centered(children: [
      _EmptyIllustration(colors: c),
      const SizedBox(height: 18),
      Text('No chats yet', style: _title(c)),
      const SizedBox(height: 8),
      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 273),
        child: Text.rich(
          TextSpan(style: _body(c), children: [
            const TextSpan(text: 'Tap '),
            TextSpan(text: 'Chat', style: TextStyle(color: c.text, fontWeight: FontWeight.w600)),
            const TextSpan(text: ' on any ad to message the seller. When someone asks about your ad, it shows up here.'),
          ]),
          textAlign: TextAlign.center,
        ),
      ),
      const SizedBox(height: 18),
      Wrap(
        spacing: 10,
        runSpacing: 10,
        alignment: WrapAlignment.center,
        children: [
          ChatPrimaryButton(label: 'Browse listings', onPressed: onBrowse),
          ChatPrimaryButton(label: 'Post an ad', onPressed: onPostAd, ghost: true),
        ],
      ),
    ]);
  }
}

class _EmptyIllustration extends StatelessWidget {
  const _EmptyIllustration({required this.colors});
  final ChatColors colors;

  @override
  Widget build(BuildContext context) {
    final c = colors;
    // Decorative drawing with fixed geometry: never scale its text with the
    // system setting (it would spill out of the mini card).
    return MediaQuery.withNoTextScaling(
      child: SizedBox(
      width: 172,
      height: 120,
      child: Stack(children: [
        Positioned(
          left: 0,
          top: 10,
          child: Container(
            width: 120,
            height: 96,
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: c.divider),
              boxShadow: [BoxShadow(color: c.brand.withValues(alpha: 0.12), blurRadius: 18, offset: const Offset(0, 8))],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFD5DCEA), Color(0xFF9AA6BF), Color(0xFF6C7892)],
                  ),
                ),
              )),
              Padding(
                padding: const EdgeInsets.fromLTRB(9, 7, 9, 8),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(height: 6, width: 70, decoration: BoxDecoration(color: c.divider, borderRadius: BorderRadius.circular(3))),
                  const SizedBox(height: 5),
                  Text('₹5,40,000',
                      maxLines: 1,
                      overflow: TextOverflow.clip,
                      style: TextStyle(fontSize: 11.5, height: 1.2, fontWeight: FontWeight.w600, color: c.text)),
                ]),
              ),
            ]),
          ),
        ),
        Positioned(
          right: 0,
          top: 0,
          child: _MiniBubble(text: 'Still available?', bg: c.brand, fg: c.onBrand, tailRight: false),
        ),
        Positioned(
          right: 8,
          bottom: 5,
          child: _MiniBubble(text: 'Yes!', bg: c.chip, fg: c.text, tailRight: true),
        ),
      ]),
      ),
    );
  }
}

class _MiniBubble extends StatelessWidget {
  const _MiniBubble({required this.text, required this.bg, required this.fg, required this.tailRight});
  final String text;
  final Color bg;
  final Color fg;
  final bool tailRight;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6.5),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(tailRight ? 16 : 4),
            bottomRight: Radius.circular(tailRight ? 4 : 16),
          ),
        ),
        child: Text(text, style: TextStyle(fontSize: 11.5, color: fg)),
      );
}

/// Filter or search returned nothing.
class ChatListNoResultsView extends StatelessWidget {
  const ChatListNoResultsView({super.key, required this.title, required this.body, this.actionLabel, this.onAction});

  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final c = ChatColors.of(context);
    return _Centered(children: [
      Icon(Icons.search_off_rounded, size: 40, color: c.muted),
      const SizedBox(height: 12),
      Text(title, style: _title(c), textAlign: TextAlign.center),
      const SizedBox(height: 6),
      Text(body, style: _body(c), textAlign: TextAlign.center),
      if (actionLabel != null && onAction != null) ...[
        const SizedBox(height: 10),
        TextButton(
          onPressed: onAction,
          child: Text(actionLabel!, style: TextStyle(color: c.brandText, fontSize: ChatSize.buttonFont, fontWeight: FontWeight.w600)),
        ),
      ],
    ]);
  }
}

/// Screen 04 — nothing cached and the load failed.
class ChatErrorView extends StatelessWidget {
  const ChatErrorView({super.key, required this.title, required this.body, required this.onRetry, this.icon});

  final String title;
  final String body;
  final VoidCallback onRetry;
  final IconData? icon;

  factory ChatErrorView.forList(ChatFailure? f, VoidCallback onRetry) => ChatErrorView(
        title: ChatCopy.listErrorTitle(f),
        body: ChatCopy.listErrorBody(f),
        icon: f?.kind == ChatFailureKind.offline ? Icons.wifi_off_rounded : Icons.cloud_off_rounded,
        onRetry: onRetry,
      );

  @override
  Widget build(BuildContext context) {
    final c = ChatColors.of(context);
    return _Centered(children: [
      Container(
        width: ChatSize.stateIconCircle,
        height: ChatSize.stateIconCircle,
        decoration: BoxDecoration(color: c.chip, shape: BoxShape.circle),
        child: Icon(icon ?? Icons.wifi_off_rounded, size: ChatSize.stateIcon, color: c.muted),
      ),
      const SizedBox(height: 14),
      Text(title, style: _title(c), textAlign: TextAlign.center),
      const SizedBox(height: 8),
      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 273),
        child: Text(body, style: _body(c), textAlign: TextAlign.center),
      ),
      const SizedBox(height: 16),
      ChatPrimaryButton(label: 'Try again', icon: Icons.refresh_rounded, onPressed: onRetry),
    ]);
  }
}

enum ChatBannerTone { warn, neutral, error }

/// Thin full-width banner (screens 01 cached-error, 11 offline/reconnecting).
class ChatBanner extends StatelessWidget {
  const ChatBanner({super.key, required this.text, required this.icon, this.tone = ChatBannerTone.warn, this.actionLabel, this.onAction});

  final String text;
  final IconData icon;
  final ChatBannerTone tone;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final c = ChatColors.of(context);
    final (bg, fg) = switch (tone) {
      ChatBannerTone.warn => (c.warnBg, c.warn),
      ChatBannerTone.neutral => (c.chip, c.text2),
      ChatBannerTone.error => (c.errBg, c.err),
    };
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        color: bg,
        padding: ChatSize.bannerPadding,
        child: Row(
          children: [
            Icon(icon, size: ChatSize.bannerIcon, color: fg),
            const SizedBox(width: 9),
            Expanded(
              child: Text(text, style: TextStyle(fontSize: ChatSize.bannerFont, color: fg, fontWeight: FontWeight.w500)),
            ),
            if (actionLabel != null && onAction != null)
              GestureDetector(
                onTap: onAction,
                child: Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: Text(actionLabel!,
                      style: TextStyle(fontSize: ChatSize.bannerFont, color: c.brandText, fontWeight: FontWeight.w600)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Maps connection status to the banner shown in a thread (null = none).
Widget? connectionBannerFor(ChatConnectionStatus status) => switch (status) {
      ChatConnectionStatus.offline =>
        const ChatBanner(text: ChatCopy.offlineBanner, icon: Icons.wifi_off_rounded, tone: ChatBannerTone.warn),
      ChatConnectionStatus.reconnecting =>
        const ChatBanner(text: ChatCopy.reconnectingBanner, icon: Icons.refresh_rounded, tone: ChatBannerTone.neutral),
      ChatConnectionStatus.authFailed =>
        const ChatBanner(text: ChatCopy.sessionBanner, icon: Icons.lock_outline_rounded, tone: ChatBannerTone.error),
      ChatConnectionStatus.suspended =>
        const ChatBanner(text: ChatCopy.suspendedBanner, icon: Icons.block_rounded, tone: ChatBannerTone.error),
      _ => null,
    };
