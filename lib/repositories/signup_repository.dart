import 'package:ado_dad_user/common/api_service.dart';
import 'package:ado_dad_user/models/signup_model.dart';
import 'package:dio/dio.dart';

class SignupRepository {
  final Dio _dio = ApiService().dio;

  Future<String> signup(SignupModel userData) async {
    try {
      print('Hiii');
      final response = await _dio.post(
        "/users",
        data: userData.toJson(),
        // options: Options(
        //     // headers: {
        //     //   "Content-Type": "application/json",
        //     // },
        //     ),
      );

      print(response.statusCode);
      print('response:.......$response');
      if (response.statusCode == 201) {
        return response.data['message'] ?? "Signed Up successfully";
      } else {
        throw Exception("Failed to signup: ${response.statusMessage}");
      }
    } on DioException catch (e) {
      print("errrererererererere");
      print(e);
      print("errrererererererere");

      if (e.response != null) {
        throw Exception(e.response!.data['message'] ?? "API error occurred");
      } else {
        throw Exception("Network error: ${e.message}");
      }
    } catch (e) {
      throw Exception("Unexpected error: $e");
    }
  }
}
