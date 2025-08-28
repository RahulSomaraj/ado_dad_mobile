part of 'ad_detail_bloc.dart';

@freezed
class AdDetailState with _$AdDetailState {
  const factory AdDetailState.initial() = _Initial;
  const factory AdDetailState.loading() = _Loading;
  const factory AdDetailState.loaded(AddModel detail) = _Loaded;
  const factory AdDetailState.error(String message) = _Error;
}
