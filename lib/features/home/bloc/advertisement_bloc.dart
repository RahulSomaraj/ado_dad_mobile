import 'package:ado_dad_user/models/advertisement_model/add_model.dart';
import 'package:ado_dad_user/repositories/add_repo.dart';
import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'advertisement_event.dart';
part 'advertisement_state.dart';
part 'advertisement_bloc.freezed.dart';

class AdvertisementBloc extends Bloc<AdvertisementEvent, AdvertisementState> {
  final AddRepository repository;
  AdvertisementBloc({required this.repository})
      : super(const AdvertisementState.initial()) {
    on<FetchAllListingsEvent>(_onFetchAllListings);
    on<FetchNextPageEvent>(_onFetchNextPage);
    on<FetchByCategory>(_onFetchByCategory);
  }

  int _currentPage = 1;
  bool _isFetching = false;

  Future<void> _onFetchAllListings(
      FetchAllListingsEvent event, Emitter<AdvertisementState> emit) async {
    emit(const AdvertisementState.loading());
    _currentPage = 1;

    try {
      final result = await repository.fetchAllAds(page: _currentPage);
      emit(AdvertisementState.listingsLoaded(
          listings: result.data, hasMore: result.hasNext));
    } catch (e) {
      emit(AdvertisementState.error("Failed to fetch ads: $e"));
    }
  }

  Future<void> _onFetchNextPage(
      FetchNextPageEvent event, Emitter<AdvertisementState> emit) async {
    if (_isFetching) return;
    _isFetching = true;

    final currentState = state;
    if (currentState is ListingsLoaded && currentState.hasMore) {
      try {
        _currentPage += 1;
        print("📥 Fetching page $_currentPage");
        final result = await repository.fetchAllAds(page: _currentPage);
        print(
            "📦 Received ${result.data.length} ads | hasNext: ${result.hasNext}");
        final updatedList = [...currentState.listings, ...result.data];

        emit(ListingsLoaded(listings: updatedList, hasMore: result.hasNext));
      } catch (e) {
        emit(AdvertisementState.error("Failed to load more ads: $e"));
      }
    }

    _isFetching = false;
  }

  Future<void> _onFetchByCategory(
    FetchByCategory event,
    Emitter<AdvertisementState> emit,
  ) async {
    emit(const AdvertisementState.loading());

    try {
      final result = await repository.fetchAllAds(
        page: 1,
        categoryId: event.categoryId,
      );
      emit(AdvertisementState.listingsLoaded(
        listings: result.data,
        hasMore: result.hasNext,
      ));
    } catch (e) {
      emit(AdvertisementState.error("Failed to fetch category ads: $e"));
    }
  }
}
