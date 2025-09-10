import 'package:ado_dad_user/models/my_ads_model.dart';
import 'package:ado_dad_user/repositories/my_ads_repo.dart';
import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'my_ads_event.dart';
part 'my_ads_state.dart';
part 'my_ads_bloc.freezed.dart';

class MyAdsBloc extends Bloc<MyAdsEvent, MyAdsState> {
  final MyAdsRepo repository;
  MyAdsBloc({required this.repository}) : super(const MyAdsState.initial()) {
    on<MyAdsEvent>((event, emit) async {
      await event.when(
        load: (page, limit) async {
          emit(const MyAdsState.loading());
          try {
            final res = await repository.fetchMyAds(page: page, limit: limit);
            emit(MyAdsState.loaded(
                ads: res.data, hasNext: res.hasNext, page: page));
          } catch (e) {
            emit(MyAdsState.error(e.toString()));
          }
        },
        loadMore: (nextPage, limit) async {
          final current = state;
          if (current is _Loaded) {
            if (!current.hasNext) return;
            emit(current.copyWith(isPaging: true));
            try {
              final res =
                  await repository.fetchMyAds(page: nextPage, limit: limit);
              emit(current.copyWith(
                ads: [...current.ads, ...res.data],
                hasNext: res.hasNext,
                page: nextPage,
                isPaging: false,
              ));
            } catch (e) {
              emit(MyAdsState.error(e.toString()));
            }
          }
        },
      );
    });
  }
}
