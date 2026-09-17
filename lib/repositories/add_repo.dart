import 'dart:async';
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
import 'package:ado_dad_user/services/location_service.dart';
import 'package:dio/dio.dart';
import 'package:mime/mime.dart';

/// One cached ads page plus the moment it was stored.
class _AdsCacheEntry {
  _AdsCacheEntry(this.value) : storedAt = DateTime.now();

  final PaginatedAdsResponse value;
  final DateTime storedAt;

  bool get isFresh => DateTime.now().difference(storedAt) < AdsCache.freshFor;
  bool get isUsable => DateTime.now().difference(storedAt) < AdsCache.keepFor;
}

/// Memory cache + in-flight dedupe for `/v2/ads/list`.
///
/// Before this, every navigation was a cold fetch: Home → category → back →
/// search all hit the network with identical parameters seconds apart, because
/// the repository was a stateless pass-through to Dio.
///
/// Three behaviours, in the order they matter:
/// * **dedupe** — two screens asking for the same key at the same moment share
///   one request instead of racing.
/// * **fresh hit** — inside [freshFor] the cached page is returned outright.
/// * **stale-while-revalidate** — between [freshFor] and [keepFor] the stale
///   page is returned *immediately* and a refresh runs behind it, so the next
///   read of that key is current. The caller is never made to wait for it.
class AdsCache {
  AdsCache._();
  static final AdsCache instance = AdsCache._();

  static const Duration freshFor = Duration(seconds: 90);
  static const Duration keepFor = Duration(minutes: 5);
  static const int maxEntries = 48;

  /// Insertion-ordered, so the oldest key is the first one `keys` yields.
  final Map<String, _AdsCacheEntry> _entries = <String, _AdsCacheEntry>{};
  final Map<String, Future<PaginatedAdsResponse>> _inFlight =
      <String, Future<PaginatedAdsResponse>>{};

  /// Coordinates are bucketed to 2 dp (~1.1 km) so that tiny GPS jitter does
  /// not produce a different key — and therefore a different request — for
  /// what is the same query.
  static String buildKey(Map<String, dynamic> body) {
    final keys = body.keys.toList()..sort();
    final parts = keys.map((k) {
      final v = body[k];
      if ((k == 'latitude' || k == 'longitude') && v is num) {
        return '$k=${v.toStringAsFixed(2)}';
      }
      if (v is List) {
        return '$k=${(v.map((e) => '$e').toList()..sort()).join(',')}';
      }
      return '$k=$v';
    });
    return parts.join('&');
  }

  PaginatedAdsResponse? peek(String key) {
    final entry = _entries[key];
    if (entry == null) return null;
    if (!entry.isUsable) {
      _entries.remove(key);
      return null;
    }
    return entry.value;
  }

  bool isFresh(String key) => _entries[key]?.isFresh ?? false;

  Future<PaginatedAdsResponse>? inFlight(String key) => _inFlight[key];

  Future<PaginatedAdsResponse> track(
      String key, Future<PaginatedAdsResponse> request) {
    // NOTE: the callback body must be a block, not an arrow. `Map.remove`
    // returns the removed value — which here is `tracked` itself — and
    // `whenComplete` waits on a Future returned by its callback. An arrow body
    // therefore made the future wait for itself and never complete: the
    // response arrived, no error was thrown, and every caller's `await` hung.
    final tracked = request.then((value) {
      store(key, value);
      return value;
    }).whenComplete(() {
      _inFlight.remove(key);
    });
    _inFlight[key] = tracked;
    return tracked;
  }

  void store(String key, PaginatedAdsResponse value) {
    _entries.remove(key); // re-insert so ordering reflects recency
    _entries[key] = _AdsCacheEntry(value);
    while (_entries.length > maxEntries) {
      _entries.remove(_entries.keys.first);
    }
  }

  /// Called on logout and whenever the user's own action makes the cached
  /// pages wrong (posting, deleting or marking an ad sold).
  void clear() {
    _entries.clear();
    _inFlight.clear();
  }
}

/// Session cache for `/vehicle-inventory/*` lookups.
///
/// Manufacturers, models, fuel types, transmission types and commercial-vehicle
/// types are effectively immutable, yet the filter sheet refetched all five on
/// every open because each bloc fires `load()` from its constructor. Holding
/// the Future (not the value) also dedupes the five parallel calls a single
/// sheet open makes.
class _ReferenceCache {
  static final Map<String, Future<dynamic>> _futures =
      <String, Future<dynamic>>{};

  static Future<T> get<T>(String key, Future<T> Function() load) {
    final existing = _futures[key];
    if (existing != null) return existing as Future<T>;

    final future = load();
    _futures[key] = future;
    // A failed lookup must not be cached, or the filter sheet stays broken for
    // the rest of the session. This listener swallows nothing — the caller's
    // copy of the future still carries the error — it only evicts the key.
    future.then<void>((_) {}, onError: (Object _) {
      _futures.remove(key);
    });
    return future;
  }

  static void clear() => _futures.clear();
}

class AddRepository {
  final Dio _dio = ApiService().dio;

  /// Drops every cached ads page. Call after any write that changes what the
  /// lists should show.
  static void invalidateAdsCache() => AdsCache.instance.clear();

  /// Drops cached reference data (filter dropdowns). Rarely needed.
  static void invalidateReferenceCache() => _ReferenceCache.clear();

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

    /// Set by pull-to-refresh: skip the cache and go to the network.
    bool forceRefresh = false,
  }) async {
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

    final cache = AdsCache.instance;
    final key = AdsCache.buildKey(body);

    if (forceRefresh) {
      return cache.track(
          key, _fetchAdsFromNetwork(body, commercialVehicleTypes));
    }

    // Two screens asking for the same page at the same moment share one request.
    final inFlight = cache.inFlight(key);
    if (inFlight != null) return inFlight;

    final cached = cache.peek(key);
    if (cached != null) {
      if (!cache.isFresh(key)) {
        // Stale but usable: hand it back now, refresh behind it. The caller
        // never waits for this, and a failure leaves the stale copy in place.
        unawaited(
          cache
              .track(key, _fetchAdsFromNetwork(body, commercialVehicleTypes))
              .catchError((_) => cached),
        );
      }
      return cached;
    }

    return cache.track(key, _fetchAdsFromNetwork(body, commercialVehicleTypes));
  }

  Future<PaginatedAdsResponse> _fetchAdsFromNetwork(
    Map<String, dynamic> body,
    List<String>? commercialVehicleTypes,
  ) async {
    final int page = body['page'] as int? ?? 1;
    final int limit = body['limit'] as int? ?? 20;
    try {
      final response = await _dio.post(
        '/v2/ads/list',
        // queryParameters: qp,
        data: body,
      );
      final List<dynamic> rawData = response.data['data'];

      // Trust the server's hasNext when it sends one. The total-derived
      // fallback is wrong whenever `total` is absent (the server omits it for
      // property/vehicle-filtered queries) and it is computed before the
      // client-side filter below shrinks the page, which made the list keep
      // reporting "more available" while rendering near-empty pages.
      final bool hasNext = response.data['hasNext'] is bool
          ? response.data['hasNext'] as bool
          : (response.data['total'] is num
              ? (page * limit) < (response.data['total'] as num)
              : rawData.length >= limit);

      final ads = rawData
          .map((e) => AddModel.fromJson(e as Map<String, dynamic>))
          .toList();

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
    int asInt(dynamic v) =>
        v is int ? v : (v is num ? v.toInt() : int.tryParse('${v ?? 0}') ?? 0);
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
    // Radius filter (audit 4.5); ignored unless both coordinates are set.
    double? latitude,
    double? longitude,
    double? maxDistance,
  }) async {
    try {
      final withRadius = latitude != null && longitude != null && maxDistance != null;
      final body = <String, dynamic>{
        'page': 1,
        'limit': 1,
        if (withRadius) 'latitude': latitude,
        if (withRadius) 'longitude': longitude,
        if (withRadius) 'maxDistance': maxDistance,
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

  /// Session-cached: this walks every page of the manufacturer list, so an
  /// uncached call is several round trips — and the filter sheet asked for it
  /// on every open.
  Future<List<VehicleManufacturer>> fetchManufacturers({
    String? search,
    String? vehicleCategory,
  }) {
    return _ReferenceCache.get(
      'manufacturers|$search|$vehicleCategory',
      () => _fetchManufacturersFromNetwork(
          search: search, vehicleCategory: vehicleCategory),
    );
  }

  Future<List<VehicleManufacturer>> _fetchManufacturersFromNetwork({
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
      {String? search}) {
    return _ReferenceCache.get(
      'models|$manufacturerId|$search',
      () => _fetchModelsFromNetwork(manufacturerId, search: search),
    );
  }

  Future<List<VehicleModel>> _fetchModelsFromNetwork(String manufacturerId,
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

  Future<List<VehicleTransmissionType>> fetchVehicleTransmissionTypes({
    String? vehicleCategory,
  }) {
    return _ReferenceCache.get(
      'transmissionTypes|$vehicleCategory',
      () =>
          _fetchTransmissionTypesFromNetwork(vehicleCategory: vehicleCategory),
    );
  }

  Future<List<VehicleTransmissionType>> _fetchTransmissionTypesFromNetwork({
    String? vehicleCategory,
  }) async {
    final queryParameters = <String, dynamic>{};
    // Add category parameter if provided (mirrors fetchManufacturers)
    if (vehicleCategory != null && vehicleCategory.isNotEmpty) {
      queryParameters['vehicleCategory'] = vehicleCategory;
      queryParameters['category'] =
          vehicleCategory; // same key fetchManufacturers uses
    }

    final resp = await _dio.get(
      '/vehicle-inventory/transmission-types',
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
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

  Future<List<VehicleFuelType>> fetchVehicleFuelTypes({
    String? vehicleCategory,
  }) {
    return _ReferenceCache.get(
      'fuelTypes|$vehicleCategory',
      () => _fetchFuelTypesFromNetwork(vehicleCategory: vehicleCategory),
    );
  }

  Future<List<VehicleFuelType>> _fetchFuelTypesFromNetwork({
    String? vehicleCategory,
  }) async {
    final queryParameters = <String, dynamic>{};
    // Add category parameter if provided (mirrors fetchManufacturers)
    if (vehicleCategory != null && vehicleCategory.isNotEmpty) {
      queryParameters['vehicleCategory'] = vehicleCategory;
      queryParameters['category'] =
          vehicleCategory; // same key fetchManufacturers uses
    }

    final resp = await _dio.get(
      '/vehicle-inventory/fuel-types',
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
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

  Future<List<CommercialVehicleType>> fetchCommercialVehicleTypes() {
    return _ReferenceCache.get(
      'commercialVehicleTypes',
      _fetchCommercialVehicleTypesFromNetwork,
    );
  }

  Future<List<CommercialVehicleType>>
      _fetchCommercialVehicleTypesFromNetwork() async {
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
      );

      if (uploadResponse.statusCode == 200 ||
          uploadResponse.statusCode == 204) {
        final videoUrl = signedUrl.split('?').first;
        return videoUrl;
      } else {
        throw Exception('Upload failed: ${uploadResponse.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception(DioErrorHandler.handleError(e));
    } catch (e) {
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
      final response = await _dio.post('/ads', data: payload);
      if (response.statusCode == 200 || response.statusCode == 201) {
        // The cached list pages no longer reflect reality.
        AdsCache.instance.clear();
      } else {
        throw Exception('Failed to post ad');
      }
    } on DioException catch (e) {
      throw Exception(DioErrorHandler.handleError(e));
    } catch (e) {
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
        AdsCache.instance.clear();
      } else {
        throw Exception('Failed to delete ad');
      }
    } on DioException catch (e) {
      throw Exception(DioErrorHandler.handleError(e));
    } catch (e) {
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
      // Send the already-known position (never wakes the GPS) so the response
      // carries `distance`. The endpoint ignores missing/invalid coordinates.
      Map<String, dynamic>? query;
      try {
        final seed = await LocationService().seedPosition();
        if (seed != null) {
          query = {
            'lat': seed.latitude.toStringAsFixed(4),
            'lng': seed.longitude.toStringAsFixed(4),
          };
        }
      } catch (_) {}
      final response = await _dio.get('/v2/ads/$adId', queryParameters: query);
      final raw = response.data;

      // Accept either {data: {...}} or plain {...}
      final obj =
          (raw is Map<String, dynamic> && raw['data'] is Map<String, dynamic>)
              ? raw['data'] as Map<String, dynamic>
              : (raw as Map<String, dynamic>);

      // Print the parsed ad detail JSON data

      return AddModel.fromJson(obj);
    } on DioException catch (e) {
      throw Exception(DioErrorHandler.handleError(e));
    } catch (e) {
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
      AdsCache.instance.clear();
    } on DioException catch (e) {
      throw Exception(DioErrorHandler.handleError(e));
    }
  }

  Future<AddModel> markAdAsSold(String adId) async {
    try {
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

      // Accept various success status codes (200, 201, 204, etc.)
      if (resp.statusCode! < 200 || resp.statusCode! >= 300) {
        throw Exception(
            'Failed to mark ad as sold - Status: ${resp.statusCode}');
      }
      AdsCache.instance.clear();

      // Parse and return the updated ad data from the response
      final raw = resp.data;
      final obj =
          (raw is Map<String, dynamic> && raw['data'] is Map<String, dynamic>)
              ? raw['data'] as Map<String, dynamic>
              : (raw as Map<String, dynamic>);

      return AddModel.fromJson(obj);
    } on DioException catch (e) {
      // If v1 fails with 404, try v2 endpoint
      if (e.response?.statusCode == 404) {
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
          if (e2 is DioException) {}
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
      throw Exception("Error fetching ads by user ID: $e");
    }
  }
}

class PaginatedAdsResponse {
  final List<AddModel> data;
  final bool hasNext;

  PaginatedAdsResponse({required this.data, required this.hasNext});
}
