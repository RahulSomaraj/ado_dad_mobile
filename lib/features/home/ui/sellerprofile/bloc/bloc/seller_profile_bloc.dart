import 'package:ado_dad_user/models/advertisement_model/add_model.dart';
import 'package:ado_dad_user/repositories/seller_profile_repo.dart';
import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'seller_profile_event.dart';
part 'seller_profile_state.dart';
part 'seller_profile_bloc.freezed.dart';

class SellerProfileBloc extends Bloc<SellerProfileEvent, SellerProfileState> {
  final SellerProfileRepository repository;

  SellerProfileBloc({required this.repository})
      : super(const SellerProfileState.initial()) {
    on<_FetchUserAds>(_onFetchUserAds);
    on<_LoadMore>(_onLoadMore);
  }

  Future<void> _onFetchUserAds(
    _FetchUserAds event,
    Emitter<SellerProfileState> emit,
  ) async {
    emit(const SellerProfileState.loading());
    try {
      final response = await repository.fetchUserAds(userId: event.userId);
      emit(SellerProfileState.loaded(
        ads: response.data,
        hasNext: response.hasNext,
        page: response.page,
      ));
    } catch (e) {
      emit(SellerProfileState.error(e.toString()));
    }
  }

  Future<void> _onLoadMore(
    _LoadMore event,
    Emitter<SellerProfileState> emit,
  ) async {
    final current = state;
    if (current is _Loaded) {
      if (!current.hasNext) return;

      emit(current.copyWith(isPaging: true));
      try {
        final nextPage = current.page + 1;
        final response = await repository.fetchUserAds(
          userId: event.userId,
          page: nextPage,
        );

        emit(current.copyWith(
          ads: [...current.ads, ...response.data],
          hasNext: response.hasNext,
          page: nextPage,
          isPaging: false,
        ));
      } catch (e) {
        emit(current.copyWith(isPaging: false));
        emit(SellerProfileState.error(e.toString()));
      }
    }
  }
}
