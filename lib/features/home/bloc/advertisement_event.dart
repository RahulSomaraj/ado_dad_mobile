part of 'advertisement_bloc.dart';

@freezed
class AdvertisementEvent with _$AdvertisementEvent {
  const factory AdvertisementEvent.started() = Started;
  const factory AdvertisementEvent.fetchAllListings() = FetchAllListingsEvent;
  const factory AdvertisementEvent.fetchNextPage() = FetchNextPageEvent;
  const factory AdvertisementEvent.fetchByCategory(
      {required String categoryId}) = FetchByCategory;
  const factory AdvertisementEvent.applyFilters({
    String? categoryId,
    int? minYear,
    int? maxYear,
    List<String>? manufacturerIds,
    List<String>? modelIds,
    List<String>? fuelTypeIds,
    List<String>? transmissionTypeIds,
    int? minPrice,
    int? maxPrice,
    // Property-specific filters
    List<String>? propertyTypes,
    int? minBedrooms,
    int? maxBedrooms,
    int? minArea,
    int? maxArea,
    bool? isFurnished,
    bool? hasParking,
  }) = ApplyFiltersEvent;
  const factory AdvertisementEvent.updateAdFavoriteStatus({
    required String adId,
    required bool isFavorited,
    String? favoriteId,
  }) = UpdateAdFavoriteStatusEvent;
  const factory AdvertisementEvent.searchByLocation({
    required double latitude,
    required double longitude,
  }) = SearchByLocationEvent;
  const factory AdvertisementEvent.fetchByUserId({
    required String userId,
  }) = FetchByUserIdEvent;
}
