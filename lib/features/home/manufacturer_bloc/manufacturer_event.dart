part of 'manufacturer_bloc.dart';

@freezed
class ManufacturerEvent with _$ManufacturerEvent {
  const factory ManufacturerEvent.started() = _Started;
  const factory ManufacturerEvent.load() = _LoadManufacturers;
}
