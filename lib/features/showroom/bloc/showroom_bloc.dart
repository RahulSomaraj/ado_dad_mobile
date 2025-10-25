import 'package:ado_dad_user/models/advertisement_model/add_model.dart';
import 'package:ado_dad_user/repositories/showroom_repo.dart';
import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'showroom_event.dart';
part 'showroom_state.dart';
part 'showroom_bloc.freezed.dart';

class ShowroomBloc extends Bloc<ShowroomEvent, ShowroomState> {
  final ShowroomRepo repository;
  ShowroomBloc({required this.repository})
      : super(const ShowroomState.initial()) {
    on<FetchShowroomUserAdsEvent>(_onFetchShowroomUserAds);
    on<FetchNextPageEvent>(_onFetchNextPage);
  }

  int _currentPage = 1;
  bool _isFetching = false;
  String? _currentUserId;

  Future<void> _onFetchShowroomUserAds(
      FetchShowroomUserAdsEvent event, Emitter<ShowroomState> emit) async {
    emit(const ShowroomState.loading());
    _currentPage = 1;
    _currentUserId = event.userId;

    try {
      final ads = await repository.fetchShowroomUserAds(
        userId: event.userId,
        page: _currentPage,
      );
      emit(ShowroomState.adsLoaded(
          ads: ads, hasMore: ads.length >= 20, userId: event.userId));
    } catch (e) {
      emit(ShowroomState.error("Failed to fetch showroom user ads: $e"));
    }
  }

  Future<void> _onFetchNextPage(
      FetchNextPageEvent event, Emitter<ShowroomState> emit) async {
    if (_isFetching || _currentUserId == null) return;
    _isFetching = true;

    final currentState = state;
    if (currentState is AdsLoaded && currentState.hasMore) {
      try {
        _currentPage += 1;
        print(
            "📥 Fetching showroom ads page $_currentPage for user $_currentUserId");
        final moreAds = await repository.fetchShowroomUserAds(
          userId: _currentUserId!,
          page: _currentPage,
        );

        final updatedAds = [...currentState.ads, ...moreAds];
        emit(ShowroomState.adsLoaded(
            ads: updatedAds,
            hasMore: moreAds.length >= 20,
            userId: _currentUserId!));
      } catch (e) {
        print("❌ Error fetching next page: $e");
        emit(ShowroomState.error("Failed to load more ads: $e"));
      } finally {
        _isFetching = false;
      }
    } else {
      _isFetching = false;
    }
  }
}
