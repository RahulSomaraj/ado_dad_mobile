import 'package:ado_dad_user/common/error_message_util.dart';
import 'package:ado_dad_user/common/auth_guard.dart';
import 'package:ado_dad_user/repositories/favorite_repo.dart';
import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'favorite_event.dart';
part 'favorite_state.dart';
part 'favorite_bloc.freezed.dart';

class FavoriteBloc extends Bloc<FavoriteEvent, FavoriteState> {
  final FavoriteRepository _favoriteRepository;

  /// Ad ids with a favorite request currently in flight. Guards against a
  /// rapid double tap firing two identical toggles concurrently.
  final Set<String> _inFlight = <String>{};

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
    // Ignore a second toggle for the same ad while one is still in flight.
    if (!_inFlight.add(event.adId)) return;

    try {
      // Capture the loaded list BEFORE emitting anything, so a single-item
      // toggle never resets the page or rebuilds the whole list as a skeleton.
      final currentState = state;
      final FavoriteLoaded? loadedState =
          currentState is FavoriteLoaded ? currentState : null;

      if (loadedState == null) {
        emit(FavoriteState.toggleLoading(adId: event.adId));
      }

      // Check authentication before favorite operations
      final isAuthenticated = await AuthGuard.isAuthenticated();
      if (!isAuthenticated) {
        emit(FavoriteState.toggleError(
          adId: event.adId,
          message: "Please login to add items to favorites.",
        ));
        if (loadedState != null) emit(loadedState);
        return;
      }

      try {
        FavoriteResponse response;

        if (event.isCurrentlyFavorited) {
          response = await _favoriteRepository.removeFromFavorites(event.adId);
        } else {
          response = await _favoriteRepository.addToFavorites(event.adId);
        }

        if (loadedState != null) {
          // Apply the change locally instead of refetching the page.
          final updated = List<dynamic>.from(loadedState.favorites);
          if (!response.isFavorited) {
            updated.removeWhere((f) => f.id == event.adId);
          }
          emit(loadedState.copyWith(favorites: updated));
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
          message: ErrorMessageUtil.getUserFriendlyMessage(e.toString()),
        ));
        // Revert to the untouched list so the page keeps showing its content.
        if (loadedState != null) emit(loadedState);
      }
    } finally {
      _inFlight.remove(event.adId);
    }
  }

  Future<void> _onAddToFavorites(
    AddToFavoritesEvent event,
    Emitter<FavoriteState> emit,
  ) async {
    emit(FavoriteState.toggleLoading(adId: event.adId));

    // Check authentication before favorite operations
    final isAuthenticated = await AuthGuard.isAuthenticated();
    if (!isAuthenticated) {
      emit(FavoriteState.toggleError(
        adId: event.adId,
        message: "Please login to add items to favorites.",
      ));
      return;
    }

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
        message: ErrorMessageUtil.getUserFriendlyMessage(e.toString()),
      ));
    }
  }

  Future<void> _onRemoveFromFavorites(
    RemoveFromFavoritesEvent event,
    Emitter<FavoriteState> emit,
  ) async {
    emit(FavoriteState.toggleLoading(adId: event.adId));

    // Check authentication before favorite operations
    final isAuthenticated = await AuthGuard.isAuthenticated();
    if (!isAuthenticated) {
      emit(FavoriteState.toggleError(
        adId: event.adId,
        message: "Please login to remove items from favorites.",
      ));
      return;
    }

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
        message: ErrorMessageUtil.getUserFriendlyMessage(e.toString()),
      ));
    }
  }

  Future<void> _onLoadFavorites(
    LoadFavoritesEvent event,
    Emitter<FavoriteState> emit,
  ) async {
    emit(const FavoriteState.loading());

    // Check authentication before loading favorites
    final isAuthenticated = await AuthGuard.isAuthenticated();
    if (!isAuthenticated) {
      emit(const FavoriteState.error(
        message: "Please login to view your favorites.",
      ));
      return;
    }

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
      emit(FavoriteState.error(
          message: ErrorMessageUtil.getUserFriendlyMessage(e.toString())));
    }
  }

  Future<void> _onRefreshFavorites(
    RefreshFavoritesEvent event,
    Emitter<FavoriteState> emit,
  ) async {
    emit(const FavoriteState.loading());

    // Check authentication before refreshing favorites
    final isAuthenticated = await AuthGuard.isAuthenticated();
    if (!isAuthenticated) {
      emit(const FavoriteState.error(
        message: "Please login to view your favorites.",
      ));
      return;
    }

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
      emit(FavoriteState.error(
          message: ErrorMessageUtil.getUserFriendlyMessage(e.toString())));
    }
  }
}
