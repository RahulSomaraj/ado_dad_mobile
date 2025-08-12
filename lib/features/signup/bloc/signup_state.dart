part of 'signup_bloc.dart';

@freezed
class SignupState with _$SignupState {
  const factory SignupState.initial() = Initial;
  const factory SignupState.loading() = Loading;
  const factory SignupState.signupSuccess(String message) = SignUpSuccess;
  const factory SignupState.error(String message) = Error;
}
