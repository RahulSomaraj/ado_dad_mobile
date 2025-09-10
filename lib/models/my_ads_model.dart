class MyAd {
  final String id;
  final String description;
  final int price;
  final List<String> images;
  final String location;
  final String category;
  final bool isActive;
  final String postedAt; // ISO string
  final String updatedAt; // ISO string
  final String postedBy;

  final MyAdUser? user;
  final int? year;

  // Keep flexible structures for these (backend may vary)
  final MyAdVehicleDetails? vehicleDetails;
  final List<Map<String, dynamic>> commercialVehicleDetails;
  final PropertyDetails? propertyDetails;

  MyAd({
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
    this.user,
    this.year,
    this.vehicleDetails,
    this.commercialVehicleDetails = const [],
    this.propertyDetails,
  });

  MyAd copyWith({
    String? id,
    String? description,
    int? price,
    List<String>? images,
    String? location,
    String? category,
    bool? isActive,
    String? postedAt,
    String? updatedAt,
    String? postedBy,
    MyAdUser? user,
    int? year,
    MyAdVehicleDetails? vehicleDetails,
    List<Map<String, dynamic>>? commercialVehicleDetails,
    PropertyDetails? propertyDetails,
  }) {
    return MyAd(
      id: id ?? this.id,
      description: description ?? this.description,
      price: price ?? this.price,
      images: images ?? this.images,
      location: location ?? this.location,
      category: category ?? this.category,
      isActive: isActive ?? this.isActive,
      postedAt: postedAt ?? this.postedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      postedBy: postedBy ?? this.postedBy,
      user: user ?? this.user,
      year: year ?? this.year,
      vehicleDetails: vehicleDetails ?? this.vehicleDetails,
      commercialVehicleDetails:
          commercialVehicleDetails ?? this.commercialVehicleDetails,
      propertyDetails: propertyDetails ?? this.propertyDetails,
    );
  }

  factory MyAd.fromJson(Map<String, dynamic> json) {
    final List<String> images = (json['images'] as List?)
            ?.where((e) => e != null)
            .map((e) => e.toString())
            .toList() ??
        const [];

    final userJson = _asMap(json['user']);
    final dynamic propertyRaw = json['propertyDetails'];
    Map<String, dynamic>? propertyJson;
    if (propertyRaw is Map) {
      propertyJson = Map<String, dynamic>.from(propertyRaw);
    }

    // vehicleDetails may be an object or an array
    final dynamic vehicleRaw = json['vehicleDetails'];
    MyAdVehicleDetails? vehicleDetails;
    if (vehicleRaw is Map) {
      vehicleDetails =
          MyAdVehicleDetails.fromJson(Map<String, dynamic>.from(vehicleRaw));
    } else if (vehicleRaw is List &&
        vehicleRaw.isNotEmpty &&
        vehicleRaw.first is Map) {
      vehicleDetails = MyAdVehicleDetails.fromJson(
          Map<String, dynamic>.from(vehicleRaw.first as Map));
    }

    final List<Map<String, dynamic>> commercialVehicleDetails =
        (json['commercialVehicleDetails'] as List?)
                ?.where((e) => e is Map)
                .map((e) => Map<String, dynamic>.from(e as Map))
                .toList() ??
            const [];

    return MyAd(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      price: _asInt(json['price']) ?? 0,
      images: images,
      location: (json['location'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
      isActive: (json['isActive'] as bool?) ?? false,
      postedAt: (json['postedAt'] ?? '').toString(),
      updatedAt: (json['updatedAt'] ?? '').toString(),
      postedBy: (json['postedBy'] ?? '').toString(),
      user: userJson != null ? MyAdUser.fromJson(userJson) : null,
      year: _asInt(json['year']) ?? vehicleDetails?.year,
      vehicleDetails: vehicleDetails,
      commercialVehicleDetails: commercialVehicleDetails,
      propertyDetails:
          propertyJson != null ? PropertyDetails.fromJson(propertyJson) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'price': price,
      'images': images,
      'location': location,
      'category': category,
      'isActive': isActive,
      'postedAt': postedAt,
      'updatedAt': updatedAt,
      'postedBy': postedBy,
      'user': user?.toJson(),
      'year': year,
      'vehicleDetails': vehicleDetails?.toJson(),
      'commercialVehicleDetails': commercialVehicleDetails,
      'propertyDetails': propertyDetails?.toJson(),
    };
  }
}

class MyAdUser {
  final String id;
  final String name;
  final String email;

  MyAdUser({
    required this.id,
    required this.name,
    required this.email,
  });

  factory MyAdUser.fromJson(Map<String, dynamic> json) {
    return MyAdUser(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
    };
  }
}

class MyAdVehicleDetails {
  final String id; // _id
  final String ad;
  final String vehicleType;
  final String manufacturerId;
  final String modelId;
  final int? year;
  final int? mileage;
  final String transmissionTypeId;
  final String fuelTypeId;
  final String color;
  final bool isFirstOwner;
  final bool hasInsurance;
  final bool hasRcBook;
  final List<String> additionalFeatures;
  final String createdAt;
  final String updatedAt;
  final int? v; // __v

  MyAdVehicleDetails({
    required this.id,
    required this.ad,
    required this.vehicleType,
    required this.manufacturerId,
    required this.modelId,
    this.year,
    this.mileage,
    required this.transmissionTypeId,
    required this.fuelTypeId,
    required this.color,
    required this.isFirstOwner,
    required this.hasInsurance,
    required this.hasRcBook,
    required this.additionalFeatures,
    required this.createdAt,
    required this.updatedAt,
    this.v,
  });

  factory MyAdVehicleDetails.fromJson(Map<String, dynamic> json) {
    return MyAdVehicleDetails(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      ad: (json['ad'] ?? '').toString(),
      vehicleType: (json['vehicleType'] ?? '').toString(),
      manufacturerId: (json['manufacturerId'] ?? '').toString(),
      modelId: (json['modelId'] ?? '').toString(),
      year: _asInt(json['year']),
      mileage: _asInt(json['mileage']),
      transmissionTypeId: (json['transmissionTypeId'] ?? '').toString(),
      fuelTypeId: (json['fuelTypeId'] ?? '').toString(),
      color: (json['color'] ?? '').toString(),
      isFirstOwner: (json['isFirstOwner'] as bool?) ?? false,
      hasInsurance: (json['hasInsurance'] as bool?) ?? false,
      hasRcBook: (json['hasRcBook'] as bool?) ?? false,
      additionalFeatures: (json['additionalFeatures'] as List?)
              ?.where((e) => e != null)
              .map((e) => e.toString())
              .toList() ??
          const [],
      createdAt: (json['createdAt'] ?? '').toString(),
      updatedAt: (json['updatedAt'] ?? '').toString(),
      v: _asInt(json['__v']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'ad': ad,
      'vehicleType': vehicleType,
      'manufacturerId': manufacturerId,
      'modelId': modelId,
      'year': year,
      'mileage': mileage,
      'transmissionTypeId': transmissionTypeId,
      'fuelTypeId': fuelTypeId,
      'color': color,
      'isFirstOwner': isFirstOwner,
      'hasInsurance': hasInsurance,
      'hasRcBook': hasRcBook,
      'additionalFeatures': additionalFeatures,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      '__v': v,
    };
  }
}

class PropertyDetails {
  final String id; // _id
  final String ad; // ad id
  final String propertyType;
  final int bedrooms;
  final int bathrooms;
  final int areaSqft;
  final int floor;
  final bool isFurnished;
  final bool hasParking;
  final bool hasGarden;
  final List<String> amenities;
  final String createdAt; // ISO string
  final String updatedAt; // ISO string
  final int? v; // __v

  PropertyDetails({
    required this.id,
    required this.ad,
    required this.propertyType,
    required this.bedrooms,
    required this.bathrooms,
    required this.areaSqft,
    required this.floor,
    required this.isFurnished,
    required this.hasParking,
    required this.hasGarden,
    required this.amenities,
    required this.createdAt,
    required this.updatedAt,
    this.v,
  });

  factory PropertyDetails.fromJson(Map<String, dynamic> json) {
    return PropertyDetails(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      ad: (json['ad'] ?? '').toString(),
      propertyType: (json['propertyType'] ?? '').toString(),
      bedrooms: _asInt(json['bedrooms']) ?? 0,
      bathrooms: _asInt(json['bathrooms']) ?? 0,
      areaSqft: _asInt(json['areaSqft']) ?? 0,
      floor: _asInt(json['floor']) ?? 0,
      isFurnished: (json['isFurnished'] as bool?) ?? false,
      hasParking: (json['hasParking'] as bool?) ?? false,
      hasGarden: (json['hasGarden'] as bool?) ?? false,
      amenities: (json['amenities'] as List?)
              ?.where((e) => e != null)
              .map((e) => e.toString())
              .toList() ??
          const [],
      createdAt: (json['createdAt'] ?? '').toString(),
      updatedAt: (json['updatedAt'] ?? '').toString(),
      v: _asInt(json['__v']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'ad': ad,
      'propertyType': propertyType,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'areaSqft': areaSqft,
      'floor': floor,
      'isFurnished': isFurnished,
      'hasParking': hasParking,
      'hasGarden': hasGarden,
      'amenities': amenities,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      '__v': v,
    };
  }
}

Map<String, dynamic>? _asMap(dynamic v) {
  if (v == null) return null;
  if (v is Map<String, dynamic>) return v;
  if (v is Map) return Map<String, dynamic>.from(v);
  return null;
}

int? _asInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}
