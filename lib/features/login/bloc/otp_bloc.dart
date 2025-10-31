import 'package:ado_dad_user/repositories/otp_repo.dart';
import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'otp_event.dart';
part 'otp_state.dart';
part 'otp_bloc.freezed.dart';

class OtpBloc extends Bloc<OtpEvent, OtpState> {
  final OtpRepository otpRepository;
  OtpBloc({OtpRepository? otpRepository})
      : otpRepository = otpRepository ?? OtpRepository(),
        super(const OtpState.initial()) {
    on<SendOtp>(_onSendOtp);
    on<VerifyOtp>(_onVerifyOtp);
  }

  Future<void> _onSendOtp(SendOtp event, Emitter<OtpState> emit) async {
    emit(const OtpState.sendOtpLoading());

    try {
      await otpRepository.sendOtp(event.identifier);
      emit(const OtpState.sendOtpSuccess());
    } catch (e) {
      emit(OtpState.sendOtpFailure(e.toString()));
    }
  }

  Future<void> _onVerifyOtp(VerifyOtp event, Emitter<OtpState> emit) async {
    emit(const OtpState.verifyOtpLoading());

    try {
      final response =
          await otpRepository.verifyOtp(event.identifier, event.otp);
      emit(OtpState.verifyOtpSuccess(username: response.name));
    } catch (e) {
      emit(OtpState.verifyOtpFailure(e.toString()));
    }
  }
}
