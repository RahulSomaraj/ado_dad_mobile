part of 'model_filter_bloc.dart';

@freezed
class ModelFilterEvent with _$ModelFilterEvent {
  const factory ModelFilterEvent.started() = _Started;
  const factory ModelFilterEvent.load() = _LoadModels;
}
