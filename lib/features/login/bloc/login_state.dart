part of 'login_bloc.dart';

@freezed
class LoginState with _$LoginState {
  const factory LoginState.initial() = Initial;
  const factory LoginState.loading() = Loading;
  const factory LoginState.success({
    required String username,
    // required String userType,
  }) = Success;
  const factory LoginState.failure(String message) = Failure;

  // Forgot password states
  const factory LoginState.forgotPasswordLoading() = ForgotPasswordLoading;
  const factory LoginState.forgotPasswordSuccess() = ForgotPasswordSuccess;
  const factory LoginState.forgotPasswordFailure(String message) =
      ForgotPasswordFailure;
}
