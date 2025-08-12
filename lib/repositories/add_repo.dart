import 'dart:typed_data';

import 'package:ado_dad_user/common/api_service.dart';
import 'package:ado_dad_user/models/advertisement_model/add_model.dart';
import 'package:ado_dad_user/models/advertisement_post_model/vehicle_manufacturer_model.dart';
import 'package:ado_dad_user/models/advertisement_post_model/vehicle_variant_model.dart';
import 'package:ado_dad_user/models/advertisement_post_model/vehilce_model.dart';
import 'package:dio/dio.dart';
import 'package:mime/mime.dart';

class AddRepository {
  final Dio _dio = ApiService().dio;

  Future<PaginatedAdsResponse> fetchAllAds({
    int page = 1,
    int limit = 20,
    String? categoryId,
    int? minYear,
    int? maxYear,
    List<String>? brands,
  }) async {
    try {
      final response = await _dio.get('/ads', queryParameters: {
        'page': page,
        'limit': limit,
        if (categoryId != null) 'category': categoryId,
        if (minYear != null) 'minYear': minYear,
        if (maxYear != null) 'maxYear': maxYear,
        if (brands != null && brands.isNotEmpty) 'brands': brands, // array
      });
      print("📡 Full API response:............... ${response.data}");
      // print("🔎 Raw listing items:");
      // (response.data['data'] as List).forEach((e) {
      //   print(
      //       "  ▶️ ID: ${e['id']} | Title: ${e['description']} | Images: ${e['images']}");
      // });

      final List<dynamic> rawData = response.data['data'];
      final total = response.data['total'] ?? 0;
      final currentCount = (page * limit);
      final hasNext = currentCount < total;

      final ads = rawData
          .map((e) => AddModel.fromJson(e as Map<String, dynamic>))
          .toList();
      print("📡 Full rawdata response:............... $rawData");

      print("📡 API returned hasNext: $hasNext, ads: ${ads.length}");

      return PaginatedAdsResponse(data: ads, hasNext: hasNext);
    } catch (e) {
      throw Exception('Failed to fetch ads: $e');
    }
  }

  Future<List<VehicleManufacturer>> fetchManufacturers() async {
    final response = await _dio.get('/vehicle-inventory/manufacturers');
    final List data = response.data['data'];
    return data
        .map((e) => VehicleManufacturer.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<VehicleModel>> fetchModelsByManufacturer(
      String manufacturerId) async {
    final response = await _dio.get(
      '/vehicle-inventory/models',
      queryParameters: {
        'manufacturerId': manufacturerId,
      },
    );

    final List data = response.data['data'];
    return data.map((e) => VehicleModel.fromJson(e)).toList();
  }

  Future<List<VehicleVariant>> fetchVariantsByModel(String modelId) async {
    final response = await _dio.get(
      '/vehicle-inventory/variants',
      queryParameters: {
        'modelId': modelId,
      },
    );

    final List data = response.data['data'];
    return data.map((e) => VehicleVariant.fromJson(e)).toList();
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

  Future<void> postAd({
    required String category,
    required Map<String, dynamic> data,
  }) async {
    try {
      final payload = {
        "category": category,
        "data": data,
      };
      print('Payload:.................. $payload');
      final response = await _dio.post('/ads', data: payload);
      print('New Item Id : ............................${response.data['id']}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Ad posted successfully');
      } else {
        print('⚠️ Failed to post ad, status: ${response.statusCode}');
        throw Exception('Failed to post ad');
      }
    } on DioException catch (e) {
      print('❌ Dio error : $e');
      throw Exception(DioErrorHandler.handleError(e));
    } catch (e) {
      print('❌ Unexpected error: $e');
      throw Exception('Failed to post ad: $e');
    }
  }
}

class PaginatedAdsResponse {
  final List<AddModel> data;
  final bool hasNext;

  PaginatedAdsResponse({required this.data, required this.hasNext});
}
