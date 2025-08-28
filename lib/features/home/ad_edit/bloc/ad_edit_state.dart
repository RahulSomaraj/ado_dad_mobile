part of 'ad_edit_bloc.dart';

@freezed
class AdEditState with _$AdEditState {
  const factory AdEditState.idle() = _Idle;
  const factory AdEditState.saving() = _Saving;
  const factory AdEditState.success(AddModel updated) = _Success;
  const factory AdEditState.failure(String message) = _Failure;
}
