import 'package:ado_dad_user/common/app_colors.dart';
import 'package:ado_dad_user/common/brand_header.dart';
import 'package:ado_dad_user/common/get_responsive_size.dart';
import 'package:ado_dad_user/common/notification_badge_service.dart';
import 'package:ado_dad_user/common/shared_pref.dart';
import 'package:ado_dad_user/common/widgets/ado_dad_logo.dart';
import 'package:ado_dad_user/features/home/ui/widgets/location_chip.dart';
import 'package:flutter/material.dart';

// The palette lives in common so Profile and Chat share the Home header look.
export 'package:ado_dad_user/common/brand_header.dart';

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

/// Full-bleed blue header at the top of Home: logo + bell, location line,
/// greeting with the user's first name, prompt and glass search.
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
      decoration: BoxDecoration(gradient: HomeHeroPalette.gradient),
      child: Padding(
        padding: EdgeInsets.fromLTRB(hPad, topPad + 14, hPad, bottomInset),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Logo left; location pill + notifications top right.
            Row(
              children: [
                AdoDadLogo(height: tab ? 40 : 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: _LocationLine(
                      onTap: onLocationTap,
                      fontSize: tab ? 15 : 13,
                      pillHeight: tab ? 44 : 38,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                HomeBellButton(onTap: onNotificationsTap, size: tab ? 44 : 38),
              ],
            ),
            const SizedBox(height: 22),
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
                            color: HomeHeroPalette.soft,
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
                color: Colors.white.withValues(alpha: 0.88),
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

/// Pin + place name + chevron in pale blue. Opens the location picker.
class _LocationLine extends StatelessWidget {
  const _LocationLine({
    required this.onTap,
    required this.fontSize,
    this.pillHeight,
  });

  final VoidCallback onTap;
  final double fontSize;

  /// When set, the line is drawn as a glass pill of this height (top right
  /// of the header, beside the bell).
  final double? pillHeight;

  @override
  Widget build(BuildContext context) {
    final bool pill = pillHeight != null;
    final Color fg = pill ? Colors.white : HomeHeroPalette.soft;
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.location_on_outlined,
            size: fontSize + 2, color: HomeHeroPalette.soft),
        const SizedBox(width: 4),
        Flexible(
          child: LocationChip(
            fontSize: fontSize,
            onTap: onTap,
            color: fg,
            textAlign: TextAlign.start,
            maxLines: 1,
          ),
        ),
        const SizedBox(width: 2),
        Icon(Icons.keyboard_arrow_down_rounded,
            size: fontSize + 4, color: fg),
      ],
    );

    if (!pill) {
      return Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: row,
          ),
        ),
      );
    }

    return Material(
      color: HomeHeroPalette.glass(0.12),
      shape: StadiumBorder(
          side: BorderSide(color: HomeHeroPalette.glassBorder())),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: pillHeight,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            // widthFactor 1: hug the place name instead of filling the row.
            child: Center(widthFactor: 1, child: row),
          ),
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
                                color: HomeHeroPalette.mid, width: 1.5),
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

/// Glass search field on the blue header. Tapping opens the full search screen.
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
                        color: Colors.white.withValues(alpha: 0.88),
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
                    // Filter is an action: action orange, like every other
                    // primary action button in the app.
                    decoration: BoxDecoration(
                      color: AppColors.ctaColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.tune_rounded,
                        color: AppColors.onCta, size: 19),
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

/// Pinned blue header that slides in once the main header scrolls away:
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
            color: HomeHeroPalette.shadowInk.withValues(alpha: 0.35),
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
                    onTap: onLocationTap,
                    fontSize: tab ? 14 : 12.5,
                    pillHeight: 36,
                  ),
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
