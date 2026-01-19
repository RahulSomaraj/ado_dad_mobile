part of 'manufacturer_bloc.dart';

@freezed
class ManufacturerEvent with _$ManufacturerEvent {
  const factory ManufacturerEvent.started() = _Started;
  const factory ManufacturerEvent.load({String? vehicleCategory}) =
      _LoadManufacturers;
  const factory ManufacturerEvent.search(String query,
      {String? vehicleCategory}) = _SearchManufacturers;
}
