# Car Create — UI/UX redesign + backend compatibility

**Scope:** `ado_dad_mobile` → Sell flow → **Car** (`SellCategory.car`, API `private_vehicle`).
**Status:** Phases 1–5 — analysis, wireframe, mapping, plan, **and implementation (20 Sep 2026)**.
**Date:** 20 Sep 2026 · **Branch inspected:** local `C:\pendrive\...\ado_dad_mobile` (`dev_redesign`), `ado-dad` (`develop`).

---

## Implementation status — 20 Sep 2026

Written to the `C:\pendrive` copies. **Uncompiled** — `flutter analyze` has not been run from this session (no Dart SDK in the cloud workspace).

**Mobile — `lib/features/sell/flow/`**

| File | |
|---|---|
| `domain/sell_variant.dart` | **new** — `SellVariant`: id, names, populated fuel/transmission ids + labels, engine cc, seats, colours; `spec` / `summary` / `fuelGroup` helpers |
| `domain/sell_color_match.dart` | **new** — name → `config.colors` hex, whole-word, last-match-wins ("Midnight Blue **Black**" is black) |
| `ui/widgets/sell_section.dart` | **new** — `SellSection` (caps label, hairline, collapse-to-summary) + `SellFromVariantTag` |
| `ui/widgets/variant_sheet.dart` | **new** — `showVariantSheet`, searchable, fuel-grouped, "I'm not sure" |
| `ui/widgets/sell_color_field.dart` | **new** — typed colour input, live swatch, dashed ring when unmatched, suggestions + `Use "…" as typed`, quick-pick pills, `n / 40` |
| `data/sell_repository.dart` | `variants()` now sends `limit=100&isActive=true&sortBy=price&sortOrder=ASC` and parses the full row; new `variantColors()` with memo |
| `domain/sell_models.dart` | `SellKeys.fuelFromVariant`, `SellKeys.transmissionFromVariant` (local only, never sent) |
| `domain/sell_rules.dart` | colour ≤ 40 check; `color` trimmed in `buildPayload`; `ownerCount` label → "Previous owners" |
| `ui/widgets/sell_ui.dart` | `SellInput` accepts an optional `focusNode` (caller-owned) — additive |
| `ui/steps/details_step.dart` | car branch rewritten as `_car()`; bike/commercial moved verbatim into `_legacyVehicle()`; property untouched; `cacheExtent` 4000 → 2000 |

**Backend — `ado-dad/src/vehicle-inventory/vehicle-inventory.service.ts`**

`findAllVehicleVariantsWithPagination`: `colors` and `images` added to the `$project` and to `reorderedVariants`. Additive to a `data: any[]` response; no schema, index or query change, so nothing touches the database. With it the colour swatches need no extra call; without it `variantColors()` falls back to `GET /variants/:id`, so the app works against either server.

**Decisions taken** (open items 1–3 of the original plan): colour posts the label the seller typed or picked; the projection change shipped; collapse-on-complete is in, triggered by blur and by the pickers closing so it never fires mid-keystroke.

**Not done:** bike and commercial still use the old flat layout — that is the next pass.

---

## Phase 1 — Repository & backend analysis

### 1.1 What "Car Create" actually is today

There is no standalone Car page. The Car create experience is the 4-step sell flow:

| Step | File | Car content |
|---|---|---|
| 1 Photos | `flow/ui/steps/photos_step.dart` | shot list, cover, video |
| **2 About the car** | **`flow/ui/steps/details_step.dart` → `_vehicle()`** | **everything car-specific** |
| 3 Price & place | `flow/ui/steps/price_place_step.dart` | price, location, title, description |
| 4 Review | `flow/ui/steps/review_step.dart` | summary + Post |

Supporting layers:

- State: `flow/bloc/sell_flow_cubit.dart` — one flat `Map<String, dynamic> values` keyed by `SellKeys`, plus `errors`, draft autosave, idempotent submit.
- Rules: `flow/domain/sell_rules.dart` — `validateStep()` (client mirror of the server validator) and `buildPayload()` (the only place the request body is built).
- Config: `flow/domain/sell_config.dart` ← `GET /v2/sell/config?category=private_vehicle` (ETag + SharedPreferences cache + offline fallback).
- Network: `flow/data/sell_repository.dart` → `/v2/sell/config`, `/vehicle-inventory/manufacturers`, and via `AddRepository` → `/vehicle-inventory/models`, `/vehicle-inventory/variants`.
- Design system: `flow/ui/widgets/sell_ui.dart` (`SellTokens` + 18 primitives) and `flow/ui/widgets/sell_pickers.dart` (brand/model, year, location sheets).

Backend: `src/ads-v2` (`POST /v2/ads` → `CreateAdV2Dto` → `normalizeCreateAdV2` → `validateCreateAdV2` → `CreateAdUc`), `src/sell` (config + limits, single source of truth), `src/vehicle-inventory` (manufacturer → model → variant catalogue), persisted as `Ad` + `VehicleAd`.

### 1.2 What is causing the clutter

1. **No hierarchy — one flat stack of eight peers.** `_vehicle()` emits Brand&model, Variant, Year+KM, Fuel, Transmission, Colour, Owner, disclosure, each with an identically-weighted `SellLabel` and an 18 px gap. Nothing signals what matters most, so the seller reads all of it.
2. **The Variant chip wall is the single worst offender.** `SellChips` renders every variant inline. Trims are near-identical strings (`VXi`, `VXi AMT`, `ZXi`, `ZXi+ AMT`…), so it becomes half a screen of low-information text — for a field marked *optional* that most private sellers cannot answer confidently.
3. **Redundant data entry.** `GET /vehicle-inventory/variants` already returns each variant's populated `fuelType` and `transmissionType` (and `seatingCapacity`, `engineSpecs`, `price`). The form still asks the seller to pick Fuel and Transmission by hand afterwards — three questions where one answer carries the data.
4. **Colour is generic, not automotive.** Ten global `SELL_COLORS` swatches; names are hidden until selection; White is a near-invisible circle on a white surface. Meanwhile `VehicleVariant.colors[]` holds the real manufacturer colour names for that exact car and is never used.
5. **Identity is split across two steps.** Brand/model/variant/year live in step 2; the *title generated from them* lives in step 3 labelled "written for you", with no visible link back.
6. **Owner is an unlabelled trailing chip row** — no explanation that it means previous owners, and optional fields look identical to required ones.
7. **`cacheExtent: 4000`** forces the entire step to build off-screen so "Fix ›" can scroll to hidden errors. That is a workaround for a form that is too tall, and it costs build time on low-end Androids.

### 1.3 Field triage

| Keep prominent | Group | Progressive / advanced | Drop from consideration |
|---|---|---|---|
| Brand & model *(req)* | Variant + Fuel + Transmission → one "Trim & drivetrain" block, because the variant determines the other two | Variant "Not sure" path | Engine, seating, body type — **no column on `VehicleAd`** |
| Year *(req)* | Colour + Owners → "Colour & condition" | Insurance / RC / Features (already disclosed) | Base vs selling price — `Ad.price` is a single field |
| KM driven *(req)* | | Owners *(optional)* | Availability / status — `Ad.status` is moderation state, not seller-controlled |

### 1.4 Components that can be reused as-is (no new primitives needed)

`SellTokens`, `SellLabel`, `SellFieldNote`, `SellInput`, `SellPickerField`, `SellChips` / `SellChip`, `SellSegmented`, `SellStepper`, `SellColorSwatches`, `SellBanner`, `SellButton`, `SellSheetFrame`, `SellSectionCard`, `SellKeyValue`, `SellPreviewCard`, `showBrandModelSheet`, `showYearSheet`, `StepScrollKeys`, `IndianGroupingFormatter`.

### 1.5 Backend constraints the redesign must respect

- **Payload shape is fixed:** `{ category: 'private_vehicle', data: {…}, vehicle: {…} }` (`SellRules.buildPayload`).
- **`vehicle` required:** `vehicleType` (`four_wheeler`), `manufacturerId`, `modelId`, `year`, `mileage`, `fuelTypeId`, `transmissionTypeId`, `color`. **Optional:** `variantId`, `ownerCount`, `isFirstOwner`, `hasInsurance`, `hasRcBook`, `additionalFeatures`.
- `manufacturerId` / `modelId` / `variantId` / `fuelTypeId` / `transmissionTypeId` must be **24-hex ObjectIds that exist** — `VehicleInventoryGateway.findInvalidRefs()` re-checks each one and returns per-field 422s.
- **`color` is a free string, 1–40 chars, no enum** (`validateVehicle`, `VehicleAd.color`). Nothing filters or searches on it: no colour field in `ListAdsV2Dto`, no occurrence anywhere in `src/search`. Its only consumers are the response mappers (`ad.v2.mappers.ts:60,96`) and the **server-side fallback title** `buildTitleFromDto` → `"<model> <year> (<color>)"` (`ad.v2.mappers.ts:148–152`), used only when the client sends no title.
- Limits come from the server (`sellLimits`): year 1990…currentYear+1, mileage 0…999 999, price 1…1 000 000 000, title 10–70 (only validated when sent), description 20–4000, photos 1–20.
- `additionalFeatures` ≤ 30 items, each ≤ 60 chars.
- **Nothing on `VehicleAd` stores engine, seating, body type, a second price or a seller-set availability.** Those fields exist only on `CommercialVehicleAd`, or not at all.

### 1.6 Frontend / backend inconsistencies found (all pre-existing)

| # | Finding | Evidence | Impact |
|---|---|---|---|
| **V-1** | **Variant list is silently capped at 10.** `add_repo.fetchVariantsByModel` sends only `modelId`; `FilterVehicleVariantDto extends PaginationDto` whose **`limit` initialises to 10**, so the service's own `limit = 20` destructure default never applies. | `add_repo.dart:523`, `pagination.dto.ts:19`, `vehicle-inventory.service.ts:999` | A Swift with 20+ trims shows 10. Sellers can't find their variant. |
| **V-2** | **Inactive variants are listed but rejected on create.** The list `$match` deliberately dropped `isActive: true`, but `findVehicleVariantById` — which `findInvalidRefs` calls — requires `isActive: true`. | `vehicle-inventory.service.ts:1025,1037` vs `:784` | Seller picks a listed variant → `POST /v2/ads` returns 422 `vehicle.variantId: "Choose a valid variant"`. **Live bug.** |
| **V-3** | Variants sort by `createdAt DESC` by default — arbitrary order in the UI. | `vehicle-inventory.service.ts:1000` | Trims appear unordered. |
| **V-4** | Variant `colors[]` and `images[]` exist on the schema but are **projected away** by the list endpoint. | `vehicle-variant.schema.ts:113,116` vs `vehicle-inventory.service.ts:1165–1233` | Real colours unavailable from the list call (still available from `GET /variants/:id`). |
| **V-5** | App's `VehicleVariant` model keeps only `id` + `name`, discarding the populated `fuelType`, `transmissionType`, `price`, `seatingCapacity`, `engineSpecs` the endpoint already returns. | `vehicle_variant_model.dart` | Forces the seller to re-enter fuel and transmission. |
| **V-6** | Colour is posted as a lowercase slug (`'white'`) while the DTO example and all display surfaces expect a label (`'White'`). | `sell_rules.dart:261`, `create-ad-v2.dto.ts:211` | Cosmetic; existing data is already mixed. |
| **V-7** | The app has **no edit-ad flow**, though `GET /v2/ads/:id/edit` and `PATCH /v2/ads/:id` are shipped and return exactly the create-body shape. | `get-ad-for-edit.uc.ts`, `update-ad-v2.dto.ts`; no `/edit` call in `add_repo.dart` | Edit reuse is greenfield — design for it now, build later. |

**V-1, V-2 and V-3 are fixable entirely from the client** by passing `limit`, `isActive=true` and `sortBy=price&sortOrder=ASC` — the filter DTO already supports all three.

---

## Phase 2 — Proposed wireframe

### 2.1 Structural decision

Keep the 4-step flow. It was rebuilt this month, the server validator is keyed to it (`SellRules.stepForKey`, the "Fix ›" jumps, draft resume), and splitting Car out would fork the flow for one of four categories. **The redesign is confined to step 2's car branch** — plus one behavioural change in the variant picker.

The organising idea: **the car identifies itself once, then the form collapses.** Automotive configurators do not ask twelve peer questions; they narrow — make → model → trim → everything the trim knows → the few things only the seller knows.

### 2.2 Wireframe — after

```text
 ← Back                                        ✓ Saved
 Step 2 of 4 · About the car                        Car
 ████████████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
────────────────────────────────────────────────────

  THE CAR                                          ← 12px caps, muted

  Brand & model
  ┌──────────────────────────────────────────────┐
  │ Maruti Suzuki · Swift                Change ›│
  └──────────────────────────────────────────────┘

  Year                      KM driven
  ┌────────────────┐        ┌────────────────────┐
  │ 2019         ▾ │        │ 42,500             │
  └────────────────┘        └────────────────────┘

        ⋮  once all three are valid, the block above
        ⋮  collapses to a single summary row:
  ┌──────────────────────────────────────────────┐
  │ 2019 Maruti Suzuki Swift · 42,500 km  Edit › │
  └──────────────────────────────────────────────┘

────────────────────────────────────────────────────
  TRIM & DRIVETRAIN              ← appears after model is set

  Variant                                  optional
  ┌──────────────────────────────────────────────┐
  │ VXi · Petrol · Manual · 1197 cc      Change ›│   ← opens a SHEET
  └──────────────────────────────────────────────┘

  Fuel                                    from VXi ✓
  ( Petrol* ) ( Diesel ) ( CNG ) ( Electric )

  Transmission                            from VXi ✓
  [   Manual*   |   Automatic   ]

────────────────────────────────────────────────────
  COLOUR & CONDITION

  Colour                                    18 / 40
  ┌──────────────────────────────────────────────┐
  │ ●  Pearl Arctic White                      ✕ │  ← free text + live swatch
  └──────────────────────────────────────────────┘
  ( ● Fire Red ) ( ● Magma Grey ) ( ● Lucent Or…   ← quick picks, scrolls

       while typing "pear":
       ┌────────────────────────────────────────┐
       │ ● Pearl Arctic White              VXi  │
       │ ● Pearl Midnight Black            VXi  │
       │ ──────────────────────────────────────  │
       │ ◌ Use "pear" as typed                   │
       └────────────────────────────────────────┘

  Previous owners                          optional
  ( 1st* ) ( 2nd ) ( 3rd ) ( 4 or more )

────────────────────────────────────────────────────

  ＋ Papers & features                    ← existing disclosure
        Insurance valid       [ Yes | No ]
        RC book available     [ Yes | No ]
        Features   ⊕ Sunroof ⊕ ABS ⊕ Alloy wheels …

────────────────────────────────────────────────────
 [ Back ]                                  [ Next ]
```

### 2.3 Variant sheet (replaces the inline chip wall)

```text
 ┌────────────────────────────────────────────┐
 │  Which variant?                         ✕  │
 │  Maruti Suzuki Swift                       │
 │  ┌──────────────────────────────────────┐  │
 │  │ 🔍 Search VXi, ZXi…                  │  │
 │  └──────────────────────────────────────┘  │
 │                                            │
 │  PETROL                                    │
 │   LXi        Manual · 1197 cc · 5 seats    │
 │   VXi        Manual · 1197 cc · 5 seats  ✓ │
 │   VXi AMT    Automatic · 1197 cc           │
 │   ZXi        Manual · 1197 cc              │
 │                                            │
 │  ┌──────────────────────────────────────┐  │
 │  │  I'm not sure                        │  │
 │  └──────────────────────────────────────┘  │
 └────────────────────────────────────────────┘
```

### 2.4 What changed, and why

| # | Change | Why |
|---|---|---|
| **C1** | Three labelled sections (`THE CAR` / `TRIM & DRIVETRAIN` / `COLOUR & CONDITION`) separated by hairlines — **labels and rules, not cards** | Gives hierarchy without adding borders, badges or nested cards. Meets "sections where they genuinely improve usability". |
| **C2** | `THE CAR` **collapses to one summary row** when brand, model, year and km are all valid | The real progressive-disclosure win: after ~20 s the top of the form is one line instead of three fields. Standard configurator accordion behaviour. Tapping `Edit ›` re-expands. |
| **C3** | `TRIM & DRIVETRAIN` is **hidden until a model is chosen** | Today Year/KM/Fuel/Transmission are all visible before the car is even identified. Nothing should be answerable out of order. |
| **C4** | Variant moves from inline chips to a **bottom sheet** with search, grouped by fuel, each row subtitled `transmission · cc · seats` | Removes the biggest block of screen noise and turns a wall of ambiguous trim codes into a scannable, searchable list using data the endpoint **already returns**. Mirrors the existing `showBrandModelSheet` pattern. |
| **C5** | Choosing a variant **auto-fills Fuel and Transmission**, marked `from VXi ✓`, still editable | Removes redundant entry (brief: "no redundant data entry"). The variant carries populated `fuelType` and `transmissionType` today. "I'm not sure" falls back to the plain choosers. |
| **C6** | Colour becomes an **editable text field with a live swatch**: type anything, and the swatch fills in the moment the text matches a colour the backend gave a hex for. Suggestions filter as you type — the variant's own `colors[]` (tagged `VXi`) above the canonical ten — with a `Use "…" as typed` row at the bottom. Quick-pick pills sit under the field. | `vehicle.color` **is** a free string (≤40 chars, no enum), so the UI should be too: the old 10-swatch grid was a made-up constraint the backend never imposed. Real cars have colours like *Nexa Aurora* and *Caffeine Brown Dual Tone* that no fixed palette covers. Typing is also faster than hunting a swatch, and the field is directly reusable in the edit flow, where the stored value may be any string. |
| **C7** | A name with no matching hex keeps a **dashed ring** instead of a colour, with the helper `Saved as typed`; light colours get a visible outline ring; a live `18 / 40` counter appears once typing starts | Never fabricate a hex for a name the backend never gave one for — the dashed ring says "we don't know this colour, and that's fine". White on white is currently invisible. The counter surfaces the server's 40-char ceiling before submit rejects it. |
| **C8** | `Owner` → **`Previous owners`** with an explicit `optional` tag; `4+` → `4 or more` | The current label is ambiguous and optional fields look required. |
| **C9** | Disclosure renamed `＋ Papers & features` (from "Add more details (insurance, RC, features)") | Shorter, scannable, same behaviour. |
| **C10** | Variant request gains `limit=100&isActive=true&sortBy=price&sortOrder=ASC` | Fixes **V-1, V-2, V-3** — client-only. |

**Explicitly not added**, because the backend has nowhere to put them: engine, seating capacity, body type, base/ex-showroom/on-road price, availability or stock status. Inventing them would mean new columns with no consumer.

---

## Phase 3 — Data mapping

`data.*` and `vehicle.*` are paths inside the `POST /v2/ads` body. All server validation from `validateCreateAdV2` + `findInvalidRefs`; all client validation from `SellRules`. **No row in this table is new.**

### 3.1 Vehicle block

| UI field (section) | Flutter state | API request field | Backend DTO → entity | Req? | Validation |
|---|---|---|---|---|---|
| Brand *(THE CAR)* | `SellKeys.brandId` / `brandName` (`String`) | `vehicle.manufacturerId` | `VehicleData.manufacturerId` → `VehicleAd.manufacturerId` (ObjectId, ref `Manufacturer`) | **Yes** | 24-hex ObjectId, must exist. Client: "Choose the brand and model" |
| Model *(THE CAR)* | `SellKeys.modelId` / `modelName` | `vehicle.modelId` | `VehicleData.modelId` → `VehicleAd.modelId` (ref `VehicleModel`) | **Yes** | as above |
| Year *(THE CAR)* | `SellKeys.year` (`int`) | `vehicle.year` | `VehicleData.year` → `VehicleAd.year` (`min: 1900`) | **Yes** | integer, `1990 … currentYear+1` |
| KM driven *(THE CAR)* | `SellKeys.mileage` (`int`) | `vehicle.mileage` | `VehicleData.mileage` → `VehicleAd.mileage` (`min: 0`) | **Yes** | number, `0 … 999 999`; 0 valid |
| Variant *(TRIM)* | `SellKeys.variantId` (`''` = not sure) / `variantName` | `vehicle.variantId` | `VehicleData.variantId` → `VehicleAd.variantId` (ref `VehicleVariant`) | No | omitted when blank (`normalizeCreateAdV2`); otherwise ObjectId, must exist **and be `isActive`** |
| Fuel *(TRIM)* | `SellKeys.fuelTypeId` | `vehicle.fuelTypeId` | `VehicleData.fuelTypeId` → `VehicleAd.fuelTypeId` (ref `FuelType`) | **Yes** | ObjectId from `/v2/sell/config.fuelTypes`, must exist |
| Transmission *(TRIM)* | `SellKeys.transmissionTypeId` | `vehicle.transmissionTypeId` | → `VehicleAd.transmissionTypeId` (ref `TransmissionType`) | **Yes for car** | optional only for `two_wheeler`; ObjectId, must exist |
| *(implicit)* | `SellCategory.car.vehicleType` | `vehicle.vehicleType` | `VehicleAd.vehicleType` enum | **Yes** | `'four_wheeler'`; defaulted server-side if absent |
| Colour *(COLOUR)* | `SellKeys.color` (`String`, free text) | `vehicle.color` | `VehicleData.color` → `VehicleAd.color` (free string) | **Yes** *(client + server)* | non-empty, ≤ 40 chars (the ≤ 40 check is **new on the client**, mirroring `validateVehicle`). **No enum** — any typed name posts fine |
| Previous owners *(COLOUR)* | `SellKeys.ownerCount` (`int?`) | `vehicle.ownerCount` (+ derived `isFirstOwner`) | `VehicleAd.ownerCount` (`min 1 max 10`), `isFirstOwner` | No | integer `1…10`; `isFirstOwner = ownerCount === 1`, set both client- and server-side |
| Insurance valid *(disclosure)* | `SellKeys.hasInsurance` (`bool?`) | `vehicle.hasInsurance` | `VehicleAd.hasInsurance` (default `false`) | No | boolean; key omitted when null |
| RC book *(disclosure)* | `SellKeys.hasRcBook` (`bool?`) | `vehicle.hasRcBook` | `VehicleAd.hasRcBook` | No | boolean |
| Features *(disclosure)* | `SellKeys.features` (`List<String>`) | `vehicle.additionalFeatures` | `VehicleAd.additionalFeatures` (`[String]`) | No | ≤ 30 items, each 1–60 chars; sourced from `config.features` |

### 3.2 Common block (steps 1 and 3 — unchanged, listed for completeness)

| UI field | Flutter state | API field | Backend | Req? | Validation |
|---|---|---|---|---|---|
| Photos | `SellMediaCubit.items` (non-video, `isDone`) | `data.mediaIds` | `Media` → `Ad.images` | **Yes** | 1…20 ObjectIds, unique, owned by caller |
| Video | same (`isVideo`) | `data.videoMediaId` | → `Ad.link` | No | ObjectId |
| Price | `SellKeys.price` (`int`) | `data.price` | `Ad.price` | **Yes** | `1 … 1 000 000 000` |
| Location | `location` / `latitude` / `longitude` | `data.location`, `data.latitude`, `data.longitude` | `Ad.location`, `geoLocation`, `city/district/state` | **Yes** (label **or** lat+lng) | lat −90…90, lng −180…180, both or neither |
| Title | `title` / `titleEdited` | `data.title` | `Ad.title` | No | 10–70 chars **when sent**; generated from year+brand+model+variant when untouched, and dropped from the payload if out of range |
| Description | `SellKeys.description` | `data.description` | `Ad.description` | **Yes** | 20–4000 chars |
| *(server-set)* | — | — | `Ad.status = pending`, `isApproved = false`, `soldOut = false` | — | moderation, not seller input |

### 3.3 Read paths used by the form

| Purpose | Endpoint | Notes |
|---|---|---|
| Limits, fuel, transmission, features, shot list, canonical colours | `GET /v2/sell/config?category=private_vehicle` | ETag + disk cache + offline fallback |
| Brands | `GET /vehicle-inventory/manufacturers?category=passenger_car&search=&page&limit=30` | |
| Models | `GET /vehicle-inventory/models?manufacturerId=…` | paged loop in `AddRepository` |
| Variants | `GET /vehicle-inventory/variants?modelId=…` | **add `limit=100&isActive=true&sortBy=price&sortOrder=ASC`** (V-1/2/3) |
| Variant colours | `GET /vehicle-inventory/variants/:id` | returns the full document incl. `colors[]`; filters `isActive && !isDeleted` |
| Edit prefill *(future)* | `GET /v2/ads/:id/edit` | already returns the create-body shape incl. `manufacturerName` / `modelName` / `variantName` |

---

## Phase 4 — Implementation plan

### 4.1 Backend: no changes required

Every part of the redesign is served by the shipped contract:

| Redesign need | Already supported by |
|---|---|
| Variant list with fuel + transmission + engine + seats | `GET /vehicle-inventory/variants` — `$project` already emits populated `fuelType`, `transmissionType`, `price`, `engineSpecs`, `performanceSpecs`, `seatingCapacity` |
| Full variant list, active only, ordered | `FilterVehicleVariantDto` already accepts `limit`, `isActive`, `sortBy`, `sortOrder` |
| Manufacturer colour names per car | `GET /vehicle-inventory/variants/:id` → `colors[]` (full document, active-only) |
| Posting a marketing colour name | `vehicle.color` is a free string ≤ 40 chars; no enum, no filter, no search term depends on it. Only side effect: the server's fallback title becomes `Swift 2019 (Pearl Arctic White)` — and the app always sends its own title, so that path is not reached in practice |
| Auto-filled fuel / transmission | Same ObjectIds the form already posts — the source of the value changes, the payload does not |
| Edit reuse | `GET /v2/ads/:id/edit` + `PATCH /v2/ads/:id` already return/accept the create-body shape |

**Optional, smallest-safe backend change (not required for Phase 5):** add `colors: 1` (and `images: 1`) to the `$project` and the `reorderedVariants` map in `findAllVehicleVariantsWithPagination` (`vehicle-inventory.service.ts:1165–1254`). Purely additive to a response whose DTO is `data: any[]`; removes the per-variant detail round trip. Backward compatible: no existing consumer reads those keys, and no client parses the response strictly. **Recommendation: ship Phase 5 without it**, using `GET /variants/:id`, then add it as a follow-up optimisation.

### 4.2 Components

**Create**

| File | What |
|---|---|
| `flow/ui/widgets/sell_section.dart` | `SellSection(label, children, collapsedSummary?)` — caps label, hairline, optional collapsed one-line summary with `Edit ›`. ~90 lines. |
| `flow/ui/widgets/variant_sheet.dart` | `showVariantSheet(context, model, variants)` → `VariantChoice?`. `SellSheetFrame` + search + fuel-grouped list + "I'm not sure". Mirrors `showBrandModelSheet`. |
| `flow/domain/sell_variant.dart` | `SellVariant` — `id, name, displayName, fuelTypeId, fuelLabel, transmissionTypeId, transmissionLabel, engineCc, seats, colors` + `fromJson`. Replaces the id/name-only `VehicleVariant` **inside the sell flow only**. |
| `flow/domain/sell_color_match.dart` | Maps a colour name → a hex from `config.colors` by normalised substring (`"Pearl Arctic White"` → `white`), longest match wins, diacritics and punctuation stripped. Returns `null` when no match, so the UI shows a dashed ring instead of inventing a colour. **No new colour constants.** |
| `flow/ui/widgets/sell_color_field.dart` | `SellColorField` — a `SellInput` with a 24 px swatch prefix, a clear button, a `n / 40` counter, an inline suggestion list (variant colours first, tagged, then `config.colors`, then `Use "<text>" as typed`), and a quick-pick pill row. Debounced 120 ms; suggestions close on blur and on selection. ~180 lines. |

**Modify**

| File | What |
|---|---|
| `steps/details_step.dart` | Rewrite `_vehicle()` as three `SellSection`s. Extract the car/bike branch into `_vehicleSections()`; leave commercial and property untouched. Drop `cacheExtent: 4000` once sections shrink the tree (keep `StepScrollKeys`; expand a collapsed section before scrolling to an error inside it). |
| `data/sell_repository.dart` | `variants(modelId)` → own Dio call with `limit: 100, isActive: true, sortBy: 'price', sortOrder: 'ASC'`, parsed into `SellVariant`. Add `variantDetail(id)` → `GET /vehicle-inventory/variants/:id` with an in-memory cache. |
| `widgets/sell_ui.dart` | `SellColorSwatches`: add `showNames` and an `outlined` flag for light colours. Additive params, default off — **commercial and bike keep today's swatch grid untouched**; only the car branch swaps to `SellColorField`. |
| `domain/sell_rules.dart` | `labelFor(SellKeys.ownerCount)` → `'Previous owners'`. **`buildPayload` unchanged.** |

### 4.3 State management

No change to the cubit's architecture — the flat `values` map already carries everything.

- Variant selection becomes one `setValues({...})` call that writes `variantId`, `variantName`, and — only when the slot is empty or was itself variant-derived — `fuelTypeId` and `transmissionTypeId`, plus two new **local-only** keys: `SellKeys.fuelFromVariant` / `transmissionFromVariant` (`bool`). These live in `values` (so drafts round-trip them) and are **never read by `buildPayload`**, exactly like the existing `titleEdited`.
- Section collapse state is local `setState` in `_DetailsStepState`, not cubit state — it is presentation, and it must not invalidate the draft.
- Manually changing Fuel or Transmission clears the corresponding `*FromVariant` flag, so the `from VXi ✓` tag disappears. Changing the **variant** overwrites them again.
- Changing brand/model already clears `variantId`; extend it to clear the two flags and the cached variant colours.

### 4.4 Validation

`SellRules.validateStep` keeps every existing key and message. One rule is **added**, mirroring a server rule the client never checked:

```dart
// in _vehicle(), after the existing empty check
final colour = '${v[SellKeys.color] ?? ''}'.trim();
if (colour.isEmpty) {
  e[SellKeys.color] = 'Choose a colour';          // unchanged
} else if (colour.length > 40) {
  e[SellKeys.color] = 'Keep the colour under 40 characters';
}
```

Today a 41-character colour passes the client and comes back as a 422 from `validateVehicle`. With a typed field that becomes reachable, so the check moves client-side too. The field also caps input at 40 via `maxLength`, so the error is a backstop rather than the primary guard.

Three presentation rules:

1. A collapsed section auto-expands when it holds an error (`StepScrollKeys.scrollToFirstError` runs after expansion).
2. `TRIM & DRIVETRAIN` is hidden until `modelId` is set; since `fuelTypeId` and `transmissionTypeId` are required, `next()` cannot pass with the section hidden — the `brandId` error fires first, which is the correct ordering.
3. The colour field validates on blur (`_flow.validateField(SellKeys.color)`), not per keystroke, so a half-typed name never shows an error.

### 4.5 Responsive behaviour

- Year + KM stay a two-up `Row` above 340 dp of content width; stack below it (currently they always share a row and can clip at 320 dp).
- Colour field: full width at every size; the quick-pick pill row scrolls horizontally rather than wrapping, so the field's height never changes. The suggestion list caps at 5 rows plus the `Use "…" as typed` row, and sits above the keyboard.
- Variant sheet: `SellSheetFrame`, capped at 70 % viewport height, keyboard-aware, single-column at every width.
- Text scale: sections and captions must survive `textScaleFactor: 1.5` without clipping — verify the collapsed summary row ellipsises rather than overflows.

### 4.6 Edit-car reuse

`GET /v2/ads/:id/edit` returns exactly the create body plus `manufacturerName` / `modelName` / `variantName`, so the whole redesigned step is reusable with a seeding function:

```
SellFlowCubit.fromEditPayload(json) → values{…}
  data.*      → title (titleEdited: true), description, price, location, lat, lng
  vehicle.*   → brandId/modelId/variantId/year/mileage/fuelTypeId/
                transmissionTypeId/color/ownerCount/hasInsurance/hasRcBook/features
  *Name       → brandName / modelName / variantName
```

Seeded values arrive with `fuelFromVariant = false`, so an edited ad shows the real stored fuel rather than claiming it came from the variant. All four sections start **collapsed** in edit mode (everything is already answered) — the edit screen then opens as a scannable summary, which is the behaviour an edit flow wants. No extra components.

### 4.7 Suggested sequencing for Phase 5

| Step | Work | Status |
|---|---|---|
| **CAR-1** | Repository fix: `limit/isActive/sortBy` on the variants call + `SellVariant` model | **Done** — fixes V-1/V-2/V-3 |
| **CAR-2** | `SellSection` + the three-section rewrite, collapse behaviour | **Done** |
| **CAR-3** | `showVariantSheet` + auto-fill of fuel/transmission + `FROM …` tags | **Done** |
| **CAR-4** | Colour: `SellColorField`, `variantColors()`, name→hex matching, the 40-char client rule | **Done** |
| **CAR-5** | `flutter analyze`, device pass of V-C1…V-C13, a11y at `textScale 1.5`, widget tests | **Open — Rahul** |
| **CAR-6** | Backend `colors`/`images` in the variants `$project` | **Done** |
| **CAR-7** | Same treatment for bike (and commercial) | **Open** |

### 4.8 Verification checklist for Phase 5

- `V-C1` Swift (or any model with >10 trims) lists **every active** variant, cheapest first.
- `V-C2` A variant chosen from the list is never rejected by `POST /v2/ads` with `variantId` 422.
- `V-C3` Choosing `VXi` fills Fuel = Petrol and Transmission = Manual, both tagged `from VXi`, both still changeable.
- `V-C4` Changing Fuel by hand drops the tag; changing the variant re-applies it.
- `V-C5` "I'm not sure" leaves `variantId` unset and the payload omits the key entirely.
- `V-C6` Typing a colour filters suggestions; picking one fills the field and the swatch; the swatch fills in on a typed match too (`pearl arctic white` lowercase still matches `white`).
- `V-C7` A name with no hex (`Nexa Aurora`) keeps a dashed ring, shows `Saved as typed`, and posts verbatim; 41 characters is blocked client-side with a message, not a 422.
- `V-C7b` With no variant chosen, the suggestions are exactly the ten from `config.colors`; with a variant, its `colors[]` come first, tagged.
- `V-C8` Completing brand/model/year/km collapses `THE CAR`; `Edit ›` re-expands with values intact.
- `V-C9` "Fix ›" from Review expands the owning section and scrolls to the field.
- `V-C10` Draft save → kill app → resume restores variant, auto-fill tags and collapse-appropriate state.
- `V-C11` Posted payload is byte-identical in shape to today's for the same answers (diff `buildPayload` output in a unit test).
- `V-C12` Bike, commercial and property steps are visually unchanged.
- `V-C13` `flutter analyze` clean; `textScaleFactor: 1.5` at 320 dp has no overflow.

---

## Open decisions for review

1. **Colour value posted.** Today: `'white'` (slug). Proposed: whatever the seller typed or picked, trimmed — `'Pearl Arctic White'`, `'White'`, `'Nexa Aurora'`. Safe (no filter, no search term, no enum reads `color`; the only other consumer is a fallback title the app never triggers), and much better for buyers. Capped at 40 chars client-side. The trade-off: colour stops being a closed set, so if you ever want a colour facet in `ListAdsV2Dto`, it will need the same name→canonical matching on the server. **Confirm before CAR-4.**
2. **Backend `colors` projection (CAR-6).** Ship with the per-variant detail call, or take the one-line additive `$project` change now?
3. **Collapse-on-complete (C2).** It is the biggest clutter win but also the biggest behavioural change. Confirm before CAR-2.
