part of 'banner_bloc.dart';

@freezed
class BannerEvent with _$BannerEvent {
  const factory BannerEvent.started() = Started;
  const factory BannerEvent.fetchBanners() = FetchBanners;
}
