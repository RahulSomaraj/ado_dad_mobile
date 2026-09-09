import 'package:flutter/material.dart';

/// Ado Dad brand lockup: the "d" mark beside the "Ado Dad" wordmark.
///
/// Both source assets are white on transparent, so [color] is applied as a
/// tint. Use white on the purple header and the primary colour on light
/// backgrounds.
class AdoDadLogo extends StatelessWidget {
  const AdoDadLogo({
    super.key,
    required this.height,
    this.color = Colors.white,
  });

  /// Height of the mark. The wordmark and the gap scale from it.
  final double height;

  /// Tint applied to both images.
  final Color color;

  static const String markAsset = 'assets/images/ado-d.png';
  static const String wordmarkAsset = 'assets/images/adodad-v1.png';

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Image.asset(
          markAsset,
          height: height,
          color: color,
          fit: BoxFit.contain,
        ),
        SizedBox(width: height * 0.3),
        Image.asset(
          wordmarkAsset,
          height: height * 0.55,
          color: color,
          fit: BoxFit.contain,
        ),
      ],
    );
  }
}
