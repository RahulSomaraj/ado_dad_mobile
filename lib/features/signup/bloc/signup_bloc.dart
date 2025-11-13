import 'dart:async';
import 'dart:typed_data';

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
    emit(const SignupState.loading());
    try {
      var model = event.data;

      // If user selected an image, upload it first and attach the URL
      if (event.profileBytes != null && event.profileBytes!.isNotEmpty) {
        final url = await signupRepository.uploadImageToS3(event.profileBytes!);
        if (url != null && url.isNotEmpty) {
          model = model.copyWith(profilePic: url);
        }
      }

      final responseMessage = await signupRepository.signup(model);
      print('Success!!!!!');
      print('responseMessage:.......$responseMessage');
      emit(SignupState.signupSuccess(responseMessage));
    } catch (e) {
      // Extract message from exception, removing "Exception: " prefix if present
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring('Exception: '.length);
      }
      // Remove '[' characters from both sides of the message
      errorMessage = errorMessage.trim();
      if (errorMessage.startsWith('[') && errorMessage.endsWith(']')) {
        errorMessage = errorMessage.substring(1, errorMessage.length - 1);
      }
      emit(SignupState.error(errorMessage));
    }
  }
}
