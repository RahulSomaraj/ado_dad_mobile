import 'package:ado_dad_user/common/api_service.dart';
import 'package:ado_dad_user/models/advertisement_model/add_model.dart';
import 'package:ado_dad_user/models/advertisement_post_model/vehicle_manufacturer_model.dart';
import 'package:ado_dad_user/models/advertisement_post_model/vehilce_model.dart';
import 'package:dio/dio.dart';

class PaginatedUserAdsResponse {
  final List<AddModel> data;
  final int total;
  final int page;
  final int limit;
  final bool hasNext;

  PaginatedUserAdsResponse({
    required this.data,
    required this.total,
    required this.page,
    required this.limit,
    required this.hasNext,
  });
}

class SellerProfileRepository {
  final Dio _dio = ApiService().dio;

  Future<PaginatedUserAdsResponse> fetchUserAds({
    required String userId,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _dio.get(
        '/ads/user/$userId',
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        final List<dynamic> rawData = responseData['data'] ?? responseData;
        final int total = responseData['total'] ?? rawData.length;
        final bool hasNext = (page * limit) < total;

        final ads = rawData.map((json) => AddModel.fromJson(json)).toList();

        // Enrich ads with manufacturer and model names if missing
        final enrichedAds = await _enrichAdsWithNames(ads);

        return PaginatedUserAdsResponse(
          data: enrichedAds,
          total: total,
          page: page,
          limit: limit,
          hasNext: hasNext,
        );
      } else {
        throw Exception("Failed to load user ads: ${response.statusMessage}");
      }
    } on DioException catch (e) {
      throw Exception("Error fetching user ads: ${e.message}");
    } catch (e) {
      throw Exception("Unexpected error: ${e.toString()}");
    }
  }

  Future<List<AddModel>> _enrichAdsWithNames(List<AddModel> ads) async {
    try {
      // Fetch all manufacturers
      final manufacturersResponse =
          await _dio.get('/vehicle-inventory/manufacturers');
      final List<dynamic> manufacturersData =
          manufacturersResponse.data['data'];
      final manufacturers = manufacturersData
          .map((e) => VehicleManufacturer.fromJson(e as Map<String, dynamic>))
          .toList();

      // Create a map for quick lookup
      final manufacturerMap = {for (var m in manufacturers) m.id: m};

      // Enrich each ad
      final enrichedAds = <AddModel>[];
      for (final ad in ads) {
        if (ad.category == 'property') {
          enrichedAds.add(ad);
          continue;
        }

        // Get manufacturer name if missing
        String? manufacturerName;
        String? manufacturerDisplayName;
        if (ad.manufacturer?.id != null) {
          final manufacturer = manufacturerMap[ad.manufacturer!.id];
          if (manufacturer != null) {
            manufacturerName = manufacturer
                .displayName; // VehicleManufacturer only has displayName
            manufacturerDisplayName = manufacturer.displayName;
          }
        }

        // Get model name if missing
        String? modelName;
        String? modelDisplayName;
        if (ad.model?.id != null && ad.manufacturer?.id != null) {
          try {
            final modelsResponse = await _dio.get(
              '/vehicle-inventory/models',
              queryParameters: {'manufacturerId': ad.manufacturer!.id},
            );
            final List<dynamic> modelsData = modelsResponse.data['data'];
            final models = modelsData
                .map((e) => VehicleModel.fromJson(e as Map<String, dynamic>))
                .toList();

            final model = models.firstWhere(
              (m) => m.id == ad.model!.id,
              orElse: () => models.isNotEmpty ? models.first : models.first,
            );
            modelName = model.displayName; // VehicleModel only has displayName
            modelDisplayName = model.displayName;
          } catch (e) {
            // Error fetching model - continue with empty name
          }
        }

        // Create enriched manufacturer and model objects
        final enrichedManufacturer = ad.manufacturer != null
            ? Manufacturer(
                id: ad.manufacturer!.id,
                name: manufacturerName ?? ad.manufacturer!.name ?? '',
                displayName:
                    manufacturerDisplayName ?? ad.manufacturer!.displayName,
              )
            : null;

        final enrichedModel = ad.model != null
            ? Model(
                id: ad.model!.id,
                name: modelName ?? ad.model!.name,
                displayName: modelDisplayName ?? ad.model!.displayName,
              )
            : null;

        // Create enriched ad
        final enrichedAd = ad.copyWith(
          manufacturer: enrichedManufacturer,
          model: enrichedModel,
        );

        enrichedAds.add(enrichedAd);
      }

      return enrichedAds;
    } catch (e) {
      // Return original ads if enrichment fails
      return ads;
    }
  }
}
