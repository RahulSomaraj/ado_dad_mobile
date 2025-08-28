class AddModel {
  // Common (for both list & detail)
  final String id;
  final String description;
  final int price;
  final List<String> images;
  final String location;
  final String category;
  final bool isActive;
  final String updatedAt;

  // ===== Additional fields for detail page =====
  // Vehicle-related
  final String? vehicleType;
  final Manufacturer? manufacturer;
  final Model? model;
  final int? year;
  final String? variant;
  final int? mileage;
  // IDs from backend (lookup keys)
  final String? transmissionId; // e.g., 6860...e111
  final String? fuelTypeId; // e.g., 6860...e0bb

  // Human-friendly names (to be enriched in BLoC)
  final String? transmission; // e.g., "Automatic"
  final String? fuelType; // e.g., "Petrol"
  final String? color;
  final bool? isFirstOwner;
  final bool? hasInsurance;
  final bool? hasRcBook;
  final List<String>? additionalFeatures;

  // Property-related
  final String? propertyType;
  final int? bedrooms;
  final int? bathrooms;
  final int? areaSqft;
  final int? floor;
  final bool? isFurnished;
  final bool? hasParking;
  final bool? hasGarden;
  final List<String>? amenities;

  // Commercial vehicles
  final String? bodyType;
  final int? payloadCapacity;
  final String? payloadUnit;
  final int? axleCount; // ✅ new
  final int? seatingCapacity; // ✅ new
  final String? commercialVehicleType; // ✅ new
  final bool? hasFitness; // ✅ new
  final bool? hasPermit;

  AddModel({
    // basic
    required this.id,
    required this.description,
    required this.price,
    required this.images,
    required this.location,
    required this.category,
    required this.isActive,
    required this.updatedAt,
    // detail
    this.vehicleType,
    this.manufacturer,
    this.model,
    this.variant,
    this.year,
    this.mileage,
    this.transmissionId,
    this.fuelTypeId,
    this.transmission,
    this.fuelType,
    this.color,
    this.isFirstOwner,
    this.hasInsurance,
    this.hasRcBook,
    this.additionalFeatures,
    this.propertyType,
    this.bedrooms,
    this.bathrooms,
    this.areaSqft,
    this.floor,
    this.isFurnished,
    this.hasParking,
    this.hasGarden,
    this.amenities,
    this.bodyType,
    this.payloadCapacity,
    this.payloadUnit,
    this.axleCount,
    this.seatingCapacity,
    this.commercialVehicleType,
    this.hasFitness,
    this.hasPermit,
  });

  AddModel copyWith({
    String? id,
    String? description,
    int? price,
    List<String>? images,
    String? location,
    String? category,
    bool? isActive,
    String? updatedAt,
    String? vehicleType,
    Manufacturer? manufacturer,
    Model? model,
    int? year,
    String? variant,
    int? mileage,
    String? transmissionId,
    String? fuelTypeId,
    String? transmission,
    String? fuelType,
    String? color,
    bool? isFirstOwner,
    bool? hasInsurance,
    bool? hasRcBook,
    List<String>? additionalFeatures,
    String? propertyType,
    int? bedrooms,
    int? bathrooms,
    int? areaSqft,
    int? floor,
    bool? isFurnished,
    bool? hasParking,
    bool? hasGarden,
    List<String>? amenities,
    String? bodyType,
    int? payloadCapacity,
    String? payloadUnit,
    int? axleCount, // ✅ new
    int? seatingCapacity, // ✅ new
    String? commercialVehicleType, // ✅ new
    bool? hasFitness, // ✅ new
    bool? hasPermit,
  }) {
    return AddModel(
      id: id ?? this.id,
      description: description ?? this.description,
      price: price ?? this.price,
      images: images ?? this.images,
      location: location ?? this.location,
      category: category ?? this.category,
      isActive: isActive ?? this.isActive,
      updatedAt: updatedAt ?? this.updatedAt,
      vehicleType: vehicleType ?? this.vehicleType,
      manufacturer: manufacturer ?? this.manufacturer,
      model: model ?? this.model,
      variant: variant ?? this.variant,
      year: year ?? this.year,
      mileage: mileage ?? this.mileage,
      transmissionId: transmissionId ?? this.transmissionId,
      fuelTypeId: fuelTypeId ?? this.fuelTypeId,
      transmission: transmission ?? this.transmission,
      fuelType: fuelType ?? this.fuelType,
      color: color ?? this.color,
      isFirstOwner: isFirstOwner ?? this.isFirstOwner,
      hasInsurance: hasInsurance ?? this.hasInsurance,
      hasRcBook: hasRcBook ?? this.hasRcBook,
      additionalFeatures: additionalFeatures ?? this.additionalFeatures,
      propertyType: propertyType ?? this.propertyType,
      bedrooms: bedrooms ?? this.bedrooms,
      bathrooms: bathrooms ?? this.bathrooms,
      areaSqft: areaSqft ?? this.areaSqft,
      floor: floor ?? this.floor,
      isFurnished: isFurnished ?? this.isFurnished,
      hasParking: hasParking ?? this.hasParking,
      hasGarden: hasGarden ?? this.hasGarden,
      amenities: amenities ?? this.amenities,
      bodyType: bodyType ?? this.bodyType,
      payloadCapacity: payloadCapacity ?? this.payloadCapacity,
      payloadUnit: payloadUnit ?? this.payloadUnit,
      axleCount: axleCount ?? this.axleCount, // ✅
      seatingCapacity: seatingCapacity ?? this.seatingCapacity, // ✅
      commercialVehicleType:
          commercialVehicleType ?? this.commercialVehicleType, // ✅
      hasFitness: hasFitness ?? this.hasFitness, // ✅
      hasPermit: hasPermit ?? this.hasPermit,
    );
  }

  factory AddModel.fromJson(Map<String, dynamic> json) {
    final vd = _asMap(json['vehicleDetails']);
    final inv = _asMap(vd?['inventory']);

    // 🔸 NEW: property nested maps
    final pd = _asMap(json['propertyDetails']) ?? _asMap(json['property']);
    final details = _asMap(json['details']); // some backends use "details"
    final propScope =
        pd ?? details ?? json; // prefer nested, else fallback top-level

    // Prefer nested inventory objects, else fall back to IDs
    Manufacturer? manufacturer;
    final manuObj =
        _asMap(inv?['manufacturer']) ?? _asMap(json['manufacturer']);
    final manuId =
        (vd?['manufacturerId'] ?? json['manufacturerId'])?.toString();
    if (manuObj != null) {
      manufacturer = Manufacturer.fromJson(manuObj);
    } else if (manuId != null && manuId.isNotEmpty) {
      manufacturer = Manufacturer(id: manuId, name: '');
    }

    Model? model;
    final modelObj = _asMap(inv?['model']) ?? _asMap(json['model']);
    final modelId = (vd?['modelId'] ?? json['modelId'])?.toString();
    if (modelObj != null) {
      model = Model.fromJson(modelObj);
    } else if (modelId != null && modelId.isNotEmpty) {
      model = Model(id: modelId, name: '');
    }

    return AddModel(
      // basics
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      price: _asInt(json['price']) ?? 0,
      images: (json['images'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
      location: (json['location'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
      isActive: (json['isActive'] as bool?) ?? false,
      updatedAt: (json['updatedAt'] ?? json['postedAt'] ?? '').toString(),

      // detail
      vehicleType: (json['vehicleType'] ?? vd?['vehicleType']) as String?,
      manufacturer: manufacturer,
      model: model,
      variant:
          (json['variant'] ?? vd?['variant'] ?? vd?['variantId'])?.toString(),
      year: _asInt(json['year']) ?? _asInt(vd?['year']),
      mileage: _asInt(json['mileage']) ?? _asInt(vd?['mileage']),

      // IDs from detail payload
      transmissionId:
          (vd?['transmissionTypeId'] ?? json['transmissionTypeId'])?.toString(),
      fuelTypeId: (vd?['fuelTypeId'] ?? json['fuelTypeId'])?.toString(),

      // if backend also sends human names anywhere, pick them up (optional)
      transmission: (json['transmission'] ??
              vd?['transmission'] ??
              vd?['transmissionType'])
          ?.toString(),
      fuelType: (json['fuelType'] ?? vd?['fuelType'])?.toString(),

      color: (json['color'] ?? vd?['color'])?.toString(),
      isFirstOwner: (json['isFirstOwner'] ?? vd?['isFirstOwner']) as bool?,
      hasInsurance: (json['hasInsurance'] ?? vd?['hasInsurance']) as bool?,
      hasRcBook: (json['hasRcBook'] ?? vd?['hasRcBook']) as bool?,
      additionalFeatures:
          ((json['additionalFeatures'] ?? vd?['additionalFeatures']) as List?)
              ?.where((e) => e != null)
              .map((e) => e.toString())
              .toList(),

      // property

      propertyType: (propScope['propertyType'] ?? propScope['type']) as String?,
      bedrooms: _asInt(propScope['bedrooms'] ?? propScope['bhk']),
      bathrooms: _asInt(propScope['bathrooms'] ?? propScope['baths']),
      areaSqft: _asInt(propScope['areaSqft'] ?? propScope['area']),
      floor: _asInt(propScope['floor']),
      isFurnished: propScope['isFurnished'] as bool?,
      hasParking: propScope['hasParking'] as bool?,
      hasGarden: propScope['hasGarden'] as bool?,
      amenities:
          (propScope['amenities'] as List?)?.map((e) => e.toString()).toList(),

      // propertyType: json['propertyType'] as String?,
      // bedrooms: _asInt(json['bedrooms']),
      // bathrooms: _asInt(json['bathrooms']),
      // areaSqft: _asInt(json['areaSqft']),
      // floor: _asInt(json['floor']),
      // isFurnished: json['isFurnished'] as bool?,
      // hasParking: json['hasParking'] as bool?,
      // hasGarden: json['hasGarden'] as bool?,
      // amenities:
      //     (json['amenities'] as List?)?.map((e) => e.toString()).toList(),

      // commercial
      bodyType: json['bodyType'] as String?,
      payloadCapacity: _asInt(json['payloadCapacity']),
      payloadUnit: json['payloadUnit'] as String?,
      axleCount: _asInt(json['axleCount']),
      seatingCapacity: _asInt(json['seatingCapacity']),
      commercialVehicleType: json['commercialVehicleType'] as String?,
      hasFitness: json['hasFitness'] as bool?,
      hasPermit: json['hasPermit'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      // basics
      'id': id,
      'description': description,
      'price': price,
      'images': images,
      'location': location,
      'category': category,
      'isActive': isActive,
      'updatedAt': updatedAt,

      // detail
      'vehicleType': vehicleType,
      'manufacturer': manufacturer?.toJson(),
      'model': model?.toJson(),
      'variant': variant,
      'year': year,
      'mileage': mileage,

      // include IDs so backend can recognize types
      'transmissionTypeId': transmissionId,
      'fuelTypeId': fuelTypeId,

      // names are optional; keep if your backend tolerates them
      'transmission': transmission,
      'fuelType': fuelType,

      'color': color,
      'isFirstOwner': isFirstOwner,
      'hasInsurance': hasInsurance,
      'hasRcBook': hasRcBook,
      'additionalFeatures': additionalFeatures,

      // property
      'propertyType': propertyType,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'areaSqft': areaSqft,
      'floor': floor,
      'isFurnished': isFurnished,
      'hasParking': hasParking,
      'hasGarden': hasGarden,
      'amenities': amenities,

      // commercial
      'bodyType': bodyType,
      'payloadCapacity': payloadCapacity,
      'payloadUnit': payloadUnit,
      'axleCount': axleCount,
      'seatingCapacity': seatingCapacity,
      'commercialVehicleType': commercialVehicleType,
      'hasFitness': hasFitness,
      'hasPermit': hasPermit,
    };
  }
}

// Helpers
Map<String, dynamic>? _asMap(dynamic v) {
  if (v == null) return null;
  if (v is Map<String, dynamic>) return v;
  if (v is Map) {
    // Try to cast if possible
    return Map<String, dynamic>.from(v);
  }
  return null;
}

int? _asInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

// Manufacturer? _parseManufacturer(dynamic v) {
//   if (v == null) return null;
//   if (v is Map<String, dynamic>) return Manufacturer.fromJson(v);
//   if (v is String)
//     return Manufacturer(id: v, displayName: ''); // only id present
//   return null;
// }

// Model? _parseModel(dynamic v) {
//   if (v == null) return null;
//   if (v is Map<String, dynamic>) return Model.fromJson(v);
//   if (v is String) return Model(id: v, name: '');
//   return null;
// }

class Manufacturer {
  final String id;
  final String? name;
  final String? displayName;
  Manufacturer({required this.id, this.name, this.displayName});

  factory Manufacturer.fromJson(Map<String, dynamic> json) => Manufacturer(
        id: (json['_id'] ?? json['id'] ?? '').toString(),
        name: (json['name'] ?? '').toString(),
        displayName: (json['displayName'] as String?)?.toString(),
      );

  Map<String, dynamic> toJson() =>
      {'id': id, 'name': name, 'displayName': displayName};
}

class Model {
  final String id;
  final String name;
  Model({required this.id, required this.name});

  factory Model.fromJson(Map<String, dynamic> json) => Model(
        id: (json['_id'] ?? json['id'] ?? '').toString(),
        name: (json['name'] ?? '').toString(),
      );

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}
