part of 'signup_bloc.dart';

@freezed
class SignupEvent with _$SignupEvent {
  const factory SignupEvent.started() = Started;
  const factory SignupEvent.signup({required SignupModel data}) = SignUp;
}
