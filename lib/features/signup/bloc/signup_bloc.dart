import 'dart:async';

import 'package:ado_dad_user/models/signup_model.dart';
import 'package:ado_dad_user/repositories/signup_repository.dart';
import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'signup_event.dart';
part 'signup_state.dart';
part 'signup_bloc.freezed.dart';

class SignupBloc extends Bloc<SignupEvent, SignupState> {
  final SignupRepository signupRepository;
  SignupBloc({required this.signupRepository})
      : super(const SignupState.initial()) {
    on<SignUp>((event, emit) => _onSignUp(event, emit));
  }

  Future<void> _onSignUp(SignUp event, Emitter<SignupState> emit) async {
    try {
      final responseMessage = await signupRepository.signup(event.data);
      print('Success!!!!!');
      print('responseMessage:.......$responseMessage');
      emit(SignupState.signupSuccess(responseMessage));
    } catch (e) {
      emit(SignupState.error(e.toString()));
    }
  }
}
