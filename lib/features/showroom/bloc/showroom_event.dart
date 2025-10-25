part of 'showroom_bloc.dart';

@freezed
class ShowroomEvent with _$ShowroomEvent {
  const factory ShowroomEvent.fetchShowroomUserAds({
    required String userId,
  }) = FetchShowroomUserAdsEvent;

  const factory ShowroomEvent.fetchNextPage() = FetchNextPageEvent;
}
