import 'package:ado_dad_user/common/app_colors.dart';
import 'package:flutter/material.dart';

/// A single shimmering placeholder block. Pulses gently between two greys that
/// adapt to light/dark. Used to build skeleton loading screens so the app
/// *feels* fast while data is being fetched.
class SkeletonBox extends StatefulWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const SkeletonBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color base =
        AppColors.isDark ? const Color(0xFF222A36) : const Color(0xFFE9ECF2);
    final animation = Tween<double>(begin: 0.45, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    return FadeTransition(
      opacity: animation,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: base,
          borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
        ),
      ),
    );
  }
}

/// A placeholder shaped like an ad card (image area + price + two text lines).
class SkeletonAdCard extends StatelessWidget {
  const SkeletonAdCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.dividerColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Expanded(
            child: SkeletonBox(borderRadius: BorderRadius.zero),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: const [
                SkeletonBox(height: 14, width: 70),
                SizedBox(height: 8),
                SkeletonBox(height: 10, width: double.infinity),
                SizedBox(height: 6),
                SkeletonBox(height: 10, width: 110),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A grid of skeleton ad cards. Mirrors the real grid's column count and card
/// height so the transition from skeleton to data is seamless.
class SkeletonAdGrid extends StatelessWidget {
  final int crossAxisCount;
  final double mainAxisExtent;
  final int itemCount;
  final double crossAxisSpacing;
  final double mainAxisSpacing;

  const SkeletonAdGrid({
    super.key,
    required this.crossAxisCount,
    required this.mainAxisExtent,
    this.itemCount = 6,
    this.crossAxisSpacing = 15,
    this.mainAxisSpacing = 15,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: itemCount,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: crossAxisSpacing,
        mainAxisSpacing: mainAxisSpacing,
        mainAxisExtent: mainAxisExtent,
      ),
      itemBuilder: (context, index) => const SkeletonAdCard(),
    );
  }
}

/// A placeholder shaped like a horizontal list row (thumbnail + lines).
class SkeletonListCard extends StatelessWidget {
  const SkeletonListCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.dividerColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonBox(
            width: 110,
            height: 92,
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SkeletonBox(height: 14, width: 90),
                SizedBox(height: 10),
                SkeletonBox(height: 11, width: double.infinity),
                SizedBox(height: 6),
                SkeletonBox(height: 11, width: 160),
                SizedBox(height: 12),
                SkeletonBox(height: 11, width: 120),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A vertical list of skeleton rows. Drop-in replacement for a full-screen
/// loading spinner on list-style screens.
class SkeletonList extends StatelessWidget {
  final int itemCount;
  const SkeletonList({super.key, this.itemCount = 6});

  @override
  Widget build(BuildContext context) {
    // shrinkWrap + non-scrolling so it is safe both as a full-screen body and
    // when placed inside an existing Column / scroll view (no unbounded-height
    // crashes). Loading is brief, so scrolling is unnecessary.
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (context, index) => const SkeletonListCard(),
    );
  }
}
