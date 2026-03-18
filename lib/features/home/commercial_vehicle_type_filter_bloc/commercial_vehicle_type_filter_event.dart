part of 'commercial_vehicle_type_filter_bloc.dart';

@freezed
class CommercialVehicleTypeFilterEvent with _$CommercialVehicleTypeFilterEvent {
  const factory CommercialVehicleTypeFilterEvent.started() = _Started;
  const factory CommercialVehicleTypeFilterEvent.load() =
      _LoadCommercialVehicleTypes;
}

