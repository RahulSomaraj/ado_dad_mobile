import 'package:ado_dad_user/common/app_colors.dart';
import 'package:flutter/widgets.dart';

/// Keeps the brightness-aware [AppColors] getters in sync with the applied
/// theme and makes every screen repaint when it changes.
///
/// Why: widgets that read `AppColors.whiteColor` / `blackColor` / … do not
/// depend on `Theme.of(context)`, so Flutter has no reason to rebuild them
/// when the theme flips — screens already on the navigation stack (and the
/// other bottom-nav tabs) kept their old colours until the app restarted.
/// After a brightness change we mark the whole element tree dirty once, on
/// the next frame, so everything rebuilds with the new colours while keeping
/// all navigation and widget state.
class ThemeRefresh {
  ThemeRefresh._();

  static bool _scheduled = false;

  /// Call from `MaterialApp.builder` with `Theme.of(context).brightness`.
  static void sync(Brightness brightness) {
    if (AppColors.brightness == brightness) return;
    AppColors.brightness = brightness;
    if (_scheduled) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      final Element? root = WidgetsBinding.instance.rootElement;
      if (root == null) return;
      void rebuild(Element element) {
        element.markNeedsBuild();
        element.visitChildren(rebuild);
      }

      root.visitChildren(rebuild);
    });
  }
}
