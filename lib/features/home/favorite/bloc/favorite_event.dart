part of 'favorite_bloc.dart';

@freezed
class FavoriteEvent with _$FavoriteEvent {
  const factory FavoriteEvent.toggleFavorite({
    required String adId,
    required bool isCurrentlyFavorited,
  }) = ToggleFavoriteEvent;

  const factory FavoriteEvent.addToFavorites({
    required String adId,
  }) = AddToFavoritesEvent;

  const factory FavoriteEvent.removeFromFavorites({
    required String adId,
  }) = RemoveFromFavoritesEvent;

  const factory FavoriteEvent.loadFavorites({
    @Default(1) int page,
    @Default(20) int limit,
  }) = LoadFavoritesEvent;

  const factory FavoriteEvent.refreshFavorites() = RefreshFavoritesEvent;
}
