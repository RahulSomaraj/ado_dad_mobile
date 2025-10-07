import 'package:ado_dad_user/common/api_service.dart';
import 'package:ado_dad_user/models/advertisement_post_model/vehicle_fuel_type_model.dart';
import 'package:ado_dad_user/models/advertisement_post_model/vehicle_manufacturer_model.dart';
import 'package:ado_dad_user/models/advertisement_post_model/vehilce_model.dart';
import 'package:dio/dio.dart';

class FavoriteRepository {
  final Dio _dio = ApiService().dio;

  /// Add an ad to favorites
  Future<FavoriteResponse> addToFavorites(String adId) async {
    try {
      final response = await _dio.post(
        '/favorites',
        data: {
          'adId': adId,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return FavoriteResponse.fromJson(response.data);
      } else {
        throw Exception('Failed to add to favorites');
      }
    } on DioException catch (e) {
      throw Exception(DioErrorHandler.handleError(e));
    } catch (e) {
      throw Exception('Failed to add to favorites: $e');
    }
  }

  /// Remove an ad from favorites
  Future<FavoriteResponse> removeFromFavorites(String adId) async {
    try {
      final response = await _dio.post(
        '/favorites',
        data: {
          'adId': adId,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return FavoriteResponse.fromJson(response.data);
      } else {
        throw Exception('Failed to remove from favorites');
      }
    } on DioException catch (e) {
      print('Error on Adding Favorite: >>>>>>>>>>>>>>>>>>>>>>>$e');
      throw Exception(DioErrorHandler.handleError(e));
    } catch (e) {
      throw Exception('Failed to remove from favorites: $e');
    }
  }

  /// Get user's favorite ads
  Future<FavoriteAdsResponse> getFavoriteAds({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _dio.get(
        '/favorites',
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );

      if (response.statusCode == 200) {
        final favoriteResponse = FavoriteAdsResponse.fromJson(response.data);

        // Enrich the favorite ads with manufacturer and model names
        final enrichedFavorites =
            await _enrichFavoriteAds(favoriteResponse.data);

        return FavoriteAdsResponse(
          data: enrichedFavorites,
          total: favoriteResponse.total,
          page: favoriteResponse.page,
          limit: favoriteResponse.limit,
          totalPages: favoriteResponse.totalPages,
          hasNext: favoriteResponse.hasNext,
          hasPrev: favoriteResponse.hasPrev,
        );
      } else {
        throw Exception('Failed to fetch favorite ads');
      }
    } on DioException catch (e) {
      throw Exception(DioErrorHandler.handleError(e));
    } catch (e) {
      throw Exception('Failed to fetch favorite ads: $e');
    }
  }

  /// Enrich favorite ads with manufacturer, model, and fuel type names
  Future<List<FavoriteAd>> _enrichFavoriteAds(
      List<FavoriteAd> favorites) async {
    try {
      print('Starting enrichment for ${favorites.length} favorites');
      // Fetch all manufacturers
      final manufacturersResponse =
          await _dio.get('/vehicle-inventory/manufacturers');
      final List<dynamic> manufacturersData =
          manufacturersResponse.data['data'];
      final manufacturers = manufacturersData
          .map((e) => VehicleManufacturer.fromJson(e as Map<String, dynamic>))
          .toList();

      // Fetch all fuel types
      final fuelTypesResponse = await _dio.get('/vehicle-inventory/fuel-types');
      final List<dynamic> fuelTypesData = fuelTypesResponse.data['data'];
      final fuelTypes = fuelTypesData
          .map((e) => VehicleFuelType.fromJson(e as Map<String, dynamic>))
          .toList();

      // Create maps for quick lookup
      final manufacturerMap = {for (var m in manufacturers) m.id: m};
      final fuelTypeMap = {for (var f in fuelTypes) f.id: f};

      // Enrich each favorite ad
      final enrichedFavorites = <FavoriteAd>[];
      for (final favorite in favorites) {
        if (favorite.category == 'property' ||
            favorite.vehicleDetails == null) {
          enrichedFavorites.add(favorite);
          continue;
        }

        // Get manufacturer name
        String? manufacturerName;
        if (favorite.vehicleDetails!.manufacturerId.isNotEmpty) {
          final manufacturer =
              manufacturerMap[favorite.vehicleDetails!.manufacturerId];
          if (manufacturer != null) {
            manufacturerName = manufacturer.displayName;
            print(
                'Found manufacturer: $manufacturerName for ID: ${favorite.vehicleDetails!.manufacturerId}');
          } else {
            print(
                'Manufacturer not found for ID: ${favorite.vehicleDetails!.manufacturerId}');
          }
        }

        // Get model name
        String? modelName;
        if (favorite.vehicleDetails!.modelId.isNotEmpty &&
            favorite.vehicleDetails!.manufacturerId.isNotEmpty) {
          try {
            final modelsResponse = await _dio.get(
              '/vehicle-inventory/models',
              queryParameters: {
                'manufacturerId': favorite.vehicleDetails!.manufacturerId
              },
            );
            final List<dynamic> modelsData = modelsResponse.data['data'];
            final models = modelsData
                .map((e) => VehicleModel.fromJson(e as Map<String, dynamic>))
                .toList();

            final model = models
                .where(
                  (m) => m.id == favorite.vehicleDetails!.modelId,
                )
                .firstOrNull;

            if (model != null) {
              modelName = model.displayName;
              print(
                  'Found model: $modelName for ID: ${favorite.vehicleDetails!.modelId}');
            } else {
              print(
                  'Model not found for ID: ${favorite.vehicleDetails!.modelId}');
            }
          } catch (e) {
            // Error fetching model - continue with empty name
          }
        }

        // Get fuel type name
        String? fuelTypeName;
        if (favorite.vehicleDetails!.fuelTypeId.isNotEmpty) {
          final fuelType = fuelTypeMap[favorite.vehicleDetails!.fuelTypeId];
          if (fuelType != null) {
            fuelTypeName = fuelType.displayName;
          }
        }

        // Create enriched vehicle details
        final enrichedVehicleDetails = EnrichedVehicleDetails(
          id: favorite.vehicleDetails!.id,
          ad: favorite.vehicleDetails!.ad,
          vehicleType: favorite.vehicleDetails!.vehicleType,
          manufacturerId: favorite.vehicleDetails!.manufacturerId,
          modelId: favorite.vehicleDetails!.modelId,
          variantId: favorite.vehicleDetails!.variantId,
          year: favorite.vehicleDetails!.year,
          mileage: favorite.vehicleDetails!.mileage,
          transmissionTypeId: favorite.vehicleDetails!.transmissionTypeId,
          fuelTypeId: favorite.vehicleDetails!.fuelTypeId,
          color: favorite.vehicleDetails!.color,
          isFirstOwner: favorite.vehicleDetails!.isFirstOwner,
          hasInsurance: favorite.vehicleDetails!.hasInsurance,
          hasRcBook: favorite.vehicleDetails!.hasRcBook,
          additionalFeatures: favorite.vehicleDetails!.additionalFeatures,
          createdAt: favorite.vehicleDetails!.createdAt,
          updatedAt: favorite.vehicleDetails!.updatedAt,
          v: favorite.vehicleDetails!.v,
          manufacturerName: manufacturerName,
          modelName: modelName,
          fuelTypeName: fuelTypeName,
        );

        // Create enriched favorite ad
        final enrichedFavorite = EnrichedFavoriteAd(
          id: favorite.id,
          description: favorite.description,
          price: favorite.price,
          images: favorite.images,
          location: favorite.location,
          category: favorite.category,
          isActive: favorite.isActive,
          postedAt: favorite.postedAt,
          updatedAt: favorite.updatedAt,
          postedBy: favorite.postedBy,
          user: favorite.user,
          enrichedVehicleDetails: enrichedVehicleDetails,
          favoriteId: favorite.favoriteId,
          favoritedAt: favorite.favoritedAt,
        );

        enrichedFavorites.add(enrichedFavorite);
      }

      return enrichedFavorites;
    } catch (e) {
      // Return original favorites if enrichment fails
      print('Error enriching favorite ads: $e');
      return favorites;
    }
  }
}

class FavoriteResponse {
  final bool isFavorited;
  final String? favoriteId;
  final String message;

  FavoriteResponse({
    required this.isFavorited,
    this.favoriteId,
    required this.message,
  });

  factory FavoriteResponse.fromJson(Map<String, dynamic> json) {
    return FavoriteResponse(
      isFavorited: json['isFavorited'] as bool? ?? false,
      favoriteId: json['favoriteId'] as String?,
      message: json['message'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isFavorited': isFavorited,
      'favoriteId': favoriteId,
      'message': message,
    };
  }
}

class FavoriteAdsResponse {
  final List<FavoriteAd> data;
  final int total;
  final int page;
  final int limit;
  final int totalPages;
  final bool hasNext;
  final bool hasPrev;

  FavoriteAdsResponse({
    required this.data,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrev,
  });

  factory FavoriteAdsResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawData = json['data'] as List<dynamic>;
    final ads = rawData
        .map((e) => FavoriteAd.fromJson(e as Map<String, dynamic>))
        .toList();

    return FavoriteAdsResponse(
      data: ads,
      total: json['total'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
      limit: json['limit'] as int? ?? 20,
      totalPages: json['totalPages'] as int? ?? 1,
      hasNext: json['hasNext'] as bool? ?? false,
      hasPrev: json['hasPrev'] as bool? ?? false,
    );
  }
}

class FavoriteAd {
  final String id;
  final String description;
  final int price;
  final List<String> images;
  final String location;
  final String category;
  final bool isActive;
  final String postedAt;
  final String updatedAt;
  final String postedBy;
  final FavoriteUser user;
  final VehicleDetails? vehicleDetails;
  final String? favoriteId;
  final String? favoritedAt;

  FavoriteAd({
    required this.id,
    required this.description,
    required this.price,
    required this.images,
    required this.location,
    required this.category,
    required this.isActive,
    required this.postedAt,
    required this.updatedAt,
    required this.postedBy,
    required this.user,
    this.vehicleDetails,
    this.favoriteId,
    this.favoritedAt,
  });

  factory FavoriteAd.fromJson(Map<String, dynamic> json) {
    return FavoriteAd(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      price: (json['price'] as num?)?.toInt() ?? 0,
      images:
          (json['images'] as List?)?.map((e) => e.toString()).toList() ?? [],
      location: (json['location'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
      isActive: (json['isActive'] as bool?) ?? false,
      postedAt: (json['postedAt'] ?? '').toString(),
      updatedAt: (json['updatedAt'] ?? '').toString(),
      postedBy: (json['postedBy'] ?? '').toString(),
      user: FavoriteUser.fromJson(json['user'] as Map<String, dynamic>),
      vehicleDetails: json['vehicleDetails'] != null
          ? VehicleDetails.fromJson(
              json['vehicleDetails'] as Map<String, dynamic>)
          : null,
      favoriteId: json['favoriteId'] as String?,
      favoritedAt: json['favoritedAt'] as String?,
    );
  }
}

class FavoriteUser {
  final String id;
  final String name;
  final String email;
  final String phone;

  FavoriteUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
  });

  factory FavoriteUser.fromJson(Map<String, dynamic> json) {
    return FavoriteUser(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
    );
  }
}

class VehicleDetails {
  final String id;
  final String ad;
  final String vehicleType;
  final String manufacturerId;
  final String modelId;
  final String variantId;
  final int year;
  final int mileage;
  final String transmissionTypeId;
  final String fuelTypeId;
  final String color;
  final bool isFirstOwner;
  final bool hasInsurance;
  final bool hasRcBook;
  final List<String> additionalFeatures;
  final String createdAt;
  final String updatedAt;
  final int v;

  VehicleDetails({
    required this.id,
    required this.ad,
    required this.vehicleType,
    required this.manufacturerId,
    required this.modelId,
    required this.variantId,
    required this.year,
    required this.mileage,
    required this.transmissionTypeId,
    required this.fuelTypeId,
    required this.color,
    required this.isFirstOwner,
    required this.hasInsurance,
    required this.hasRcBook,
    required this.additionalFeatures,
    required this.createdAt,
    required this.updatedAt,
    required this.v,
  });

  factory VehicleDetails.fromJson(Map<String, dynamic> json) {
    return VehicleDetails(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      ad: (json['ad'] ?? '').toString(),
      vehicleType: (json['vehicleType'] ?? '').toString(),
      manufacturerId: (json['manufacturerId'] ?? '').toString(),
      modelId: (json['modelId'] ?? '').toString(),
      variantId: (json['variantId'] ?? '').toString(),
      year: (json['year'] as num?)?.toInt() ?? 0,
      mileage: (json['mileage'] as num?)?.toInt() ?? 0,
      transmissionTypeId: (json['transmissionTypeId'] ?? '').toString(),
      fuelTypeId: (json['fuelTypeId'] ?? '').toString(),
      color: (json['color'] ?? '').toString(),
      isFirstOwner: (json['isFirstOwner'] as bool?) ?? false,
      hasInsurance: (json['hasInsurance'] as bool?) ?? false,
      hasRcBook: (json['hasRcBook'] as bool?) ?? false,
      additionalFeatures: (json['additionalFeatures'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      createdAt: (json['createdAt'] ?? '').toString(),
      updatedAt: (json['updatedAt'] ?? '').toString(),
      v: (json['__v'] as num?)?.toInt() ?? 0,
    );
  }
}

// Enriched classes to hold manufacturer, model, and fuel type names
class EnrichedVehicleDetails extends VehicleDetails {
  final String? manufacturerName;
  final String? modelName;
  final String? fuelTypeName;

  EnrichedVehicleDetails({
    required super.id,
    required super.ad,
    required super.vehicleType,
    required super.manufacturerId,
    required super.modelId,
    required super.variantId,
    required super.year,
    required super.mileage,
    required super.transmissionTypeId,
    required super.fuelTypeId,
    required super.color,
    required super.isFirstOwner,
    required super.hasInsurance,
    required super.hasRcBook,
    required super.additionalFeatures,
    required super.createdAt,
    required super.updatedAt,
    required super.v,
    this.manufacturerName,
    this.modelName,
    this.fuelTypeName,
  });
}

class EnrichedFavoriteAd extends FavoriteAd {
  final EnrichedVehicleDetails? enrichedVehicleDetails;

  EnrichedFavoriteAd({
    required super.id,
    required super.description,
    required super.price,
    required super.images,
    required super.location,
    required super.category,
    required super.isActive,
    required super.postedAt,
    required super.updatedAt,
    required super.postedBy,
    required super.user,
    required this.enrichedVehicleDetails,
    super.favoriteId,
    super.favoritedAt,
  }) : super(vehicleDetails: enrichedVehicleDetails);
}
