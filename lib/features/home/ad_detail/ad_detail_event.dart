part of 'ad_detail_bloc.dart';

@freezed
class AdDetailEvent with _$AdDetailEvent {
  const factory AdDetailEvent.started() = _Started;
  const factory AdDetailEvent.fetch(String adId) = _FetchAdDetail;
  const factory AdDetailEvent.markAsSold(String adId) = _MarkAsSold;
}
