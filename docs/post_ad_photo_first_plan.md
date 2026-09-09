# Post-Ad flow redesign — photo-first (plan v1, 2026-09-09)

## Current state (audited)
- `lib/features/sell/ui/item_category.dart` → full page category list → pushes `/add-{two-wheeler|private-vehicle|commercial-vehicle|property}-form`.
- Four forms in `lib/features/sell/ui/form/add_*_form.dart` (1.7k–2k lines each, copy-pasted). Each has `int _step = 0; // Details, Photos, Review`, own `_buildStepHeader/_buildStepNav/_buildImagePicker/_buildVideoPicker`.
- Images/video picked into memory (`_imageFiles`, `_videoFile`) and uploaded to S3 **only inside `_addAdvertisement()` on submit**, serially, via `AddRepository().uploadImageToS3/uploadVideoToS3`. Null URLs are silently dropped.
- Validation only runs on submit; failure does `setState(() => _step = 0)`.
- `AddPostBloc` only handles `postAd(category, data)` + commercial vehicle types.
- Edit forms in `lib/features/home/ui/edit_add_details/*_form_edit.dart` duplicate the pickers again (`widgets/image_picker_widget.dart`, `video_picker_widget.dart`).

## Target flow
0. Category bottom sheet (2×2) from Sell tab — tablet keeps a page. Shows "Resume draft" if one exists.
1. **Photos** — camera primary, gallery secondary, up to 10, cover = first, drag reorder, per-tile upload progress/✓/Retry, optional video. Uploads start immediately, concurrency 3, compress ~1600px q70. Continue needs ≥1 photo; uploads may still be running.
2. **Details** — category-specific facts only (manufacturer/model/variant/year/km/fuel/transmission/ownership… or property fields). Chips/toggles for short single-choice lists. Progress row shows "5/6 photos up".
3. **Price & location** — price, location (LocationPickerWidget as-is), optional title (auto-generated), description. Inline per-step validation.
4. **Review & Post** — grouped by step with Edit links. Post sends JSON only; images = urls in display order, link = video url. If any upload pending/failed → button says "Waiting for 1 photo…" with Retry/Remove sheet.
5. **Posted** screen — replaces the AlertDialog. "View my ad" / "Post another".

## Implementation order
1. `post_ad_shell.dart` — owns `_step`, header/progress, nav, draft save; takes `List<PostAdStep>`; each step has `validate()` + `toJson()`.
2. `MediaUploadCubit` (`features/sell/bloc/media_upload/`) — `List<MediaItem{localId, bytes, status queued|uploading|done|failed, progress, url}>` + video; add/remove/reorder/setCover/retry. Provided at shell level. `AddPostBloc` unchanged.
3. Extract per-category `*_details_section.dart` from each `add_*_form.dart` (private vehicle: lines ~322–757). Existing manufacturer/model/variant/fuel/transmission blocs untouched. Payload identical to today → no backend change.
4. Category bottom sheet + drafts (SharedPreferences/Hive keyed by category; autosave on back).
5. Edit forms reuse the shell with `initialData`; existing URLs seed cubit as `done`. Delete duplicate picker widgets.

## Open questions
- Max photo cap (10?) — none today.
- Backend moderation before publish? (affects "Under review" pill)
- Price-hint endpoint now or later?
- Video on step 1 (as drawn) vs separate optional step?

Wireframe artifact: "Ado-Dad Photo-First Post Flow" (claude.ai artifacts gallery). Copy also at `docs/post_ad_photo_first_wireframe.html` in the repo.

## Phase 1 — implemented (2026-09-09)
State management kept as-is: `flutter_bloc` + `freezed` (same shape as `AddPostBloc`).

New:
- `lib/features/sell/bloc/media_upload/media_upload_bloc.dart` (+ `_event.dart`, `_state.dart`) — `MediaUploadBloc`: images/video upload to S3 the moment they are picked (3 concurrent), per-item `queued|uploading|done|failed`, cover = index 0, reorder/retry/remove, `seeded()` for the edit flow. Getters: `hasImages`, `allDone`, `hasFailed`, `pendingCount`, `imageUrls`, `videoUrl`.
- `lib/features/sell/ui/form/widgets/photo_step_widget.dart` — shared step-1 UI (camera/gallery sheet, 3-col grid with COVER badge + upload status, tile action sheet, video card, per-category copy/tips).

Changed (all four `lib/features/sell/ui/form/add_*_form.dart`, ~450 lines removed each):
- Steps are now **Photos → Details → Review**. Step 0 = `PhotoStepWidget`; Next is disabled on step 0 until ≥1 photo.
- Old `_pickImages/_uploadImages/_pickVideo/_uploadVideo/_buildImagePicker/_buildVideoPicker` and the in-memory byte lists are gone.
- `_addAdvertisement()` no longer uploads: it reads `media.imageUrls` / `media.videoUrl` from the bloc. If uploads are pending/failed it returns to step 0 with a snackbar instead of silently dropping null URLs. Validation failure now jumps to step 1 (Details), not step 0.
- `MediaUploadBloc` is created per form (`late final _mediaBloc`), provided with `BlocProvider.value`, closed in `dispose()`.

To build:
```
dart run build_runner build --delete-conflicting-outputs   # generates media_upload_bloc.freezed.dart
dart format lib/features/sell
flutter analyze
```

Not yet done (phase 2): category bottom sheet, Price & location as its own step, review Edit-links, "Posted" screen, drafts, edit-form migration to the shared widget.
