import 'dart:convert';
import 'dart:typed_data';

import 'package:ado_dad_user/common/api_service.dart';
import 'package:ado_dad_user/models/advertisement_model/add_model.dart';
import 'package:ado_dad_user/models/advertisement_post_model/vehicle_fuel_type_model.dart';
import 'package:ado_dad_user/models/advertisement_post_model/vehicle_manufacturer_model.dart';
import 'package:ado_dad_user/models/advertisement_post_model/vehicle_transmission_type_model.dart';
import 'package:ado_dad_user/models/advertisement_post_model/vehicle_variant_model.dart';
import 'package:ado_dad_user/models/advertisement_post_model/vehilce_model.dart';
import 'package:dio/dio.dart';
import 'package:mime/mime.dart';

class AddRepository {
  final Dio _dio = ApiService().dio;

  Future<PaginatedAdsResponse> fetchAllAds({
    int page = 1,
    int limit = 20,
    String? category,
    int? minYear,
    int? maxYear,
    List<String>? manufacturerIds,
    List<String>? modelIds,
    List<String>? fuelTypeIds,
    List<String>? transmissionTypeIds,
    int? minPrice,
    int? maxPrice,
    // Property-specific filters
    List<String>? propertyTypes,
    int? minBedrooms,
    int? maxBedrooms,
    int? minArea,
    int? maxArea,
    bool? isFurnished,
    bool? hasParking,
    // Location-based filters
    double? latitude,
    double? longitude,
  }) async {
    try {
      final body = <String, dynamic>{
        'page': page,
        'limit': limit,
        if (category != null) 'category': category,
        if (minYear != null) 'minYear': minYear,
        if (maxYear != null) 'maxYear': maxYear,
        if (minPrice != null) 'minPrice': minPrice,
        if (maxPrice != null) 'maxPrice': maxPrice,
        if (manufacturerIds != null && manufacturerIds.isNotEmpty)
          'manufacturerIds': manufacturerIds,
        if (modelIds != null && modelIds.isNotEmpty) 'modelIds': modelIds,
        if (fuelTypeIds != null && fuelTypeIds.isNotEmpty)
          'fuelTypeIds': fuelTypeIds, // ✅ plural
        if (transmissionTypeIds != null && transmissionTypeIds.isNotEmpty)
          'transmissionTypeIds': transmissionTypeIds, // ✅ plural
        // Property-specific filters
        if (propertyTypes != null && propertyTypes.isNotEmpty)
          'propertyTypes': propertyTypes,
        if (minBedrooms != null) 'minBedrooms': minBedrooms,
        if (maxBedrooms != null) 'maxBedrooms': maxBedrooms,
        if (minArea != null) 'minArea': minArea,
        if (maxArea != null) 'maxArea': maxArea,
        if (isFurnished != null) 'isFurnished': isFurnished,
        if (hasParking != null) 'hasParking': hasParking,
        // Location-based filters
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      };

      // if (manufacturerIds != null && manufacturerIds.isNotEmpty) {
      //   qp['manufacturerIds'] = manufacturerIds;
      // }
      // if (fuelTypeIds != null && fuelTypeIds.isNotEmpty) {
      //   qp['fuelTypeId'] = fuelTypeIds;
      // }
      // if (transmissionTypeIds != null && transmissionTypeIds.isNotEmpty) {
      //   qp['transmissionTypeId'] = transmissionTypeIds;
      // }

      final response = await _dio.post(
        '/v2/ads/list',
        // queryParameters: qp,
        data: body,
      );
      print("📡 Full API response qp:............... ${response.data}");
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

  Future<List<VehicleTransmissionType>> fetchVehicleTransmissionTypes() async {
    final resp = await _dio.get(
      '/vehicle-inventory/transmission-types',
      options: Options(responseType: ResponseType.json),
    );

    dynamic raw = resp.data;

    // If backend sent text/plain, decode it
    if (raw is String) {
      raw = jsonDecode(raw);
    }

    // Accept either top-level list or { data: [...] }
    List list;
    if (raw is List) {
      list = raw;
    } else if (raw is Map<String, dynamic> && raw['data'] is List) {
      list = raw['data'] as List;
    } else {
      // Helpful debug to see what came back
      throw StateError('Unexpected response: ${raw.runtimeType} -> $raw');
    }

    return list
        .whereType<Map<String, dynamic>>()
        .map((e) => VehicleTransmissionType.fromJson(e))
        .toList();
  }

  Future<List<VehicleFuelType>> fetchVehicleFuelTypes() async {
    final resp = await _dio.get(
      '/vehicle-inventory/fuel-types',
      options: Options(responseType: ResponseType.json),
    );

    dynamic raw = resp.data;

    // If backend sent text/plain, decode it
    if (raw is String) {
      raw = jsonDecode(raw);
    }

    // Accept either top-level list or { data: [...] }
    List list;
    if (raw is List) {
      list = raw;
    } else if (raw is Map<String, dynamic> && raw['data'] is List) {
      list = raw['data'] as List;
    } else {
      // Helpful debug to see what came back
      throw StateError('Unexpected response: ${raw.runtimeType} -> $raw');
    }

    return list
        .whereType<Map<String, dynamic>>()
        .map((e) => VehicleFuelType.fromJson(e))
        .toList();
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

  Future<String?> uploadVideoToS3(Uint8List fileBytes) async {
    try {
      final mimeType = lookupMimeType('video.mp4', headerBytes: fileBytes);
      final fileExtension = mimeType?.split('/').last ?? 'mp4';
      final fileName =
          'video_${DateTime.now().millisecondsSinceEpoch}.$fileExtension';

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
      print('❌ Unexpected error in uploadVideoToS3: $e');
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

  Future<List<VehicleModel>> fetchModals() async {
    final response = await _dio.get('/vehicle-inventory/models');
    final List data = response.data['data'];
    return data
        .map((e) => VehicleModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<AddModel> fetchAdDetail(String adId) async {
    try {
      final response = await _dio.get('/v2/ads/$adId');
      print("Ad detail API raw response: ${response.data}");
      final raw = response.data;

      // Accept either {data: {...}} or plain {...}
      final obj =
          (raw is Map<String, dynamic> && raw['data'] is Map<String, dynamic>)
              ? raw['data'] as Map<String, dynamic>
              : (raw as Map<String, dynamic>);

      return AddModel.fromJson(obj);
    } on DioException catch (e) {
      print('❌ Dio error : $e');
      throw Exception(DioErrorHandler.handleError(e));
    } catch (e) {
      print('Error:>>>>>>>>>>>>>>>>>>>>>>>$e');
      throw Exception('Failed to fetch ad detail: $e');
    }
  }

  Future<void> updateAd(String adId,
      {required String category, required Map<String, dynamic> data}) async {
    try {
      final resp = await _dio.put(
        '/ads/$adId',
        // data: data,
        data: {
          'category': category, // ✅ top-level
          'data': data, // ✅ nested fields
        },
      );
      if (resp.statusCode != 200) throw Exception('Update failed');
    } on DioException catch (e) {
      print('Dio Error: $e');
      throw Exception(DioErrorHandler.handleError(e));
    }
  }

  Future<AddModel> markAdAsSold(String adId) async {
    try {
      print('🔍 Marking ad as sold - Ad ID: $adId');
      print('🔍 Base URL: ${_dio.options.baseUrl}');
      print('🔍 Full URL will be: ${_dio.options.baseUrl}ads/$adId/sold');
      print('🔍 Trying v2 endpoint: ${_dio.options.baseUrl}v2/ads/$adId/sold');
      print('🔍 Request data: {"soldOut": true}');

      final resp = await _dio.put(
        '/ads/$adId/sold',
        data: {
          'soldOut': true,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      print('✅ Mark as sold response: ${resp.statusCode} - ${resp.data}');

      // Accept various success status codes (200, 201, 204, etc.)
      if (resp.statusCode! < 200 || resp.statusCode! >= 300) {
        throw Exception(
            'Failed to mark ad as sold - Status: ${resp.statusCode}');
      }

      // Parse and return the updated ad data from the response
      final raw = resp.data;
      final obj =
          (raw is Map<String, dynamic> && raw['data'] is Map<String, dynamic>)
              ? raw['data'] as Map<String, dynamic>
              : (raw as Map<String, dynamic>);

      return AddModel.fromJson(obj);
    } on DioException catch (e) {
      print('❌ Dio error in markAdAsSold (v1): $e');
      print('❌ Response data: ${e.response?.data}');
      print('❌ Response status: ${e.response?.statusCode}');
      print('❌ Request URL: ${e.requestOptions.uri}');

      // If v1 fails with 404, try v2 endpoint
      if (e.response?.statusCode == 404) {
        print('🔄 Trying v2 endpoint...');
        try {
          final resp2 = await _dio.put(
            '/v2/ads/$adId/sold',
            data: {
              'soldOut': true,
            },
            options: Options(
              headers: {
                'Content-Type': 'application/json',
              },
            ),
          );
          print(
              '✅ Mark as sold response (v2): ${resp2.statusCode} - ${resp2.data}');

          if (resp2.statusCode! < 200 || resp2.statusCode! >= 300) {
            throw Exception(
                'Failed to mark ad as sold - Status: ${resp2.statusCode}');
          }

          // Parse and return the updated ad data from the v2 response
          final raw2 = resp2.data;
          final obj2 = (raw2 is Map<String, dynamic> &&
                  raw2['data'] is Map<String, dynamic>)
              ? raw2['data'] as Map<String, dynamic>
              : (raw2 as Map<String, dynamic>);

          return AddModel.fromJson(obj2);
        } catch (e2) {
          print('❌ Dio error in markAdAsSold (v2): $e2');
          if (e2 is DioException) {
            print('❌ Response data: ${e2.response?.data}');
            print('❌ Response status: ${e2.response?.statusCode}');
          }
        }
      }

      throw Exception(DioErrorHandler.handleError(e));
    }
  }
}

class PaginatedAdsResponse {
  final List<AddModel> data;
  final bool hasNext;

  PaginatedAdsResponse({required this.data, required this.hasNext});
}
