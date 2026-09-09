# Login redesign — OTP first (plan v1, 2026-09-09)

## Current state (audited, branch dev_redesign @ d2e2cbe)
- `/login` → `Login()` → `LoginPage` (password). Text link "Login with OTP" pushes `/login-otp`.
- `/login-otp` → `OtpLoginPage` (phone default, email toggle, country picker). `/otp-verification` → `OtpVerificationPage(identifier, isEmail)`.
- Blocs: `LoginBloc` (login/logout/checkLoginStatus/forgotPassword), `OtpBloc` (sendOtp/verifyOtp) — flutter_bloc + freezed. **No bloc changes needed.**
- All logout / token-expiry / splash / signup-done paths `context.go('/login')`.

## Bug: number shows as +91919474414563
`otp_login_page.dart`: input formatter is `digitsOnly`; `_buildIdentifier()` = `'$_selectedCountryCode$trimmedValue'`; `_isPhone` = `^[0-9]+$` (no length check). Autofill/paste of `+91 94744 14563` → digits `919474414563` → prefixed again → `+91919474414563`. `otp_verification_page.dart` mask hard-codes `'+91 '`. `login_page.dart` `_getFormattedUsername()` has a slightly different rule (keeps input if it starts with `+`) — two pages, two behaviours.

Fix: `lib/common/phone_number_util.dart` — `normalise(raw, dialCode)`: strip non-digits → drop leading `0` → if it starts with the dial-code digits and length == dialCode.length + 10, drop them → valid iff 10 digits for +91 (7–15 otherwise). Returns `{national, e164, isValid}`. Used by OTP page, password page, signup, and the verify-page mask (dial code from the identifier, not hard-coded). Show the cleaned number back in the field + a live "Will send to +91 …" hint.

## Target flow
- `/login` = OTP page (phone default). "Use email instead" text link. Bottom: divider + full-width secondary button **Login with password**. Footer: New here? Create account · T&C.
- `/otp-verification`: "Sent to +91 94•••• ••63 · Change", 6 boxes, auto-submit on 6th digit, inline error (no snackbar), resend timer (existing 30 s), bottom **Login with password** fallback.
- `/login-password` = existing `LoginPage`, with the old "Login with OTP" link replaced by a mirrored bottom button **Login with OTP instead**.
- `/login-otp` kept as a redirect to `/login` for old deep links.

## Implementation order
1. Phone util + unit tests; wire into `otp_login_page.dart`, `otp_verification_page.dart` mask, `login_page.dart`. (Ship first — it's the user-visible bug.)
2. Route swap in `app_routes.dart`; add `/login-password` to `auth_guard.dart` public list. Nothing else changes.
3. Shared `lib/common/widgets/phone_or_email_field.dart` (country chip + number / email; exposes `identifier`, `isEmail`) replacing duplicated code in OTP, password, signup pages.
4. Screen copy/layout as in the wireframe.

## Open questions
- Does the OTP API return attempts-left / lockout? (drives the wrong-code copy)
- Keep email OTP, or phone-only OTP + email only on password page?
- SMS auto-read (`sms_autofill`) now or later?

Wireframe artifact: "Ado-Dad OTP-First Login". Repo copy: `docs/login_otp_first_wireframe.html`.

## Implemented (2026-09-09) — steps 1, 2, 4 + SMS auto-read
New files:
- `lib/common/phone_number_util.dart` — `PhoneNumberUtil.normalise(raw, dialCode)` → `{national, e164, isValid, validationMessage}`, `format()`, `mask()`. Tests in `test/common/phone_number_util_test.dart` (note: `test/` is git-ignored in this repo).
- `lib/services/otp_autofill_service.dart` — Android SMS **User Consent** API via `smart_auth` (added to pubspec). Parses the 6 digits after "otp"/"code" from:
  `Dear User, Your Login otp is 833448. Do not share with any one. Team Adodad`.
  No SMS permission needed; Android shows a one-tap "allow reading this message" sheet. Tests in `test/services/otp_autofill_service_test.dart`.
  Silent (no prompt) reading needs the SMS Retriever format — backend must send `<#> Your Login otp is 833448 … <11-char app hash>`; get the hash with `SmartAuth.instance.getAppSignature()`. Then switch `listen()` to `getSmsWithRetrieverApi()`.

Changed:
- `app_routes.dart`: `/login` → `OtpLoginPage`, `/login-password` → password `Login()`, `/login-otp` redirects to `/login`. `auth_guard.dart` public list updated.
- `otp_login_page.dart`: validation + identifier go through `PhoneNumberUtil` (fixes `+9191…`); pasted/autofilled numbers are rewritten to the clean 10 digits; live "Will send to +91 94744 14563" hint; copy "Welcome back"; "Use email instead" link; OR divider + outlined **Login with password** button; back arrow only when `context.canPop()`.
- `otp_verification_page.dart`: starts SMS listener on open and after Resend; fills boxes + auto-verifies; auto-submits when the 6th digit is typed; first box has `AutofillHints.oneTimeCode` (iOS) and accepts a 6-char paste; mask uses the real dial code; "Reading SMS automatically…" indicator; "Login with password instead" link at bottom.
- `login_page.dart`: `_getFormattedUsername()` uses the same util; "Login with OTP instead" now `go('/login')`.

Run: `flutter pub get` · `flutter test test/common test/services` · `flutter analyze`.
If `smart_auth` 3.x API names differ from what the analyzer expects, the only file to touch is `otp_autofill_service.dart` (`getSmsWithUserConsentApi`, `removeUserConsentApiListener`, `SmartAuth.instance`).

Still pending (step 3): shared `phone_or_email_field.dart` widget to replace the duplicated country-picker code in OTP / password / signup pages.
