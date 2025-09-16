import 'package:ado_dad_user/common/api_service.dart';
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
        return FavoriteAdsResponse.fromJson(response.data);
      } else {
        throw Exception('Failed to fetch favorite ads');
      }
    } on DioException catch (e) {
      throw Exception(DioErrorHandler.handleError(e));
    } catch (e) {
      throw Exception('Failed to fetch favorite ads: $e');
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
