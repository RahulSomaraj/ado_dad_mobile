part of 'manufacturer_bloc.dart';

@freezed
class ManufacturerState with _$ManufacturerState {
  const factory ManufacturerState.initial() = _Initial;
  const factory ManufacturerState.loading() = _Loading;
  const factory ManufacturerState.loaded(List<VehicleManufacturer> items) =
      _Loaded;
  const factory ManufacturerState.error(String message) = _Error;
}
