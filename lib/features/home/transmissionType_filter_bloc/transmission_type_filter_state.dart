part of 'transmission_type_filter_bloc.dart';

@freezed
class TransmissionTypeFilterState with _$TransmissionTypeFilterState {
  const factory TransmissionTypeFilterState.initial() = _Initial;
  const factory TransmissionTypeFilterState.loading() = _Loading;
  const factory TransmissionTypeFilterState.loaded(
      List<VehicleTransmissionType> items) = _Loaded;
  const factory TransmissionTypeFilterState.error(String message) = _Error;
}
