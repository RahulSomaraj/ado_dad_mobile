// Chat design tokens — the single source for every size and colour in the chat
// UI (docs/chat_redesign_wireframes.html → app).
//
// SCALE RULE: the wireframe phone screen is 278 px wide; the Android baseline
// device is 360 dp. Every wireframe px value is multiplied by 1.3 and rounded
// (sizes to 0.5 dp, spacing to 1 dp), so on a 360 dp phone the chat screens have
// exactly the wireframe's proportions. Do not hard-code sizes in widgets —
// add a token here and note the wireframe source value next to it.

import 'package:ado_dad_user/common/app_colors.dart';
import 'package:flutter/material.dart';

class ChatColors {
  const ChatColors._(this.isDark);

  final bool isDark;

  static ChatColors of(BuildContext context) =>
      ChatColors._(Theme.of(context).brightness == Brightness.dark);

  // Brand — fills keep #4F48EC in both themes; brand-coloured TEXT lightens on dark.
  Color get brand => AppColors.primaryColor;
  Color get brandText => isDark ? const Color(0xFF9C98FF) : AppColors.primaryColor;
  Color get onBrand => Colors.white;
  Color get brandPending => const Color(0xFF8D88F2); // .b.pend
  Color get readTick => const Color(0xFFBFF0DA); // .b.out .rd

  // Surfaces
  Color get background => isDark ? AppColors.darkBackground : const Color(0xFFF6F7FB); // --a-bg
  Color get surface => isDark ? AppColors.darkSurface : Colors.white; // --a-surface
  Color get chip => isDark ? const Color(0xFF232833) : const Color(0xFFF4F5F9); // --a-chip
  Color get divider => isDark ? const Color(0xFF2A2F3A) : const Color(0xFFE6E8EE); // --a-div
  Color get soft => isDark ? const Color(0xFF26244A) : const Color(0xFFEDEBFF); // --a-soft
  Color get skeleton => divider;
  Color get scrim => const Color(0x610A0A14); // rgba(10,10,20,.38)

  // Text
  Color get text => isDark ? AppColors.darkText : AppColors.lightBlack; // --a-text
  Color get text2 => isDark ? AppColors.darkText1 : AppColors.lightBlack1; // --a-text2
  Color get muted => isDark ? AppColors.darkGrey : const Color(0xFF6B7080); // --a-muted

  // Semantic
  Color get okBg => isDark ? const Color(0xFF15372A) : const Color(0xFFE3F5EC);
  Color get ok => isDark ? const Color(0xFF5FD3A2) : const Color(0xFF12805A);
  Color get call => AppColors.successColor; // #19A463
  Color get warnBg => isDark ? const Color(0xFF3A2F12) : const Color(0xFFFFF3D6);
  Color get warn => isDark ? const Color(0xFFF2C66D) : const Color(0xFF7A5200);
  Color get errBg => isDark ? const Color(0xFF3D1B1E) : const Color(0xFFFDECEC);
  Color get err => isDark ? const Color(0xFFFF8A8A) : const Color(0xFFC23030);
  Color get recording => const Color(0xFFE5484D);
  Color get highlight => isDark ? const Color(0xFF6B5A12) : const Color(0xFFFFE58A);
  Color get onHighlight => isDark ? const Color(0xFFFFF3C4) : const Color(0xFF0A0A0A);
}

/// Sizes in dp. Comment = wireframe px.
abstract final class ChatSize {
  // ---- List (screens 01–05) ----
  static const double gutter = 18; // 14
  static const double listTitle = 24.5; // 19
  static const double searchFont = 15; // 11.5
  static const double searchRadius = 14; // 11
  static const EdgeInsets searchPadding = EdgeInsets.symmetric(horizontal: 13, vertical: 9); // 10 / 7
  static const double searchIcon = 16; // 12
  static const double chipFont = 13.5; // 10.5
  static const double chipCountFont = 11.5; // 9
  static const EdgeInsets chipPadding = EdgeInsets.symmetric(horizontal: 13, vertical: 5); // 10 / 4
  static const double chipRadius = 18; // 14
  static const double chipGap = 8; // 6
  static const double rowVPad = 13; // 10
  static const double avatar = 52; // 40
  static const double avatarSm = 44; // 34
  static const double avatarLg = 83; // 64
  static const double avatarThumb = 27; // 21
  static const double avatarThumbRadius = 8; // 6
  static const double avatarThumbOffset = 6.5; // 5
  static const double avatarRing = 2.5; // 2
  static const double avatarInitialFont = 19.5; // 15
  static const double avatarGap = 14; // 11
  static const double dividerInset = gutter + avatar + avatarGap; // 66 → 84
  static const double nameFont = 16; // 12.5
  static const double timeFont = 12.5; // 9.5
  static const double adLineFont = 13; // 10
  static const double adLineIcon = 13; // 10
  static const double previewFont = 15; // 11.5
  static const double badgeHeight = 22; // 17
  static const double badgeFont = 11.5; // 9
  static const double pillFont = 11; // 8.5
  static const EdgeInsets pillPadding = EdgeInsets.symmetric(horizontal: 8, vertical: 2.5); // 6 / 2
  static const double pillRadius = 6.5; // 5
  static const double progressLine = 2.5; // 2
  static const double groupLabelFont = 12.5; // 9.5

  // ---- Empty / error (03, 04) ----
  static const double stateTitle = 18; // 14
  static const double stateBody = 14.5; // 11
  static const double stateIconCircle = 68; // 52
  static const double stateIcon = 31; // 24
  static const double buttonFont = 15; // 11.5
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(horizontal: 21, vertical: 10); // 16 / 8
  static const double buttonRadius = 13; // 10

  // ---- Thread (06–12) ----
  static const EdgeInsets headerPadding = EdgeInsets.fromLTRB(4, 8, 8, 10); // 6 10 8
  static const double headerIconButton = 40; // 30
  static const double headerIcon = 22; // 17
  static const double headerName = 16; // 12.5
  static const double headerSub = 12.5; // 9.5
  static const EdgeInsets stripPadding = EdgeInsets.symmetric(horizontal: 16, vertical: 9); // 12 / 7
  static const Size stripThumb = Size(52, 42); // 40 × 32
  static const double stripThumbRadius = 9; // 7
  static const double stripTitle = 13.5; // 10.5
  static const double stripPrice = 15.5; // 12
  static const double stripView = 13; // 10
  static const EdgeInsets messagesPadding = EdgeInsets.fromLTRB(16, 10, 16, 13); // 12 8 12 10
  static const double bubbleMaxWidthFactor = 0.78;
  static const EdgeInsets bubblePadding = EdgeInsets.fromLTRB(13, 8, 13, 6.5); // 10 6 10 5
  static const double bubbleRadius = 20; // 15
  static const double bubbleTail = 5; // 4
  static const double bubbleFont = 15; // 11.5
  static const double bubbleLineHeight = 1.38;
  static const double metaFont = 11; // 8.5
  static const double metaIcon = 13; // 10
  static const double sameSenderGap = 3; // 2
  static const double senderSwitchGap = 9; // 7
  static const double dateFont = 12; // 9
  static const EdgeInsets datePadding = EdgeInsets.symmetric(horizontal: 12, vertical: 3); // 9 / 2
  static const double dateRadius = 12; // 9
  static const double dateMargin = 8; // 6
  static const double failFont = 12.5; // 9.5
  static const Size imageBubble = Size(195, 153); // 150 × 118
  static const double imageRadius = 18; // 14
  static const double progressRing = 47; // 36
  static const double voiceMinWidth = 195; // 150
  static const double voicePlay = 34; // 26
  static const double waveHeight = 23; // 18
  static const EdgeInsets composerPadding = EdgeInsets.fromLTRB(8, 10, 13, 13); // 10 8 10 10
  static const double fieldRadius = 24; // 18
  static const EdgeInsets fieldPadding = EdgeInsets.symmetric(horizontal: 16, vertical: 10); // 12 / 8
  static const double fieldFont = 15; // 11.5
  static const double sendButton = 42; // 32
  static const double composerIcon = 24;
  static const double trayThumb = 73; // 56
  static const double trayRadius = 12; // 9
  static const double trayRemove = 22; // 17
  static const EdgeInsets bannerPadding = EdgeInsets.symmetric(horizontal: 16, vertical: 8); // 12 / 6
  static const double bannerFont = 13.5; // 10.5
  static const double bannerIcon = 16; // 12
  static const double starterFont = 13.5; // 10.5
  static const double safetyFont = 13; // 10
  static const EdgeInsets safetyPadding = EdgeInsets.symmetric(horizontal: 13, vertical: 10); // 10 / 8
  static const double safetyRadius = 13; // 10
  static const double introCardRadius = 18; // 14
  static const double introImageHeight = 114; // 88
  static const double introPrice = 19.5; // 15
  static const double introSpecs = 14.5; // 11

  // ---- Details sheet (13) ----
  static const double sheetRadius = 23; // 18
  static const double sheetName = 18; // 14
  static const double sheetSub = 12.5; // 9.5
  static const double actionCircle = 49; // 38
  static const double actionLabel = 12.5; // 9.5
  static const double sheetRowFont = 15; // 11.5
  static const EdgeInsets sheetRowPadding = EdgeInsets.symmetric(horizontal: 21, vertical: 12); // 16 / 9
}

abstract final class ChatMotion {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 220);
  static bool reduced(BuildContext context) => MediaQuery.maybeOf(context)?.disableAnimations ?? false;
}
