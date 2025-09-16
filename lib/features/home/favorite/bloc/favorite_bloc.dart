import 'package:ado_dad_user/repositories/favorite_repo.dart';
import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'favorite_event.dart';
part 'favorite_state.dart';
part 'favorite_bloc.freezed.dart';

class FavoriteBloc extends Bloc<FavoriteEvent, FavoriteState> {
  final FavoriteRepository _favoriteRepository;

  FavoriteBloc({required FavoriteRepository favoriteRepository})
      : _favoriteRepository = favoriteRepository,
        super(const FavoriteState.initial()) {
    on<ToggleFavoriteEvent>(_onToggleFavorite);
    on<AddToFavoritesEvent>(_onAddToFavorites);
    on<RemoveFromFavoritesEvent>(_onRemoveFromFavorites);
    on<LoadFavoritesEvent>(_onLoadFavorites);
    on<RefreshFavoritesEvent>(_onRefreshFavorites);
  }

  Future<void> _onToggleFavorite(
    ToggleFavoriteEvent event,
    Emitter<FavoriteState> emit,
  ) async {
    emit(FavoriteState.toggleLoading(adId: event.adId));

    try {
      FavoriteResponse response;

      if (event.isCurrentlyFavorited) {
        response = await _favoriteRepository.removeFromFavorites(event.adId);
      } else {
        response = await _favoriteRepository.addToFavorites(event.adId);
      }

      // If we're currently in a loaded state, refresh the list to reflect changes
      if (state is FavoriteLoaded) {
        // Refresh the favorites list to reflect the change
        final refreshResponse = await _favoriteRepository.getFavoriteAds(
          page: (state as FavoriteLoaded).currentPage,
          limit: 20,
        );

        emit(FavoriteState.loaded(
          favorites: refreshResponse.data,
          hasNext: refreshResponse.hasNext,
          currentPage: (state as FavoriteLoaded).currentPage,
        ));
      } else {
        // For other cases, emit toggle success
        emit(FavoriteState.toggleSuccess(
          adId: event.adId,
          isFavorited: response.isFavorited,
          favoriteId: response.favoriteId,
          message: response.message,
        ));
      }
    } catch (e) {
      emit(FavoriteState.toggleError(
        adId: event.adId,
        message: e.toString(),
      ));
    }
  }

  Future<void> _onAddToFavorites(
    AddToFavoritesEvent event,
    Emitter<FavoriteState> emit,
  ) async {
    emit(FavoriteState.toggleLoading(adId: event.adId));

    try {
      final response = await _favoriteRepository.addToFavorites(event.adId);

      // If we're currently in a loaded state, refresh the list to reflect changes
      if (state is FavoriteLoaded) {
        // Refresh the favorites list to reflect the change
        final refreshResponse = await _favoriteRepository.getFavoriteAds(
          page: (state as FavoriteLoaded).currentPage,
          limit: 20,
        );

        emit(FavoriteState.loaded(
          favorites: refreshResponse.data,
          hasNext: refreshResponse.hasNext,
          currentPage: (state as FavoriteLoaded).currentPage,
        ));
      } else {
        // For other cases, emit toggle success
        emit(FavoriteState.toggleSuccess(
          adId: event.adId,
          isFavorited: response.isFavorited,
          favoriteId: response.favoriteId,
          message: response.message,
        ));
      }
    } catch (e) {
      emit(FavoriteState.toggleError(
        adId: event.adId,
        message: e.toString(),
      ));
    }
  }

  Future<void> _onRemoveFromFavorites(
    RemoveFromFavoritesEvent event,
    Emitter<FavoriteState> emit,
  ) async {
    emit(FavoriteState.toggleLoading(adId: event.adId));

    try {
      final response =
          await _favoriteRepository.removeFromFavorites(event.adId);

      // If we're currently in a loaded state, refresh the list to reflect changes
      if (state is FavoriteLoaded) {
        // Refresh the favorites list to reflect the change
        final refreshResponse = await _favoriteRepository.getFavoriteAds(
          page: (state as FavoriteLoaded).currentPage,
          limit: 20,
        );

        emit(FavoriteState.loaded(
          favorites: refreshResponse.data,
          hasNext: refreshResponse.hasNext,
          currentPage: (state as FavoriteLoaded).currentPage,
        ));
      } else {
        // For other cases, emit toggle success
        emit(FavoriteState.toggleSuccess(
          adId: event.adId,
          isFavorited: response.isFavorited,
          favoriteId: response.favoriteId,
          message: response.message,
        ));
      }
    } catch (e) {
      emit(FavoriteState.toggleError(
        adId: event.adId,
        message: e.toString(),
      ));
    }
  }

  Future<void> _onLoadFavorites(
    LoadFavoritesEvent event,
    Emitter<FavoriteState> emit,
  ) async {
    emit(const FavoriteState.loading());

    try {
      final response = await _favoriteRepository.getFavoriteAds(
        page: event.page,
        limit: event.limit,
      );

      emit(FavoriteState.loaded(
        favorites: response.data,
        hasNext: response.hasNext,
        currentPage: event.page,
      ));
    } catch (e) {
      emit(FavoriteState.error(message: e.toString()));
    }
  }

  Future<void> _onRefreshFavorites(
    RefreshFavoritesEvent event,
    Emitter<FavoriteState> emit,
  ) async {
    emit(const FavoriteState.loading());

    try {
      final response = await _favoriteRepository.getFavoriteAds(
        page: 1,
        limit: 20,
      );

      emit(FavoriteState.loaded(
        favorites: response.data,
        hasNext: response.hasNext,
        currentPage: 1,
      ));
    } catch (e) {
      emit(FavoriteState.error(message: e.toString()));
    }
  }
}
