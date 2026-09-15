# AdoDad Chat — Implementation Plan & Checklist

Source docs: `docs/chat_system_audit_phase1.md` (findings F-xx), `docs/chat_redesign_wireframes.html` (screens 01–14), `docs/chat_backend_api_spec.md`.
Baseline: backend `ado-dad@develop`, mobile `ado_dad_mobile@dev_redesign` (C:\pendrive copy).
Order: **Backend (Phase 4) → Mobile foundation (5) → List UI (6) → Thread UI (7) → Perf (8) → Integration (9)**.

Implemented items move to the **Done log** at the bottom. Only open work stays in the phase lists.

---

## Decisions locked for implementation
| # | Decision | Why |
|---|---|---|
| D1 | **Writes over REST** (`POST …/messages` with `clientMessageId`). **Delivery over socket.** The socket `sendMessage` stays and acks properly | REST is retryable, idempotent and works when the socket is down |
| D2 | **Backward compatible.** Every legacy socket event and REST shape keeps working until the new app version is forced via the version check | Store builds keep chatting during rollout |
| D3 | Other party's `phoneNumber` + `countryCode` stay (Call button, per spec). **Email removed** from all chat payloads | F-13 |
| D4 | Unread = per-user counter on the room (`unreadCounts.<userId>`), reset by mark-read. The legacy `isRead` flag is still written | Cheap list query, no count scans |
| D5 | Typing + presence **deferred** (Q4). The contract reserves `typing` and `presence` events but they aren't built | Scope |
| D6 | Only strong profanity **blocks** (`CONTENT_BLOCKED`). URLs, phones, emails and "hate/kill/die" are **flagged, not blocked** | F-05 |
| D7 | Chat media uploads go to `chat/{roomId}/…`, presigned by the chat module with a type/size allowlist | F-03, F-16 |
| D8 | Mobile: new `lib/features/chat/` (data / state / widgets / pages), **Cubits per page**, no new packages | F-18, rule 10 |

---

## Target contracts (v2, additive)

### REST (`/chats`, JWT)
| Method & path | Body / query | Returns |
|---|---|---|
| `POST /chats/rooms` | `{adId}` | `{success, data: RoomDto}` (idempotent get-or-create) |
| `GET /chats/rooms` | `?limit&cursor&filter=all\|unread\|buying\|selling\|archived&q` | `{success, data: RoomDto[], nextCursor}`. Without `limit` → legacy full list (cap 200) |
| `GET /chats/rooms/:roomId` | — | `{success, data: RoomDto}` |
| `GET /chats/unread-count` | — | `{success, data: {total, rooms}}` |
| `GET /chats/rooms/:roomId/messages` | `?limit&cursor` (older) `&after` (newer, catch-up) | `{success, data:{messages, nextCursor, hasMore}}` |
| `POST /chats/rooms/:roomId/messages` | `{clientMessageId, type, content?, attachments?}` | `{success, data: MessageDto}`. Same `clientMessageId` → same message |
| `POST /chats/rooms/:roomId/read` | `{lastMessageId?}` | `{success, data:{roomId, unreadCount:0, lastReadAt}}` |
| `POST /chats/rooms/:roomId/archive` · `DELETE …/archive` | — | Per-user archive / unarchive. A new message unarchives for both |
| `POST /chats/rooms/:roomId/unread` | — | Mark unread for me (`unreadCounts.<me>` ≥ 1) |
| `POST /chats/rooms/:roomId/uploads` | `{kind: image\|audio, mimeType, size}` | `{success, data:{uploadUrl, method:'PUT', headers, url, key, expiresIn}}` |

**RoomDto**: `roomId, adId, status, isClosed, myRole(buying|selling), createdAt, lastMessageAt, unreadCount, archived, otherUser{id,name,profilePic,phoneNumber,countryCode}, ad{id,title,price,image,status}, lastMessage{id,type,preview,senderId,createdAt,status}`. `lastMessage.status` is `sent|read` only when the last message is mine (from the other user's `lastReadAt`); voice previews carry the duration (`Voice message · 0:24`). Legacy keys `initiatorId, adPosterId, participants, messageCount, latestMessage, adDetails` are kept.

**MessageDto**: `_id, id, roomId, clientMessageId, senderId, type, content, attachments[], createdAt, isRead`. No `sender.email`.

### Socket (`/chat`)
| Direction | Event | Payload |
|---|---|---|
| server→client | `connected` | `{userId}` |
| server→client | `auth_error` | `{code: TOKEN_EXPIRED\|UNAUTHORIZED\|SUSPENDED}`, then disconnect |
| client→server | `joinChatRoom {roomId}` | ack `{success, roomId}` |
| client→server | `sendMessage {roomId, clientMessageId?, type, content, attachments}` | ack `{success, message}` / `{success:false, code, error}` |
| client→server | `markChatRoomRead {roomId, lastMessageId?}` | ack `{success}` |
| server→room | `message` | MessageDto (legacy name, now carries `clientMessageId`) |
| server→room | `messages_read` | `{roomId, userId, lastReadAt}` |
| server→`user:{id}` | `conversation_updated` | RoomDto for that user |

---

## Phase 4 — Backend

Code is done and on disk. Chat specs pass (66/66) and `tsc` is clean for the chat module closure. Remaining work is cleanup and verification you run against a real DB:

### B13 · Cleanup
- [ ] `git rm src/chat/guards/rate-limit.guard.ts src/chat/guards/rate-limit.guard.spec.ts src/auth/guard/ws-guard.ts` (unused legacy; the Cowork shell can't delete on this drive)

### B14 · Verification
- [ ] `npx tsc --noEmit && npm run chat:test` (expect 66 passing), then `npm run start:dev` and check Swagger lists `/chats/rooms/{roomId}/archive` and `/unread`

### B15 · Deploy (UAT first)
- [ ] `MONGO_URI=… npm run chat:backfill -- --dry-run`, then without `--dry-run`
- [ ] `MONGO_URI=… SMOKE_BUYER_ID=… SMOKE_AD_ID=… npm run chat:smoke` → every line PASS
- [ ] One voice note from the **current store app** on UAT, to confirm the legacy presign fix (F-03)
- [ ] Old app on UAT: list, open, send, image, offer all still work (backward-compat D2)
- [ ] `MONGO_URI=… npm run chat:indexes` (prints the winning index per query), then `-- --apply` to drop the legacy message indexes it reports as unused
- [ ] Set `CORS_ORIGINS` (gateway now reads it) and optional `CHAT_MEDIA_HOSTS` if media is served from a CDN

## Phase 5 — Mobile foundation (`lib/features/chat/`)

The data, state and UI layers are written but **not yet wired** into routes or main, so the current app is unaffected. None of it has been compiled (no Flutter SDK in the cloud).
- [ ] `bash tool/chat_verify.sh --clean` — removes the old chat files, then `flutter analyze` + `flutter test test/features/chat` (analyze was clean on 15 Sep; the smoke-test overflows were fixed, re-run to confirm)

---

## Design fidelity — the rules every chat screen is built and checked against

**Source of truth:** `docs/chat_redesign_wireframes.html` (the PROPOSED phones, screens 01–14).
**Code source of truth:** `lib/features/chat/widgets/chat_tokens.dart`. No literal sizes or colours in chat widgets.

### DF-1 · Scale rule (how "pixel perfect" is defined)
The wireframe phone screen is **278 px** wide and the Android baseline is **360 dp**. **dp = wireframe px × 1.3**, with type rounded to 0.5 dp and spacing to 1 dp. On a 360 dp device every screen has the wireframe's exact proportions; wider phones get more horizontal room, never bigger type.

| Element | Wireframe px | App dp | Token |
|---|---|---|---|
| Side gutter | 14 | 18 | `ChatSize.gutter` |
| List title "Chats" | 19 / 600 | 24.5 / 600 | `listTitle` |
| Search field text / radius / padding | 11.5 / 11 / 10×7 | 15 / 14 / 13×9 | `searchFont` `searchRadius` `searchPadding` |
| Filter chip text / radius / padding / gap | 10.5 / 14 / 10×4 / 6 | 13.5 / 18 / 13×5 / 8 | `chip*` |
| Row padding (v) | 10 | 13 | `rowVPad` |
| Avatar / header avatar / sheet avatar | 40 / 34 / 64 | 52 / 44 / 83 | `avatar*` |
| Listing thumb on avatar (size / radius / ring / offset) | 21 / 6 / 2 / −5 | 27 / 8 / 2.5 / −6.5 | `avatarThumb*` |
| Name / time / ad line / preview | 12.5 / 9.5 / 10 / 11.5 | 16 / 12.5 / 13 / 15 | `nameFont` `timeFont` `adLineFont` `previewFont` |
| Unread badge height / text | 17 / 9 | 22 / 11.5 | `badge*` |
| Divider inset | 66 | 84 | `dividerInset` |
| Status pill text / radius | 8.5 / 5 | 11 / 6.5 | `pill*` |
| Header name / sub | 12.5 / 9.5 | 16 / 12.5 | `headerName` `headerSub` |
| Listing strip thumb / title / price / View | 40×32 / 10.5 / 12 / 10 | 52×42 / 13.5 / 15.5 / 13 | `strip*` |
| Bubble text / padding / radius / tail / max width | 11.5 / 10×6 / 15 / 4 / 78% | 15 / 13×8 / 20 / 5 / 78% | `bubble*` |
| Meta (time + tick) | 8.5 | 11 | `metaFont` `metaIcon` |
| Gap same sender / sender switch | 2 / 7 | 3 / 9 | `sameSenderGap` `senderSwitchGap` |
| Date chip text / radius | 9 / 9 | 12 / 12 | `date*` |
| Composer field text / radius · send button | 11.5 / 18 · 32 | 15 / 24 · 42 | `field*` `sendButton` |
| Image bubble / radius | 150×118 / 14 | 195×153 / 18 | `imageBubble` `imageRadius` |
| Voice play button / min width | 26 / 150 | 34 / 195 | `voice*` |
| Tray thumb / radius | 56 / 9 | 73 / 12 | `tray*` |
| Banner text / padding | 10.5 / 12×6 | 13.5 / 16×8 | `banner*` |
| Empty/error title / body / icon circle | 14 / 11 / 52 | 18 / 14.5 / 68 | `state*` |
| Details sheet name / action circle / row text | 14 / 38 / 11.5 | 18 / 49 / 15 | `sheet*` `action*` |

### DF-2 · Colour tokens (light / dark), from `app_colors.dart` + wireframe `--a-*`
brand `#4F48EC` (fills, both themes) · brandText `#4F48EC` / `#9C98FF` · pending bubble `#8D88F2` · read tick `#BFF0DA` · background `#F6F7FB` / `#0F1115` · surface `#FFFFFF` / `#1B1F27` · chip `#F4F5F9` / `#232833` · divider `#E6E8EE` / `#2A2F3A` · soft `#EDEBFF` / `#26244A` · text `#0A0A0A` / `#ECEEF3` · text2 `#424242` / `#C2C7D0` · muted `#6B7080` / `#9AA1AF` · ok `#12805A` on `#E3F5EC` / `#5FD3A2` on `#15372A` · warn `#7A5200` on `#FFF3D6` / `#F2C66D` on `#3A2F12` · err `#C23030` on `#FDECEC` / `#FF8A8A` on `#3D1B1E` · call `#19A463`

### DF-3 · Type
Poppins (from `AppTheme`) everywhere. Weights: 400 body · 500 names/preview-unread/buttons · 600 titles/prices/badges/unread name. Tabular figures for times and durations. Only 12 dp and up at 1.0× scale.

### DF-4 · Interaction and state rules
- Unread rows change **weight** (and show a count + brand-coloured time), never background colour
- Pending bubble = `#8D88F2` + clock + "Sending". Failed = err fill + err border + "Not sent · reason" + Retry (transient) or Edit (policy)
- Banners sit directly under the header. "Reconnecting…" only after 3 s. Attachments disabled while offline
- Reversed list, so the thread opens at the bottom with no scroll animation. Date chip whenever the day changes; time + tick only on the last bubble of a run
- Composer: + · pill field (1–5 lines) · mic when empty → send when text. Photos → tray + caption + "Send N". Hold mic → recording bar, slide left 90 dp to cancel, auto-send at 3:00
- Never show raw exceptions. All copy comes from `chat_copy.dart`

### DF-5 · QA procedure (each screen must pass before it's ticked)
1. `flutter run -t lib/main_chat_preview.dart` on a **360×800** emulator (Pixel 4a / "Small phone")
2. Open the screen; screenshot light and dark
3. Put the screenshot next to the wireframe's PROPOSED phone. Check spacing rhythm, alignment, hierarchy, colours and copy; within ±1 dp on the table above is a pass
4. Repeat at **412×915** (layout holds, nothing stretches oddly) and **text scale 1.3** (no clipping; smoke test covers overflow)
5. Tick the screen below and note any deliberate deviation in the Deviations log

---

## Phase 6 — Chat list UI (screens 01–05)

Implemented in `pages/chat_list_view.dart`, `pages/chat_list_page.dart` and `widgets/*`. Every item below still needs design QA (DF-5):
- [ ] **01 Default** — header "Chats" + search + chips (server Unread count) · tile: avatar + listing thumb, name/time, tag + ad title · ₹price (no price on sold/removed), "You:" + ✓ sent / brand ✓✓ read, unread weight + badge + brand time, sold row dimmed with "Ad sold" pill, voice preview with duration · inset dividers · long-press → Mark as unread/read · Archive chat (+ Undo snackbar). Code audited against the wireframe on 15 Sep; only DF-5 visual QA remains
- [ ] **02 Loading** — tile-shaped skeleton (first load only). Cached list + 2.5 dp progress line on refresh
- [ ] **03 Empty** — mini listing card + bubbles illustration, "No chats yet", copy with bold **Chat**, Browse listings / Post an ad. Filter-empty variant with "Show all chats"
- [ ] **04 Error** — icon circle, title/body by failure kind, Try again. "Showing saved chats · Retry" banner when cached data exists
- [ ] **05 Search** — back arrow + focused field, "N CHATS" label, highlight in name / ad title / preview, "Searching older chats…" row, no-results copy

## Phase 7 — Thread UI (screens 06–14) + entry points

Implemented in `pages/chat_thread_view.dart`, `pages/chat_thread_page.dart` and `widgets/*`. Every item below still needs design QA (DF-5):
- [ ] **06 Default** — header (back · avatar · name · "Buying/Selling · ad" · call · more), listing strip (thumb, title, ₹price, Live/Sold pill, View ›), date chips, grouped bubbles with tail + time on last of run, read ticks
- [ ] **07 Loading** — header + strip immediately, alternating bubble skeleton, composer usable
- [ ] **08 New conversation** — listing card, "Ask {first name} about this listing", role-aware starter chips that fill the composer, safety tip
- [ ] **09 Sending** — optimistic `#8D88F2` bubble + clock → ✓ → mint ✓✓
- [ ] **10 Failed** — err bubble, "Not sent · No connection · Retry" / "Not sent · Message not allowed · Edit", long-press Retry/Edit/Delete
- [ ] **11 Offline** — amber banner under the header, queued bubbles "Sending", auto-flush on reconnect, attachments disabled
- [ ] **12 Attachments** — tray (73 dp thumbs, remove, add tile), caption + "Send N", image bubble with progress ring, voice bubble (shared player, waveform, duration), recording bar with slide-to-cancel + 3:00 cap
- [ ] **13 Details sheet** — 83 dp avatar, name, role, Call / Profile / View ad, Report row, "Chat started … about …"
- [ ] **14 Dark mode** — all of the above in dark via `ChatColors`

### Deviations log (deliberate differences from the wireframe)
| Screen | Wireframe | App | Why |
|---|---|---|---|
| 06 | "Active now" + typing dots | Role · ad title subline, no typing | Presence/typing deferred (D5) |
| 13 | Mute, Archive, Block, shared photos | Hidden | Need new APIs; rule "don't show what the backend can't do" |
| 05 | Separate search screen | Same screen: header swaps to back + field when searching | Same visual; one route, keeps list state |

## Phase 8 — Performance
- [ ] Baseline vs after: list first row, thread first bubble, send→ack, `explain` stats, rebuild counts

## Phase 9 — Integration
- [ ] Two-device script: login → list → open → send → receive → read ticks → background push → tap → return → state correct
- [ ] Token expiry mid-chat, airplane mode, app kill with a failed message, sold ad

---

## Done log

### 15 Sep 2026 — Phase 4 backend (ado-dad `develop`, C:\pendrive copy)
| Item | What changed | Files |
|---|---|---|
| B1 | Handlers return acks (F-01). `@UsePipes(ValidationPipe)` + `ChatWsExceptionFilter` ack every error with a code (F-17). `onAny`/payload/PII logging removed (F-13). Gateway CORS from `CORS_ORIGINS` | `chat.gateway.ts`, `realtime/chat-ws-exception.filter.ts`, `chat-errors.ts` |
| B2 | JWT verified once at handshake with issuer/audience; deleted/banned/suspended users refused. `client.data.user.exp` checked per event → `auth_error{TOKEN_EXPIRED}` + disconnect (F-02 — access tokens live **1 h**, so chat died hourly). Joins `user:{id}`. `connectedUsers` map removed | `realtime/chat-socket-auth.service.ts`, `chat.gateway.ts` |
| B3 | `clientMessageId` + partial unique index; idempotent send incl. duplicate-key race; `{roomId,_id}` history index | `schemas/chat-message.schema.ts`, `chat.service.ts` |
| B4 | `POST /chats/rooms/:roomId/messages`. One write path (`ChatMessagingService`) for REST and socket: persist → room broadcast → per-user `conversation_updated` → push | `chat.controller.ts`, `chat-messaging.service.ts` |
| B5 | `unreadCounts`/`lastReadAt` maps. One atomic room update per send (preview, recency, count, recipient +1; no unread for self-chat). `POST …/read` + `markChatRoomRead` handler (the old app already emits it). `messages_read` event. `GET /chats/unread-count` | `chat.service.ts`, `chat-messaging.service.ts`, `chat.gateway.ts` |
| B6 | Room list is one aggregation (no N+1, F-20): cursor, `filter`, `q`, per-user unread/role, ad availability, denormalised `lastMessage` with self-healing repair for old rooms. No email (F-13). Closed rooms stay listed (F-29). New rooms get `lastMessageAt` (F-33). `GET /chats/rooms/:roomId`. `POST /chats/rooms` returns the full view. Legacy keys kept | `chat.service.ts`, `schemas/chat-room.schema.ts` |
| B7 | History: `$sort/$limit` before `$lookup`, no email/moderation fields, `total` opt-in, `after=` catch-up, requester required | `chat.service.ts` |
| B8/B9 | `conversation_updated` to both users. FCM push via `NotificationProducer` only when the recipient has no live socket, collapsed per room for 30 s, data `{type:'chat', roomId}` | `realtime/chat-notifier.service.ts`, `realtime/chat-events.service.ts` |
| B10 | Only strong profanity blocks (`CONTENT_BLOCKED`). "hate/kill/die", links, phones (Indian formats) and emails are flagged, not blocked (F-05) | `services/content-moderation.service.ts` |
| B11 | `POST …/uploads`: participant-only, type allowlist, 10 MB/5 MB caps, key `chat/{roomId}/…`, returns the exact signed `Content-Type` (F-03). Attachments must be on our bucket host over https (F-16). Client duration accepted; server download only as legacy fallback, capped 6 MB (F-27). Legacy `/upload/presigned-url` now signs the type the client sends (F-03 for store builds). `/upload/file` MIME regex fixed (`audio/…` was never matching) | `chat-upload.service.ts`, `shared/s3.service.ts`, `shared/upload.controller.ts` |
| B12 | Redis fixed-window limiter (send 20/10 s, create 10/min, upload 30/min, read 60/min) with bounded in-memory fallback; `RATE_LIMITED` acks (F-32) | `realtime/chat-rate-limiter.service.ts` |
| B13 | Controller keeps real status codes (F-42). Legacy socket `getRoomMessages`/`getUserChatRooms`/`checkExistingChatRoom` now return the shapes the old client parses | `chat.controller.ts`, `chat.gateway.ts` |
| B14 | New/rewritten specs: service, gateway, controller, messaging, upload, socket-auth, rate-limiter, moderation — **61 passing** | `*.spec.ts` |
| B15 | Backfill script (zero unread, lastMessage, lastMessageAt, participants, create indexes) and a real-DB smoke script | `scripts/backfill-chat-rooms.ts`, `scripts/chat-smoke.ts` |

### 15 Sep 2026 — Phase 5 mobile foundation (not wired yet)
| Item | What | File |
|---|---|---|
| M1 | Room/message/attachment/failure models, local-time parsing (F-11), legacy room shape accepted, `mergeMessages` dedupe by id ∥ clientMessageId | `data/chat_models.dart` |
| M2 | REST client on shared `ApiService().dio` (F-40); S3 PUT with signed headers and progress; server error codes → `ChatFailure` | `data/chat_api.dart` |
| M3 | One socket. `auth_error` → `AuthService.refreshAccessToken()` → reconnect (F-02). Rooms re-joined on reconnect. `reconnected` stream for catch-up. "Reconnecting" only after 3 s | `data/chat_connection.dart` |
| M4 | SharedPreferences cache, per user: first room page, last 30 msgs × 20 rooms (LRU), outbox; 24 h TTL | `data/chat_cache.dart` |
| M5 | Repository + outbox: optimistic send, explicit roomId (F-04), REST delivery with clientMessageId, auto-retry network failures on reconnect, uploads with progress, persisted failed text | `data/chat_repository.dart` |
| M6 | `ChatListCubit` (cache-first, filters, search local+remote, pagination, live upsert), `ChatThreadCubit` (join→fetch, older pages, catch-up, read receipts, debounced mark-read, send/retry/discard), `ChatBadgeCubit` | `state/*.dart` |
| — | Unit tests for parsing, failures, merge/dedupe, cache restore, id format | `test/features/chat/chat_models_test.dart` |

### 15 Sep 2026 — Last code items closed
| Item | What | Files |
|---|---|---|
| Report from chat | Details-sheet Report row opens the existing report sheet (`ReportAdDialog`, `POST /user-reports`) for the other user + this ad | `pages/chat_thread_page.dart` |
| npm scripts | `chat:test`, `chat:backfill`, `chat:smoke`, `chat:indexes` | `ado-dad/package.json` |
| Index check | `chat-indexes.ts`: explains room list / unread / history / mark-read, lists legacy message indexes, drops only unused ones with `--apply` | `src/chat/scripts/chat-indexes.ts` |
| One-shot verify | `tool/chat_verify.sh [--clean]`: old-file cleanup + analyze + chat tests | `ado_dad_mobile/tool/chat_verify.sh` |

### 15 Sep 2026 — Old chat unhooked (F-34, F-35)
Nothing references the old chat anymore: `ChatBloc` provider removed from `main.dart`; `/chat-debug` route and import removed from `app_routes.dart`; `ChatSocketService().disconnect()` removed from `auth_service.dart` and replaced by `ChatRepository.instance.signOut()` in `login_bloc.dart`. The old files themselves only reference each other and are deleted with the `git rm` above.

### 15 Sep 2026 — New chat wired into the real app (main.dart)
| Item | What changed | Files |
|---|---|---|
| Routes | `/chat-rooms` → `ChatListPage` (tab shell); `/chat/:roomId` → `ChatThreadPage` with the room as `extra`, URL carries only the id (F-31). `/chat-debug` kept for now | `common/app_routes.dart` |
| Nav badge | `ChatBadgeCubit` provided in `main.dart`; the shell starts it when signed in, refreshes on tab switches, resets on logout; brand `UnreadBadge` on the Chat tab | `main.dart`, `common/widgets/scaffold_with_nav_bar.dart` |
| Push tap | `{type:'chat', roomId}` → Chat tab + thread on top; chat pushes no longer land in the notifications inbox | `main.dart` |
| Sign-out | `logout()` and `handleTokenExpiration()` also call `ChatRepository.instance.signOut()` (socket, cache, outbox) | `services/auth_service.dart` |
| Ad detail entry | Chat and Make an offer use one get-or-create call, then open the thread; the offer is queued as the first message (optimistic). Old room-exists/socket-join flow and error dialogs removed | `features/home/services/chat_service.dart`, `offer_service.dart` |
| Shell fit | List bottom padding and snackbar margin clear the floating nav bar | `pages/chat_list_page.dart`, `pages/chat_list_view.dart` |

### 15 Sep 2026 — Screen 01 audit vs wireframe: gaps closed
| Gap found | Fix | Files |
|---|---|---|
| Long-press Archive / Mark unread missing (wireframe marks it "new API") | Per-user `archivedFor` map; `POST/DELETE …/archive`, `POST …/unread`; list/unread summary exclude my archived chats; new message unarchives both; `conversation_updated` fan-out. App: actions sheet, optimistic cubit actions with rollback, Undo snackbar | backend `chat.service.ts`, `chat-messaging.service.ts`, `chat.controller.ts`, `schemas/chat-room.schema.ts`, `dto/chat-query.dto.ts`; app `widgets/chat_room_actions_sheet.dart`, `state/chat_list_cubit.dart`, `pages/chat_list_page.dart`, `pages/chat_list_view.dart`, `widgets/conversation_tile.dart`, `data/chat_api.dart`, `data/chat_repository.dart` |
| "You:" always showed a read ✓✓ | `lastMessage.status` from the other user's `lastReadAt`; mark-read now also refreshes the other user's row. Tile: ✓ muted when sent, ✓✓ brand when read | `chat.service.ts`, `chat-messaging.service.ts`, `data/chat_models.dart`, `widgets/conversation_tile.dart` |
| Voice preview lacked "· 0:24" | `previewFor` uses the attachment duration (list rows and push text) | `chat.service.ts`, `chat-messaging.service.ts` |
| Unread chip counted only loaded rows ("counted on the server") | `GET /chats/unread-count` `rooms` seeds the chip, adjusted locally on read/unread/archive/live updates | `state/chat_list_cubit.dart`, `data/chat_api.dart` |
| Sold row showed a price (wireframe: pill + title only) | Price hidden unless the ad is live | `widgets/conversation_tile.dart`, `widgets/chat_room_actions_sheet.dart` |
| Search field ~4 dp taller than 7 px × 1.3 | Vertical padding from `searchPadding` (9 dp) | `widgets/chat_list_controls.dart` |
| — | Specs +5 (archive filter, read/sent status, archive/unarchive, mark unread, unarchive on send, voice duration) → 66 passing; widget tests for the long-press sheet and row details | `chat.service.spec.ts`, `test/features/chat/chat_screens_smoke_test.dart` |

### 15 Sep 2026 — Phase 6/7 UI built to the design spec (unwired, not yet compiled or QA'd)
| Area | Files |
|---|---|
| Tokens (DF-1 scale ×1.3, DF-2 colours), formatting, copy | `widgets/chat_tokens.dart`, `widgets/chat_format.dart`, `widgets/chat_copy.dart` |
| List widgets | `widgets/chat_avatar.dart`, `widgets/chat_pills.dart`, `widgets/conversation_tile.dart`, `widgets/chat_list_controls.dart`, `widgets/chat_skeletons.dart`, `widgets/chat_state_views.dart` |
| Thread widgets | `widgets/chat_thread_header.dart`, `widgets/message_bubble.dart`, `widgets/chat_audio_controller.dart`, `widgets/message_composer.dart`, `widgets/chat_intro.dart`, `widgets/chat_details_sheet.dart` |
| Pages (pure views + cubit wiring) | `pages/chat_list_view.dart`, `pages/chat_list_page.dart`, `pages/chat_thread_view.dart`, `pages/chat_thread_page.dart` |
| Design QA harness (all states from fixtures) | `lib/main_chat_preview.dart`, `preview/chat_preview_fixtures.dart` |
| Tests | `test/features/chat/chat_format_test.dart`, `test/features/chat/chat_screens_smoke_test.dart` |
| Data layer tweak | `ChatConnection` watches connectivity → `offline` state for the amber banner; initial status `connecting` (no false offline flash) |
