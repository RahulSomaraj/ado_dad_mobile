import 'package:ado_dad_user/common/get_responsive_size.dart';
import 'package:ado_dad_user/common/notification_badge_service.dart';
import 'package:ado_dad_user/common/shared_pref.dart';
import 'package:ado_dad_user/common/widgets/ado_dad_logo.dart';
import 'package:ado_dad_user/features/home/ui/widgets/location_chip.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Colours of the home header — design "Option C · Indigo night".
///
/// The header is indigo in light and dark theme alike, so these are
/// constants rather than brightness-aware getters.
class HomeHeroPalette {
  HomeHeroPalette._();

  static const Color indigoDeep = Color(0xFF141238);
  static const Color indigoMid = Color(0xFF221E5C);
  static const Color indigoBright = Color(0xFF3B32A0);

  /// Lavender for the name, the location line and accents on the indigo.
  static const Color lavender = Color(0xFFC7D2FE);

  /// Accent for links / active dots on light surfaces (7.3:1 on white).
  static const Color accent = Color(0xFF4338CA);

  /// Unread dot on the bell.
  static const Color dot = Color(0xFFFB923C);

  static Color glass([double a = 0.1]) => Colors.white.withValues(alpha: a);
  static Color glassBorder([double a = 0.2]) =>
      Colors.white.withValues(alpha: a);

  static const LinearGradient gradient = LinearGradient(
    begin: Alignment(-0.35, -1),
    end: Alignment(0.35, 1),
    colors: [indigoDeep, indigoMid, indigoBright],
    stops: [0, 0.55, 1],
  );

  /// Serif display face for the greeting and section titles.
  static TextStyle display({
    required double size,
    Color color = Colors.white,
    FontStyle style = FontStyle.normal,
    double height = 1.12,
  }) =>
      GoogleFonts.playfairDisplay(
        fontSize: size,
        fontWeight: FontWeight.w700,
        fontStyle: style,
        height: height,
        color: color,
      );
}

/// "Good afternoon, Rahul" for a signed-in user; "Good afternoon" signed out.
/// Returns the greeting and the first name separately so the name can be
/// styled on its own.
({String greeting, String? firstName}) homeGreeting(
    String? fullName, DateTime now) {
  final h = now.hour;
  final greeting = h < 12
      ? 'Good morning'
      : h < 17
          ? 'Good afternoon'
          : 'Good evening';
  final first = (fullName ?? '').trim().split(RegExp(r'\s+')).first;
  return (greeting: greeting, firstName: first.isEmpty ? null : first);
}

/// Full-bleed indigo header at the top of Home: logo + bell, location line,
/// serif greeting with the user's first name, prompt and glass search.
///
/// [bottomInset] leaves room at the bottom for the floating category card,
/// which the page overlaps onto the header.
class HomeHero extends StatelessWidget {
  const HomeHero({
    super.key,
    required this.onLocationTap,
    required this.onNotificationsTap,
    required this.onSearchTap,
    this.bottomInset = 86,
  });

  final VoidCallback onLocationTap;
  final VoidCallback onNotificationsTap;
  final VoidCallback onSearchTap;
  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final bool tab = GetResponsiveSize.isTablet(context);
    final double headline = tab ? 40 : 30;
    final double hPad = tab ? 32 : 20;

    return DecoratedBox(
      decoration: const BoxDecoration(gradient: HomeHeroPalette.gradient),
      child: Padding(
        padding: EdgeInsets.fromLTRB(hPad, topPad + 14, hPad, bottomInset),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                AdoDadLogo(height: tab ? 40 : 28),
                const Spacer(),
                HomeBellButton(onTap: onNotificationsTap),
              ],
            ),
            const SizedBox(height: 18),
            _LocationLine(onTap: onLocationTap, fontSize: tab ? 15 : 13),
            const SizedBox(height: 6),
            // Rebuilds on login, logout and profile-name edits.
            ValueListenableBuilder<String?>(
              valueListenable: currentUserName,
              builder: (context, name, _) {
                final g = homeGreeting(name, DateTime.now());
                return Text.rich(
                  TextSpan(
                    style: HomeHeroPalette.display(size: headline),
                    children: [
                      TextSpan(
                          text: g.firstName == null
                              ? g.greeting
                              : '${g.greeting}, '),
                      if (g.firstName != null)
                        TextSpan(
                          text: g.firstName,
                          style: HomeHeroPalette.display(
                            size: headline,
                            style: FontStyle.italic,
                            color: HomeHeroPalette.lavender,
                          ),
                        ),
                    ],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                );
              },
            ),
            const SizedBox(height: 6),
            Text(
              'What are you looking for today?',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.72),
                fontSize: tab ? 16 : 14,
              ),
            ),
            const SizedBox(height: 18),
            HomeGlassSearch(onTap: onSearchTap, height: tab ? 56 : 50),
          ],
        ),
      ),
    );
  }
}

/// Pin + place name + chevron in lavender. Opens the location picker.
class _LocationLine extends StatelessWidget {
  const _LocationLine({required this.onTap, required this.fontSize});

  final VoidCallback onTap;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_on_outlined,
                size: fontSize + 2, color: HomeHeroPalette.lavender),
            const SizedBox(width: 4),
            Flexible(
              child: LocationChip(
                fontSize: fontSize,
                onTap: onTap,
                color: HomeHeroPalette.lavender,
                textAlign: TextAlign.start,
                maxLines: 1,
              ),
            ),
            const SizedBox(width: 2),
            Icon(Icons.keyboard_arrow_down_rounded,
                size: fontSize + 4, color: HomeHeroPalette.lavender),
          ],
        ),
      ),
    );
  }
}

/// Round glass bell with the unread dot.
class HomeBellButton extends StatelessWidget {
  const HomeBellButton({super.key, required this.onTap, this.size = 38});

  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: NotificationBadgeService.hasUnread,
      builder: (context, hasUnread, _) => Semantics(
        button: true,
        label: hasUnread ? 'Notifications, unread' : 'Notifications',
        child: Material(
          color: HomeHeroPalette.glass(0.08),
          shape: CircleBorder(
              side: BorderSide(color: HomeHeroPalette.glassBorder())),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              width: size,
              height: size,
              child: Center(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.notifications_none_rounded,
                        size: 19, color: Colors.white),
                    if (hasUnread)
                      Positioned(
                        top: -1,
                        right: -1,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: HomeHeroPalette.dot,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: HomeHeroPalette.indigoMid, width: 1.5),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Glass search field on the indigo. Tapping opens the full search screen.
class HomeGlassSearch extends StatelessWidget {
  const HomeGlassSearch({super.key, required this.onTap, this.height = 50});

  final VoidCallback onTap;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Search cars, bikes, property',
      child: Material(
        color: HomeHeroPalette.glass(),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: HomeHeroPalette.glassBorder()),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: height,
            child: Row(
              children: [
                const SizedBox(width: 16),
                const Icon(Icons.search_rounded, color: Colors.white, size: 21),
                const SizedBox(width: 10),
                Expanded(
                  child: ExcludeSemantics(
                    child: Text(
                      'Search cars, bikes, property…',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(6),
                  child: Container(
                    width: height - 12,
                    height: height - 12,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.tune_rounded,
                        color: HomeHeroPalette.indigoMid, size: 19),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Pinned indigo header that slides in once the main header scrolls away:
/// logo, location, bell and search.
class HomeCompactHeader extends StatelessWidget {
  const HomeCompactHeader({
    super.key,
    required this.onLocationTap,
    required this.onNotificationsTap,
    required this.onSearchTap,
  });

  final VoidCallback onLocationTap;
  final VoidCallback onNotificationsTap;
  final VoidCallback onSearchTap;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final bool tab = GetResponsiveSize.isTablet(context);
    final double hPad = tab ? 28 : 16;
    const radius = BorderRadius.vertical(bottom: Radius.circular(24));
    return Container(
      decoration: BoxDecoration(
        gradient: HomeHeroPalette.gradient,
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: HomeHeroPalette.indigoDeep.withValues(alpha: 0.35),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(hPad, topPad + 10, hPad, 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              AdoDadLogo(height: tab ? 34 : 24),
              const SizedBox(width: 12),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: _LocationLine(
                      onTap: onLocationTap, fontSize: tab ? 14 : 12.5),
                ),
              ),
              const SizedBox(width: 8),
              HomeBellButton(onTap: onNotificationsTap, size: 36),
            ],
          ),
          const SizedBox(height: 10),
          HomeGlassSearch(onTap: onSearchTap, height: 44),
        ],
      ),
    );
  }
}
