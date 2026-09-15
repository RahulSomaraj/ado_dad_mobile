// Screens 06, 09, 10, 12: date separator, bubbles (text / image / voice),
// status meta and the "Not sent" note.

import 'package:ado_dad_user/common/widgets/app_network_image.dart';
import 'package:flutter/material.dart';

import '../data/chat_models.dart';
import 'chat_audio_controller.dart';
import 'chat_copy.dart';
import 'chat_format.dart';
import 'chat_tokens.dart';

class ChatDateSeparator extends StatelessWidget {
  const ChatDateSeparator({super.key, required this.date});
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final c = ChatColors.of(context);
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: ChatSize.dateMargin),
        padding: ChatSize.datePadding,
        decoration: BoxDecoration(color: c.chip, borderRadius: BorderRadius.circular(ChatSize.dateRadius)),
        child: Text(
          formatDateLabel(date),
          style: TextStyle(fontSize: ChatSize.dateFont, color: c.muted, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}

/// One message with grouping handled by the caller:
/// [tail] = last of a same-sender run (small corner + time shown),
/// [topGap] = space above (3 dp same sender, 9 dp on sender switch).
class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.mine,
    required this.tail,
    required this.topGap,
    this.onRetry,
    this.onEdit,
    this.onDelete,
    this.onOpenImage,
  });

  final ChatMessage message;
  final bool mine;
  final bool tail;
  final double topGap;
  final VoidCallback? onRetry;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final void Function(String url)? onOpenImage;

  @override
  Widget build(BuildContext context) {
    final c = ChatColors.of(context);
    final failed = message.status == MessageStatus.failed;
    final maxWidth = MediaQuery.sizeOf(context).width * ChatSize.bubbleMaxWidthFactor;

    Widget body = switch (message.type) {
      MessageType.image => _ImageContent(message: message, mine: mine, tail: tail, onOpen: onOpenImage),
      MessageType.audio => _Bubble(message: message, mine: mine, tail: tail, child: _VoiceContent(message: message, mine: mine)),
      _ => _Bubble(
          message: message,
          mine: mine,
          tail: tail,
          child: Text(
            message.content,
            style: TextStyle(
              fontSize: ChatSize.bubbleFont,
              height: ChatSize.bubbleLineHeight,
              color: mine && !failed ? c.onBrand : c.text,
            ),
          ),
        ),
    };

    return Padding(
      padding: EdgeInsets.only(top: topGap),
      child: Column(
        crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: GestureDetector(
              onTap: failed && ChatCopy.canRetry(message.failure) ? onRetry : null,
              onLongPress: failed ? () => _showFailedActions(context) : null,
              child: body,
            ),
          ),
          if (failed) _FailNote(message: message, onRetry: onRetry, onEdit: onEdit),
        ],
      ),
    );
  }

  void _showFailedActions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onRetry != null && ChatCopy.canRetry(message.failure))
              ListTile(
                leading: const Icon(Icons.refresh_rounded),
                title: const Text('Retry'),
                onTap: () {
                  Navigator.pop(ctx);
                  onRetry!();
                },
              ),
            if (onEdit != null && message.type == MessageType.text)
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit'),
                onTap: () {
                  Navigator.pop(ctx);
                  onEdit!();
                },
              ),
            if (onDelete != null)
              ListTile(
                leading: Icon(Icons.delete_outline_rounded, color: ChatColors.of(context).err),
                title: Text('Delete', style: TextStyle(color: ChatColors.of(context).err)),
                onTap: () {
                  Navigator.pop(ctx);
                  onDelete!();
                },
              ),
          ],
        ),
      ),
    );
  }
}

BorderRadius _radius({required bool mine, required bool tail, double r = ChatSize.bubbleRadius}) {
  final big = Radius.circular(r);
  const small = Radius.circular(ChatSize.bubbleTail);
  return BorderRadius.only(
    topLeft: big,
    topRight: big,
    bottomLeft: !mine && tail ? small : big,
    bottomRight: mine && tail ? small : big,
  );
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.mine, required this.tail, required this.child});

  final ChatMessage message;
  final bool mine;
  final bool tail;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = ChatColors.of(context);
    final failed = message.status == MessageStatus.failed;
    final Color bg;
    if (failed) {
      bg = c.errBg;
    } else if (!mine) {
      bg = c.surface;
    } else if (message.isPending) {
      bg = c.brandPending;
    } else {
      bg = c.brand;
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: _radius(mine: mine, tail: tail),
        border: failed
            ? Border.all(color: c.err)
            : (!mine ? Border.all(color: c.divider, width: 0.7) : null),
      ),
      child: Padding(
        padding: ChatSize.bubblePadding,
        child: IntrinsicWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              child,
              if (tail || failed || message.isPending) ...[
                const SizedBox(height: 1.5),
                Align(
                  alignment: Alignment.centerRight,
                  child: MessageMeta(message: message, mine: mine),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// `09:31 ✓✓` · `Sending ⏲` · `⚠`
class MessageMeta extends StatelessWidget {
  const MessageMeta({super.key, required this.message, required this.mine, this.onImage = false});

  final ChatMessage message;
  final bool mine;
  final bool onImage;

  @override
  Widget build(BuildContext context) {
    final c = ChatColors.of(context);
    final failed = message.status == MessageStatus.failed;
    final Color fg = onImage
        ? Colors.white
        : failed
            ? c.err
            : mine
                ? c.onBrand.withValues(alpha: 0.78)
                : c.muted;
    final style = TextStyle(fontSize: ChatSize.metaFont, color: fg, fontFeatures: const [FontFeature.tabularFigures()]);

    if (failed) return Icon(Icons.error_outline_rounded, size: ChatSize.metaIcon, color: c.err);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(message.isPending ? 'Sending' : formatClock(message.createdAt), style: style),
        if (mine) ...[
          const SizedBox(width: 3),
          Icon(
            switch (message.status) {
              MessageStatus.sending => Icons.schedule_rounded,
              MessageStatus.read => Icons.done_all_rounded,
              _ => Icons.done_rounded,
            },
            size: ChatSize.metaIcon,
            color: message.status == MessageStatus.read && !onImage ? c.readTick : fg,
            semanticLabel: switch (message.status) {
              MessageStatus.sending => 'Sending',
              MessageStatus.read => 'Read',
              _ => 'Sent',
            },
          ),
        ],
      ],
    );
  }
}

class _FailNote extends StatelessWidget {
  const _FailNote({required this.message, this.onRetry, this.onEdit});

  final ChatMessage message;
  final VoidCallback? onRetry;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final c = ChatColors.of(context);
    final retry = ChatCopy.canRetry(message.failure);
    final action = retry ? onRetry : onEdit;
    return Padding(
      padding: const EdgeInsets.only(top: 3, right: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              'Not sent · ${ChatCopy.failReason(message.failure)}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: TextStyle(fontSize: ChatSize.failFont, color: c.err, fontWeight: FontWeight.w500),
            ),
          ),
          if (action != null) ...[
            const SizedBox(width: 6),
            GestureDetector(
              onTap: action,
              child: Text(
                retry ? 'Retry' : 'Edit',
                style: TextStyle(fontSize: ChatSize.failFont, color: c.brandText, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ImageContent extends StatelessWidget {
  const _ImageContent({required this.message, required this.mine, required this.tail, this.onOpen});

  final ChatMessage message;
  final bool mine;
  final bool tail;
  final void Function(String url)? onOpen;

  @override
  Widget build(BuildContext context) {
    final c = ChatColors.of(context);
    final att = message.firstAttachment;
    var size = ChatSize.imageBubble;
    if (att?.width != null && att?.height != null && att!.width! > 0) {
      final h = (size.width * att.height! / att.width!).clamp(120.0, 260.0).toDouble();
      size = Size(size.width, h);
    }
    final radius = _radius(mine: mine, tail: tail, r: ChatSize.imageRadius);
    final uploading = message.isPending;
    final failed = message.status == MessageStatus.failed;

    Widget image;
    if (message.localBytes != null) {
      image = Image.memory(message.localBytes!, width: size.width, height: size.height, fit: BoxFit.cover, gaplessPlayback: true);
    } else if (att != null && att.url.isNotEmpty) {
      image = AppNetworkImage(url: att.url, width: size.width, height: size.height);
    } else {
      image = ColoredBox(color: c.chip);
    }

    return GestureDetector(
      onTap: att != null && att.url.isNotEmpty && !uploading ? () => onOpen?.call(att.url) : null,
      child: Container(
        width: size.width,
        height: size.height,
        decoration: BoxDecoration(
          borderRadius: radius,
          border: failed ? Border.all(color: c.err, width: 1.5) : null,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            image,
            if (uploading)
              ColoredBox(
                color: const Color(0x590F0F19),
                child: Center(
                  child: SizedBox(
                    width: ChatSize.progressRing,
                    height: ChatSize.progressRing,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: (message.uploadProgress ?? 0) <= 0 ? null : message.uploadProgress,
                          strokeWidth: 4,
                          color: Colors.white,
                          backgroundColor: Colors.white.withValues(alpha: 0.3),
                        ),
                        Text(
                          '${((message.uploadProgress ?? 0) * 100).round()}%',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (!uploading && tail)
              Positioned(
                right: 8,
                bottom: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.35), borderRadius: BorderRadius.circular(8)),
                  child: MessageMeta(message: message, mine: mine, onImage: true),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _VoiceContent extends StatelessWidget {
  const _VoiceContent({required this.message, required this.mine});

  final ChatMessage message;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final c = ChatColors.of(context);
    final att = message.firstAttachment;
    final url = att?.url ?? '';
    final fg = mine && message.status != MessageStatus.failed ? c.onBrand : c.brandText;
    final total = att?.durationSec ?? 0;

    return ValueListenableBuilder<VoicePlayback>(
      valueListenable: ChatAudioController.instance.state,
      builder: (context, pb, _) {
        final active = url.isNotEmpty && pb.isFor(url);
        final playing = active && pb.playing;
        final loading = active && pb.loading;
        final durationMs = (pb.duration?.inMilliseconds ?? total * 1000);
        final progress = active && durationMs > 0 ? (pb.position.inMilliseconds / durationMs).clamp(0.0, 1.0).toDouble() : 0.0;
        final label = active && (playing || pb.position > Duration.zero)
            ? formatDuration(pb.position.inSeconds)
            : formatDuration(total);

        return ConstrainedBox(
          constraints: const BoxConstraints(minWidth: ChatSize.voiceMinWidth),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkResponse(
                onTap: url.isEmpty || message.isPending
                    ? null
                    : () => ChatAudioController.instance.toggle(url).catchError((_) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Couldn\'t play this voice message.')),
                            );
                          }
                        }),
                radius: 22,
                child: Container(
                  width: ChatSize.voicePlay,
                  height: ChatSize.voicePlay,
                  decoration: BoxDecoration(
                    color: mine ? Colors.white.withValues(alpha: 0.22) : c.chip,
                    shape: BoxShape.circle,
                  ),
                  child: loading || message.isPending
                      ? Padding(
                          padding: const EdgeInsets.all(9),
                          child: CircularProgressIndicator(strokeWidth: 2, color: fg),
                        )
                      : Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 21, color: fg),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: _Waveform(seed: url.hashCode, progress: progress, color: fg)),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(fontSize: 11.5, color: fg, fontFeatures: const [FontFeature.tabularFigures()]),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Waveform extends StatelessWidget {
  const _Waveform({required this.seed, required this.progress, required this.color});

  final int seed;
  final double progress;
  final Color color;

  static const _bars = 22;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: ChatSize.waveHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(_bars, (i) {
          final v = ((seed >> (i % 16)) ^ (i * 7919)) & 0xF;
          final h = 5.0 + (v / 15.0) * (ChatSize.waveHeight - 5);
          final played = i / _bars < progress;
          return Container(
            width: 2.5,
            height: h,
            decoration: BoxDecoration(
              color: color.withValues(alpha: played ? 1 : 0.55),
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }),
      ),
    );
  }
}
