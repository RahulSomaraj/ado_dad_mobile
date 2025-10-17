import 'package:ado_dad_user/common/api_service.dart';
import 'package:ado_dad_user/common/shared_pref.dart';
import 'package:ado_dad_user/models/login_response_model.dart';
import 'package:dio/dio.dart';

class AuthRepository {
  final Dio _dio = ApiService().dio;

  Future<LoginResponse> login(String username, String password) async {
    try {
      final response = await _dio.post('auth/login', data: {
        'username': username,
        'password': password,
      });
      print(response.data);
      if (response.statusCode == 201) {
        final loginResponse = LoginResponse.fromJson(response.data);

        await saveLoginResponse(loginResponse);
        return loginResponse;
      } else {
        throw Exception("Login failed: ${response.statusMessage}");
      }
    } on DioException catch (e) {
      throw Exception(DioErrorHandler.handleError(e));
    } catch (e) {
      throw Exception("Unexpected error: ${e.toString()}");
    }
  }

  Future<void> forgotPassword(String email) async {
    try {
      final response = await _dio.post('users/forgot-password', data: {
        'email': email,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Success - password reset email sent
        return;
      } else {
        throw Exception(
            "Failed to send password reset email: ${response.statusMessage}");
      }
    } on DioException catch (e) {
      throw Exception(DioErrorHandler.handleError(e));
    } catch (e) {
      throw Exception("Unexpected error: ${e.toString()}");
    }
  }
}
