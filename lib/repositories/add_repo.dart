import 'dart:convert';
import 'dart:typed_data';

import 'package:ado_dad_user/common/api_service.dart';
import 'package:ado_dad_user/models/advertisement_model/add_model.dart';
import 'package:ado_dad_user/models/advertisement_post_model/commercial_vehicle_type_model.dart';
import 'package:ado_dad_user/models/advertisement_post_model/vehicle_fuel_type_model.dart';
import 'package:ado_dad_user/models/advertisement_post_model/vehicle_manufacturer_model.dart';
import 'package:ado_dad_user/models/advertisement_post_model/vehicle_transmission_type_model.dart';
import 'package:ado_dad_user/models/advertisement_post_model/vehicle_variant_model.dart';
import 'package:ado_dad_user/models/advertisement_post_model/vehilce_model.dart';
import 'package:ado_dad_user/models/seller_stats.dart';
import 'package:dio/dio.dart';
import 'package:mime/mime.dart';

class AddRepository {
  final Dio _dio = ApiService().dio;

  Future<PaginatedAdsResponse> fetchAllAds({
    int page = 1,
    int limit = 20,
    String? search,
    String? category,
    int? minYear,
    int? maxYear,
    List<String>? manufacturerIds,
    List<String>? modelIds,
    List<String>? fuelTypeIds,
    List<String>? transmissionTypeIds,
    int? minPrice,
    int? maxPrice,
    List<String>? commercialVehicleTypes,
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
    double? maxDistance,
  }) async {
    try {
      final body = <String, dynamic>{
        'page': page,
        'limit': limit,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        if (category != null) 'category': category,
        if (commercialVehicleTypes != null && commercialVehicleTypes.isNotEmpty)
          'commercialVehicleTypes': commercialVehicleTypes,
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
        if (maxDistance != null) 'maxDistance': maxDistance,
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

      // Safety: backend may not apply commercialVehicleTypes filter consistently
      // since the field lives under commercialVehicleDetails in the v2 list response.
      // After fixing model mapping, we can also filter client-side when requested.
      final filteredAds =
          (commercialVehicleTypes != null && commercialVehicleTypes.isNotEmpty)
              ? ads
                  .where((ad) =>
                      (ad.commercialVehicleType ?? '').trim().isNotEmpty &&
                      commercialVehicleTypes
                          .contains((ad.commercialVehicleType ?? '').trim()))
                  .toList()
              : ads;

      return PaginatedAdsResponse(data: filteredAds, hasNext: hasNext);
    } catch (e) {
      throw Exception('Failed to fetch ads: $e');
    }
  }

  /// Accurate per-user counts for the profile stats strip
  /// (My ads / Wishlist / Chats). Backed by GET /v2/ads/me/stats.
  Future<Map<String, int>> fetchProfileStats() async {
    int asInt(dynamic v) => v is int
        ? v
        : (v is num ? v.toInt() : int.tryParse('${v ?? 0}') ?? 0);
    try {
      final response = await _dio.get('/v2/ads/me/stats');
      final data = (response.data as Map?) ?? const {};
      return {
        'ads': asInt(data['ads']),
        'wishlist': asInt(data['wishlist']),
        'chats': asInt(data['chats']),
      };
    } catch (_) {
      return {'ads': 0, 'wishlist': 0, 'chats': 0};
    }
  }

  /// Trust signals for a seller's ad-detail tile (ad count, member-since,
  /// reply time, verified). Backed by GET /v2/ads/sellers/:id/stats.
  /// Returns null on failure so callers fall back to ad-embedded data.
  Future<SellerStats?> fetchSellerStats(String sellerId) async {
    if (sellerId.trim().isEmpty) return null;
    try {
      final response = await _dio.get('/v2/ads/sellers/$sellerId/stats');
      final data = (response.data as Map?) ?? const {};
      return SellerStats.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  /// Lightweight count for the filter screens' live "Show N results" CTA.
  /// Reuses the same /v2/ads/list endpoint (which already returns `total`)
  /// with limit:1 so we only transfer one row.
  Future<int> fetchAdsCount({
    String? search,
    String? category,
    int? minYear,
    int? maxYear,
    List<String>? manufacturerIds,
    List<String>? modelIds,
    List<String>? fuelTypeIds,
    List<String>? transmissionTypeIds,
    int? minPrice,
    int? maxPrice,
    List<String>? commercialVehicleTypes,
    List<String>? propertyTypes,
    int? minBedrooms,
    int? maxBedrooms,
    int? minArea,
    int? maxArea,
    bool? isFurnished,
    bool? hasParking,
  }) async {
    try {
      final body = <String, dynamic>{
        'page': 1,
        'limit': 1,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        if (category != null) 'category': category,
        if (commercialVehicleTypes != null && commercialVehicleTypes.isNotEmpty)
          'commercialVehicleTypes': commercialVehicleTypes,
        if (minYear != null) 'minYear': minYear,
        if (maxYear != null) 'maxYear': maxYear,
        if (minPrice != null) 'minPrice': minPrice,
        if (maxPrice != null) 'maxPrice': maxPrice,
        if (manufacturerIds != null && manufacturerIds.isNotEmpty)
          'manufacturerIds': manufacturerIds,
        if (modelIds != null && modelIds.isNotEmpty) 'modelIds': modelIds,
        if (fuelTypeIds != null && fuelTypeIds.isNotEmpty)
          'fuelTypeIds': fuelTypeIds,
        if (transmissionTypeIds != null && transmissionTypeIds.isNotEmpty)
          'transmissionTypeIds': transmissionTypeIds,
        if (propertyTypes != null && propertyTypes.isNotEmpty)
          'propertyTypes': propertyTypes,
        if (minBedrooms != null) 'minBedrooms': minBedrooms,
        if (maxBedrooms != null) 'maxBedrooms': maxBedrooms,
        if (minArea != null) 'minArea': minArea,
        if (maxArea != null) 'maxArea': maxArea,
        if (isFurnished != null) 'isFurnished': isFurnished,
        if (hasParking != null) 'hasParking': hasParking,
      };
      final response = await _dio.post('/v2/ads/list', data: body);
      final total = response.data['total'];
      if (total is int) return total;
      if (total is num) return total.toInt();
      return int.tryParse('${total ?? 0}') ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<List<VehicleManufacturer>> fetchManufacturers({
    String? search,
    String? vehicleCategory,
  }) async {
    final List<VehicleManufacturer> allManufacturers = [];
    int page = 1;
    int limit = 20; // Fetch 20 items per page
    bool hasMore = true;

    while (hasMore) {
      final queryParameters = <String, dynamic>{
        'page': page,
        'limit': limit,
      };

      // Add search parameter if provided
      if (search != null && search.isNotEmpty) {
        queryParameters['search'] = search;
      }

      // Add category parameter if provided
      if (vehicleCategory != null && vehicleCategory.isNotEmpty) {
        queryParameters['category'] = vehicleCategory;
      }

      final response = await _dio.get(
        '/vehicle-inventory/manufacturers',
        queryParameters: queryParameters,
      );

      final responseData = response.data;
      final List data = responseData['data'] ?? [];

      final manufacturers = data
          .map((e) => VehicleManufacturer.fromJson(e as Map<String, dynamic>))
          .toList();

      allManufacturers.addAll(manufacturers);

      // Check if there are more pages
      final total = responseData['total'] ?? 0;
      final currentCount = page * limit;
      hasMore = currentCount < total && manufacturers.length == limit;

      // If no total is provided, check if we got fewer items than the limit
      if (total == 0 && manufacturers.length < limit) {
        hasMore = false;
      }

      page++;
    }

    return allManufacturers;
  }

  Future<List<VehicleModel>> fetchModelsByManufacturer(String manufacturerId,
      {String? search}) async {
    final List<VehicleModel> allModels = [];
    int page = 1;
    int limit = 20; // Fetch 20 items per page
    bool hasMore = true;

    while (hasMore) {
      final queryParameters = <String, dynamic>{
        'manufacturerId': manufacturerId,
        'page': page,
        'limit': limit,
      };

      // Add search parameter if provided
      if (search != null && search.isNotEmpty) {
        queryParameters['search'] = search;
      }

      final response = await _dio.get(
        '/vehicle-inventory/models',
        queryParameters: queryParameters,
      );

      final responseData = response.data;
      final List data = responseData['data'] ?? [];

      final models = data.map((e) => VehicleModel.fromJson(e)).toList();
      allModels.addAll(models);

      // Check if there are more pages
      final total = responseData['total'] ?? 0;
      final currentCount = page * limit;
      hasMore = currentCount < total && models.length == limit;

      // If no total is provided, check if we got fewer items than the limit
      if (total == 0 && models.length < limit) {
        hasMore = false;
      }

      page++;
    }

    return allModels;
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

  Future<List<CommercialVehicleType>> fetchCommercialVehicleTypes() async {
    final resp = await _dio.get(
      '/vehicle-inventory/commercial-vehicle-types',
      options: Options(responseType: ResponseType.json),
    );

    dynamic raw = resp.data;
    if (raw is String) {
      raw = jsonDecode(raw);
    }

    // Endpoint returns a top-level list (as per provided example),
    // but we also accept { data: [...] } for safety.
    List list;
    if (raw is List) {
      list = raw;
    } else if (raw is Map<String, dynamic> && raw['data'] is List) {
      list = raw['data'] as List;
    } else {
      throw StateError('Unexpected response: ${raw.runtimeType} -> $raw');
    }

    final items = list
        .whereType<Map<String, dynamic>>()
        .map((e) => CommercialVehicleType.fromJson(e))
        .where((t) => t.name.trim().isNotEmpty)
        .toList();

    items.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return items;
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

  /// Upload a file to S3 (e.g. chat image/audio). [filePrefix] e.g. 'image', 'audio'.
  Future<String?> uploadFileToS3(Uint8List fileBytes, String mimeType,
      {String filePrefix = 'file'}) async {
    try {
      final fileExtension = mimeType.split('/').last;
      final safeExt = fileExtension.length <= 4 ? fileExtension : 'bin';
      final fileName =
          '${filePrefix}_${DateTime.now().millisecondsSinceEpoch}.$safeExt';

      final signedUrlResponse = await _dio.get(
        '/upload/presigned-url',
        queryParameters: {
          'fileName': fileName,
          'fileType': mimeType,
        },
      );

      final signedUrl = signedUrlResponse.data['url'];
      if (signedUrl == null) throw Exception('No signed URL received');

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
      print('❌ Unexpected error in uploadFileToS3: $e');
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

      print('📹 Got presigned URL, starting S3 upload...');
      print('📹 File size: ${fileBytes.length} bytes');
      print('📹 MIME type: $mimeType');

      // Step 2: Upload to S3 with timeout
      final uploadDio = Dio();
      uploadDio.options.connectTimeout = const Duration(minutes: 5);
      uploadDio.options.receiveTimeout = const Duration(minutes: 5);
      uploadDio.options.sendTimeout =
          const Duration(minutes: 10); // Longer for large videos

      final uploadResponse = await uploadDio.put(
        signedUrl,
        data: fileBytes,
        options: Options(
          headers: {
            'Content-Type': mimeType,
            'Content-Length': fileBytes.length.toString(),
          },
          sendTimeout: const Duration(minutes: 10),
          receiveTimeout: const Duration(minutes: 5),
        ),
        onSendProgress: (sent, total) {
          if (total > 0) {
            final progress = (sent / total * 100).toStringAsFixed(1);
            print('📹 Upload progress: $progress% ($sent/$total bytes)');
          }
        },
      );

      print('📹 S3 upload response status: ${uploadResponse.statusCode}');

      if (uploadResponse.statusCode == 200 ||
          uploadResponse.statusCode == 204) {
        final videoUrl = signedUrl.split('?').first;
        print('✅ Video upload successful, URL: $videoUrl');
        return videoUrl;
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

  /// Delete an advertisement by ID.
  /// Backend endpoint: DELETE /ads/{id}
  Future<void> deleteAd(String adId) async {
    try {
      final response = await _dio.delete('/ads/$adId');

      if (response.statusCode == 200 ||
          response.statusCode == 204 ||
          response.statusCode == 202) {
        print('✅ Ad deleted successfully: $adId');
      } else {
        print('⚠️ Failed to delete ad, status: ${response.statusCode}');
        throw Exception('Failed to delete ad');
      }
    } on DioException catch (e) {
      print('❌ Dio error while deleting ad $adId: $e');
      throw Exception(DioErrorHandler.handleError(e));
    } catch (e) {
      print('❌ Unexpected error while deleting ad $adId: $e');
      throw Exception('Failed to delete ad: $e');
    }
  }

  Future<List<VehicleModel>> fetchModals({String? search}) async {
    final List<VehicleModel> allModels = [];
    int page = 1;
    int limit = 20; // Fetch 20 items per page
    bool hasMore = true;

    while (hasMore) {
      final queryParameters = <String, dynamic>{
        'page': page,
        'limit': limit,
      };

      // Add search parameter if provided
      if (search != null && search.isNotEmpty) {
        queryParameters['search'] = search;
      }

      final response = await _dio.get(
        '/vehicle-inventory/models',
        queryParameters: queryParameters,
      );

      final responseData = response.data;
      final List data = responseData['data'] ?? [];

      final models = data
          .map((e) => VehicleModel.fromJson(e as Map<String, dynamic>))
          .toList();

      allModels.addAll(models);

      // Check if there are more pages
      final total = responseData['total'] ?? 0;
      final currentCount = page * limit;
      hasMore = currentCount < total && models.length == limit;

      // If no total is provided, check if we got fewer items than the limit
      if (total == 0 && models.length < limit) {
        hasMore = false;
      }

      page++;
    }

    return allModels;
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

      // Print the parsed ad detail JSON data
      print('📦 Ad Detail Page - Item Data JSON Response:');
      print('   Ad ID: ${obj['id']}');
      print('   Title: ${obj['title']}');
      print('   Category: ${obj['category']}');
      print('   Price: ${obj['price']}');
      print('   Location: ${obj['location']}');
      print('   Video Link: ${obj['link']}');
      print('   Images Count: ${(obj['images'] as List?)?.length ?? 0}');
      print('   Full JSON Response: $obj');

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

  Future<PaginatedAdsResponse> fetchAdsByUserId({
    required String userId,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _dio.get(
        '/ads',
        queryParameters: {
          'userId': userId,
          'page': page,
          'limit': limit,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final List<dynamic> adsData = data['data'] ?? [];
        final bool hasNext = data['hasNext'] ?? false;

        final List<AddModel> ads =
            adsData.map((adJson) => AddModel.fromJson(adJson)).toList();

        return PaginatedAdsResponse(data: ads, hasNext: hasNext);
      } else {
        throw Exception("Failed to fetch ads for user");
      }
    } catch (e) {
      print('Error fetching ads by user ID: $e');
      throw Exception("Error fetching ads by user ID: $e");
    }
  }
}

class PaginatedAdsResponse {
  final List<AddModel> data;
  final bool hasNext;

  PaginatedAdsResponse({required this.data, required this.hasNext});
}
