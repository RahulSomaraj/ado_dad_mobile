# Chat — Backend changes required for the wireframe redesign

The chat UI redesign (inbox with unread badges + previews, pinned listing card
with price, Call in header) is implemented on the client. Three pieces of data
must come from the backend for those features to actually appear. The Flutter
client already reads all of the fields below with safe fallbacks, so the moment
the backend includes them the UI lights up — no further app release needed for
the data wiring.

Summary of what's needed:

1. `unreadCount` per room in the room-list payload.
2. A `markChatRoomRead` action so opening a chat resets that count.
3. `otherUser.phoneNumber` + `otherUser.countryCode` in the room payload (enables the Call button in the chat header).
4. `adDetails.price` (and ideally `adDetails.image`) in the room payload (lets the pinned listing card show the price without a second API call).

The client gets rooms over **Socket.IO** (`getUserChatRooms` → `getUserChatRoomsResponse`). There is also a REST endpoint `GET /chats/rooms`; if it returns rooms it should use the same shape.

---

## 1. Room list — add `unreadCount`, phone, price

### Socket event (existing)

Client emits:

```
socket.emit('getUserChatRooms')
```

Server responds on `getUserChatRoomsResponse`. **Add the bold fields:**

```jsonc
{
  "success": true,
  "chatRooms": [
    {
      "roomId": "665f1a2b3c4d5e6f7a8b9c0d",
      "adId": "660aabbccddeeff001122334",
      "status": "active",
      "messageCount": 12,
      "lastMessageAt": "2026-06-13T09:41:00.000Z",

      "unreadCount": 2,                      // ← NEW: unread for the requesting user

      "otherUser": {
        "id": "5fd0...e1",
        "name": "Rahul S.",
        "profilePic": "https://cdn.adodad.in/u/abc.jpg",
        "phoneNumber": "9876543210",        // ← NEW (enables Call in header)
        "countryCode": "+91"                 // ← NEW
      },

      "latestMessage": {
        "content": "Is it still available?",
        "type": "text"                       // text | image | audio
      },

      "adDetails": {
        "title": "Maruti Swift VXI 2021",
        "price": 540000,                     // ← NEW (pinned card price)
        "image": "https://cdn.adodad.in/ads/xyz.jpg"  // ← NEW (optional)
      }
    }
  ]
}
```

Notes for the implementer:
- `unreadCount` is **per requesting user** — count messages in the room with `createdAt` after that user's `lastReadAt` for the room and `senderId != requestingUserId`.
- `price` may be sent as a number or numeric string; the client coerces both.
- If a field is absent the client falls back gracefully (badge hidden, price hidden, Call button hidden), so partial rollout is safe.

### REST equivalent (if used): `GET /chats/rooms`

Same per-room object shape as `chatRooms[]` above.

---

## 2. Mark room as read

When the user opens a conversation the client emits:

```
socket.emit('markChatRoomRead', { "roomId": "665f1a2b3c4d5e6f7a8b9c0d" })
```

Server should:
1. Set `lastReadAt = now()` for `(userId, roomId)`.
2. Reset that user's `unreadCount` for the room to `0`.
3. (Optional) ack on `markChatRoomReadResponse` with `{ "success": true, "roomId": "..." }`.

The client already zeroes the badge optimistically, so an ack is not strictly required — but returning the updated room (or re-emitting the room list) keeps multiple devices in sync.

### Optional REST equivalent

```
POST /chats/rooms/:roomId/read      → 200 { "success": true }
```

---

## 3. Unread increment semantics (server-side)

- On a new message delivered to a room, increment `unreadCount` for **every member except the sender**.
- Reset to `0` on `markChatRoomRead` (section 2).
- The existing `newMessage` socket broadcast does not need to change shape; if it can also carry the recipient's updated `unreadCount` for the room, the inbox badge can update live without a refetch (nice-to-have).

---

## Client-side wiring already in place (for reference)

| Field / action            | Where the client consumes it |
|---------------------------|------------------------------|
| `unreadCount` / `unread`  | `chat_repository.dart` → `_formatRoomData` → badge in `chat_rooms_page.dart` |
| `adDetails.price`         | `_formatRoomData` → `adPrice` → pinned card in `chat_page.dart` |
| `otherUser.phoneNumber` / `countryCode` | `_openRoom` builds the `phone` param → Call icon in `chat_page.dart` header |
| `markChatRoomRead` emit   | `chat_socket_service.dart` → `markRoomRead()` (dispatched on chat open) |

No app changes are required once the backend returns the fields above; values are read defensively with fallbacks.
