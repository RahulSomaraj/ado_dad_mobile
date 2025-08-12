part of 'advertisement_bloc.dart';

@freezed
class AdvertisementState with _$AdvertisementState {
  // const factory AdvertisementState.initial() = _Initial;

  const factory AdvertisementState.initial() = AdvertisementInitial;

  const factory AdvertisementState.loading() = AdvertisementLoading;

  /// **State when both Vehicles and Properties are loaded**
  // const factory AdvertisementState.listingsLoaded({
  //   required List<dynamic> listings, // Holds both Vehicles and Properties
  // }) = ListingsLoaded;
  const factory AdvertisementState.listingsLoaded({
    required List<AddModel> listings,
    required bool hasMore,
  }) = ListingsLoaded;

  const factory AdvertisementState.error(String message) = AdvertisementError;
}
