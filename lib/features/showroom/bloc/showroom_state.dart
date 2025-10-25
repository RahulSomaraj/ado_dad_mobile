part of 'showroom_bloc.dart';

@freezed
class ShowroomState with _$ShowroomState {
  const factory ShowroomState.initial() = Initial;
  const factory ShowroomState.loading() = Loading;
  const factory ShowroomState.adsLoaded({
    required List<AddModel> ads,
    required bool hasMore,
    required String userId,
  }) = AdsLoaded;
  const factory ShowroomState.error(String message) = Error;
}
