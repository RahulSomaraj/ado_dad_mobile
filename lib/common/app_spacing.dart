import 'package:ado_dad_user/common/get_responsive_size.dart';
import 'package:flutter/widgets.dart';

/// 4 dp spacing scale. Use these instead of ad-hoc paddings so section edges
/// and gaps line up from one screen block to the next.
class AppSpacing {
  AppSpacing._();

  static const double xs4 = 4;
  static const double sm8 = 8;
  static const double md12 = 12;
  static const double lg16 = 16;
  static const double xl20 = 20;
  static const double xl24 = 24;
  static const double xxl32 = 32;

  /// Page side gutter.
  static const double gutter = lg16;

  /// Minimum touch target.
  static const double minTap = 48;

  /// Scales a phone dp value for tablets, matching the ratios the rest of the
  /// app uses through [GetResponsiveSize] (≈1.25× / 1.4× / 1.5×).
  static double s(BuildContext context, double dp) =>
      GetResponsiveSize.getResponsiveSize(
        context,
        mobile: dp,
        tablet: dp * 1.25,
        largeTablet: dp * 1.4,
        desktop: dp * 1.5,
      );
}

/// Corner radii. Four values only: chip, control, sheet, pill.
class AppRadius {
  AppRadius._();

  static const double small8 = 8;
  static const double chip8 = 8;
  static const double control12 = 12;
  static const double button12 = 12;
  static const double input12 = 12;
  static const double card16 = 16;
  static const double sheet16 = 16;
  static const double pill = 999;
}
