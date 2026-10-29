import 'package:ado_dad_user/common/app_colors.dart';
import 'package:ado_dad_user/common/app_fonts.dart';
import 'package:flutter/material.dart';

/// Colours of the brand header (Home, Profile, Chats) — the app's brand blue as a gradient.
///
/// Light theme: brand blue running to a lighter blue. Dark theme: the same
/// hue, deeper (navy into brand blue) so it does not glare at night.
/// Text on the header is always white / pale blue.
class HomeHeroPalette {
  HomeHeroPalette._();

  static bool get _dark => AppColors.isDark;

  /// Navy used for soft shadows under the header, card and banners.
  static const Color shadowInk = Color(0xFF0B1F44);

  /// Mid tone of the gradient (filter icon, bell dot ring).
  static Color get mid => _dark ? const Color(0xFF12306E) : AppColors.primaryColor;

  /// Pale blue for the user's name and the location line on the header.
  /// #DBEAFE on #2563EB is 4.6:1; #BFDBFE on the dark gradient is 8:1+.
  static Color get soft =>
      _dark ? const Color(0xFFBFDBFE) : const Color(0xFFDBEAFE);

  /// Unread dot on the bell.
  static const Color dot = Color(0xFFFB923C);

  static Color glass([double a = 0.14]) => Colors.white.withValues(alpha: a);
  static Color glassBorder([double a = 0.26]) =>
      Colors.white.withValues(alpha: a);

  static const LinearGradient _light = LinearGradient(
    begin: Alignment(-0.35, -1),
    end: Alignment(0.35, 1),
    colors: [Color(0xFF1E40AF), Color(0xFF1D4ED8), Color(0xFF2563EB)],
    stops: [0, 0.5, 1],
  );

  static const LinearGradient _darkGradient = LinearGradient(
    begin: Alignment(-0.35, -1),
    end: Alignment(0.35, 1),
    colors: [Color(0xFF0B1F44), Color(0xFF12306E), Color(0xFF1E40AF)],
    stops: [0, 0.55, 1],
  );

  static LinearGradient get gradient => _dark ? _darkGradient : _light;

  /// Display style for the greeting and section titles — the app font
  /// (see app_fonts.dart) at extra-bold, so Home uses one family throughout.
  static TextStyle display({
    required double size,
    Color color = Colors.white,
    FontStyle style = FontStyle.normal,
    double height = 1.15,
  }) =>
      appFont(
        fontSize: size,
        fontWeight: FontWeight.w800,
        fontStyle: style,
        height: height,
        letterSpacing: -0.4,
        color: color,
      );
}

/// Brand-blue gradient header block used at the top of Home-style screens
/// (Profile, Chats): rounded bottom corners, white content, status-bar safe.
class BrandHeader extends StatelessWidget {
  const BrandHeader({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(20, 12, 20, 20),
    this.radius = 28,
    this.includeStatusBar = true,
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final bool includeStatusBar;

  @override
  Widget build(BuildContext context) {
    final top = includeStatusBar ? MediaQuery.of(context).padding.top : 0.0;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: HomeHeroPalette.gradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(radius)),
        boxShadow: [
          BoxShadow(
            color: HomeHeroPalette.shadowInk.withValues(alpha: 0.22),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: -6,
          ),
        ],
      ),
      padding: padding.copyWith(top: padding.top + top),
      child: child,
    );
  }
}

/// Round glass icon button for use on [BrandHeader].
class BrandHeaderIconButton extends StatelessWidget {
  const BrandHeaderIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    required this.tooltip,
    this.size = 40,
    this.color = Colors.white,
    this.background,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final String tooltip;
  final double size;
  final Color color;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: background ?? HomeHeroPalette.glass(0.12),
        shape: CircleBorder(
          side: background == null
              ? BorderSide(color: HomeHeroPalette.glassBorder())
              : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(icon, size: size * 0.5, color: color),
          ),
        ),
      ),
    );
  }
}
