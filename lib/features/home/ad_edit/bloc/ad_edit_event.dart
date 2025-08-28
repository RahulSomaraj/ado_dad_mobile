part of 'ad_edit_bloc.dart';

@freezed
class AdEditEvent with _$AdEditEvent {
  const factory AdEditEvent.started() = _Started;
  const factory AdEditEvent.submit({
    required String adId,
    required String category,
    required Map<String, dynamic> payload,
  }) = _Submit;
}
