part of 'fuel_type_filter_bloc.dart';

@freezed
class FuelTypeFilterEvent with _$FuelTypeFilterEvent {
  const factory FuelTypeFilterEvent.started() = _Started;
  const factory FuelTypeFilterEvent.load() = _LoadFuelTypes;
}
