// Screens 02 / 07: skeletons shaped exactly like the content they replace.

import 'package:flutter/material.dart';

import 'chat_tokens.dart';

class _Pulse extends StatefulWidget {
  const _Pulse({required this.child});
  final Widget child;

  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (ChatMotion.reduced(context)) {
      _c.stop();
      _c.value = 0;
    } else if (!_c.isAnimating) {
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: Tween<double>(begin: 1, end: 0.5).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut)),
        child: widget.child,
      );
}

Widget _bar(ChatColors c, {double? width, required double height, double radius = 6, double? widthFactor}) {
  final box = Container(
    width: width,
    height: height,
    decoration: BoxDecoration(color: c.skeleton, borderRadius: BorderRadius.circular(radius)),
  );
  return widthFactor == null ? box : FractionallySizedBox(widthFactor: widthFactor, alignment: Alignment.centerLeft, child: box);
}

class ConversationSkeletonList extends StatelessWidget {
  const ConversationSkeletonList({super.key, this.count = 6});
  final int count;

  static const _widths = [
    [0.44, 0.62, 0.8],
    [0.36, 0.54, 0.7],
    [0.5, 0.58, 0.76],
    [0.4, 0.48, 0.66],
  ];

  @override
  Widget build(BuildContext context) {
    final c = ChatColors.of(context);
    return _Pulse(
      child: Column(
        children: [
          for (var i = 0; i < count; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: ChatSize.gutter, vertical: ChatSize.rowVPad),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _bar(c, width: ChatSize.avatar, height: ChatSize.avatar, radius: ChatSize.avatar / 2),
                  const SizedBox(width: ChatSize.avatarGap),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Expanded(child: _bar(c, height: 12, widthFactor: _widths[i % 4][0])),
                            _bar(c, width: 34, height: 9),
                          ]),
                          const SizedBox(height: 8),
                          _bar(c, height: 9, widthFactor: _widths[i % 4][1]),
                          const SizedBox(height: 8),
                          _bar(c, height: 10.5, widthFactor: _widths[i % 4][2]),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Alternating bubble placeholders (screen 07), bottom-aligned like a thread.
class BubbleSkeleton extends StatelessWidget {
  const BubbleSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final c = ChatColors.of(context);
    Widget bubble(bool mine, double f, double h) => Align(
          alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: f,
            child: Container(
              height: h,
              margin: const EdgeInsets.only(bottom: 9),
              decoration: BoxDecoration(
                color: mine ? c.brand.withValues(alpha: 0.2) : c.skeleton,
                borderRadius: BorderRadius.circular(ChatSize.bubbleRadius),
              ),
            ),
          ),
        );
    return _Pulse(
      child: Padding(
        padding: ChatSize.messagesPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Center(child: _bar(c, width: 60, height: 18, radius: 9)),
            const SizedBox(height: 9),
            bubble(false, 0.62, 36),
            bubble(false, 0.4, 36),
            bubble(true, 0.58, 57),
            bubble(false, 0.36, 36),
          ],
        ),
      ),
    );
  }
}
