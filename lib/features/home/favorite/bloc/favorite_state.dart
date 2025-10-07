part of 'favorite_bloc.dart';

@freezed
class FavoriteState with _$FavoriteState {
  const factory FavoriteState.initial() = FavoriteInitial;

  const factory FavoriteState.loading() = FavoriteLoading;

  const factory FavoriteState.loaded({
    required List<dynamic>
        favorites, // Changed to dynamic to handle both FavoriteAd and EnrichedFavoriteAd
    required bool hasNext,
    required int currentPage,
  }) = FavoriteLoaded;

  const factory FavoriteState.error({
    required String message,
  }) = FavoriteError;

  const factory FavoriteState.toggleLoading({
    required String adId,
  }) = FavoriteToggleLoading;

  const factory FavoriteState.toggleSuccess({
    required String adId,
    required bool isFavorited,
    String? favoriteId,
    required String message,
  }) = FavoriteToggleSuccess;

  const factory FavoriteState.toggleError({
    required String adId,
    required String message,
  }) = FavoriteToggleError;
}
