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

  AdDetailBloc({
    required this.repository,
  }) : super(const AdDetailState.initial()) {
    on<AdDetailEvent>((event, emit) async {
      await event.when(
        fetch: (adId) async {
          emit(const AdDetailState.loading());
          try {
            final detail = await repository.fetchAdDetail(adId);
            // Names are now parsed directly from nested objects in the model
            _lastLoaded = detail;
            emit(AdDetailState.loaded(detail));
          } catch (e) {
            emit(AdDetailState.error(e.toString()));
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
