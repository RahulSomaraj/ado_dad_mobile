part of 'advertisement_bloc.dart';

@freezed
class AdvertisementEvent with _$AdvertisementEvent {
  const factory AdvertisementEvent.started() = Started;
  const factory AdvertisementEvent.fetchAllListings() = FetchAllListingsEvent;
  const factory AdvertisementEvent.fetchNextPage() = FetchNextPageEvent;
  const factory AdvertisementEvent.fetchByCategory(
      {required String categoryId}) = FetchByCategory;
}
