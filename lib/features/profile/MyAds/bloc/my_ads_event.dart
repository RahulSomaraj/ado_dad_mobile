part of 'my_ads_bloc.dart';

@freezed
class MyAdsEvent with _$MyAdsEvent {
  const factory MyAdsEvent.load(
      {@Default(1) int page, @Default(100) int limit}) = _Load;
  const factory MyAdsEvent.loadMore(
      {required int nextPage, @Default(100) int limit}) = _LoadMore;
}
