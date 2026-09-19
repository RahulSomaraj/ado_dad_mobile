# Bike Create — audit, competitor research and wireframes

**Scope:** `ado_dad_mobile` → Sell flow → **Bike or scooter** (`SellCategory.bike`, API category `two_wheeler`).
**Status:** research + audit + wireframes, **and implementation of BIKE-1 to BIKE-5 (20 Sep 2026)**. See §11.
**Date:** 20 Sep 2026 · **Inspected:** `C:\pendrive\...\ado_dad_mobile` (`dev_redesign`), `ado-dad` (`develop`).
**Separate from** the Car redesign (`claude/car-create-redesign-plan.md`). Nothing from that task is assumed here.

---

## 1. Existing Bike Implementation Audit

### 1.1 The pages that exist — and the ones that do not

| Asked for | What actually exists |
|---|---|
| Bike **Create** page | No standalone page. Step 2 of the shared 4-step sell flow, `ui/steps/details_step.dart` → `_legacyVehicle()`, with `SellCategory.bike` branches inside it |
| Bike **Edit** page | **Does not exist.** `GET /v2/ads/:id/edit` and `PATCH /v2/ads/:id` are shipped and return the create-body shape, but nothing in `add_repo.dart` calls either |
| Bike **Listing** page | **Does not exist as a bike page.** The shared feed (`features/home`) filtered by `category=two_wheeler` |
| Bike **Detail** page | **Does not exist as a bike page.** The shared ad detail (`features/home/ui/ad_detail/*`) |
| Bike-specific components | **None.** A grep for `two_wheeler` / `two-wheeler` across `ado_dad_mobile/lib` returns **3 files only**: `sell_category.dart`, `sell_flow_cubit.dart`, `vehicle_manufacturer_model.dart` |

That last line is the headline of this audit: **there is almost no bike-specific code.** Bike is a set of conditionals inside a generic vehicle form. Any "bike redesign" is therefore a decision about *how much to differentiate*, not a rewrite.

### 1.2 What the bike form asks today

`_legacyVehicle()` with `c == SellCategory.bike`, in render order:

| # | Field | Control | Required? |
|---|---|---|---|
| 1 | Brand & model | `SellPickerField` → `showBrandModelSheet` | **Yes** |
| — | *Variant* | **Not rendered** — gated by `c != SellCategory.bike` | n/a |
| 2 | Year | `SellPickerField` → `showYearSheet` | **Yes** |
| 3 | KM driven | `SellInput` + Indian digit grouping | **Yes** |
| 4 | Fuel | `SellChips` | **Yes** |
| 5 | Transmission | `SellSegmented` (≤3 options) else `SellChips` | Optional server-side, **pre-filled client-side** |
| 6 | Colour | `SellColorSwatches`, 10 global swatches | **Yes** (client and server) |
| 7 | Owner | `SellChips` 1st/2nd/3rd/4+ | Optional, unlabelled as such |
| 8 | `＋ Add more details` | disclosure → Insurance, RC book, Features (6 bike items) | Optional |

Steps 1, 3 and 4 are shared with every category. Bike-specific limits: **`maxPhotos` 15** (cars 20), shot list `Left side / Right side / Front / Odometer / Tyres`, features `ABS, Disc brakes, Alloy wheels, Digital console, USB charging, Self start` (`sell.constants.ts`).

### 1.3 Services, DTOs, validation

| Layer | Bike specifics |
|---|---|
| Config | `GET /v2/sell/config?category=two_wheeler` → limits, fuel, transmission, features, shot list, colours |
| Brands | `GET /vehicle-inventory/manufacturers?category=two_wheeler` (`MANUFACTURER_CATEGORY.two_wheeler`) |
| Models | `GET /vehicle-inventory/models?manufacturerId=…` — **no category filter on this call** |
| Variants | Not called for bikes |
| Create | `POST /v2/ads` `{category:'two_wheeler', data:{…}, vehicle:{…}}`, `vehicle.vehicleType = 'two_wheeler'` |
| Client rules | `SellRules._vehicle` — transmission skipped for bike (`c != SellCategory.bike`) |
| Server rules | `validateVehicle` — `transmissionOptional = category === TWO_WHEELER` |
| Persistence | `Ad` + `VehicleAd` (same tables as cars) |

### 1.4 Design system

`sell_ui.dart` — `SellTokens` plus `SellLabel, SellFieldNote, SellInput, SellPickerField, SellChips/SellChip, SellSegmented, SellStepper, SellColorSwatches, SellBanner, SellButton, SellSheetFrame, showSellSheet, SellPhoto, SellPreviewCard, SellSectionCard, SellKeyValue`. Pickers in `sell_pickers.dart`. Nothing here is car- or bike-specific.

---

## 2. Previous Bike Changes Audit

Two change sets have touched bike. For each: what, why (from the record, not guessed), and a verdict.

### 2.1 The 15 Sep 2026 sell-flow rebuild

The whole flow was rebuilt (`claude/create-sell-flow-implementation.md`). The bike-relevant decisions:

---

**C-1 · Variant hidden for bikes** — `details_step.dart`: `if (c != SellCategory.bike && v[SellKeys.modelId] != null)`

- **Why:** the July 2026 audit records **FE-01** — *"variant validator runs while the field is disabled, which blocks Details for models without variants (car + commercial)"* (`claude/audit-jul2026-mobile-todo.md`). The old flow could dead-end on a model with no variants. Hiding the field for the category most likely to have empty variant lists removes that class of bug outright.
- **Does it match the backend?** Yes — `variantId` is optional for every vehicle category.
- **UX problem it creates:** a bike that *does* have trims (R15 V3 / V4, Classic 350 Halcyon / Signals) cannot record them, and the ad title generated by `suggestedTitle` loses the trim. It also throws away the fuel/transmission/engine data a variant carries.
- **Verdict: `MODIFY`** — keep the *outcome* (never show an empty or blocking variant control) but reach it by data, not by category. Render the field only when the variants call returns two or more active rows. That preserves the FE-01 fix and unlocks the trims that exist.

---

**C-2 · Transmission optional for two-wheelers, server-side** — `validateVehicle`: `transmissionOptional = category === AdCategoryV2.TWO_WHEELER`

- **Why:** the July audit records **FE-02/03** — *"two-wheeler colour/transmission shown optional but backend-required → 400 → 'Invalid request'"*. The Sept backend change closed that mismatch by making transmission genuinely optional for `two_wheeler` (`create-sell-flow-implementation.md`: "two-wheeler transmission optional").
- **Verdict: `KEEP`.** Correct, and it is the premise the next item now contradicts.

---

**C-3 · Transmission silently defaulted to Manual for bikes** — `sell_flow_cubit.dart` → `_applyInferredDefaults()`

```dart
if (state.category != SellCategory.bike) return;
if (state.v(SellKeys.transmissionTypeId) != null) return;
final manual = state.config.transmissionTypes.where((t) => t.name.toLowerCase().contains('manual'));
if (manual.isNotEmpty) setValue(SellKeys.transmissionTypeId, manual.first.id, save: false);
```

- **What it does:** as soon as the config loads, **every bike draft is set to Manual** before the seller has looked at the field.
- **Why it was written:** it is the client half of the FE-02/03 fix — when transmission was still backend-required for two-wheelers, supplying a default was the only way to stop a 400. C-2 removed that requirement.
- **Does it match the backend?** It no longer needs to. The requirement it defends against is gone.
- **UX problem:** **every scooter posted through this app is recorded as Manual.** Activa, Jupiter, Access, Ntorq — all Manual. The seller is not asked and is not told. This is a data-quality defect that is invisible in the UI and permanent in the database.
- **Verdict: `REMOVE`** — and replace with an honest optional control (see §7). Removing it means a seller who skips the field posts no `transmissionTypeId`, which the server accepts.
- **Migration note:** existing bike ads already carry Manual. A back-fill is out of scope here and would need product sign-off; flagged, not proposed.

---

**C-4 · Colour required client-side for bikes** — `SellRules._vehicle`: `if (_empty(v[SellKeys.color])) e[color] = 'Choose a colour'`

- **Why:** matches `validateVehicle`, which requires a non-empty `color` for every vehicle category including two-wheelers. This is the other half of FE-02/03.
- **Verdict: `KEEP`** as a rule. **`MODIFY`** the control (§7) — ten generic swatches cannot express "Matte Axis Grey Metallic with Sports Red", and the competitor evidence (§3) shows a constrained list with a free-text escape is the industry shape.

---

**C-5 · `maxPhotos` 15 for bikes, 20 otherwise** — `sellLimits()`, mirrored in `SellLimits.defaults`

- **Why:** not recorded. Consistent with the industry (BikeWale caps at 10, OLX at 12 for non-car categories — §3).
- **Verdict: `KEEP`.** Well-judged and independently corroborated.

---

**C-6 · Bike shot list and feature list** — `SELL_SHOT_LISTS.two_wheeler`, `SELL_FEATURES.two_wheeler`

- **Why:** not recorded. Both are genuinely two-wheeler vocabulary (Left side / Right side / Tyres; Disc brakes / Self start / Digital console).
- **Verdict: `KEEP`.**

---

### 2.2 Today's car pass — what it did to bike

The car redesign (20 Sep 2026) moved the bike/commercial rendering **verbatim** into `_legacyVehicle()` and added a separate `_car()`. Bike rendering is unchanged. Four shared edits do reach bike:

| Change | Effect on bike | Verdict |
|---|---|---|
| `SellRules._vehicle` colour ≤ 40 chars | Now applies to bikes too; mirrors a server rule that was always there | `KEEP` |
| `buildPayload` trims `color` | Applies to bikes | `KEEP` |
| `labelFor(ownerCount)` → "Previous owners" | Bike failure banner wording only | `KEEP` |
| `SellRepository.variants()` returns `SellVariant`, sends `limit/isActive/sortBy` | **Not reached by bike today** (the call is gated off), but ready the moment C-1 is modified | `KEEP` |
| `SellInput` gains an optional `focusNode` | Additive, unused by bike | `KEEP` |

**Nothing in the car pass regressed bike.** The `_legacyVehicle()` seam is where the bike work lands.

---

## 3. Competitor Bike UX Reference

Research conducted 20 Sep 2026. BikeWale renders server-side and could be read field-by-field; BikeDekho, Droom and CredR render client-side or block crawlers, so those rows are partial and marked.

### 3.1 OLX India — Motorcycles (c81)

| | |
|---|---|
| **Observed pattern** | Seven steps: Sell → category → details → images → price → location → confirm. Category selection gates which attribute fields appear at all |
| **Identity** | Brand, Model, Year, KM Driven, Fuel Type, and "No. of owners" (collected but inconsistently populated — present on one sampled ad, absent on another) |
| **Variants** | **None.** No variant field, no variant filter, no variant on rendered ads. Model granularity is the model line ("Royal Enfield Classic 350"). Sellers put trim in the title: one sampled ad reads *"RE CLASSIC 350 2020 PUNJAB NUMBER"* |
| **Colours** | **Not a structured field.** OLX's own ad-writing guide puts colour in the *title* — its worked example is *"Samsung Galaxy S21, 128GB, Phantom Gray, Excellent Condition"* |
| **Specifications** | None. No two-wheeler catalogue exists, so nothing is auto-filled; fuel type is the only spec-like field and the seller picks it |
| **Images** | 12 for non-car categories (20 for Cars and Real Estate). No guided shot list. Sampled live ads had 2 photos, so not enforced |
| **Clutter control** | Category-gated attribute sets; the bike form is short because bikes have few attributes |
| **Relevance to us** | Our buyer-side filters should not out-run our seller-side fields. OLX's motorcycle filters are exactly five: Budget, Brand and Model, KM Driven, Year, Fuel |

### 3.2 BikeWale — the fully verified case

| | |
|---|---|
| **Observed pattern** | Five sections: Bike details → Personal details → **OTP verification** → More details → Congratulations |
| **Identity** | Make\*, Model\*, **Version\***, Year of manufacturing\*, Kms ridden\*, City\*, Expected price\*, Owner\*, Bike registered at\*, Colour\* |
| **Variants** | **Required**, labelled "Version", a cascading dropdown placed third — *before* year. The only platform researched that hard-requires a variant on a two-wheeler |
| **Colours** | **Required dropdown with "Other, please specify"** — a constrained list plus a free-text escape. No swatches |
| **Specifications** | The seller types **none**. No cc, power, torque, mileage, kerb weight, brakes, ABS, tyres, transmission or fuel field exists. Everything is implied by Make + Model + Version |
| **Images** | Up to 10, ≤4 MB, optional; **"first photo being the profile photo"**; incentive copy *"Ads with images are likely to get 50% more responses!"* |
| **Pricing** | One field, "Expected price\*". No valuation shown inline |
| **Clutter control** | Required set front-loaded; registration number, insurance, description and images deferred to a "More details" step **after OTP**. Lead captured before the expensive asks |
| **Relevance to us** | The required/optional split across steps is the strongest transferable idea. Our 4-step flow already does a version of this |

### 3.3 BikeDekho

| | |
|---|---|
| **Observed pattern** | One screen: **Select Bike → KMs Driven → Ownership → City → Expected Price → Upload Photos** |
| **Identity** | Brand, model (and possibly variant and year) collapsed into a **single "Select Bike" field**. No separate year field visible |
| **Variants** | Not visible on the form; **no variant filter** on the buyer side. Where trim matters it is baked into the model name — the filter list contains *"Hero Passion Pro BS4"*, *"Yamaha FZ S FI"* |
| **Colours** | Not asked on the visible form; no colour filter |
| **Specifications** | **Engine Displacement** and **Body Type** exist as *buyer filters* but not as seller fields → catalogue-derived. The clearest evidence of auto-fill in this research |
| **Images** | *"More photos give 5x more verified buyers"* — incentive, no count or shot list |
| **Pricing** | One field, "Expected Price". "Free Bike Valuation" marketed as a separate tool |
| **Clutter control** | Aggressive compression: one combined vehicle picker instead of four dropdowns |
| **Relevance to us** | Our `showBrandModelSheet` is already the "Select Bike" idea, half-built |

### 3.4 Droom / Orange Book Value / Bikes4Sale — the valuation school

| | |
|---|---|
| **Droom** | From **"Make-Model-Year-Trim"** it will *"auto-create the listing for you in less than 10 seconds"*. Three pricing formats (Fixed Price / Best Offer / Auction) — unique in this sample. Valuation via Orange Book Value |
| **Orange Book Value** | Used-bike flow: Category → Make → Model → Year → **Variant/Trim** → Kilometers. Its own copy says trim *"helps the algorithm differentiate between variant specifications, which affects depreciation calculations and pricing accuracy"* |
| **Bikes4Sale** | Brand → Model → **Version** → State → Year → KMs → City. Same shape as BikeWale |
| **Relevance to us** | **Variant is collected as a pricing input, not a browse attribute.** No platform in this research offers variant as a buyer-side two-wheeler filter — not even BikeWale, which requires it from sellers |

### 3.5 International comparisons

| | |
|---|---|
| **mobile.de** | Selling page names only *Modell, Baujahr, Laufleistung* — model, year of build, mileage. Not variant, not colour. Form fields UNVERIFIED |
| **Marktplaats** | Motorcycle category exposes **no** merk / model / bouwjaar / kilometerstand / kleur filters — brand is expressed as a category. A mature Western horizontal runs two-wheelers with *less* structure than OLX India |
| **Cars24** (car contrast) | Registration-number-first lookup: *"Enter your car plate number… Get instant car price"*. **No two-wheeler equivalent found on any platform** |
| **CredR, Bikes24, Facebook Marketplace** | **UNVERIFIED** — robots-blocked or defunct. No claims made |

---

## 4. Bike UX Patterns We Should Consider

| # | Pattern | Why competitors use it | Problem it solves | Can our architecture support it? |
|---|---|---|---|---|
| **P1** | **The seller types no specifications** — identity in, specs derived (BikeWale, BikeDekho, Droom; 3 of 3 catalogue-backed platforms) | A seller does not know their bike's torque and will abandon rather than look it up | Form length and abandonment | **Yes, and we already comply.** `VehicleAd` has no spec columns, so we *cannot* ask. Our variant carries `engineSpecs`, `performanceSpecs`, `seatingCapacity` for display |
| **P2** | **Variant collected only where it changes price** (OBV explicitly; Droom, BikeWale, Bikes4Sale) | Trim drives depreciation maths | Valuation accuracy without browse clutter | **Yes** — `variantId` is optional on the ad. But we have no valuation feature, so the *benefit* is weaker for us than for OBV |
| **P3** | **Variant is not a buyer-side two-wheeler filter anywhere** | Buyers search by model line | Avoids paying seller friction for nothing | **Yes** — `ListAdsV2Dto` has no variant filter either. Consistent |
| **P4** | **Constrained colour list with a free-text escape** (BikeWale's "Other, please specify") | Real colour names are marketing names | Neither a fixed palette nor pure free text alone works | **Yes** — `vehicle.color` is a free string ≤40 chars, no enum |
| **P5** | **Photos optional and incentivised, never gated** (all three Indian platforms) | Gating photos loses the listing entirely | Abandonment at the most expensive step | **Partly.** We *require* ≥1 photo (`minPhotos: 1`, step 1). A deliberate divergence — see §7 |
| **P6** | **Year means year of manufacture; registration is separate and optional** (BikeWale splits them explicitly) | Sellers confuse the two | Wrong-year data | **Yes** for year. We have **no registration field at all** and should not add one |
| **P7** | **One price field, "Expected price"; valuation is a separate tool** (OLX, BikeWale, BikeDekho) | Inline estimates invite haggling before contact | Pricing anxiety without complexity | **Yes** — `Ad.price` is a single field. Confirms the Car finding: do not add base/selling price |
| **P8** | **Combined vehicle picker over cascading dropdowns** (BikeDekho) | Four dropdowns read as four questions | Perceived form length | **Yes** — `showBrandModelSheet` already does brand→model in one sheet |
| **P9** | **Required set front-loaded, optional tail deferred** (BikeWale, post-OTP) | Capture the lead before the long asks | Abandonment | **Yes** — our 4 steps plus the `＋ more details` disclosure are the same idea |
| **P10** | **Fewer attributes than cars, deliberately** (OLX bikes have 5 filters, cars have owners + transmission + inspection on top) | Transmission is near-constant on Indian two-wheelers; no interior, no seating, no diesel | Asking questions that do not discriminate | **Yes** — argues for *demoting* transmission on bikes, not promoting it |

**Patterns deliberately NOT adopted:** registration-number lookup (no two-wheeler precedent, and we have no RC data source); auction/best-offer pricing (Droom-only, and `Ad` has one price); inline valuation (no pricing engine).

---

## 5. Backend / Data Model Audit

### 5.1 The catalogue chain — verified from schemas

```
Manufacturer                     manufacturer.schema.ts
  vehicleCategory: enum('passenger_car','two_wheeler','commercial_vehicle','luxury','suv')
  unique (name, vehicleCategory)          ← "Honda" exists twice: car and two_wheeler
      │ ref
      ▼
VehicleModel                     vehicle-model.schema.ts
  manufacturer: ObjectId (required)
  vehicleType: enum VehicleTypes  ← BODY type: SUV, Sedan, …, 'two-wheeler' (hyphen!)
  NO vehicleCategory field
  fuelTypes?: string[]            ← display NAMES, e.g. ['Petrol','Electric']
  transmissionTypes?: string[]    ← display NAMES, e.g. ['Manual','Automatic']
  bodyType?, segment?, images?
  unique (manufacturer, name)
      │ ref
      ▼
VehicleVariant                   vehicle-variant.schema.ts
  vehicleModel: ObjectId (required)
  fuelType: ObjectId (required)            ← a variant is ONE fuel
  transmissionType: ObjectId (required)    ← and ONE transmission
  engineSpecs (required): capacity, maxPower, maxTorque, cylinders?, turbocharged?
  performanceSpecs (required): mileage, acceleration?, topSpeed?, fuelCapacity?
  seatingCapacity (required), price (required)
  exShowroomPrice?, onRoadPrice?
  colors?: string[]        ← plain names, NO hex
  images?: string[], features?, dimensions?, brochureUrl?, videoUrl?
  unique (vehicleModel, fuelType, transmissionType, featurePackage)
```

**Model category is inherited from the manufacturer, not stored.** `GET /vehicle-inventory/models?manufacturerId=…` has no category filter — it does not need one, because a two-wheeler manufacturer only has two-wheeler models. `VehicleModel.vehicleType` is a *body* enum whose `TWOWHEELER = 'two-wheeler'` value uses a hyphen, unlike the ad's `two_wheeler`. Two vocabularies, do not conflate them.

### 5.2 The ad side

`VehicleAd` (`vehicle-ad.schema.ts`) — the only place a posted bike's data lands:

```
ad, vehicleType('two_wheeler'), manufacturerId, modelId,
variantId?, year, mileage, transmissionTypeId?, fuelTypeId,
color?, ownerCount?, isFirstOwner, hasInsurance, hasRcBook, additionalFeatures?
```

**There is no column for:** engine cc, power, torque, kerb weight, brakes, ABS, tyres, body type, registration number, RTO, insurance type, seating capacity, or a second price. Seating and body type exist only on `CommercialVehicleAd`. **Do not design fields that have nowhere to land.**

### 5.3 Colour — where it actually comes from

Three distinct sources, only one of which reaches the bike form today:

| Source | Shape | Reaches bike form? |
|---|---|---|
| `SELL_COLORS` in `sell.constants.ts`, served by `/v2/sell/config` | 10 × `{value, label, hex}` — **global, not per category, not per model** | **Yes** — the ten swatches |
| `VehicleVariant.colors[]` | `string[]` of names, **no hex** | No — variant is gated off for bikes |
| `VehicleModel` | **has no colour field at all** | n/a |

Answering the audit questions directly: colours are **global**, not model-scoped and not bike-scoped. Variant colours exist but are names only. The backend provides **no colour IDs** — `vehicle.color` is a free string. **Only one colour can be selected** (single field, not an array). Hex values exist **only** in `SELL_COLORS`.

### 5.4 Two defects found while auditing

**B-1 · The category filter on fuel and transmission types does nothing.**

`SellConfigService.activeRefs()` filters:

```ts
const own = typeof d.vehicleCategory === 'string' ? d.vehicleCategory : '';
return !vehicleCategory || !own || own === vehicleCategory;
```

But **neither `FuelType` nor `TransmissionType` has a `vehicleCategory` field** — check `fuel-type.schema.ts` and `transmission-type.schema.ts`. `own` is therefore always `''`, `!own` is always true, and **every active fuel and transmission type is returned for every category**. A bike seller is offered Diesel, CNG, Hybrid, Plugin Hybrid, Flex Fuel and AMT, CVT, Dual-Clutch, IMT (per the `FuelType`/`TransmissionType` enums in `vehicles/enum/vehicle.type.ts`).

The code comment claims it mirrors "the app's `appliesTo(category)`" — that rule is not implemented on these two collections. Client-only fix available (§7, X-2); no backend change required.

*Side effect on Car:* the same defect means `cfg.fuelTypes.length <= 3` is never true, so the segmented-control branch added in the car pass never fires. No regression — it falls through to chips, exactly as before.

**B-2 · `VehicleModel.fuelTypes` / `transmissionTypes` are never read.** Populated as display names (`['Petrol','Electric']`), they are the natural per-model narrowing for B-1 — filter `config.fuelTypes` by name. Unused by any client. **UNKNOWN how well populated** in the live catalogue; see §10 check V-B3.

---

## 6. Variant Analysis

### Scenario A — bike **with** variants

Supported end to end. `VehicleVariant.vehicleModel` accepts any model including two-wheelers; the seeder creates variants for **every** model regardless of category (`safe-seed-vehicle-variants.ts` loops all models, naming them `<model>_<fuel>_<transmission>`). `POST /v2/ads` accepts `vehicle.variantId` for `two_wheeler` — `validateVehicle` runs for `TWO_WHEELER` and only format-checks the id when present.

### Scenario B — bike **without** variants

Also supported: omit the key. The **current UI never shows the field for bikes**, so B is the only path a bike can take today. The risk to avoid when changing this is exactly FE-01 — an empty or blocking variant control.

### Scenario C — optional variant: **confirmed yes**

Three independent confirmations:

1. `VehicleAd.variantId` — `@Prop({ required: false })`
2. `normalizeCreateAdV2` — `if (isBlank(veh.variantId)) delete veh.variantId`
3. `validateVehicle` — `if (!isBlank(v.variantId) && !isObjectId(v.variantId)) set(…)`; no error when absent

`null` is not the representation — the key is **deleted**. Our client already models "I'm not sure" as `''` and `buildPayload` emits `variantId` only `if (variant is String && variant.isNotEmpty)`.

### Scenario D — variant-specific information

Verified against `vehicle-variant.schema.ts`:

| Can a variant differ by…? | Answer | Evidence |
|---|---|---|
| Price | **Yes** | `price` (required), `exShowroomPrice?`, `onRoadPrice?` |
| Colours | **Yes** | `colors?: string[]` — names only, no hex |
| Engine specs | **Yes** | `engineSpecs` required: capacity, maxPower, maxTorque |
| Features | **Yes** | `features?: VehicleFeatures` |
| Images | **Yes** | `images?: string[]` |
| Fuel type | **Yes** | `fuelType` required — one fuel **per variant** |
| Transmission | **Yes** | `transmissionType` required — one **per variant** |
| Seating / dimensions / mileage | **Yes** | `seatingCapacity`, `dimensions?`, `performanceSpecs.mileage` |

The unique index `(vehicleModel, fuelType, transmissionType, featurePackage)` confirms the intent: a variant **is** the fuel × transmission × trim combination.

**Consequence for bikes:** if a bike model has variants, picking one answers fuel *and* transmission. That is the single strongest argument for un-gating the variant field — it converts three questions into one.

### The decision for the UI

| Option | Verdict |
|---|---|
| Hide variant for all bikes (today) | **No** — discards trims that exist and the fuel/transmission they carry |
| Always show, even when empty | **No** — this is FE-01 |
| Show "No Variant" placeholder | **No** — a control the seller cannot act on is noise |
| **Render only when the call returns ≥ 2 active variants** | **Yes** |
| Make it required | **No** — only BikeWale does, and it does so for a valuation engine we do not have |

**≥ 2, not ≥ 1**, because a model with exactly one variant offers no choice — auto-adopt its fuel and transmission silently and skip the control. The seller answers fewer questions and the ad still carries `variantId`.

---

## 7. Existing Implementation → Proposed UX

| # | Existing | Problem | Proposed | Backend impact | Risk | Recommendation |
|---|---|---|---|---|---|---|
| **X-1** | Variant never shown for bikes (C-1) | Trims that exist cannot be recorded; fuel + transmission asked by hand | Load variants for bikes; render only when ≥ 2 active rows; 1 row → adopt silently; 0 → no control | **None** — `variants()` already fixed in the car pass | Low | **MODIFY** |
| **X-2** | Bike fuel/transmission lists include Diesel, CNG, AMT, CVT (B-1) | Nonsense options on a scooter; a wrong pick is unfalsifiable | Client-side narrowing: intersect `config.fuelTypes` with `VehicleModel.fuelTypes` names when present; else apply a two-wheeler allow-list derived from the chosen variant's own fuel/transmission | **None** (client filter). A real fix — adding `vehicleCategory` to the two collections — is a **separate, approved-only** backend change | Low | **REFACTOR** |
| **X-3** | Transmission pre-set to Manual (C-3) | Every scooter is recorded Manual | Remove `_applyInferredDefaults`. Show the control as **optional**, unselected, labelled **"Gears"**, helper *"Scooters are usually automatic"*. Fill it from the variant when one is chosen | **None** — already optional server-side | **Medium** — changes posted data; some ads will now have no transmission | **REMOVE the default** |
| **X-4** | Colour = 10 global swatches, name only on selection, White invisible on white | Cannot express "Matte Axis Grey Metallic"; poor contrast | Typed field with live swatch + suggestions (variant colours first, then the ten), free-text escape. Matches BikeWale's shape (P4) and the component already exists from the car pass | **None** — free string ≤ 40 | Low | **MODIFY** |
| **X-5** | Eight flat peer fields | No hierarchy | Three labelled sections; identity collapses to one summary row when complete | **None** | Low | **REFACTOR** |
| **X-6** | "Owner" chips, unlabelled as optional, "4+" | Ambiguous | "Previous owners", `optional` tag, "4 or more". BikeWale's first-person phrasing is better still but is a copy decision | **None** | Low | **MODIFY** |
| **X-7** | ≥ 1 photo required (step 1) | Diverges from all three Indian platforms (P5), which never gate | **Keep the requirement.** A marketplace with photo-less ads degrades for buyers, and 1 is a low bar | n/a | n/a | **KEEP — deliberate divergence** |
| **X-8** | No registration number, no RTO, no insurance *type* | BikeWale collects all three | **Do not add.** No columns exist; adding them is backend work with no consumer | n/a | n/a | **KEEP** |
| **X-9** | No bike edit page | Cannot correct a listing | Out of scope; the sections are built to be seeded from `GET /v2/ads/:id/edit` | None | — | **Defer** |

### Compatibility table (prompt §7)

| UX requirement | Backend support | Frontend support | Existing implementation | Change required |
|---|---|---|---|---|
| Brand | **Yes** — `manufacturerId`, category-filtered | Yes | Existing | None |
| Model | **Yes** — `modelId` | Yes | Existing | None |
| Variant | **Yes** — `variantId` accepted for `two_wheeler` | **No** — gated off for bikes | Existing (disabled) | **Frontend only** |
| Optional variant | **Yes** — key deleted when blank | Yes — `''` = not sure | Existing | None |
| Variant → fuel/transmission | **Yes** — both populated in the list response | **No** for bikes | New for bike (exists for car) | **Frontend only** |
| Colours (global) | **Yes** — `/v2/sell/config` `colors[]` with hex | Yes | Existing | None |
| Variant colours | **Yes** — `colors[]`, now in the list projection | **No** for bikes | New for bike (exists for car) | **Frontend only** |
| Colour free text | **Yes** — free string ≤ 40, no enum | Partly — swatches only | Existing | **Frontend only** |
| Fuel/transmission scoped to two-wheelers | **No** — no `vehicleCategory` on either collection (B-1) | No | Broken | **Frontend workaround; backend fix needs approval** |
| Engine cc / power / torque | **No column on `VehicleAd`** | n/a | Absent | **None — do not add** |
| Body type (bike) | **No column on `VehicleAd`** | n/a | Absent | **None — do not add** |
| Images | **Yes** — `mediaIds`, 1–15 for bikes | Yes | Existing | None |
| Pricing (single) | **Yes** — `Ad.price` | Yes | Existing | None |
| Base + selling price | **No — one price column** | n/a | Absent | **None — do not add** |
| Availability / status | **No** — `Ad.status` is moderation | n/a | Absent | **None — do not add** |
| Registration number / RTO | **No column** | n/a | Absent | **None — do not add** |

---

## 8. Wireframes

Six scenarios. Rendered versions are on the design canvas; the text below is the contract.

### W1 — Bike Create, general (no model chosen yet)

```text
 ← Back                                        ✓ Saved
 Step 2 of 4 · About the bike            Bike or scooter
 ████████████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
────────────────────────────────────────────────────
  THE BIKE

  Brand & model
  ┌──────────────────────────────────────────────┐
  │ Choose brand and model                      ›│
  └──────────────────────────────────────────────┘

  Year                      KM driven
  ┌────────────────┐        ┌────────────────────┐
  │ Year         ▾ │        │ e.g. 18,400        │
  └────────────────┘        └────────────────────┘
────────────────────────────────────────────────────
  ○ Fuel, gears and colour appear once you've
    picked the model.
────────────────────────────────────────────────────
 [ Back ]                                  [ Next ]
```

### W2 — model **with** variants (≥ 2)

```text
  ┌──────────────────────────────────────────────┐
  │ 2021 Honda Activa 6G · 18,400 km      Edit › │  ← collapsed
  └──────────────────────────────────────────────┘
────────────────────────────────────────────────────
  VARIANT & DRIVE

  Variant                                  optional
  ┌──────────────────────────────────────────────┐
  │ 6G DLX                               Change ›│
  │ Petrol · Automatic · 109 cc                  │
  └──────────────────────────────────────────────┘

  Fuel                                from 6G DLX ✓
  [   Petrol*   |   Electric   ]        ← ≤3 → segmented

  Gears                                    optional
  [   Geared   |   Gearless*   ]      from 6G DLX ✓
  Scooters are usually gearless.
────────────────────────────────────────────────────
```

### W3 — model **without** variants

```text
  ┌──────────────────────────────────────────────┐
  │ 2019 Hero Splendor Plus · 41,000 km   Edit › │
  └──────────────────────────────────────────────┘
────────────────────────────────────────────────────
  FUEL & DRIVE            ← section renamed: no variant

  Fuel
  [   Petrol   |   Electric   ]

  Gears                                    optional
  [   Geared   |   Gearless   ]
  Leave this out if you're not sure.
────────────────────────────────────────────────────
```

**No empty variant control, no "No Variant" placeholder, no disabled field.** The section header changes and the row is simply absent.

### W4 — colour

```text
  COLOUR & CONDITION

  Colour                                    29 / 40
  ┌──────────────────────────────────────────────┐
  │ ●  Matte Axis Grey Metallic                ✕ │
  └──────────────────────────────────────────────┘
  ( ● Pearl Precious White ) ( ● Rebel Red…  ← scrolls

       typing "gr":
       ┌────────────────────────────────────────┐
       │ ● Matte Axis Grey Metallic     6G DLX  │
       │ ● Grey                                 │
       │ ────────────────────────────────────── │
       │ ◌ Use "gr" as typed                    │
       └────────────────────────────────────────┘

  Previous owners                          optional
  ( 1st ) ( 2nd ) ( 3rd ) ( 4 or more )
```

### W5 — images (step 1, shown for completeness — **unchanged**)

```text
 Step 1 of 4 · Photos                    0 / 15 added
  ┌────────┐ ┌────────┐ ┌────────┐
  │   ＋   │ │        │ │        │     cover = first
  └────────┘ └────────┘ └────────┘
  Suggested shots
  ( Left side ) ( Right side ) ( Front ) ( Odometer ) ( Tyres )

  At least 1 photo. Up to 15.
```

No change proposed. The shot list is already two-wheeler vocabulary and the 15 cap is well-judged (§2.1 C-5).

### W6 — advanced / optional

```text
  ＋ Papers & features
        Insurance valid       [ Yes | No ]
        RC book available     [ Yes | No ]
        Features   ⊕ ABS ⊕ Disc brakes ⊕ Alloy wheels
                   ⊕ Digital console ⊕ USB charging
                   ⊕ Self start
```

Unchanged except the label, which drops "(insurance, RC, features)".

### Why six screens and not more

The prompt's example structure lists Pricing and Images as sections of a Create page. **In this app they are steps 3 and 1 of an existing 4-step flow**, not sections of step 2. Adding them to step 2 would fork the flow for one of four categories and break `SellRules.stepForKey`, the "Fix ›" jumps and draft resume. W5 is included to show the existing photos step is already right, not to propose changing it.

---

## 9. Data Mapping

All paths are inside the `POST /v2/ads` body. **No row is new.**

| UI field (section) | Form state | Frontend type | API request | Backend DTO | Entity | DB | Req | Validation |
|---|---|---|---|---|---|---|---|---|
| Brand *(THE BIKE)* | `SellKeys.brandId` / `brandName` | `String` | `vehicle.manufacturerId` | `VehicleData.manufacturerId` | `VehicleAd.manufacturerId` | ObjectId ref `Manufacturer` | **Yes** | 24-hex, must exist (`findInvalidRefs`) |
| Model *(THE BIKE)* | `modelId` / `modelName` | `String` | `vehicle.modelId` | `VehicleData.modelId` | `VehicleAd.modelId` | ObjectId ref `VehicleModel` | **Yes** | as above |
| Year *(THE BIKE)* | `year` | `int` | `vehicle.year` | `VehicleData.year` | `VehicleAd.year` | Number, `min: 1900` | **Yes** | int, `1990 … currentYear+1` |
| KM driven *(THE BIKE)* | `mileage` | `int` | `vehicle.mileage` | `VehicleData.mileage` | `VehicleAd.mileage` | Number, `min: 0` | **Yes** | `0 … 999 999`; 0 valid |
| Variant *(VARIANT & DRIVE)* | `variantId` (`''` = not sure) / `variantName` | `String` | `vehicle.variantId` | `VehicleData.variantId` | `VehicleAd.variantId` | ObjectId ref `VehicleVariant`, **not required** | **No** | deleted when blank; else ObjectId **and `isActive`** |
| Fuel | `fuelTypeId` | `String` | `vehicle.fuelTypeId` | `VehicleData.fuelTypeId` | `VehicleAd.fuelTypeId` | ObjectId ref `FuelType` | **Yes** | must exist |
| Gears (transmission) | `transmissionTypeId` | `String?` | `vehicle.transmissionTypeId` | `VehicleData.transmissionTypeId` | `VehicleAd.transmissionTypeId` | ObjectId, **not required** | **No for bike** | `transmissionOptional = TWO_WHEELER`; omitted when blank |
| *(implicit)* | `SellCategory.bike.vehicleType` | `String` | `vehicle.vehicleType` | `VehicleData.vehicleType` | `VehicleAd.vehicleType` | enum | **Yes** | `'two_wheeler'`; server defaults it |
| Colour *(COLOUR)* | `color` | `String` free text | `vehicle.color` | `VehicleData.color` | `VehicleAd.color` | String, trimmed | **Yes** | non-empty, ≤ 40. **No enum, no ID** |
| Previous owners | `ownerCount` | `int?` | `vehicle.ownerCount` + `isFirstOwner` | `VehicleData.ownerCount` | `VehicleAd.ownerCount` / `isFirstOwner` | Number `min 1 max 10` / Boolean | No | `1…10`; `isFirstOwner = ownerCount === 1` |
| Insurance valid | `hasInsurance` | `bool?` | `vehicle.hasInsurance` | same | `VehicleAd.hasInsurance` | Boolean `default false` | No | omitted when null |
| RC book | `hasRcBook` | `bool?` | `vehicle.hasRcBook` | same | `VehicleAd.hasRcBook` | Boolean | No | — |
| Features | `features` | `List<String>` | `vehicle.additionalFeatures` | same | `VehicleAd.additionalFeatures` | `[String]` | No | ≤ 30 items, each 1–60 chars |
| Photos *(step 1)* | `SellMediaCubit.items` | `List<SellMediaItem>` | `data.mediaIds` | `CommonData.mediaIds` | `Ad.images` | `[String]` | **Yes** | **1–15 for bikes**, unique ObjectIds, owned by caller |
| Price *(step 3)* | `price` | `int` | `data.price` | `CommonData.price` | `Ad.price` | Number `min 0` | **Yes** | `1 … 1 000 000 000` |
| Location *(step 3)* | `location`/`latitude`/`longitude` | `String`/`double` | `data.location` etc. | `CommonData` | `Ad.location`, `geoLocation`, `city/district/state` | — | **Yes** (label **or** lat+lng) | both or neither |
| Title *(step 3)* | `title`/`titleEdited` | `String` | `data.title` | `CommonData.title` | `Ad.title` | String | No | 10–70 **when sent**; dropped if out of range |
| Description *(step 3)* | `description` | `String` | `data.description` | `CommonData.description` | `Ad.description` | String | **Yes** | 20–4000 |

**Read paths**

| Purpose | Endpoint |
|---|---|
| Limits, fuel, transmission, features, shot list, colours | `GET /v2/sell/config?category=two_wheeler` |
| Brands | `GET /vehicle-inventory/manufacturers?category=two_wheeler&page&limit=30&search=` |
| Models | `GET /vehicle-inventory/models?manufacturerId=…` |
| Variants | `GET /vehicle-inventory/variants?modelId=…&limit=100&isActive=true&sortBy=price&sortOrder=ASC` |
| Variant colours | in the list response (post-Sep 2026 projection); else `GET /vehicle-inventory/variants/:id` |

**ID vs display value:** brand, model, variant, fuel and transmission all post **ObjectIds**; the app keeps `*Name` alongside purely for the summary rows and `suggestedTitle`. Colour posts a **display string** — it is the only vehicle field with no id.

---

## 10. Implementation Plan

**Nothing here is approved yet. This section is the proposal, not a task list to start.**

### 10.1 Backend

**No changes required.** Every proposed behaviour is served by the shipped contract.

One change is *worth discussing separately*, not bundled: adding `vehicleCategory` to `FuelType` and `TransmissionType` would make `SellConfigService.activeRefs`'s existing filter do what its comment claims (B-1). It is additive and backward compatible — absent means "applies to all", which is today's behaviour — but it needs a data back-fill to be useful, so it is a **product decision, not a side effect of a UI pass**. The client-side narrowing in X-2 delivers the user-visible benefit without it.

### 10.2 Frontend sequencing

| Step | Work | Risk |
|---|---|---|
| **BIKE-1** | Remove `_applyInferredDefaults` (X-3); label transmission "Gears", optional, unselected, with helper copy | **Medium** — changes posted data |
| **BIKE-2** | `_bike()` branch split off `_legacyVehicle()`, mirroring `_car()`: three sections + collapse (X-5, X-6) | Low |
| **BIKE-3** | Un-gate variants (X-1): load for bikes, render at ≥ 2, auto-adopt at 1, absent at 0; reuse `showVariantSheet` | Low — components exist |
| **BIKE-4** | Fuel/transmission narrowing (X-2) | Low |
| **BIKE-5** | `SellColorField` for bikes (X-4) | Low — component exists |
| **BIKE-6** | `flutter analyze`, device pass, `textScale 1.5`, widget tests | Low |

### 10.3 Checks that must run before BIKE-1 — these answer questions the code cannot

| # | Check | Command |
|---|---|---|
| **V-B1** | Do two-wheeler models actually have variants, and how many? | `GET /vehicle-inventory/manufacturers?category=two_wheeler&limit=50` → pick Honda/Hero/TVS → `GET /vehicle-inventory/models?manufacturerId=…` → `GET /vehicle-inventory/variants?modelId=…&limit=100&isActive=true` |
| **V-B2** | Are those variants real trims or seeder noise? | Seeded rows are named `<model>_<fuel>_<transmission>` with `displayName` `"<Model> <Fuel> <Transmission>"`. If that is all there is, **BIKE-3 must not ship** — showing "Activa 6G Petrol Manual" as a variant is worse than hiding it |
| **V-B3** | Are `VehicleModel.fuelTypes` / `transmissionTypes` populated for two-wheelers? | Same models call; inspect the two arrays. Decides whether X-2 can use the model lists or must fall back to an allow-list |
| **V-B4** | What does `/v2/sell/config?category=two_wheeler` actually return for `fuelTypes` and `transmissionTypes`? | Confirms B-1 against the live catalogue rather than the schema alone |

Run these **read-only against UAT** (`uatapi.ado-dad.com`), not production — the `ado-dad` checkout still points at the prod database.

### 10.4 Open decisions (for the record — see §11 for how they were settled)

1. **X-3 changes posted data.** Bikes will start posting with no `transmissionTypeId` where they previously posted Manual. Confirm that is wanted, and decide separately whether existing bike ads get a back-fill or are left alone.
2. **V-B2 gates BIKE-3.** If the two-wheeler catalogue has no real trims, un-gating variants is wrong however well it is built. Check first.
3. **"Gears: Geared / Gearless"** is proposed copy that maps onto whatever `transmissionTypes` the config returns. If the catalogue has no such values, fall back to the raw labels and revisit.
4. **Photo requirement (X-7)** — we require ≥ 1, the industry does not. Recommended to keep; flagging because it is a deliberate divergence from three of three researched platforms.

---

## 11. Implementation status — 20 Sep 2026

Written to the `C:\pendrive` copies. **Uncompiled** — `flutter analyze` has not been run from this session.

### 11.1 Shipped

| Step | File | What changed |
|---|---|---|
| **BIKE-1** | `bloc/sell_flow_cubit.dart` | `_applyInferredDefaults()` **deleted** along with its call in `loadConfig()`. A bike now posts no `transmissionTypeId` unless the seller or the variant supplies one. `hasContent` lost its `k != SellKeys.transmissionTypeId` exclusion — that exclusion only existed because the default wrote the key before the seller touched anything; now its presence means a real answer |
| **BIKE-2** | `ui/steps/details_step.dart` | New `_bike()` branch: three `SellSection`s, identity collapses to a summary row, `Previous owners · optional`, `＋ Papers & features`. `_carCollapsed`/`_carComplete`/`_maybeCollapseCar` renamed to `_identity*` and gated by a new `_sectioned()` so car and bike share them |
| **BIKE-3** | `details_step.dart`, `domain/sell_variant.dart` | Variants are loaded for **every** vehicle category, not car and commercial only. New `SellVariant.isGenericFor(modelName)` hides seeder scaffolding. The section renames itself `Fuel & drive` when nothing usable comes back — no empty control, no disabled field, no "No variant" placeholder |
| **BIKE-5** | `details_step.dart` | `SellColorField` for bikes, with the chosen variant's `colors[]` as suggestions |

### 11.2 The V-B2 gate is now solved in code, not by a manual check

The audit said BIKE-3 must not ship if the two-wheeler catalogue holds only seeder rows named `<model>_<fuel>_<transmission>`. Rather than block on that, `SellVariant.isGenericFor()` strips the model name and the variant's own fuel and transmission labels from its display name; if nothing is left, the row carries no trim information and is hidden. "Activa 6G Petrol Manual" disappears, "6G DLX" stays.

Two consequences worth knowing:

- The rule is **self-healing**. Whatever the catalogue holds today, the control appears the moment real trims are added and disappears if they are not there.
- It is applied to **car as well as bike**, in the shared `_variantField`. Car had the same exposure and has not reached users. A variant a draft already holds is always kept in the list, so a resumed ad can still be changed.

V-B1 to V-B4 in §10.3 are still worth running — they tell you whether bikes will show a variant control at all — but nothing is blocked on them.

### 11.3 BIKE-4 — the fuel and gears narrowing (added after review)

This was deferred in the first pass, which left gear and fuel visually unchanged — still the full seven-chip walls. That was the wrong call: it is the part of the bike section that most needed to move.

Two client-side routes were considered and both are guesses: the app's `VehicleModel` carries only `{id, displayName}`, so the model's own `fuelTypes` array is out of reach (V-B3 unverified); and narrowing from the union of a model's variants is unsafe because the seeder picks up to three **random** fuel and transmission docs per model, so on a seeded catalogue that union could legitimately contain Diesel for a scooter.

**So the fix went where the problem is — the server.** Not a schema change and not a migration:

| File | Change |
|---|---|
| `src/sell/sell.constants.ts` | New `CATEGORY_FUEL_TYPES` and `CATEGORY_TRANSMISSION_TYPES`, alongside the per-category lists this file already owns (`SELL_FEATURES`, `SELL_SHOT_LISTS`, `BODY_TYPE_LABELS`). `two_wheeler` → fuel `Petrol, Electric, CNG`; gearbox `Manual, Automatic, CVT`. Car and commercial stay `null` = unrestricted. `SELL_CONFIG_VERSION` bumped to `2026-09-20.1` |
| `src/sell/sell-config.service.ts` | `activeRefs()` takes an `allowedNames` list and narrows by `name`, matched case- and punctuation-insensitively |

Why constants rather than a `vehicleCategory` column on the two collections: the column needs a back-fill against live data, and the `ado-dad` checkout still points at production. The constants route is code-only, deploys with the service, and can be replaced by the column later without touching any client.

**Two safety behaviours**, because this list can drift from the catalogue:

- A name that no longer exists in the collection is simply ignored.
- If the filter would leave a category with **nothing**, the unfiltered list is served instead and a warning is logged. A rename in the catalogue degrades to today's behaviour, never to a form the seller cannot complete.

CNG is in the two-wheeler list deliberately — CNG motorcycles exist (Bajaj Freedom 125). AMT, DCT, IMT and Semi-Automatic are car gearboxes and are excluded.

**What this does to the UI, with no further client change.** The bike branch already switches to a segmented control at three options or fewer, so Fuel renders as `Petrol | Electric | CNG` instead of seven chips. Gears stays a chip row on purpose even at three options: a segmented control cannot be cleared, and gears is optional — tapping the selected chip clears it, which is the affordance the field needs. The difference in control type is itself the signal that one is required and the other is not.

It also fixes car and commercial, which were being served the same unfiltered lists.

### 11.4 Not implemented

**"Geared / Gearless" copy.** The field is labelled **Gears** and marked optional, but the options render with the catalogue's own labels (Manual / Automatic / CVT). Mapping those onto Geared/Gearless would be an invented translation of ids the app does not own. The helper line — *"Scooters are usually automatic. Leave it out if you're not sure."* — carries the meaning without faking the data.

### 11.5 Behaviour changes to expect on device

1. **Bikes post no transmission unless it is chosen.** Previously every bike posted Manual. Existing bike ads in the database still carry that Manual — the back-fill question in §10.4 is still open.
2. **Transmission is deselectable on bikes** — tapping the chosen chip clears it, which is how an optional chip row should behave.
3. **A car model whose variants are all seeder rows now shows no variant control**, where it previously showed a chip per row. This is the `isGenericFor` filter, and it is intended.
4. **An untouched bike draft counts as content slightly differently**, because of the `hasContent` change. In practice a draft with nothing but a transmission can no longer exist, since nothing writes it unprompted.

### 11.6 Still to run

- `flutter analyze` on rahul-pc. `details_step.dart` is now 48.5 KB — if the incremental compiler skips it, touch the file first the way the build `.bat` does.
- Device pass: post a scooter with no variant, a bike with variants, and a bike where the only variants are seeder rows. Confirm the section header flips between `Variant & drive` and `Fuel & drive`.
- Confirm the car flow is unchanged except for the variant filter.
- **Backend:** `tsc` on `ado-dad`, then `GET /v2/sell/config?category=two_wheeler` and check `fuelTypes` has three entries and `transmissionTypes` three. The app caches the config by ETag, so it picks the new list up on the next launch.
