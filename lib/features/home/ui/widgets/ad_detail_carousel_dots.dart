import 'package:ado_dad_user/common/get_responsive_size.dart';
import 'package:flutter/material.dart';

class AdDetailCarouselDots extends StatelessWidget {
  final int count;
  final int currentIndex;

  const AdDetailCarouselDots({
    super.key,
    required this.count,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: GetResponsiveSize.getResponsivePadding(
          context,
          mobile: 8,
          tablet: 10,
          largeTablet: 12,
          desktop: 14,
        ),
        bottom: GetResponsiveSize.getResponsivePadding(
          context,
          mobile: 6,
          tablet: 8,
          largeTablet: 10,
          desktop: 12,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(count, (i) {
          final isActive = i == currentIndex;
          final dotHeight = GetResponsiveSize.getResponsiveSize(
            context,
            mobile: 6,
            tablet: 8,
            largeTablet: 10,
            desktop: 12,
          );
          final dotWidth = isActive
              ? GetResponsiveSize.getResponsiveSize(
                  context,
                  mobile: 14,
                  tablet: 18,
                  largeTablet: 22,
                  desktop: 26,
                )
              : dotHeight;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: EdgeInsets.symmetric(
              horizontal: GetResponsiveSize.getResponsiveSize(
                context,
                mobile: 3,
                tablet: 4,
                largeTablet: 5,
                desktop: 6,
              ),
            ),
            height: dotHeight,
            width: dotWidth,
            decoration: BoxDecoration(
              color: isActive ? Colors.indigo : Colors.grey.shade400,
              borderRadius: BorderRadius.circular(
                GetResponsiveSize.getResponsiveBorderRadius(
                  context,
                  mobile: 4,
                  tablet: 5,
                  largeTablet: 6,
                  desktop: 6,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
