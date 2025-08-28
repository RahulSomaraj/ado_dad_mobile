part of 'transmission_type_filter_bloc.dart';

@freezed
class TransmissionTypeFilterEvent with _$TransmissionTypeFilterEvent {
  const factory TransmissionTypeFilterEvent.started() = _Started;
  const factory TransmissionTypeFilterEvent.load() = _LoadTransmissionTypes;
}
