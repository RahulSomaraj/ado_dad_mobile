import 'package:ado_dad_user/models/advertisement_model/add_model.dart';
import 'package:ado_dad_user/repositories/add_repo.dart';
import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'ad_detail_event.dart';
part 'ad_detail_state.dart';
part 'ad_detail_bloc.freezed.dart';

class AdDetailBloc extends Bloc<AdDetailEvent, AdDetailState> {
  final AddRepository repository;

  /// Last successfully loaded ad, so a failed sold/delete action can put the
  /// page back on the detail view instead of leaving it on the error screen.
  AddModel? _lastLoaded;

  /// [seed] is the list row the route already had in hand (`state.extra`).
  /// With it the page opens on real content and the `/v2/ads/:id` call becomes
  /// a background revalidation instead of a skeleton the user sits through.
  AdDetailBloc({
    required this.repository,
    AddModel? seed,
  }) : super(seed == null
            ? const AdDetailState.initial()
            : AdDetailState.loaded(seed)) {
    _lastLoaded = seed;

    on<AdDetailEvent>((event, emit) async {
      await event.when(
        fetch: (adId) async {
          // Only show the skeleton when there is nothing to show yet.
          final hadSeed = _lastLoaded != null;
          if (!hadSeed) emit(const AdDetailState.loading());
          try {
            final detail = await repository.fetchAdDetail(adId);
            // Names are now parsed directly from nested objects in the model
            _lastLoaded = detail;
            emit(AdDetailState.loaded(detail));
          } catch (e) {
            if (!hadSeed) {
              emit(AdDetailState.error(e.toString()));
            } else {
              // A failed *revalidation* must not strand the user on an error
              // screen — but it must not be silent either. Surface it (the page
              // listener shows a SnackBar) and put the seeded ad straight back.
              _emitActionError(emit, e);
            }
          }
        },
        markAsSold: (adId) async {
          emit(const AdDetailState.markingAsSold());
          try {
            final updatedAd = await repository.markAdAsSold(adId);
            _lastLoaded = updatedAd;
            emit(AdDetailState.markedAsSold(updatedAd));
          } catch (e) {
            _emitActionError(emit, e);
          }
        },
        deleteAd: (adId) async {
          emit(const AdDetailState.deleting());
          try {
            await repository.deleteAd(adId);
            emit(const AdDetailState.deleted());
          } catch (e) {
            _emitActionError(emit, e);
          }
        },
        started: () {},
      );
    });
  }

  /// Surfaces the error (listeners show a SnackBar) and then restores the
  /// previously loaded ad so the builder keeps showing the detail page.
  void _emitActionError(Emitter<AdDetailState> emit, Object e) {
    emit(AdDetailState.error(e.toString()));
    final ad = _lastLoaded;
    if (ad != null) {
      emit(AdDetailState.loaded(ad));
    }
  }
}
