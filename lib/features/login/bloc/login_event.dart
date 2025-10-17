part of 'login_bloc.dart';

@freezed
class LoginEvent with _$LoginEvent {
  const factory LoginEvent.started() = _Started;
  const factory LoginEvent.login({
    required String username,
    required String password,
  }) = Login;

  const factory LoginEvent.checkLoginStatus() = CheckLoginStatus;

  const factory LoginEvent.logout() = Logout;

  const factory LoginEvent.forgotPassword({
    required String email,
  }) = ForgotPassword;
}
