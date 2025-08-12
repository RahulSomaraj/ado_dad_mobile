import 'dart:async';

import 'package:ado_dad_user/common/shared_pref.dart';
import 'package:ado_dad_user/repositories/login_repository.dart';
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
  }

  Future<void> _onLogin(Login event, Emitter<LoginState> emit) async {
    emit(const LoginState.loading());

    try {
      final response =
          await authRepository.login(event.username, event.password);
      emit(LoginState.success(username: response.name));
      print('response:.............:${event.username}');
    } catch (e) {
      // emit(const LoginState.failure('Invalid Username or Password'));
      print('❌ Error in Bloc: ${e.toString()}'); // 👀 Debugging
      emit(LoginState.failure(e.toString())); // Emit actual error message
    }
  }

  Future<void> _onLogout(Logout event, Emitter<LoginState> emit) async {
    await clearUserData();
    emit(const LoginState.initial());
  }

  Future<void> _onCheckLoginStatus(
      CheckLoginStatus event, Emitter<LoginState> emit) async {
    emit(const LoginState.loading());

    final sharedPrefs = SharedPrefs();
    final isExpired = await sharedPrefs.isLoginExpired(); // 👈 New line

    if (isExpired) {
      await clearUserData(); // 👈 Clear all old login data
      emit(const LoginState.initial()); // 👈 Not logged in
      print("🔐 Session expired. Redirecting to login...");
      return;
    }
    final String? username = await getUserName();
    // final String? userType = await getUserType();

    if (username != null) {
      emit(LoginState.success(username: username));
    } else {
      emit(const LoginState.initial());
    }
  }
}
