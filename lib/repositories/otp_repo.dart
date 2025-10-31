import 'package:ado_dad_user/common/api_service.dart';
import 'package:ado_dad_user/models/login_response_model.dart';
import 'package:ado_dad_user/common/shared_pref.dart';
import 'package:dio/dio.dart';

class OtpRepository {
  final Dio _dio = ApiService().dio;

  Future<void> sendOtp(String identifier) async {
    try {
      final response = await _dio.post(
        'users/send-otp',
        data: {
          'identifier': identifier,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Success - OTP sent
        return;
      } else {
        throw Exception("Failed to send OTP: ${response.statusMessage}");
      }
    } on DioException catch (e) {
      throw Exception(DioErrorHandler.handleError(e));
    } catch (e) {
      throw Exception("Unexpected error: ${e.toString()}");
    }
  }

  Future<LoginResponse> verifyOtp(String identifier, String otp) async {
    try {
      final response = await _dio.post(
        'users/verify-otp',
        data: {
          'identifier': identifier,
          'otp': otp,
        },
      );
      print(response.data);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final loginResponse = LoginResponse.fromJson(response.data);
        await saveLoginResponse(loginResponse);
        return loginResponse;
      } else {
        throw Exception("OTP verification failed: ${response.statusMessage}");
      }
    } on DioException catch (e) {
      throw Exception(DioErrorHandler.handleError(e));
    } catch (e) {
      throw Exception("Unexpected error: ${e.toString()}");
    }
  }
}
