part of 'fuel_type_filter_bloc.dart';

@freezed
class FuelTypeFilterState with _$FuelTypeFilterState {
  const factory FuelTypeFilterState.initial() = _Initial;
  const factory FuelTypeFilterState.loading() = _Loading;
  const factory FuelTypeFilterState.loaded(List<VehicleFuelType> items) =
      _Loaded;
  const factory FuelTypeFilterState.error(String message) = _Error;
}
