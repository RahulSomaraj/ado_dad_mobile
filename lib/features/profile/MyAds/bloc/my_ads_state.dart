part of 'my_ads_bloc.dart';

@freezed
class MyAdsState with _$MyAdsState {
  const factory MyAdsState.initial() = _Initial;
  const factory MyAdsState.loading() = _Loading;
  const factory MyAdsState.loaded({
    required List<MyAd> ads,
    @Default(false) bool hasNext,
    @Default(1) int page,
    @Default(false) bool isPaging,
  }) = _Loaded;
  const factory MyAdsState.error(String message) = _Error;
}
