# Backend fields needed to unblock UI features

All additions below are **additive and backward-compatible**: new fields are optional/nullable, and the Flutter client only reads keys it knows (`fromJson` ignores unknown keys, missing keys render as nothing). Existing API responses and existing app versions keep working unchanged.

Brand/UX context: these unblock the redesigned ad cards, My Ads management, Profile stats, and dealer trust signals.

---

## 1. Ad object — engagement counters
Add to each ad in `/v2/ads/list` and ad detail responses.

| Field | Type | Example | Unblocks |
|------|------|---------|----------|
| `viewsCount` | int (nullable) | `1240` | Per-ad views on My Ads tile |
| `favoritesCount` | int (nullable) | `34` | Per-ad saves on My Ads tile |
| `chatsCount` | int (nullable) | `8` | Per-ad chats on My Ads tile |

```json
{ "id": "…", "price": 540000, "viewsCount": 1240, "favoritesCount": 34, "chatsCount": 8 }
```

## 2. Ad object — explicit status
Currently the client can only derive Active/Sold/Inactive from `isActive` + `soldOut`. A status string enables the full Active / Pending / Sold / Expired tabs.

| Field | Type | Allowed values | Unblocks |
|------|------|----------------|----------|
| `status` | string (nullable) | `active` \| `pending` \| `sold` \| `expired` | Full My Ads status filter tabs |

## 3. Ad actions — new endpoints
| Endpoint | Method | Purpose | Unblocks |
|----------|--------|---------|----------|
| `/ads/{id}/mark-sold` | PATCH | Mark a listing sold | My Ads "Mark sold" inline action |
| `/ads/{id}/boost` | POST | Promote/bump a listing | My Ads "Boost" inline action |
| `/ads/{id}/relist` | POST | Re-publish an expired/sold ad | My Ads "Relist" action |

(If a mark-sold path already exists, share it and we'll wire the existing one.)

## 4. User / profile — counts
Add to the profile / `me` response.

| Field | Type | Example | Unblocks |
|------|------|---------|----------|
| `adsCount` | int (nullable) | `5` | Profile stats strip |
| `wishlistCount` | int (nullable) | `18` | Profile stats strip |
| `chatsCount` | int (nullable) | `3` | Profile stats strip |

## 5. Seller / dealer — trust signals
Add to the `user` object on ads and to the showroom/dealer responses.

| Field | Type | Example | Unblocks |
|------|------|---------|----------|
| `isVerified` | bool (nullable) | `true` | Verified seller/dealer badge (Ad detail, Showroom) |
| `rating` | number (nullable) | `4.6` | Dealer rating chip (Showroom) |
| `ratingCount` | int (nullable) | `212` | Rating count (optional) |
| `avgResponseMins` | int (nullable) | `5` | "Replies fast" signal (Showroom, Seller profile) |

## 6. Already supported — no change needed
- `distance` is already returned when the request includes the user's lat/lng — used for "X km away" on cards. Just ensure it's populated when coordinates are sent.
- EMI estimate is computed **client-side** from `price`; no backend field needed.

---

### Priority order (most user-visible first)
1. `status` on ads (unblocks full My Ads tabs) + mark-sold endpoint.
2. Engagement counters (`viewsCount` / `favoritesCount` / `chatsCount`) on ads + profile counts.
3. `isVerified` on user/dealer.
4. `boost` / `relist` endpoints + `rating` / `avgResponseMins` for dealers.

Once 1–2 land, the My Ads management screen and Profile stats can be completed with no further client risk.
