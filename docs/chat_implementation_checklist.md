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
| `GET /chats/rooms` | `?limit&cursor&filter=all\|unread\|buying\|selling&q` | `{success, data: RoomDto[], nextCursor}`. Without `limit` → legacy full list (cap 200) |
| `GET /chats/rooms/:roomId` | — | `{success, data: RoomDto}` |
| `GET /chats/unread-count` | — | `{success, data: {total, rooms}}` |
| `GET /chats/rooms/:roomId/messages` | `?limit&cursor` (older) `&after` (newer, catch-up) | `{success, data:{messages, nextCursor, hasMore}}` |
| `POST /chats/rooms/:roomId/messages` | `{clientMessageId, type, content?, attachments?}` | `{success, data: MessageDto}`. Same `clientMessageId` → same message |
| `POST /chats/rooms/:roomId/read` | `{lastMessageId?}` | `{success, data:{roomId, unreadCount:0, lastReadAt}}` |
| `POST /chats/rooms/:roomId/uploads` | `{kind: image\|audio, mimeType, size}` | `{success, data:{uploadUrl, method:'PUT', headers, url, key, expiresIn}}` |

**RoomDto**: `roomId, adId, status, isClosed, myRole(buying|selling), createdAt, lastMessageAt, unreadCount, otherUser{id,name,profilePic,phoneNumber,countryCode}, ad{id,title,price,image,status}, lastMessage{id,type,preview,senderId,createdAt}`. Legacy keys `initiatorId, adPosterId, participants, messageCount, latestMessage, adDetails` are kept.

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

Code is done and on disk. Chat specs pass (61/61) and `tsc` is clean for the chat module closure. Remaining work is cleanup and verification you run against a real DB:

### B13 · Cleanup
- [ ] Delete the unused legacy files `src/chat/guards/rate-limit.guard.ts` (+ spec) and `src/auth/guard/ws-guard.ts` (needs delete permission, or delete by hand)
- [ ] Add npm scripts: `"chat:backfill": "ts-node src/chat/scripts/backfill-chat-rooms.ts"`, `"chat:smoke": "ts-node src/chat/scripts/chat-smoke.ts"` (left out because another session is editing package.json)

### B14 · Verification
- [ ] `npx tsc --noEmit` on the **whole** project (only the chat module closure was compiled in the cloud)
- [ ] `npx jest src/chat` locally (expect 61 passing + the untouched legacy `rate-limit.guard.spec`)
- [ ] `npm run start:dev`, then check Swagger shows the new `/chats` routes

### B15 · Deploy (UAT first)
- [ ] `MONGO_URI=… npx ts-node src/chat/scripts/backfill-chat-rooms.ts --dry-run`, then without `--dry-run`
- [ ] `MONGO_URI=… SMOKE_BUYER_ID=… SMOKE_AD_ID=… npx ts-node src/chat/scripts/chat-smoke.ts` → every line PASS
- [ ] One voice note from the **current store app** on UAT, to confirm the legacy presign fix (F-03)
- [ ] Old app on UAT: list, open, send, image, offer all still work (backward-compat D2)
- [ ] `explain()` the room list, history and unread queries, then drop unused message indexes (`isRead_1`, `createdAt_-1`, `roomRef_1_isRead_1`, `roomId_1_isRead_1`)
- [ ] Set `CORS_ORIGINS` (gateway now reads it) and optional `CHAT_MEDIA_HOSTS` if media is served from a CDN

## Phase 5 — Mobile foundation (`lib/features/chat/`)

Data and state layers are written but **not yet wired** into routes or main, so the current app is unaffected. They have not been compiled (no Flutter SDK in the cloud).
- [ ] `flutter analyze lib/features/chat test/features/chat` and `flutter test test/features/chat` on your machine
- [ ] **M7** Widgets per the wireframe component table (`lib/features/chat/widgets/`)
- [ ] Wire `ChatRepository.instance.signOut()` into `AuthService.logout()` / `handleTokenExpiration()` (replaces `ChatSocketService().disconnect()`)
- [ ] Provide `ChatBadgeCubit` in `main.dart` and start it after login

## Phase 6 — Chat list UI (screens 01–05)
- [ ] ConversationTile, FilterChips, search (name/ad/preview), skeleton, empty, error kinds, pagination, pull-to-refresh awaits
- [ ] Cache-first render. Socket never blocks the list (F-10)
- [ ] Live row patch from `conversation_updated` (F-22)
- [ ] Nav bar Chat badge (`ChatBadgeCubit`)

## Phase 7 — Thread UI (screens 06–13) + entry points
- [ ] Header, ListingStrip, reversed list, grouping, local time (F-11), date separators, status ticks
- [ ] Load older (F-08). Join-then-fetch + catch-up (F-09)
- [ ] Optimistic send / failed / retry / edit (screens 09–10)
- [ ] Connection banner + queued sends (screen 11)
- [ ] Attachment tray, image progress, voice 3:00 cap + duration, shared audio player, cached images (F-24–F-27)
- [ ] New-conversation starters (role/category-aware) + safety tip (screen 08)
- [ ] Details sheet: Call, profile, ad, report (screen 13)
- [ ] Keyboard-inset composer (F-28). Dark tokens (screen 14)
- [ ] Entry: ad detail Chat / Make offer → `POST /chats/rooms` → `/chat/:roomId` with no PII in the URL (F-23, F-31, F-15)
- [ ] Push tap `{type:'chat', roomId}` → `/chat/:roomId`
- [ ] Remove old `ChatBloc`, `ChatSocketService`, `ChatApiService`, `ChatRepository`, `ChatService`, `/chat-debug` (F-34, F-35)

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
