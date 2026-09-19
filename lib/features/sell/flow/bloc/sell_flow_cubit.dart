import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/sell_draft_store.dart';
import '../data/sell_repository.dart';
import '../domain/sell_category.dart';
import '../domain/sell_config.dart';
import '../domain/sell_format.dart';
import '../domain/sell_models.dart';
import '../domain/sell_rules.dart';
import 'package:ado_dad_user/services/review_prompt_service.dart';

enum SubmissionStatus { idle, submitting, slow, failed, succeeded }

class SellFlowState {
  final SellCategory category;
  final SellConfig config;
  final SellStep step;
  final Map<String, dynamic> values;
  final Map<String, String> errors;

  /// Bumped every time Next/Post finds errors, so the page can scroll to the
  /// first one even when the error set is unchanged.
  final int attentionTick;
  final String draftId;
  final String idempotencyKey;
  final DateTime? savedAt;
  final DateTime? restoredFrom;
  final bool online;
  final bool returnToReview;
  final SubmissionStatus submission;
  final CreateAdFailure? failure;
  final CreatedAd? created;

  const SellFlowState({
    required this.category,
    required this.config,
    required this.step,
    required this.values,
    required this.errors,
    required this.draftId,
    required this.idempotencyKey,
    this.attentionTick = 0,
    this.savedAt,
    this.restoredFrom,
    this.online = true,
    this.returnToReview = false,
    this.submission = SubmissionStatus.idle,
    this.failure,
    this.created,
  });

  bool get isPosting =>
      submission == SubmissionStatus.submitting || submission == SubmissionStatus.slow;

  int get stepIndex => SellStep.values.indexOf(step);

  dynamic v(String key) => values[key];

  SellFlowState copyWith({
    SellConfig? config,
    SellStep? step,
    Map<String, dynamic>? values,
    Map<String, String>? errors,
    int? attentionTick,
    String? idempotencyKey,
    DateTime? savedAt,
    DateTime? restoredFrom,
    bool clearRestored = false,
    bool? online,
    bool? returnToReview,
    SubmissionStatus? submission,
    CreateAdFailure? failure,
    bool clearFailure = false,
    CreatedAd? created,
  }) =>
      SellFlowState(
        category: category,
        config: config ?? this.config,
        step: step ?? this.step,
        values: values ?? this.values,
        errors: errors ?? this.errors,
        attentionTick: attentionTick ?? this.attentionTick,
        draftId: draftId,
        idempotencyKey: idempotencyKey ?? this.idempotencyKey,
        savedAt: savedAt ?? this.savedAt,
        restoredFrom: clearRestored ? null : (restoredFrom ?? this.restoredFrom),
        online: online ?? this.online,
        returnToReview: returnToReview ?? this.returnToReview,
        submission: submission ?? this.submission,
        failure: clearFailure ? null : (failure ?? this.failure),
        created: created ?? this.created,
      );
}

/// The whole post-an-ad flow for one category (W02–W15). Route-scoped.
class SellFlowCubit extends Cubit<SellFlowState> {
  SellFlowCubit({
    required SellCategory category,
    required SellConfig initialConfig,
    SellDraft? draft,
    String? draftId,
    SellRepository? repository,
    SellDraftStore? store,
    required this.mediaSnapshot,
  })  : _repo = repository ?? SellRepository(),
        _store = store ?? SellDraftStore.instance,
        super(SellFlowState(
          category: category,
          config: initialConfig,
          step: draft?.step ?? SellStep.photos,
          values: Map<String, dynamic>.from(draft?.values ?? _defaults(category)),
          errors: const {},
          draftId: draft?.id ?? draftId ?? 'd${DateTime.now().millisecondsSinceEpoch}',
          idempotencyKey: draft?.idempotencyKey ?? SellFormat.uuidV4(),
          savedAt: draft?.updatedAt,
          restoredFrom: draft?.updatedAt,
        ));

  final SellRepository _repo;
  final SellDraftStore _store;

  /// Current media list, provided by the page (SellMediaCubit).
  final List<SellMediaItem> Function() mediaSnapshot;

  Timer? _saveDebounce;
  Timer? _slowTimer;
  bool _discarded = false;

  static Map<String, dynamic> _defaults(SellCategory c) {
    if (c == SellCategory.property) {
      return {
        SellKeys.listingType: 'sell',
        SellKeys.builtUnit: 'sqft',
        SellKeys.landUnit: 'cent',
      };
    }
    if (c == SellCategory.commercial) {
      return {SellKeys.payloadUnit: 'kg'};
    }
    return {};
  }

  bool _configLoading = false;

  /// Fetches the config, retrying with backoff while only the offline
  /// fallback is available (its server lookups are empty).
  Future<void> loadConfig() async {
    if (_configLoading) return;
    _configLoading = true;
    try {
      for (var attempt = 0; attempt < 5; attempt++) {
        final cfg = await _repo.refreshConfig(state.category);
        if (isClosed) return;
        emit(state.copyWith(config: cfg));
        if (!cfg.isFallback) return;
        await Future<void>.delayed(Duration(seconds: 3 << attempt));
        if (isClosed) return;
      }
    } finally {
      _configLoading = false;
    }
  }

  // Bikes used to have their transmission silently defaulted to Manual here
  // (BIKE-1). That was the client half of the July FE-02/03 fix, from when the
  // server still required `transmissionTypeId` for two-wheelers. Since
  // validateVehicle made it optional for TWO_WHEELER the default only produced
  // wrong data — every scooter was recorded as Manual without being asked.
  // A bike now posts no transmission unless the seller or the variant supplies
  // one.

  // ---------------------------------------------------------------- editing

  void setValue(String key, dynamic value, {bool save = true}) {
    setValues({key: value}, save: save);
  }

  void setValues(Map<String, dynamic> changes, {bool save = true}) {
    if (state.isPosting) return;
    final values = Map<String, dynamic>.from(state.values);
    final errors = Map<String, String>.from(state.errors);
    changes.forEach((k, v) {
      if (v == null) {
        values.remove(k);
      } else {
        values[k] = v;
      }
      errors.remove(k);
      if (k == SellKeys.modelId || k == SellKeys.brandId) errors.remove(SellKeys.brandId);
      if (k == SellKeys.latitude || k == SellKeys.longitude) errors.remove(SellKeys.location);
      if (k == SellKeys.landArea || k == SellKeys.landUnit) errors.remove(SellKeys.landArea);
      if (k == SellKeys.builtArea || k == SellKeys.builtUnit) errors.remove(SellKeys.builtArea);
    });
    // Untouched titles follow the details they were written from.
    if (values[SellKeys.titleEdited] != true) {
      final suggestion = SellRules.suggestedTitle(state.category, values);
      if (suggestion.isEmpty) {
        values.remove(SellKeys.title);
      } else {
        values[SellKeys.title] = suggestion;
      }
    }
    final clearFailure = state.failure is ValidationFailure &&
        errors.isEmpty &&
        state.submission == SubmissionStatus.failed;
    emit(state.copyWith(
      values: values,
      errors: errors,
      clearFailure: clearFailure,
      submission: clearFailure ? SubmissionStatus.idle : null,
    ));
    if (save) scheduleSave();
  }

  /// Re-checks a single field (on blur). Only reports errors for keys the
  /// seller has actually filled, so empty fields stay quiet until Next.
  void validateField(String key) {
    final all = SellRules.validateStep(state.step, state.category, state.values, mediaSnapshot(), state.config);
    final message = all[key];
    final errors = Map<String, String>.from(state.errors);
    final filled = state.values[key] != null && '${state.values[key]}'.isNotEmpty;
    if (message != null && filled) {
      errors[key] = message;
    } else if (message == null) {
      errors.remove(key);
    }
    emit(state.copyWith(errors: errors));
  }

  void mediaChanged() {
    if (state.errors.containsKey(SellKeys.photos) && mediaSnapshot().any((m) => !m.isVideo)) {
      final errors = Map<String, String>.from(state.errors)..remove(SellKeys.photos);
      emit(state.copyWith(errors: errors));
    }
    scheduleSave();
  }

  // ------------------------------------------------------------- navigation

  /// Returns true when the step changed.
  bool next() {
    if (state.isPosting) return false;
    final errors = SellRules.validateStep(state.step, state.category, state.values, mediaSnapshot(), state.config);
    if (errors.isNotEmpty) {
      emit(state.copyWith(errors: errors, attentionTick: state.attentionTick + 1));
      return false;
    }
    final target = state.returnToReview
        ? SellStep.review
        : SellStep.values[(state.stepIndex + 1).clamp(0, SellStep.values.length - 1)];
    final staleFailure = target == SellStep.review && state.failure is ValidationFailure;
    emit(state.copyWith(
      step: target,
      errors: const {},
      returnToReview: false,
      clearRestored: true,
      clearFailure: staleFailure,
      submission: staleFailure ? SubmissionStatus.idle : null,
    ));
    saveNow();
    return true;
  }

  /// Returns false when already on the first step (caller should leave).
  bool back() {
    if (state.isPosting) return true;
    if (state.returnToReview) {
      emit(state.copyWith(step: SellStep.review, returnToReview: false, errors: const {}));
      return true;
    }
    if (state.stepIndex == 0) return false;
    emit(state.copyWith(
      step: SellStep.values[state.stepIndex - 1],
      errors: const {},
      clearRestored: true,
    ));
    return true;
  }

  /// From Review "Edit" or failure "Fix ›".
  void editStep(SellStep step, {String? focusKey}) {
    if (state.isPosting) return;
    final errors = focusKey != null && state.errors[focusKey] != null
        ? {focusKey: state.errors[focusKey]!}
        : Map<String, String>.from(state.errors);
    emit(state.copyWith(
      step: step,
      returnToReview: step != SellStep.review,
      errors: errors,
      attentionTick: state.attentionTick + 1,
    ));
  }

  void setOnline(bool online) {
    if (online != state.online) emit(state.copyWith(online: online));
  }

  void dismissRestored() => emit(state.copyWith(clearRestored: true));

  // ------------------------------------------------------------------- post

  bool _submitBusy = false;

  Future<void> submit() async {
    if (_submitBusy || state.isPosting || state.submission == SubmissionStatus.succeeded) return;
    _submitBusy = true;
    try {
      await _submit();
    } finally {
      _submitBusy = false;
    }
  }

  Future<void> _submit() async {
    final media = mediaSnapshot();
    for (final step in [SellStep.photos, SellStep.details, SellStep.pricePlace]) {
      final errors = SellRules.validateStep(step, state.category, state.values, media, state.config);
      if (errors.isNotEmpty) {
        emit(state.copyWith(step: step, errors: errors, returnToReview: true, attentionTick: state.attentionTick + 1));
        return;
      }
    }
    if (!state.online) return;
    if (!media.every((m) => m.isDone)) return; // Post stays disabled until uploads finish.

    await saveNow();
    emit(state.copyWith(submission: SubmissionStatus.submitting, clearFailure: true, errors: const {}));
    _slowTimer?.cancel();
    _slowTimer = Timer(const Duration(seconds: 8), () {
      if (!isClosed && state.submission == SubmissionStatus.submitting) {
        emit(state.copyWith(submission: SubmissionStatus.slow));
      }
    });

    final payload = SellRules.buildPayload(state.category, state.values, media);
    CreateAdFailure? failure;
    CreatedAd? created;
    // Timeouts and "still in progress" are retried with the SAME key, so the
    // server returns the ad it already created instead of a second one.
    for (var attempt = 0; attempt < 4; attempt++) {
      try {
        created = await _repo.createAd(payload, state.idempotencyKey);
        failure = null;
        break;
      } on CreateAdFailure catch (f) {
        failure = f;
        final retryable = f is InProgressFailure || (f is NetworkFailure && attempt < 1);
        if (!retryable || isClosed) break;
        if (state.submission == SubmissionStatus.submitting) {
          emit(state.copyWith(submission: SubmissionStatus.slow));
        }
        await Future<void>.delayed(Duration(seconds: 2 + attempt * 2));
      } catch (_) {
        failure = const ServerFailure('Something went wrong on our side.');
        break;
      }
    }
    _slowTimer?.cancel();
    if (isClosed) return;

    if (created != null) {
      _discarded = true;
      _saveDebounce?.cancel();
      await _store.delete(state.draftId);
      if (isClosed) return;
      emit(state.copyWith(submission: SubmissionStatus.succeeded, created: created));
      return;
    }

    final f = failure ?? const ServerFailure('Something went wrong on our side.');
    // No review prompt on a day posting failed (audit 3.3).
    unawaited(ReviewPromptService.instance.noteProblem());
    if (f is ServerFailure && f.keyReused) {
      // The body changed after an ambiguous attempt; the next Post needs a new key.
      emit(state.copyWith(idempotencyKey: SellFormat.uuidV4()));
      unawaited(saveNow());
    }
    if (f is ValidationFailure &&
        state.values[SellKeys.propertyType] == 'plot' &&
        f.fields.containsKey(SellKeys.builtArea)) {
      f.fields[SellKeys.landArea] = f.fields.remove(SellKeys.builtArea)!;
    }
    emit(state.copyWith(
      submission: SubmissionStatus.failed,
      failure: f,
      errors: f is ValidationFailure ? f.fields : const {},
      step: SellStep.review,
    ));
  }

  void clearFailure() {
    if (state.submission == SubmissionStatus.failed) {
      emit(state.copyWith(submission: SubmissionStatus.idle, clearFailure: true));
    }
  }

  // ----------------------------------------------------------------- drafts

  /// `transmissionTypeId` used to be excluded here because the bike default
  /// above wrote it before the seller touched anything, which would have made
  /// an untouched draft look like content. Now that nothing writes it on the
  /// seller's behalf, its presence means a real answer and counts.
  bool get hasContent =>
      mediaSnapshot().isNotEmpty ||
      state.values.keys.any((k) => !_defaults(state.category).containsKey(k));

  void scheduleSave() {
    if (_discarded) return;
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 600), () => saveNow());
  }

  Future<void> saveNow() async {
    _saveDebounce?.cancel();
    if (_discarded || !hasContent) return;
    final draft = SellDraft(
      id: state.draftId,
      category: state.category,
      step: state.step,
      values: state.values,
      media: mediaSnapshot(),
      idempotencyKey: state.idempotencyKey,
      updatedAt: DateTime.now(),
    );
    await _store.save(draft);
    if (!isClosed) emit(state.copyWith(savedAt: draft.updatedAt));
  }

  Future<void> discard() async {
    _discarded = true;
    _saveDebounce?.cancel();
    await _store.delete(state.draftId);
  }

  @override
  Future<void> close() {
    _slowTimer?.cancel();
    if (_saveDebounce?.isActive ?? false) {
      _saveDebounce?.cancel();
      unawaited(saveNow());
    }
    return super.close();
  }
}
