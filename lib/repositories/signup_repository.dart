import 'dart:typed_data';

import 'package:ado_dad_user/common/api_service.dart';
import 'package:ado_dad_user/models/signup_model.dart';
import 'package:dio/dio.dart';
import 'package:mime/mime.dart';

class SignupRepository {
  final Dio _dio = ApiService().dio;

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

  Future<String> signup(SignupModel userData) async {
    try {
      print('Hiii');
      final payload = userData.toJson();
      print("📤 Signup payload: $payload");
      final response = await _dio.post(
        "/users",
        data: payload,
        // options: Options(
        //     // headers: {
        //     //   "Content-Type": "application/json",
        //     // },
        //     ),
      );

      print(response.statusCode);
      print('response:.......${response.data}');
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
