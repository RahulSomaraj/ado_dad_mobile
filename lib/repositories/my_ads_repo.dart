import 'package:ado_dad_user/common/api_service.dart';
import 'package:ado_dad_user/common/shared_pref.dart';
import 'package:dio/dio.dart';
import 'package:ado_dad_user/models/my_ads_model.dart';
import 'package:ado_dad_user/models/advertisement_model/add_model.dart';

class MyAdsRepo {
  final Dio _dio = ApiService().dio;

  Future<PaginatedMyAdsResponse> fetchMyAds({
    int page = 1,
    int limit = 20,
    String sortBy = 'createdAt',
    String sortOrder = 'ASC',
  }) async {
    try {
      // Debug: Check if user is authenticated
      final token = await getToken();
      if (token == null) {
        throw Exception('User not authenticated. Please login again.');
      }

      final requestBody = <String, dynamic>{
        'page': page,
        'limit': limit,
        'sortBy': sortBy,
        'sortOrder': sortOrder,
      };

      final response = await _dio.post(
        '/ads/my-ads',
        data: requestBody,
        options: Options(responseType: ResponseType.json),
      );

      dynamic raw = response.data;

      List<dynamic> list;
      try {
        if (raw is List) {
          list = raw;
        } else if (raw is Map) {
          // Handle both Map<String, dynamic> and Map<dynamic, dynamic>
          final Map map = raw;
          final dataField = map['data'];

          if (dataField is List) {
            list = dataField;
          } else if (dataField is Map) {
            // Handle case where data is a single object wrapped in a map
            // Convert single object to list
            list = [dataField];
          } else if (dataField == null) {
            // If data field is null, return empty list
            list = [];
          } else {
            // Unexpected type
            throw StateError(
                'Unexpected data field type: ${dataField.runtimeType}. '
                'Expected List or Map. Got: $dataField');
          }
        } else {
          throw StateError('Unexpected response type: ${raw.runtimeType}. '
              'Expected List or Map. Response: $raw');
        }
      } catch (_) {
        rethrow;
      }

      final int total = raw is Map<String, dynamic>
          ? (raw['total'] is int ? raw['total'] as int : list.length)
          : list.length;
      final bool hasNext = (page * limit) < total;

      final ads = list.whereType<Map<String, dynamic>>().map((obj) {
        try {
          return MyAd.fromJson(obj);
        } catch (_) {
          rethrow;
        }
      }).toList();

      // Enrich ads with manufacturer and model names
      final enrichedAds = await _enrichMyAdsWithNames(ads);

      return PaginatedMyAdsResponse(data: enrichedAds, hasNext: hasNext);
    } on DioException catch (e) {
      throw Exception(DioErrorHandler.handleError(e));
    } catch (e) {
      throw Exception('Failed to fetch my ads: $e');
    }
  }

  /// Enrich MyAds with manufacturer and model names using IDs
  Future<List<MyAd>> _enrichMyAdsWithNames(List<MyAd> ads) async {
    try {
      // Get all unique manufacturer IDs
      final manufacturerIds = ads
          .where((ad) => ad.vehicleDetails?.manufacturerId.isNotEmpty == true)
          .map((ad) => ad.vehicleDetails!.manufacturerId)
          .toSet()
          .toList();

      // Fetch manufacturer names
      final Map<String, String> manufacturerMap = {};
      if (manufacturerIds.isNotEmpty) {
        try {
          final response = await _dio.get('/vehicle/manufacturers');
          if (response.statusCode == 200) {
            dynamic manufacturersData = response.data;
            List<dynamic> manufacturers;

            // Handle different response structures
            if (manufacturersData is List) {
              manufacturers = manufacturersData;
            } else if (manufacturersData is Map &&
                manufacturersData['data'] is List) {
              manufacturers = manufacturersData['data'] as List;
            } else {
              manufacturers = [];
            }

            for (final manufacturer in manufacturers) {
              if (manufacturer is Map) {
                final Map map = manufacturer;
                final id = map['_id']?.toString() ?? map['id']?.toString();
                final name =
                    map['displayName']?.toString() ?? map['name']?.toString();
                if (id != null && name != null) {
                  manufacturerMap[id] = name;
                }
              }
            }
          }
        } catch (_) {
        }
      }

      // Get all unique model IDs with their manufacturer IDs
      final modelRequests = <Map<String, String>>[];
      for (final ad in ads) {
        if (ad.vehicleDetails?.modelId.isNotEmpty == true &&
            ad.vehicleDetails?.manufacturerId.isNotEmpty == true) {
          modelRequests.add({
            'modelId': ad.vehicleDetails!.modelId,
            'manufacturerId': ad.vehicleDetails!.manufacturerId,
          });
        }
      }

      // Fetch model names
      final Map<String, String> modelMap = {};
      for (final request in modelRequests) {
        try {
          final response = await _dio.get(
            '/vehicle/models',
            queryParameters: {
              'manufacturerId': request['manufacturerId'],
            },
          );
          if (response.statusCode == 200) {
            dynamic modelsData = response.data;
            List<dynamic> models;

            // Handle different response structures
            if (modelsData is List) {
              models = modelsData;
            } else if (modelsData is Map && modelsData['data'] is List) {
              models = modelsData['data'] as List;
            } else {
              models = [];
            }

            for (final model in models) {
              if (model is Map) {
                final Map map = model;
                final id = map['_id']?.toString() ?? map['id']?.toString();
                final name =
                    map['displayName']?.toString() ?? map['name']?.toString();
                if (id != null && name != null) {
                  modelMap[id] = name;
                }
              }
            }
          }
        } catch (_) {
        }
      }

      // Create enriched ads with manufacturer and model names
      return ads.map((ad) {
        if (ad.vehicleDetails == null) return ad;

        final manufacturerName =
            manufacturerMap[ad.vehicleDetails!.manufacturerId];
        final modelName = modelMap[ad.vehicleDetails!.modelId];

        // Create manufacturer and model objects if we have the names
        Manufacturer? manufacturer;
        if (manufacturerName != null &&
            ad.vehicleDetails!.manufacturerId.isNotEmpty) {
          manufacturer = Manufacturer(
            id: ad.vehicleDetails!.manufacturerId,
            name: manufacturerName,
            displayName: manufacturerName,
          );
        }

        Model? model;
        if (modelName != null && ad.vehicleDetails!.modelId.isNotEmpty) {
          model = Model(
            id: ad.vehicleDetails!.modelId,
            name: modelName,
            displayName: modelName,
          );
        }

        return ad.copyWith(
          manufacturer: manufacturer,
          model: model,
        );
      }).toList();
    } catch (_) {
      return ads; // Return original ads if enrichment fails
    }
  }
}

class PaginatedMyAdsResponse {
  final List<MyAd> data;
  final bool hasNext;

  PaginatedMyAdsResponse({required this.data, required this.hasNext});
}
