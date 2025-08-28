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
  }) = ApplyFiltersEvent;
}
