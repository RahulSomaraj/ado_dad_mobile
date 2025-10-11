part of 'profile_bloc.dart';

@freezed
class ProfileEvent with _$ProfileEvent {
  const factory ProfileEvent.started() = Started;
  const factory ProfileEvent.fetchProfile() = FetchProfile;
  const factory ProfileEvent.updateProfile(UserProfile profile) = UpdateProfile;
  const factory ProfileEvent.changePassword(String newPassword) =
      ChangePassword;
}
