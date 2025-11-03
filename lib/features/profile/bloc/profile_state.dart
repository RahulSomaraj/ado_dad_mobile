part of 'profile_bloc.dart';

@freezed
class ProfileState with _$ProfileState {
  const factory ProfileState.initial() = _Initial;
  const factory ProfileState.loading() = Loading;
  const factory ProfileState.loaded(UserProfile profile) = Loaded;
  const factory ProfileState.saving() = Saving;
  const factory ProfileState.changingPassword() = ChangingPassword;
  const factory ProfileState.passwordChanged() = PasswordChanged;
  const factory ProfileState.deletingData() = DeletingData;
  const factory ProfileState.dataDeleted() = DataDeleted;
  const factory ProfileState.error(String message) = Error;
}
