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
}
