import 'dart:async';

import 'package:ado_dad_user/common/shared_pref.dart';
import 'package:ado_dad_user/repositories/login_repository.dart';
import 'package:ado_dad_user/services/chat_socket_service.dart';
import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'login_event.dart';
part 'login_state.dart';
part 'login_bloc.freezed.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final AuthRepository authRepository;
  LoginBloc({required this.authRepository})
      : super(const LoginState.initial()) {
    on<Login>(_onLogin);
    on<Logout>(_onLogout);
    on<CheckLoginStatus>(_onCheckLoginStatus);
    on<ForgotPassword>(_onForgotPassword);
  }

  Future<void> _onLogin(Login event, Emitter<LoginState> emit) async {
    emit(const LoginState.loading());

    try {
      final response =
          await authRepository.login(event.username, event.password);
      emit(LoginState.success(username: response.name));
      print('response:.............:${event.username}');
    } catch (e) {
      print('❌ Error in Bloc: ${e.toString()}'); // 👀 Debugging
      // Emit clean error message without "Exception:" prefix
      emit(const LoginState.failure('Invalid Username or Password'));
    }
  }

  Future<void> _onLogout(Logout event, Emitter<LoginState> emit) async {
    // Disconnect chat socket to prevent using old user's token
    try {
      await ChatSocketService().disconnect();
      print('🔌 Chat socket disconnected on logout');
    } catch (e) {
      print('⚠️ Error disconnecting chat socket: $e');
    }

    await clearUserData();
    emit(const LoginState.initial());
  }

  Future<void> _onCheckLoginStatus(
      CheckLoginStatus event, Emitter<LoginState> emit) async {
    emit(const LoginState.loading());

    // Persist login until explicit logout: check for stored token
    final String? token = await getToken();
    final String? username = await getUserName();

    if (token != null && token.isNotEmpty) {
      emit(LoginState.success(username: username ?? ''));
    } else {
      emit(const LoginState.initial());
    }
  }

  Future<void> _onForgotPassword(
      ForgotPassword event, Emitter<LoginState> emit) async {
    emit(const LoginState.forgotPasswordLoading());

    try {
      await authRepository.forgotPassword(event.email);
      emit(const LoginState.forgotPasswordSuccess());
    } catch (e) {
      emit(LoginState.forgotPasswordFailure(e.toString()));
    }
  }
}
