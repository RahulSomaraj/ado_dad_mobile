part of 'commercial_vehicle_type_filter_bloc.dart';

@freezed
class CommercialVehicleTypeFilterState with _$CommercialVehicleTypeFilterState {
  const factory CommercialVehicleTypeFilterState.initial() = _Initial;
  const factory CommercialVehicleTypeFilterState.loading() = _Loading;
  const factory CommercialVehicleTypeFilterState.loaded(
      List<CommercialVehicleType> items) = _Loaded;
  const factory CommercialVehicleTypeFilterState.error(String message) = _Error;
}

