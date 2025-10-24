import 'dart:typed_data';

import 'package:ado_dad_user/common/api_service.dart';
import 'package:ado_dad_user/common/shared_pref.dart';
import 'package:ado_dad_user/models/profile_model.dart';
import 'package:dio/dio.dart';
import 'package:mime/mime.dart';

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

  Future<String?> uploadImageToS3(Uint8List fileBytes) async {
    try {
      final mimeType = lookupMimeType('image.jpg', headerBytes: fileBytes);
      final fileExtension = mimeType?.split('/').last ?? 'jpg';
      final fileName =
          'image_${DateTime.now().millisecondsSinceEpoch}.$fileExtension';

      // Step 1: Get presigned URL
      final signedUrlResponse = await _dio.get(
        '/upload/presigned-url',
        queryParameters: {
          'fileName': fileName,
          'fileType': mimeType,
        },
      );

      final signedUrl = signedUrlResponse.data['url'];
      if (signedUrl == null) throw Exception('No signed URL received');

      // Step 2: Upload to S3
      final uploadResponse = await Dio().put(
        signedUrl,
        data: fileBytes,
        options: Options(headers: {
          'Content-Type': mimeType,
          'Content-Length': fileBytes.length.toString(),
        }),
      );

      if (uploadResponse.statusCode == 200 ||
          uploadResponse.statusCode == 204) {
        return signedUrl.split('?').first;
      } else {
        throw Exception('Upload failed: ${uploadResponse.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception(DioErrorHandler.handleError(e));
    } catch (e) {
      print('❌ Unexpected error in uploadImageToS3: $e');
      throw Exception('Unexpected error: $e');
    }
  }

  // 🔹 Update User Profile
  // Future<void> updateUserProfile(UserProfile updatedProfile) async {
  //   try {
  //     final userId = await SharedPrefs().getUserId();
  //     if (userId == null) throw Exception("User ID not found.");

  //     Map<String, dynamic> body = updatedProfile.toJson();

  //     body.remove("_id"); // Some APIs don't require `_id` in body

  //     print("🟢 Sending PUT request to: /users/$userId");
  //     print("📝 Request Body: ${jsonEncode(body)}");

  //     final response = await _dio.put(
  //       "/users/$userId", // PUT request with user ID
  //       data: jsonEncode(body),
  //     );
  //     print('Hiiiiiiiiiiii');
  //     fetchUserProfile();
  //     print('Hellooooooo');
  //     print(response.statusCode);
  //     if (response.statusCode != 200) {
  //       throw Exception("Failed to update profile.");
  //     }
  //   } on DioException catch (e) {
  //     throw Exception(DioErrorHandler.handleError(e));
  //   } catch (e) {
  //     print('errrrrrrrrrrrrrrrrrrr');
  //     print(e);
  //     print('errrrrrrrrrrrrrrrrrr');
  //     throw Exception("Error updating profile: $e");
  //   }
  // }

  Future<void> updateUserProfile(UserProfile updatedProfile) async {
    try {
      final userId = await SharedPrefs().getUserId();
      if (userId == null) throw Exception("User ID not found.");

      // Get the original profile to compare changes
      final originalProfile = await fetchUserProfile();

      // Build body with only changed fields
      final body = <String, dynamic>{};

      if (updatedProfile.name != originalProfile.name) {
        body['name'] = updatedProfile.name;
        print(
            "📝 Name changed: ${originalProfile.name} → ${updatedProfile.name}");
      }

      if (updatedProfile.email != originalProfile.email) {
        body['email'] = updatedProfile.email;
        print(
            "📝 Email changed: ${originalProfile.email} → ${updatedProfile.email}");
      }

      if (updatedProfile.phoneNumber != originalProfile.phoneNumber) {
        body['phoneNumber'] = updatedProfile.phoneNumber;
        print(
            "📝 Phone changed: ${originalProfile.phoneNumber} → ${updatedProfile.phoneNumber}");
      }

      if (updatedProfile.profilePic != originalProfile.profilePic) {
        body['profilePic'] = updatedProfile.profilePic;
        print(
            "📝 ProfilePic changed: ${originalProfile.profilePic} → ${updatedProfile.profilePic}");
      }

      // If no fields changed, don't send request
      if (body.isEmpty) {
        print("ℹ️ No changes detected, skipping update");
        return;
      }

      print("🟢 Sending PUT request to: /users/$userId");
      print("📝 Request Body (only changed fields): ${body}");

      // Validate profile picture URL if provided
      if (body.containsKey('profilePic') && body['profilePic'] != null) {
        final profilePicUrl = body['profilePic'] as String;
        print("📸 Profile picture URL: $profilePicUrl");

        // Check if it's a valid URL (starts with http/https) or default value
        if (profilePicUrl.isNotEmpty &&
            profilePicUrl != 'default-profile-pic-url' &&
            !profilePicUrl.startsWith('http')) {
          print("⚠️ Invalid profile picture URL format: $profilePicUrl");
          // Don't throw error, let backend handle it, but log the issue
        }
      }

      final response = await _dio.put(
        "/users/$userId",
        data: body, // ← pass Map, not jsonEncode
        options: Options(headers: {
          'Content-Type': 'application/json', // be explicit
        }),
      );

      print("✅ Profile update response: ${response.statusCode}");
      print("📄 Response data: ${response.data}");

      if (response.statusCode != 200) {
        throw Exception("Failed to update profile.");
      }
    } on DioException catch (e) {
      print("❌ DioException in updateUserProfile: ${e.response?.data}");

      // Provide more specific error messages for profile update failures
      if (e.response?.statusCode == 400) {
        final errorData = e.response?.data;
        if (errorData is Map<String, dynamic> &&
            errorData.containsKey('message')) {
          throw Exception("❌ ${errorData['message']}");
        }
        throw Exception(
            "❌ Invalid profile data. Please check your information and try again.");
      } else if (e.response?.statusCode == 500) {
        throw Exception(
            "❌ Server error while updating profile. Please try again or contact support if the issue persists.");
      }

      throw Exception(DioErrorHandler.handleError(e));
    } catch (e) {
      print("❌ General error in updateUserProfile: $e");
      throw Exception("Error updating profile: $e");
    }
  }

  Future<void> changePassword(String newPassword) async {
    try {
      final userId = await SharedPrefs().getUserId();
      if (userId == null) throw Exception("User ID not found.");

      final body = {
        "password": newPassword,
      };

      final response = await _dio.put(
        "/users/$userId",
        data: body,
        options: Options(headers: {
          'Content-Type': 'application/json',
        }),
      );

      print("✅ Password change response: ${response.statusCode}");
      print("📄 Response data: ${response.data}");

      if (response.statusCode != 200) {
        throw Exception("Failed to change password.");
      }
    } on DioException catch (e) {
      print("❌ DioException in changePassword: ${e.response?.data}");
      throw Exception(DioErrorHandler.handleError(e));
    } catch (e) {
      print("❌ General error in changePassword: $e");
      throw Exception("Error changing password: $e");
    }
  }
}
