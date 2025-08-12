import 'dart:convert';

import 'package:ado_dad_user/common/api_service.dart';
import 'package:ado_dad_user/common/shared_pref.dart';
import 'package:ado_dad_user/models/profile_model.dart';
import 'package:dio/dio.dart';

class ProfileRepo {
  final Dio _dio = ApiService().dio;
  Future<UserProfile> fetchUserProfile() async {
    try {
      // Retrieve user ID from SharedPreferences
      final userId = await SharedPrefs().getUserId();
      print("🔎 Retrieved User ID from SharedPrefs: $userId");

      if (userId == null) {
        throw Exception("User ID not found in storage");
      }

      final response = await _dio.get("/users/$userId");
      print('response......................:$response');

      if (response.statusCode == 200) {
        return UserProfile.fromJson(response.data);
      } else {
        throw Exception("Failed to load profile data");
      }
    } catch (e) {
      print('errrrrrrooooooorrrrrrrrrrr:$e');
      throw Exception("Error fetching profile: $e");
    }
  }

  // 🔹 Update User Profile
  Future<void> updateUserProfile(UserProfile updatedProfile) async {
    try {
      final userId = await SharedPrefs().getUserId();
      if (userId == null) throw Exception("User ID not found.");

      Map<String, dynamic> body = updatedProfile.toJson();

      body.remove("_id"); // Some APIs don't require `_id` in body

      print("🟢 Sending PUT request to: /users/$userId");
      print("📝 Request Body: ${jsonEncode(body)}");

      final response = await _dio.put(
        "/users/$userId", // PUT request with user ID
        data: jsonEncode(body),
      );
      print('Hiiiiiiiiiiii');
      fetchUserProfile();
      print('Hellooooooo');
      print(response.statusCode);
      if (response.statusCode != 200) {
        throw Exception("Failed to update profile.");
      }
    } on DioException catch (e) {
      throw Exception(DioErrorHandler.handleError(e));
    } catch (e) {
      print('errrrrrrrrrrrrrrrrrrr');
      print(e);
      print('errrrrrrrrrrrrrrrrrr');
      throw Exception("Error updating profile: $e");
    }
  }
}
