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
