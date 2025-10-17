import 'package:ado_dad_user/models/advertisement_model/add_model.dart';
import 'package:ado_dad_user/repositories/add_repo.dart';
import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'ad_detail_event.dart';
part 'ad_detail_state.dart';
part 'ad_detail_bloc.freezed.dart';

class AdDetailBloc extends Bloc<AdDetailEvent, AdDetailState> {
  final AddRepository repository;

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
            emit(AdDetailState.loaded(detail));
          } catch (e) {
            emit(AdDetailState.error(e.toString()));
          }
        },
        markAsSold: (adId) async {
          emit(const AdDetailState.markingAsSold());
          try {
            // Mark as sold and get the updated ad data directly from the response
            final updatedAd = await repository.markAdAsSold(adId);
            emit(AdDetailState.markedAsSold(updatedAd));
          } catch (e) {
            emit(AdDetailState.error(e.toString()));
          }
        },
        started: () {},
      );
    });
  }
}
