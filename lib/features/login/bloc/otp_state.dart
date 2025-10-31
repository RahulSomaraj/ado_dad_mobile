part of 'otp_bloc.dart';

@freezed
class OtpState with _$OtpState {
  const factory OtpState.initial() = Initial;
  const factory OtpState.sendOtpLoading() = SendOtpLoading;
  const factory OtpState.sendOtpSuccess() = SendOtpSuccess;
  const factory OtpState.sendOtpFailure(String message) = SendOtpFailure;
  const factory OtpState.verifyOtpLoading() = VerifyOtpLoading;
  const factory OtpState.verifyOtpSuccess({required String username}) =
      VerifyOtpSuccess;
  const factory OtpState.verifyOtpFailure(String message) = VerifyOtpFailure;
}
