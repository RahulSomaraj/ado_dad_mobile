part of 'otp_bloc.dart';

@freezed
class OtpEvent with _$OtpEvent {
  const factory OtpEvent.sendOtp({
    required String identifier,
  }) = SendOtp;

  const factory OtpEvent.verifyOtp({
    required String identifier,
    required String otp,
  }) = VerifyOtp;
}
