# AdoDad Chat — Phase 1: Audit & Mapping

```text
PHASE:           1 — Audit (investigation only, no code changed)
OBJECTIVE:       Map the chat system end-to-end and find why it fails, stalls or misbehaves
FILES INSPECTED: 22 mobile files, 20 backend files (listed in §1)
FILES CHANGED:   none
RISKS:           static analysis only — no runtime, DB or device access this session (see §9)
EXPECTED RESULT: ranked problem list + decisions needed before Phase 2
```

Date: 15 Sep 2026 · Source: `C:\pendrive\personal\ado-dad-repo` on rahul-pc

---

## 0. Read this first — baseline mismatch

| Repo | Checked-out branch | Local branches |
|---|---|---|
| `ado-dad` (NestJS) | **develop** | develop, KAN_001, main |
| `ado_dad_mobile` (Flutter) | **dev_redesign** | dev_redesign, main — **no `develop` exists** |

Also, project doc `claude/backend-contract-round3.md` says two chat fixes landed on `feat/ad-detail-wave-0`: `POST /chats/rooms/:roomId/messages` and a single-`ChatState` bloc refactor. **Neither is in this copy.** The controller has no POST route and the bloc still has 8 one-shot state classes. This audit covers the code as it is on disk. Phase 2 has to start from an agreed baseline (see §10, Q1).

`ado-dad-chat/` is not a service. It only holds five static HTML test pages. `lib/single-user-chat*.html` are the same kind of test pages.

---

## 1. Inventory

### Mobile (`ado_dad_mobile/lib`)
| Layer | File | Lines | Role |
|---|---|---|---|
| UI | `features/chat/ui/chat_rooms_page.dart` | 731 | Conversation list (search, skeleton, error, empty) |
| UI | `features/chat/ui/chat_page.dart` | 1681 | Thread, composer, image/voice staging, inline audio player: all in one file |
| UI | `features/chat/ui/chat_debug_page.dart` | 224 | Debug screen, **routed in production** (`/chat-debug`) |
| State | `features/chat/bloc/chat_bloc.dart` / `_event` / `_state` | 305/82/47 | **One global `ChatBloc`** (`main.dart:243`) shared by the list and the thread |
| Repo | `repositories/chat_repository.dart` | 628 | Singleton. Mixes REST, socket, upload and legacy/dead paths |
| Data | `services/chat_api_service.dart` | 217 | Raw `package:http` with its own 401-refresh logic (does not use `ApiService`/Dio) |
| Data | `services/chat_socket_service.dart` | 471 | Singleton `socket_io_client`, `/chat` namespace |
| Flow | `features/home/services/chat_service.dart` | 222 | "Chat" button flow from ad detail (check → create → join → push) |
| Flow | `features/home/services/offer_service.dart` | 627 | "Make an offer" flow: sends a text message via socket |
| Upload | `repositories/add_repo.dart:706` `uploadFileToS3` | — | Presigned PUT to S3 |
| Routes | `common/app_routes.dart:138, 400, 424` | — | `/chat-rooms` (nav shell), `/chat/:roomId?name&profilePic&phone&adId&adTitle&price`, `/chat-debug` |
| Push | `main.dart:95-190` | — | FCM: every tap opens `/notifications`. **No chat-specific handling** |
| Model | `models/chat_item.dart` | 13 | Unused. All chat data is `Map<String, dynamic>` |

Packages in use: `socket_io_client ^2.0.3`, `flutter_bloc ^8.1.6`, `http`, `dio ^5.8`, `just_audio`, `audioplayers` (both), `record ^6`, `cached_network_image` (**not used by chat**), `firebase_messaging`.

### Backend (`ado-dad/src`)
| File | Lines | Role |
|---|---|---|
| `chat/chat.controller.ts` | 631 | REST: 4 routes (≈80% Swagger text) |
| `chat/chat.gateway.ts` | 714 | Socket.IO `/chat`: 9 events |
| `chat/chat.service.ts` | 850 | Rooms, messages, read flag, admin/export |
| `chat/schemas/chat-room.schema.ts`, `chat-message.schema.ts` | 88/94 | Mongo models + 12 + 8 indexes |
| `chat/services/content-moderation.service.ts` | 198 | Regex moderation on every text message |
| `chat/guards/rate-limit.guard.ts` | 112 | In-memory per-instance rate limiter |
| `auth/guard/ws-guard.ts` | — | Socket JWT guard (per event, verifies the handshake token) |
| `shared/redis-io.adapter.ts` | — | Socket.IO Redis adapter (falls back to in-memory) |
| `shared/upload.controller.ts`, `shared/s3.service.ts` | — | Presigned URL + multipart upload |
| Notifications (`fcm-notification.service.ts`, `notification.worker.ts`) | — | **No chat integration** |

Not present: a Redis presence/unread store, typing events, read-receipt events, a chat push notification, a REST send route, a mark-read route or event, an unread-count API.

---

## 2. API map (as implemented)

### REST: `@Controller('chats')`, all `JwtAuthGuard + RolesGuard` (USER, SHOWROOM, ADMIN, SUPER_ADMIN)

| Endpoint | Request | Response | Pagination | DB work | Failure cases |
|---|---|---|---|---|---|
| `POST /chats/rooms` | `{adId}` | `{success, data:{roomId, initiatorId, adId, adPosterId, participants, status, createdAt}}` | — | ad findById, room findOne, room create | **Every error is rethrown as 400**, so a 404 for an ad becomes 400. Inactive ad → 400. Self-chat is allowed |
| `GET /chats/rooms` | — | `{success, data:[room + otherUser{name, profilePic, **email, countryCode, phoneNumber**} + latestMessage + adDetails{title, description, price, **images[]**, category}]}` | **None, unbounded** | 1 find + **3 queries per room** (user, latest message, ad) | Every error → 400. Sorted `lastMessageAt desc`: rooms with no messages sort by nulls. **Inactive/archived rooms are excluded, so their history disappears** |
| `GET /chats/rooms/:roomId/messages?limit&cursor` | — | `{success, data:{messages[+sender{name, **email**, profilePic}], nextCursor, hasMore, total}, roomId}` | Keyset on `_id` (desc), limit ≤200 | room findOne, **countDocuments every call**, aggregate (`$lookup users` runs **before** `$sort/$limit`) | 403 non-participant ✅, 404 room. `parseInt('abc')` → NaN limit (not validated) |
| `GET /chats/rooms/check/:adId/:otherUserId` | — | `{success, data:{exists, roomId, participants}}` | — | room findOne (`$or` of 2 shapes) | Client calls it with `otherUserId=''` → route doesn't match → **404** |
| ~~POST /chats/rooms/:roomId/messages~~ | — | **does not exist here** | | | Client uses it first for every image/voice send (§5 F-14) |

### Socket.IO: namespace `/chat`, class guards `WsJwtGuard, RateLimitGuard`

| Client emits | Server handler | How the server responds | Actually reaches the client? |
|---|---|---|---|
| `sendMessage {roomId, content, type, attachments}` | ✅ | broadcast `message` to the room; `callback?.()`; emits `sendMessageResponse` **only on success** | Errors: **nothing** (F-01) |
| `createChatRoom {adId}` | ✅ | `return response` (Nest ack) + broadcast `chatRoomCreated` | ✅ ack works |
| `joinChatRoom {roomId}` | ✅ participant check | `callback?.()` (never defined) + emits `joinChatRoomResponse` | ✅ via event only |
| `leaveChatRoom` | ✅ | `callback?.()` only | ❌ no response (not used by the client) |
| `checkExistingChatRoom` | ✅ | `callback?.()` only | ❌ **never responds** |
| `getRoomMessages {roomId}` | ✅ | emits `getRoomMessagesResponse {messages}` | Client parses `response['data']`, so it gets an **empty list** |
| `getUserChatRooms` | ✅ | emits `getUserChatRoomsResponse` | Client's `emitWithAck` variant **always times out (5 s)** |
| `ping` | ✅ | return | ✅ |
| `markChatRoomRead {roomId}` | ❌ **no handler** | — | Unread is never cleared server-side |
| typing / presence / read receipts | ❌ | — | — |

Server → client events: `connected`, `message`, `chatRoomCreated`, `userJoinedRoom`, `userLeftRoom`, `sendMessageResponse`, `joinChatRoomResponse`, `getRoomMessagesResponse`, `getUserChatRoomsResponse`, and Nest's `exception` (the client does not listen for it).

---

## 3. Database map

**ChatRoom:** `roomId` (string `chat_{adId}_{initiatorId}_{posterId}`, unique), `initiatorId`, `adId`, `adPosterId`, `participants: [String]` (written as ObjectIds, cast to strings), `userRoles: Map`, `status (active|inactive|archived)`, `lastMessageAt`, `messageCount`.

Indexes (12): `roomId` unique, `{initiatorId, adId}` unique ✅, `adId`, `adPosterId`, `participants`, `status`, `lastMessageAt`, `createdAt`, `{initiatorId, status}`, `{adPosterId, status}`, `{adId, status}`, `{initiatorId, adPosterId}`.

**ChatMessage:** `roomRef` (ObjectId), `roomId` (string, denormalised), `senderId`, `type (text|image|audio|file|system)`, `content`, `attachments[{type, url, mimeType, size, duration≤180, thumbnailUrl}]`, `isRead` (**one flag for the whole room, not per user**), `readAt`, `readBy` (never written), `moderationFlags`, `moderationScore`.

Indexes (8): `{roomRef, createdAt}`, `{roomId, createdAt}`, `senderId`, `isRead`, `createdAt`, `{roomRef, isRead}`, `{roomId, isRead}`, `{senderId, createdAt}`.

| Query | Index used | Assessment |
|---|---|---|
| Room list `$or[initiatorId, adPosterId] + status`, sort `lastMessageAt,createdAt` | `{initiatorId,status}` ∪ `{adPosterId,status}` | Sort runs in memory. Fine at today's volume. Should become `{initiatorId,status,lastMessageAt}` / `{adPosterId,status,lastMessageAt}` |
| Latest message per room `{roomId}` sort `createdAt desc` limit 1 | `{roomId, createdAt}` ✅ | Efficient per call, but called N times (N+1) |
| History `{roomId, _id<cursor}` sort `_id desc` | `{roomId, createdAt}` does not serve an `_id` sort | Blocking sort over the whole room, plus a `$lookup` on every message before `$limit`. Needs `{roomId:1, _id:-1}` |
| `countDocuments({roomId})` per history page | `{roomId, createdAt}` | Wasted work. The client never uses `total` |
| Unread count | — | Nothing calls it (`getUnreadCount` exists, is not exposed, and counts the user's **own** messages too) |
| Low-value indexes | `isRead`, `createdAt`, the duplicate `roomRef*`/`roomId*` pairs, `participants`, `status` | Extra write cost on every message. Candidates to drop **after** `explain()` confirms they're unused |

Also: `messageCount`/`lastMessageAt` are updated in a second, separate write after the message insert. If that write fails, the room counters drift. `maxPoolSize: 10` (`app.module.ts:79`) caps concurrency. The N+1 room list alone can take all 10 connections.

Not verified (file not read): where `deactivateChatRoom` is called (ad sold/removed).

---

## 4. Current end-to-end flows (from the code)

### 4a. Opening the Chat tab
```text
Tap Chat tab → ChatRoomsPage.initState (post-frame)
  ↓ bloc state Initial/Error/Loading? → InitializeChat, else LoadChatRooms
InitializeChat
  ↓ AuthGuard.isAuthenticated()                          [prefs read]
  ↓ emit ChatLoading → skeleton
  ↓ repository.initialize() (idempotent listeners)
  ↓ await socket.connect()  ← BLOCKS up to 5 s           ✗ F-10
  │    fail → errorStream "Connection timeout" → ChatErrorState → "Connection Failed" screen
  ↓ GET /chats/rooms                                     ✗ N+1, unbounded (F-20)
  ↓ _formatRoomData: unreadCount = 0 always              ✗ F-06
  │    rooms with no message → timestamp = DateTime.now() → "Just now"
  ↓ roomsStream → ChatRoomsLoaded → ChatRoomsSuccess → list
Afterwards: list never updates live — user is in no socket room and there is no per-user channel   ✗ F-07
Every return to the tab → full reload again (no cache)
```

### 4b. "Chat" on an ad (`ChatService.startDirectChat`)
```text
Loading dialog
  ↓ GET /chats/rooms/check/:adId/:posterId               (RTT 1)
  ├─ exists → joinChatRoom (connect ≤5 s if needed + join ≤5 s)
  └─ not    → socket.connect ≤5 s → createChatRoom ack ≤5 s → join ≤5 s
  ↓ context.push('/chat/:roomId?name&adTitle&adId')      (no price, phone, avatar)
ChatPage.initState
  ↓ JoinChatRoom       → joins AGAIN                      ✗ duplicate
  ↓ MarkRoomRead       → emits markChatRoomRead (no server handler)   ✗ F-06
  ↓ LoadRoomMessages   → GET messages (latest 50, never paginated)    ✗ F-08
  ↓ _fetchAdPrice      → GET ad detail (price not passed)
  ↓ _getCurrentUserId  → async prefs; bubbles may render all-left first   ✗ F-19
Join and REST history run in parallel → any message sent between the REST
snapshot and join completion is never shown                 ✗ F-09
```
Worst case before the thread paints: 3 socket timeouts × 5 s = **15 s**, then an error dialog. Typical: **5–7 serial round trips**.

### 4c. Sending a text message
```text
Send → controller.clear() (text gone) → SendMessage(text)   ← no roomId
  ↓ ChatBloc → repo.sendMessage → socket.sendMessage
  ↓ uses singleton _currentRoomId (last joined/created room)   ✗ F-04
  ↓ _ensureConnection → maybe connect()
  ↓ socket.emit('sendMessage')  — fire & forget, no ack, no client id
Server: WsJwtGuard (handshake token re-verified) ✗ F-02 → RateLimitGuard
  ↓ getChatRoom + status + participant ✅
  ↓ moderation (regex) — may REJECT                           ✗ F-05
  ↓ insert message → update room counters (2 writes)
  ↓ broadcast 'message' to room → sender and receiver (if joined)
  ↓ success: 'sendMessageResponse' | error: callback?.() = undefined → NOTHING   ✗ F-01
Client: 'message' → messagesStream → NewMessageReceived → ChatPage dedupes by _id → append
        → ChatRoomsPage (alive in nav shell) → full rooms reload, throttled 2 s   ✗ F-22
Recipient not in the thread: nothing. No push, no badge, no list update   ✗ F-07
```

### 4d. Sending an image or voice note
```text
Stage → Send → SendMessage(type, bytes, mime, roomId)
  ↓ GET /upload/presigned-url?fileName&fileType
  ↓ Dio PUT bytes → S3 (voice: signed type audio/mp4, sent as audio/m4a)   ✗ F-03
  ↓ POST /chats/rooms/:roomId/messages → 404 (route missing)               ✗ F-14
  ↓ catch "404" → joinRoomAndWait → socket sendMessage (fire & forget)
  ↓ server: audio without duration → server downloads the file (≤15 MB) to measure   ✗ F-27
  ↓ bloc add(LoadRoomMessages) → ChatLoading → full thread reload per file
```

### 4e. Offer
`OfferService` → socket `sendMessage` (text) → `await 1 s` → **shows "offer sent" regardless of the outcome** (F-15).

---

## 5. Failure analysis

Severity: **P0** chat fails · **P1** major functional · **P2** performance/UX · **P3** cleanup.
Confidence: ✔ confirmed in code · ◐ strong inference, needs one runtime check.

### P0: chat fails or loses data

| ID | Problem | Location | Root cause | Impact | Fix |
|---|---|---|---|---|---|
| **F-01** ✔ | Rejected or failed sends are silently lost | `chat.gateway.ts:226,332,339` · `chat_socket_service.dart:364` · `chat_page.dart:1356` | Handlers declare `callback?` as a 3rd undecorated param. **Nest never injects it** (acks come from the return value; the code comment at :643 admits this). The error branch only calls `callback?.()`. The client `emit`s without an ack or client message id, and clears the input first | Moderation rejects, room inactive, validation errors and DB errors all make the message vanish with no feedback. The user thinks it was sent | Return an ack object from the handler. Client uses `emitWithAck` with a timeout and a `clientMessageId`, keeps the message as `sending` → `sent`/`failed` + Retry |
| **F-02** ◐ | Chat stops working after the access token expires, until app restart | `ws-guard.ts` (reads `handshake.auth.token` per event) · `chat_socket_service.dart:92` (token set once) · `chat.gateway.ts:154` | The handshake token never changes. After expiry every event fails the guard (`exception` event, not handled). Reconnects reuse the stale token → `handleConnection` calls `client.disconnect()` → a server-initiated disconnect, which socket.io **does not auto-reconnect** | All socket traffic silently dead: no sends, no live messages, joins time out. REST still works, so the app looks half-alive | Client refreshes the token and reconnects on `connect_error`/`exception` with an auth code. Server emits an explicit `auth_expired` before disconnecting. Access TTL not found in code (JwtModule has no `expiresIn` here), so check it |
| **F-03** ◐ | Voice notes fail to upload | `upload.controller.ts:133-140` · `add_repo.dart:725-731` · `chat_bloc/_sendStagedVoice` (`audio/m4a`) | The presigned URL is signed with `ContentType: audio/mp4` (normalised). The client PUTs `Content-Type: audio/m4a`. With SDK v3 presigning, content-type is a signed header → `SignatureDoesNotMatch` | Every voice note from the app fails at upload | Return the signed content type from the endpoint and have the client use it, or send `audio/mp4` from the client. **Verify with one upload** |
| **F-04** ✔ | Messages can go to the wrong conversation | `chat_socket_service.dart:14,175,228,344` · `chat_page.dart:1359` (no roomId) | Text send uses a global `_currentRoomId`, mutated by any `joinChatRoomResponse`/`chatRoomCreated` (including background offer/create flows and reconnect rejoins) | If the join for room B is slow or fails, text typed in B is delivered to A (a room the user belongs to, so the server accepts it) | Every send carries an explicit `roomId` from the page. Delete `_currentRoomId`-based sending |

### P1: major functional

| ID | Problem | Location | Root cause | Impact | Fix |
|---|---|---|---|---|---|
| F-05 ✔ | Normal messages are rejected by moderation | `content-moderation.service.ts:16-33` | `\b(kill|die|hate)\b` scores 70 = reject. URL +30, email +50, US-format phone +50 | "I'd hate to lose this deal", "send photos at a@b.com" are rejected, and silently lost because of F-01 | Remove violence words from auto-reject, flag instead of block, return a clear reason code the UI can show |
| F-06 ✔ | Unread counts and badges don't exist | `chat.service.ts:677` (unexposed) · `chat_repository.dart:104` · `chat_socket_service.dart:337` · `scaffold_with_nav_bar.dart` | Backend returns no `unreadCount`. The client emits `markChatRoomRead`, which has no handler. `isRead` is one flag for the whole room, so reading marks your own sent messages too | No unread badge in the list or nav, no "new" state | Per-user read pointer (`lastReadMessageId` per participant on ChatRoom), `unreadCount` in the room list, `markRead` endpoint + event. This was already specified in `docs/chat_backend_api_spec.md` §1–3; phone and price from that spec were built, but unread and mark-read never were |
| F-07 ✔ | Conversation list and other chats are not live; offline users are never notified | `chat.gateway.ts:167` (no per-user room) · notifications module (no chat code) · `main.dart:111` | Sockets join only the open room. No `user:{id}` room, no FCM on new message, taps always go to `/notifications` | A buyer's message is unseen until the seller happens to open the tab. On a marketplace that means lost leads | On connect, join `user:{id}`. On send, emit `conversation.updated` to both users. Queue FCM for recipients not connected. Deep link to `/chat/:roomId` |
| F-08 ✔ | Only the latest 50 messages are ever visible | `chat_api_service.dart:93` (no cursor) · `chat_page.dart:407` | Backend paginates. Client never passes `cursor`/`limit` and has no load-more | Older history is unreachable | Reversed ListView + load-older on scroll using `nextCursor` |
| F-09 ✔ | Messages missed between history load and join | `chat_page.dart:101-106` | `JoinChatRoom` and `LoadRoomMessages` run concurrently. No catch-up after join or reconnect | Messages go missing until the page is reopened | Join first (ack), then fetch history. On every reconnect, fetch "since last id" and merge by id |
| F-10 ✔ | Chat list waits on socket connect (up to 5 s) and flashes "Connection Failed" | `chat_bloc.dart:45-53` · `chat_socket_service.dart:112` | REST room load is `await`ed after `connect()`. A connect timeout is pushed to the error stream → `ChatErrorState` | Slow first paint. Offline or blocked socket = error screen before data | Load REST immediately. Connect socket in the background. Show a small "connecting" banner, not an error |
| F-11 ✔ | Bubble time and date separators are shown in UTC | `chat_page.dart:551-557, 703-722` | `DateTime.tryParse('…Z')` stays UTC. No `.toLocal()` | Times off by 5 h 30 m in India. "Today"/"Yesterday" wrong around midnight | `.toLocal()` at model parse time |
| F-12 ✔ | Suspended users can keep chatting | `ws-guard.ts` · `chat.gateway.ts:42-85` | Socket auth checks only the JWT signature. No user-exists / suspension / session check (HTTP has `suspension.guard.ts`) | Moderation bypass | Load the user once at handshake and cache status on the socket. Re-check on send (cheap Redis flag) |
| F-13 ✔ | PII in API responses and logs | `chat.service.ts:298, 636` · `chat.gateway.ts:230,244,314,677,684` · `onAny` at :100 | Room list returns the other party's **email + phone**. Every message returns sender email. The gateway logs full payloads, message content and room lists (phones) at `log` level, plus every packet | Contact details exposed to anyone who opens a chat. Chat content and phone numbers sit in PM2 logs | Return only what the UI needs (name, avatar, and phone only if a product rule allows the call button). Remove payload logging |
| F-14 ✔ | Image/voice send always tries a missing route first | `chat_repository.dart:261-290` · controller | `POST /chats/rooms/:roomId/messages` is absent on this branch | Extra failed request per file. The fallback socket path inherits F-01 and F-04 | Decide one send path (§10 Q3) |
| F-15 ✔ | Offer flow reports success without confirmation | `offer_service.dart:185-193` | Fire-and-forget send, fixed 1 s delay, then success snackbar | False "Offer sent" | Await ack (after F-01) |
| F-16 ◐ | Attachment URLs are not validated; uploads unrestricted | `chat.service.ts:507-537` · `send-message.dto.ts` · `upload.controller.ts:120` · `s3.service.ts:83` | Any `url` is accepted for image/audio. Presigned PUT has no content-type allowlist or size cap, and the client chooses the file name. Objects appear to be publicly readable by URL (bucket policy not verified) | External tracking images or phishing links inside chat. Arbitrary files in the bucket. Private chat media readable by anyone with the link | Server issues a presigned URL for `chat/{roomId}/…` with an allowlist and size cap. `sendMessage` only accepts keys it issued. Signed GET URLs for chat media |
| F-17 ◐ | Global `ValidationPipe` may not run on gateway events | `main.ts:224` · `chat.gateway.ts` | Whether `useGlobalPipes` covers gateway handlers depends on Nest version and app setup, and the gateway declares no `@UsePipes`. **Needs one runtime test** (send 2000 chars over the socket) | `SendMessageDto` limits (1–1000 chars, enum, nested attachments) may be unenforced on socket | `@UsePipes(new ValidationPipe({whitelist:true, transform:true}))` on the gateway, with a WS exception filter that returns an ack error |

### P2: performance and UX

| ID | Problem | Location | Fix |
|---|---|---|---|
| F-18 | Single global bloc of one-shot states: thread events repaint the list and vice versa. `ChatErrorState` from the thread wipes list context. `_lastRooms` hides later errors forever | `chat_bloc.dart`, `chat_rooms_page.dart:28,147-171` | Separate list and thread controllers with explicit status (Phase 2) |
| F-19 | `_currentUserId` loaded async after the first build → all bubbles left-aligned until the next rebuild | `chat_page.dart:87,115,570` | Resolve the user id before rendering (session provider) |
| F-20 | Room list N+1: 1 + 3N queries, no pagination (50 rooms ≈ 151 queries on a 10-connection pool) | `chat.service.ts:271-361` | One aggregation (`$lookup` users/ads with `$project`, last message denormalised on room), cursor pagination |
| F-21 | History query: `$lookup` before `$limit`, sort on non-indexed `_id`, `countDocuments` per page, sender email | `chat.service.ts:569-654` | `{roomId:1,_id:-1}` index, `$sort+$limit` first, drop `total`, drop per-message sender lookup (2 participants: send once with the room) |
| F-22 | Each incoming message in an open thread triggers a full N+1 room-list reload (list page stays alive in the nav shell) | `chat_rooms_page.dart:135-138` | Patch the one room row from a `conversation.updated` event |
| F-23 | Opening a chat from an ad: 5–7 serial round trips, duplicate join, 5 s timeouts stack to 15 s | `chat_service.dart`, `chat_page.dart:101` | Single `POST /chats/rooms` (idempotent get-or-create, REST) → navigate with room payload → page joins once |
| F-24 | Images: `Image.network` full-resolution, 220 px box, no disk cache, no `cacheWidth`, no client resize before upload; each image = separate send + full thread reload | `chat_page.dart:738`, `chat_bloc.dart:212` | `cached_network_image` (already a dependency) with `memCacheWidth`, compress/resize before upload, thumbnail, optimistic insert instead of reload |
| F-25 | One `AudioPlayer` per voice bubble created in `initState`. Every play re-downloads to a new temp file (never deleted). Position stream calls `setState` ~every 200 ms | `chat_page.dart:1454-1680` | Lazy single shared player, cache by URL, stream from URL or cache file |
| F-26 | No client-side 180 s voice cap → a long note is uploaded, then rejected (orphan S3 object, silent failure) | `chat_page.dart:1159-1234` | Stop recording at 180 s, send duration with the attachment |
| F-27 | Client never sends `duration` → server downloads every voice file (≤15 MB into memory) to read it | `chat_repository.dart:309` · `chat.service.ts:99-128` | Client sends duration. Server validates range only |
| F-28 | Non-reversed `ListView` + `animateTo(maxScrollExtent)` → lands short when images load. `SafeArea minimum bottom 50` wastes space above the keyboard | `chat_page.dart:277-285, 407, 429` | `reverse: true` list, keyboard-aware composer |
| F-29 | Deactivated/archived rooms disappear from the list with their history | `chat.service.ts:282` | Show as read-only "Ad no longer available" |
| F-30 | Quick replies are the same for buyer and seller ("Is it still available?" shown to the seller) | `chat_page.dart:811-848` | Role-aware (room `userRoles` already exists) |
| F-31 | Other party's phone number travels in route query params (router location/logs) | `chat_rooms_page.dart:673`, `app_routes.dart:406` | Pass a room id only. The thread reads the room from state or cache |
| F-32 | In-memory rate limiter: never cleaned (`cleanup()` never called → unbounded map), per instance (useless with PM2 cluster), throws `HttpException` in WS context | `rate-limit.guard.ts` | Redis `INCR`+`EXPIRE` limiter, `WsException` → ack error |
| F-33 | Time/label bugs: rooms without messages show "Just now". Pull-to-refresh spinner ends immediately | `chat_repository.dart:99-101`, `chat_rooms_page.dart:335` | Use `createdAt`. Await the reload future |

### P3: cleanup
F-34 dead or broken paths: `sendOfferMessage*` (type `offer`, not in enum), `getOrCreateRoom`/`checkRoomExistsForAd` (call with `''`), `findRoomByAdId` (ack never comes), `getExistingRoomForAd` (reads `_id`, not in payload), socket `getRoomMessages` (parses `data`), `joinChatRoomHelper`, `sendMessageToRoom`, `ChatItem`, `DisposeChat`. · F-35 `/chat-debug` route shipped. · F-36 duplicated auth: gateway `authenticateClient` + `WsJwtGuard` (two copies of the dev fallback secret). · F-37 `connectedUsers` map keyed by user (a second device overwrites; one disconnect removes both); unused by anything useful. · F-38 gateway CORS `origin:'*'` + `credentials:true`. · F-39 two audio packages (`audioplayers` + `just_audio`). · F-40 `ChatApiService` duplicates `ApiService` token refresh on raw `http` (two refresh paths can race). · F-41 8 message indexes with low-selectivity singles (write amplification). · F-42 all controller errors mapped to 400 (`chat.controller.ts:185,317,628`). · F-43 self-chat allowed (`chat.service.ts:185`).

**Totals:** P0 ×4 · P1 ×13 · P2 ×16 · P3 ×10

---

## 6. Performance audit

No timings were measured. There was no runtime, DB or device access this session (§9). Figures are derived from the code and are the **baseline to measure in Phase 8**.

| Metric | Current behaviour (code-derived) | Main cause |
|---|---|---|
| Chat list first paint | socket connect (0–5 s, blocking) + `GET /chats/rooms` (1+3N queries) | F-10, F-20 |
| Chat list repeat visit | Same full reload, no cache | F-18 |
| Open thread from list | join + history + mark-read + ad detail fetch, in parallel | F-09, F-23 |
| Open thread from ad | 5–7 serial RTTs, 15 s worst case | F-23 |
| Time to first message | History aggregate with per-message `$lookup`, `countDocuments` | F-21 |
| Send latency | 1 RTT + moderation + 2 writes. Unknowable to the user (no ack) | F-01 |
| Receive latency (thread open) | 1 broadcast. Fine | — |
| Receive latency (thread closed / app backgrounded) | ∞ (no push, no list event) | F-07 |
| Image send | presign + PUT (full-size) + failed POST + socket + full thread reload | F-14, F-24 |
| Voice send | Fails at upload (F-03). If fixed: server-side re-download | F-27 |
| Unread calculation | Not implemented | F-06 |

Unnecessary work found: duplicate join, full room-list reload per message, full thread reload per attachment, `countDocuments` per page, per-message sender lookup, ad-detail fetch for price, audio re-download per play, `onAny` logging of every packet, 3 queries per room.

**Measurement plan for Phase 8** (needs your environment): `explain("executionStats")` on the 4 queries above against a prod-sized copy. Nest interceptor timing for `/chats/*`. Client stopwatch marks (tab tap → first row, row tap → first bubble, send tap → ack). Socket connect time. Flutter DevTools rebuild counts on the thread while receiving 20 messages.

---

## 7. Realtime audit

| Check | Status |
|---|---|
| Authentication | JWT at handshake ✅. Stale after expiry ❌ (F-02). No user/suspension check ❌ (F-12) |
| Connection lifecycle | Singleton, `forceNew`, reuse guard ✅. Monitor timer de-duplicated ✅. Manual `connect()` can dispose a socket mid-reconnect ⚠ |
| Room management | Join checks participant ✅. No `user:{id}` room ❌. Global `_currentRoomId` ❌ (F-04) |
| Message events | `message` broadcast ✅. No ack/error ❌ (F-01). No client id → no safe retry or dedupe of optimistic items |
| Read / typing / presence | Not implemented |
| Reconnect | Rejoins last room only ✅. No catch-up fetch ❌ (F-09) |
| Duplicate listeners | Repository `initialize()` idempotent ✅. Bloc subscriptions `??=` ✅ |
| Multi-instance | Redis adapter present ✅ (if `REDIS_*` set). Rate limiter and `connectedUsers` are per-instance ❌ |
| Server-side authorization | Send ✅, join ✅, history ✅ (REST passes requester). `leaveChatRoom` unchecked (harmless) |

---

## 8. Security summary

| Area | Finding | ID |
|---|---|---|
| IDOR (messages/rooms) | Protected: participant checked on send, join, REST history ✅. `getRoomMessages` makes `requesterId` optional; both callers pass it today, but that's one refactor away from an IDOR → make it required | — |
| Socket auth | Stale token, no suspension check, dev fallback secret if `NODE_ENV` ≠ production and `TOKEN_KEY` unset | F-02, F-12, F-36 |
| PII exposure | Email + phone of the counterpart in the room list, email per message, PII in logs | F-13, F-31 |
| Attachments | Arbitrary URLs accepted, unrestricted presigned uploads, public media | F-16 |
| Validation | WS DTO validation may not run | F-17 |
| Rate limiting / spam | Per-instance, leaking, wrong exception type | F-32 |
| Content | Moderation both over-blocks and is trivially bypassed (Indian phone formats, spacing) | F-05 |
| Adjacent (not chat path) | `/upload/file` MIME regex `audio\/` + `$` only matches the literal `audio/` → real audio/video MIME types rejected | — |

---

## 9. What this audit could not do

- **No runtime measurements.** `device_bash` cannot mount `C:\pendrive` (Windows update issue), so no `flutter test`, `npm test`, `explain()` or live socket trace was possible. ◐ items need one runtime check each.
- Access token TTL, bucket policy, `deactivateChatRoom` callers and `ads.service.ts` were not read.
- Existing backend specs (`chat.service.spec.ts`, `chat.gateway.spec.ts`, `chat.controller.spec.ts`) were not run.

---

## 10. Decisions needed before Phase 2

1. **Baseline.** Mobile has no `develop`. Audit `dev_redesign` (this copy), or `feat/ad-detail-wave-0` (where Round 3/4 chat changes reportedly are, not on this machine)? Phase 2 depends on the answer.
2. **Contact visibility.** `docs/chat_backend_api_spec.md` asks for the phone number on purpose (Call button), so phone looks intended. Email is not in that spec but is returned. Confirm: phone for every enquirer (or only after the seller replies?), and drop email? This decides the room payload and F-13.
3. **Send transport.** Recommendation: **REST for writes** (`POST …/messages` with `clientMessageId`, idempotent, retryable, works without socket) + **socket for delivery only** (`message.created`, `conversation.updated`, `read`, `typing`). The alternative is socket-with-ack for writes. Both work. REST writes are simpler to make reliable and test.
4. **Scope of realtime extras.** Typing and online presence cost Redis state plus battery. Needed for v1, or read receipts + push + live list only?
5. **Push notifications.** Confirm FCM chat pushes are in scope (token registration exists; `onTokenRefresh` is still a TODO in `main.dart:96`).

---

```text
COMPLETED:      Phase 1 audit: repo inventory, frontend/backend/API/DB/realtime maps,
                5 traced flows, 43 findings ranked, perf baseline plan, security review
CHANGES:        None (read-only)
TESTS:          None run (no runtime access, §9)
PROBLEMS FOUND: P0 ×4 · P1 ×13 · P2 ×16 · P3 ×10
PROBLEMS FIXED: 0 (by design)
REMAINING:      Runtime verification of F-02, F-03, F-16, F-17. Decisions Q1–Q5
NEXT PHASE:     Phase 2 — target architecture, models, contracts, state, cache,
                security model. Blocked on Q1 (baseline) and Q3 (send transport)
```
