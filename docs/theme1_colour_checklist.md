# Theme 1 · Trust Blue · Action Orange — colour checklist

Branch: `feat/theme1-colours` (off `dev_redesign`). **Colour and light/dark only** — no layout, icon, copy or flow changes.
Design reference: Design canvas "AdoDad Mobile — Theme 1 (Light & Dark)" (35 screens × light/dark).

## Tokens (`lib/common/app_colors.dart`)

| Token | Light | Dark | Use |
|---|---|---|---|
| `primaryColor` (const) | `#1D4ED8` | `#1D4ED8` | brand FILLS with white content (buttons, selected chips, badges, header) |
| `brandText` | `#1D4ED8` | `#9DBBFF` | brand TEXT / ICONS / focus borders on a surface |
| `ctaColor` / `onCta` | `#CC4409` / white | `#FF7A3D` / `#121212` | **only** Sell (+), Call / Call seller, Post ad, chat call |
| `highlight` / `onHighlight` | `#FFC53D` / navy | `#FFD166` / `#121212` | PREMIUM tag |
| `scaffoldBackground` | `#F5F7FB` | `#0B1220` | |
| `whiteColor` (surface) | `#FFFFFF` | `#151D30` | |
| `blackColor` / `blackColor1` | `#0B1F44` / `#2E3D5C` | `#E8EDF7` / `#C3CCE0` | ink |
| `textMuted` / `greyColor` | `#5B6478` / `#8A93A6` | `#9AA6BD` | |
| `dividerColor` | `#E3E7F0` | `#263049` | |
| `chipFill` / `primarySoft` | `#EEF2F8` / `#E3ECFB` | `#1C2538` / `#1C2A4A` | |
| `positiveText` / `successColor` | `#12805A` | `#4ADE9A` / `#12805A` | |
| `redColor` | `#C62828` | `#C62828` | danger |

All text pairs ≥ 4.5:1 (orange button 4.8:1 light, 7.2:1 dark).

## Code checklist

- [x] C1 `app_colors.dart` — Theme 1 values; new `brandText`, `ctaColor`, `onCta`, `highlight`, `onHighlight`, raw `*Light/*Dark` consts
- [x] C2 `app_theme.dart` — scaffold/border tokens; focused input border, TextButton, bottom-nav selected → `brandText`; FAB theme → CTA
- [x] C3 Orange CTA — Sell button (`scaffold_with_nav_bar.dart`, legacy `home_page.dart` BottomNavBar), ad-detail Call (`ad_detail_bars.dart`), seller-profile Call, sell-flow **Post ad** (`SellButtonKind.cta` in `sell_ui.dart`, used in `sell_flow_page.dart`), chat `call` token
- [x] C4 Hardcoded violet retuned — `SellTokens` (brand/accent/track/disabled/info), `chat_tokens.dart` (brandText, soft, chip, divider, muted, pending, scrim), splash brand, lavender bgs (seller profile, My Ads, My Activity segmented, notifications), skeleton, ad-card tags (PREMIUM amber, FOR SALE/RENT blue, NEW green), notification kinds
- [x] C5 Dark-mode readability — 61 brand text/icon/border usages moved from `primaryColor` to `brandText` (only where not inside a `const` expression; 14 `const Icon/TextStyle` dropped `const` where no outer const existed)
- [ ] V1 `flutter analyze` clean (run on rahul-pc — not runnable from the Cowork VM)
- [ ] V2 Device pass, light + dark + system, against the screen checklist below

### Left on `primaryColor` on purpose (inside `const` parents — fine in light, slightly dim in dark)
`dialog_util.dart` 289/298, `update_app_dialog.dart` 79/85, `home_page.dart` 197 (header fill), `offer_popup.dart` 312, `report_ad_dialog.dart` 285, `login_page.dart` 168, `login_widget.dart` 59, `help.dart` 254, `change_password_dialog.dart` 355, `profile_card.dart` 77, `wishlist_page.dart` 323, `search_page.dart` 982, `ad_detail_gallery.dart` 359. Convert after V1 if wanted.

## Screen checklist (verify on device: Light ☐ / Dark ☐)

Onboarding: Splash · Login (OTP) · OTP verify · Login with password · Sign up
Home & discovery: Home · Location picker · Search · Search results + filters · Category list · Vehicle filters · Property filters
Listing: Ad detail (vehicle) · Ad detail (property) · Make an offer · Report ad · Seller profile · Showrooms · Showroom products
Chat: Chats · Chat thread · Notifications
Sell: What are you selling? · Photos · About · Price & place · Review (**Post ad orange**) · Submitted · Edit ad
Account: My Ads · Wishlist · Profile · Help · loading/empty/error states · route error

Check on each: no violet left; orange appears only on Sell / Call / Post ad; brand text readable in dark.
