part of 'model_filter_bloc.dart';

@freezed
class ModelFilterState with _$ModelFilterState {
  const factory ModelFilterState.initial() = _Initial;
  const factory ModelFilterState.loading() = _Loading;
  const factory ModelFilterState.loaded(List<VehicleModel> items) = _Loaded;
  const factory ModelFilterState.error(String message) = _Error;
}
