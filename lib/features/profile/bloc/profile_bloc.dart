import 'package:ado_dad_user/common/shared_pref.dart';
import 'package:ado_dad_user/models/profile_model.dart';
import 'package:ado_dad_user/repositories/profile_repo.dart';
import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile_event.dart';
part 'profile_state.dart';
part 'profile_bloc.freezed.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ProfileRepo repository;
  ProfileBloc({required this.repository})
      : super(const ProfileState.initial()) {
    on<FetchProfile>((event, emit) async {
      emit(const ProfileState.loading());
      try {
        final profile = await repository.fetchUserProfile();
        emit(ProfileState.loaded(profile));
      } catch (e) {
        emit(ProfileState.error(e.toString()));
      }
    });

    // 🔹 Handle Profile Update Event
    on<UpdateProfile>((event, emit) async {
      emit(const ProfileState.saving());
      try {
        await repository.updateUserProfile(event.profile);
        await SharedPrefs().saveUserProfile(event.profile);
        emit(ProfileState.loaded(event.profile));
      } catch (e) {
        emit(ProfileState.error(e.toString()));
      }
    });

    // 🔹 Handle Change Password Event
    on<ChangePassword>((event, emit) async {
      emit(const ProfileState.changingPassword());
      try {
        await repository.changePassword(event.newPassword);
        emit(const ProfileState.passwordChanged());
      } catch (e) {
        emit(ProfileState.error(e.toString()));
      }
    });
  }

  Future<void> deleteAccount() async {
    await repository.deleteAccount();
  }
}
