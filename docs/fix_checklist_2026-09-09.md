# Full code scan + fix round — 2026-09-09 (branch dev_redesign, on top of 65cd215)

Artifact: "Ado-Dad Fix Checklist" (claude.ai artifacts). Repo copy: docs/fix_checklist_2026-09-09.html.
34 files changed in the working copy (uncommitted at time of writing). Nothing compiled in the sandbox — run build_runner + flutter analyze first.

## Root causes of the 3 reported symptoms
1. Broken after background/resume — chat socket layer: disconnect/reconnect events were forwarded as ChatErrorState (chat screens flip to error), room never re-joined after reconnect, monitoring timer re-created the socket every 5 s, rooms page retried LoadChatRooms inside build() (infinite loop). Plus: parallel 401s after resume triggered a second refresh → forced logout; _initFcm() blocked runApp with no try/catch (blank screen on cold relaunch).
2. Back after messaging page — ChatBloc only subscribed to repository streams in InitializeChat (rooms page stuck on skeleton if chat opened from an ad); chat back did go('/chat-rooms?from=…') which destroyed the ad page and jumped tabs; Android back differed.
3. Bikes show wrong fields — /transmission-types and /fuel-types are not category-filtered (bike seller sees Diesel/CNG, CVT/AMT); Color + Transmission were required. NOTE: backend must honour `category`/`vehicleCategory` query on those two endpoints (or return a category field) — client now sends both keys and filters client-side via appliesTo().

## Fixed (35) — see artifact for file:line
Resume: socket connectionStatusStream, rejoin on connect, timer no-op, rooms-page loop removed, api_service 401 token compare, handleTokenExpiration no pop loop, _initFcm unawaited+try/catch, chat_repository init guard, auth_guard '/' exact match.
Chat: _ensureSubscriptions() in bloc, canPop?pop:go + PopScope in chat page and rooms page, _lastRooms cache + 2 s throttled reload, roomId filter on NewMessageReceivedState, single LoadRoomMessages, voice-player sub cancelled.
Sell: category param on fuel/transmission fetch + filter; two-wheeler colour + transmission optional; Next validates Details; Review summary; mounted/try-catch in loaders; prints/divider removed; media bloc retry-with-no-bytes; photo widget mounted + errorBuilder; 4 edit forms pop(true) + safe lookups + tryParse.
Auth: OtpLoginPage listener isCurrent guard (no duplicate verify page on Resend); OTP box-0 multi-char handling; login_page '+' handling + validation; ?redirect honoured; signup phone normalised; SMS parser strict; /logout → OTP page.
Home: ad detail sold/delete pop(true) + bloc keeps loaded state on error; My Ads reload on result; nullable route extras → _RouteErrorScreen; placemarks guard + mounted in home_page; seller-id guards; owner Future cached; notifications back maybePop.

## Pending (14) — priority order
1. advertisement_bloc pagination: location branch overrides category/filters on page 2+; isFurnished/hasParking dropped on page 2; load-more failure wipes list + page counter. (HIGH)
2. Search per-keystroke race → bloc_concurrency restartable + debounce. (HIGH)
3. Favourite toggle flow (favorite_bloc / wishlist / ad_detail_action_buttons). (HIGH)
4. category_list_page: hard-coded debug ad id, prints, fetchNextPage in build. (HIGH)
5. Chat state refactor to a single data state (rooms+messages+status). (MED)
6. Search clear / wishlist paging / My Ads chips / didChangeDependencies refetch. (MED)
7. Shared phone_or_email_field widget. (MED)
8. Post-ad phase 2 (category sheet, price+location step, Posted screen, drafts, edit forms on PhotoStep). (MED)
9. Commercial manufacturers category; TwoWheelerAdModel.variantId nullable. (LOW)
10. print() cleanup + dark-mode hard-coded colours (~12 files); splash/connectivity leaks. (LOW)

## Needs backend
- vehicle-inventory: filter /transmission-types and /fuel-types by category (or add vehicleCategory to items).
- OTP SMS: prepend `<#>` + app hash for silent Retriever read (optional).

## Verify on device
- Long background (token expiry) → resume: no splash/login loop.
- smart_auth 3.x API names compile (otp_autofill_service.dart).

---

# Round 2 — 2026-09-09 (on top of commit 2cd4df2)
24 more files changed. Total fixed across both rounds: 51. Pending: 3. Needs backend: 2. Verify on device: 3.

## Change password — why it was failing
Three client bugs, all fixed:
1. **Blank page.** profile_page.dart's builder renders content only for Loaded/Saving/Error(+cached). `ChangingPassword`, `PasswordChanged`, `DeletingData`, `DataDeleted` all fell through to `SizedBox.shrink()` at line ~2832 — so tapping OK blanked the whole profile page.
2. **Silent failure.** The error snackbar is gated on `_isUpdatingProfile`, which is set only by the profile-save path, never by a password change. Every failure was swallowed. New `_isChangingPassword` flag; failures now show the server's own message for 5 s and reload the profile.
3. **Success got stuck.** After `PasswordChanged` the bloc never returned to `Loaded` and `context.go('/profile')` was a no-op (already there). Now refetches the profile.
Repo (profile_repo.dart): accepts any 2xx (a 201/204 previously reported failure), `validateStatus < 500` + `_serverMessage()` so NestJS `message` arrays / `error` / `detail` reach the UI.

STILL POSSIBLY BACKEND: the app sends `PUT /users/:id` with only `{"password": "..."}` and no current password. If the API requires `currentPassword`, or excludes `password` from the update DTO (common — then it 200s and changes nothing), that is the remaining cause. Run it once now: the snackbar prints the server's message. If it needs the old password → add the field to ChangePasswordDialog; if it needs a dedicated route → switch the repo call.
ALSO CHECK: if the API rotates the JWT on password change, every later request 401s → auto-logout.

## Also fixed in round 2
- advertisement_bloc: `_ListMode` enum so page 2+ keeps category/filters/search instead of falling into the location branch; isFurnished/hasParking passed on next page; `_requestSeq` guard so stale responses can't overwrite newer ones; next-page failure rolls the counter back and keeps the list (same in showroom_bloc, seller_profile_bloc).
- search_page: 350 ms debounce + mounted guards; clearing the query refetches all listings instead of restoring a stale snapshot.
- category_list_page: removed 15 prints + the hard-coded debug ad id; Premium auto-paging moved out of build() into a listener with a guard; Retry reuses the refresh handler with current filters.
- favorite_bloc: no global loading on toggle, optimistic local add/remove, `_inFlight` set blocks double-tap; ad_detail_action_buttons is now stateful with optimistic heart + revert on failure; wishlist keeps the list visible while toggling.
- my_ads_page: auto-loads more pages when a status filter yields an empty view; misleading total replaced with "N+".
- seller_profile_page / showroom_user_ads_page: removed didChangeDependencies refetch (fired on every keyboard/rotation).
- showroom_users_page: mounted guards, guarded NetworkImage.
- 76 print → debugPrint; 16 hard-coded colours → AppColors (dark mode); splash stream subscription cancelled; connectivity list check fixed; TwoWheelerAdModel.variantId now optional.

## Still pending
1. Chat state refactor to a single data state (rooms+messages+status) — removes the remaining flicker. Deliberately not done: high risk without a compiler.
2. Shared phone_or_email_field widget (login plan step 3).
3. Post-ad phase 2 (category sheet, price+location step, Posted screen, drafts, edit forms on PhotoStep).
