import 'dart:async';
import 'dart:typed_data';
import 'package:ado_dad_user/common/api_service.dart';
import 'package:ado_dad_user/data/dummy_data.dart';
import 'package:ado_dad_user/models/advertisement/advertisement_model.dart';
import 'package:ado_dad_user/models/advertisement/property_model.dart';
import 'package:ado_dad_user/models/advertisement/vehicle_model.dart';
import 'package:dio/dio.dart';
import 'package:mime/mime.dart';

class AdvertisementRepository {
  final Dio _dio = ApiService().dio;

  Future<AdvertisementModel?> addAdvertisement(
      AdvertisementModel advertisement) async {
    try {
      final Map<String, dynamic> advertisementJson = advertisement.toJson();
      print('??????????????????repository calling??????????????????');
      final response = await _dio
          .post('/advertisements', data: advertisementJson)
          .timeout(const Duration(seconds: 15));
      print('status code:................${response.statusCode}');

      if (response.statusCode == 201) {
        return AdvertisementModel.fromJson(response.data);
      } else {
        throw Exception('Failed to add advertisement');
      }
    } on DioException catch (e) {
      throw Exception(DioErrorHandler.handleError(e));
    } catch (e) {
      print("⚠️ Unhandled exception: $e (${e.runtimeType})");
      if (e is Map<String, dynamic>) {
        throw Exception("Unexpected error: ${e.toString()}");
      } else if (e is Exception) {
        throw e;
      } else {
        throw Exception("Unexpected error: ${e.runtimeType} → ${e.toString()}");
      }
    }

    // catch (e) {
    //   throw Exception("Unexpected error: ${e.toString()}");
    // }
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
        return signedUrl
            .split('?')
            .first; // ✅ Public URL (without query params)
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

  /// 🔁 Update image URLs of an advertisement after upload
  Future<void> updateAdvertisementImages({
    required String advertisementId,
    required List<String> imageUrls,
  }) async {
    try {
      final response = await _dio.put(
        '/advertisements/$advertisementId',
        data: {'imageUrls': imageUrls},
      );

      if (response.statusCode != 200) {
        throw Exception("Failed to update images: ${response.statusCode}");
      }
    } on DioException catch (e) {
      throw Exception(DioErrorHandler.handleError(e));
    }
  }

  Future<void> updatePersonalInfo({
    required String advertisementId,
    required String fullName,
    required String phoneNumber,
    required String state,
    required String city,
    required String district,
  }) async {
    try {
      final response = await _dio.put(
        '/advertisements/$advertisementId',
        data: {
          "fullName": fullName,
          "phoneNumber": phoneNumber,
          "state": state,
          "city": city,
          "district": district,
        },
      );
      print(
          'Personal info Status code:........?????????${response.statusCode}');
      if (response.statusCode != 200) {
        throw Exception(
            "Failed to update personal info: ${response.statusCode}");
      }
    } on DioException catch (e) {
      throw Exception(DioErrorHandler.handleError(e));
    }
  }

  Future<List<Vehicle>> fetchVehicles() async {
    await Future.delayed(const Duration(seconds: 2));
    return DummyData.vehicles;
  }

  Future<List<Property>> fetchProperties() async {
    await Future.delayed(const Duration(seconds: 2));
    return DummyData.properties;
  }

  Future<Vehicle?> fetchVehicleById(int index) async {
    await Future.delayed(const Duration(seconds: 1));
    if (index < DummyData.vehicles.length) {
      return DummyData.vehicles[index];
    }
    return null;
  }

  Future<Property?> fetchPropertyById(int index) async {
    await Future.delayed(const Duration(seconds: 1));
    if (index < DummyData.properties.length) {
      return DummyData.properties[index];
    }
    return null;
  }
}
