import 'sell_category.dart';

/// A lookup row served by `/v2/sell/config` (fuel, transmission, commercial type).
class SellOption {
  final String id;
  final String name;
  final String label;

  const SellOption({required this.id, required this.name, required this.label});

  factory SellOption.fromJson(Map<String, dynamic> json) {
    final name = (json['name'] ?? json['value'] ?? '').toString();
    return SellOption(
      id: (json['id'] ?? json['_id'] ?? name).toString(),
      name: name,
      label: (json['displayName'] ?? json['label'] ?? name).toString(),
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'displayName': label};
}

class SellPropertyType {
  final String value;
  final String label;
  final bool residential;

  const SellPropertyType(this.value, this.label, this.residential);

  factory SellPropertyType.fromJson(Map<String, dynamic> json) =>
      SellPropertyType(
        (json['value'] ?? '').toString(),
        (json['label'] ?? json['value'] ?? '').toString(),
        json['residential'] == true,
      );

  Map<String, dynamic> toJson() =>
      {'value': value, 'label': label, 'residential': residential};
}

class SellColor {
  final String value;
  final String label;
  final int argb;

  const SellColor(this.value, this.label, this.argb);

  factory SellColor.fromJson(Map<String, dynamic> json) {
    final hex = (json['hex'] ?? '#9E9E9E').toString().replaceAll('#', '');
    final parsed = int.tryParse(hex.length == 6 ? 'FF$hex' : hex, radix: 16);
    return SellColor(
      (json['value'] ?? '').toString(),
      (json['label'] ?? json['value'] ?? '').toString(),
      parsed ?? 0xFF9E9E9E,
    );
  }

  Map<String, dynamic> toJson() => {
        'value': value,
        'label': label,
        'hex': '#${(argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}',
      };
}

class SellLimits {
  final int minPhotos;
  final int recommendedPhotos;
  final int maxPhotos;
  final int maxImageBytes;
  final int maxVideoBytes;
  final int maxVideoSeconds;
  final int titleMin;
  final int titleMax;
  final int descriptionMin;
  final int descriptionMax;
  final int priceMin;
  final int priceMax;
  final int yearMin;
  final int yearMax;
  final int mileageMax;

  const SellLimits({
    this.minPhotos = 1,
    this.recommendedPhotos = 5,
    this.maxPhotos = 20,
    this.maxImageBytes = 10 * 1024 * 1024,
    this.maxVideoBytes = 50 * 1024 * 1024,
    this.maxVideoSeconds = 60,
    this.titleMin = 10,
    this.titleMax = 70,
    this.descriptionMin = 20,
    this.descriptionMax = 4000,
    this.priceMin = 1,
    this.priceMax = 1000000000,
    this.yearMin = 1990,
    required this.yearMax,
    this.mileageMax = 999999,
  });

  factory SellLimits.fromJson(Map<String, dynamic>? json, SellCategory c) {
    final d = SellLimits.defaults(c);
    if (json == null) return d;
    int v(String k, int fallback) {
      final raw = json[k];
      if (raw is num) return raw.toInt();
      return int.tryParse('${raw ?? ''}') ?? fallback;
    }

    return SellLimits(
      minPhotos: v('minPhotos', d.minPhotos),
      recommendedPhotos: v('recommendedPhotos', d.recommendedPhotos),
      maxPhotos: v('maxPhotos', d.maxPhotos),
      maxImageBytes: v('maxImageBytes', d.maxImageBytes),
      maxVideoBytes: v('maxVideoBytes', d.maxVideoBytes),
      maxVideoSeconds: v('maxVideoSeconds', d.maxVideoSeconds),
      titleMin: v('titleMin', d.titleMin),
      titleMax: v('titleMax', d.titleMax),
      descriptionMin: v('descriptionMin', d.descriptionMin),
      descriptionMax: v('descriptionMax', d.descriptionMax),
      priceMin: v('priceMin', d.priceMin),
      priceMax: v('priceMax', d.priceMax),
      yearMin: v('yearMin', d.yearMin),
      yearMax: v('yearMax', d.yearMax),
      mileageMax: v('mileageMax', d.mileageMax),
    );
  }

  factory SellLimits.defaults(SellCategory c) => SellLimits(
        maxPhotos: c == SellCategory.bike ? 15 : 20,
        yearMax: DateTime.now().year + 1,
      );

  Map<String, dynamic> toJson() => {
        'minPhotos': minPhotos,
        'recommendedPhotos': recommendedPhotos,
        'maxPhotos': maxPhotos,
        'maxImageBytes': maxImageBytes,
        'maxVideoBytes': maxVideoBytes,
        'maxVideoSeconds': maxVideoSeconds,
        'titleMin': titleMin,
        'titleMax': titleMax,
        'descriptionMin': descriptionMin,
        'descriptionMax': descriptionMax,
        'priceMin': priceMin,
        'priceMax': priceMax,
        'yearMin': yearMin,
        'yearMax': yearMax,
        'mileageMax': mileageMax,
      };
}

/// Everything a category's form needs, from `GET /v2/sell/config`.
/// [SellConfig.fallback] keeps the flow usable when the call has not
/// answered yet (static lists only; server lookups stay empty).
class SellConfig {
  final SellCategory category;
  final String version;
  final SellLimits limits;
  final List<SellOption> fuelTypes;
  final List<SellOption> transmissionTypes;
  final List<SellOption> commercialVehicleTypes;
  final List<SellOption> bodyTypes;
  final List<SellPropertyType> propertyTypes;
  final String manufacturerCategory;
  final List<String> features;
  final List<String> shotList;
  final List<SellColor> colors;
  final bool isFallback;

  const SellConfig({
    required this.category,
    required this.version,
    required this.limits,
    required this.fuelTypes,
    required this.transmissionTypes,
    required this.commercialVehicleTypes,
    required this.bodyTypes,
    required this.propertyTypes,
    required this.manufacturerCategory,
    required this.features,
    required this.shotList,
    required this.colors,
    this.isFallback = false,
  });

  factory SellConfig.fromJson(Map<String, dynamic> json, SellCategory c) {
    List<Map<String, dynamic>> list(String k) => (json[k] is List)
        ? (json[k] as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
        : const [];
    List<String> strings(String k) => (json[k] is List)
        ? (json[k] as List).map((e) => e.toString()).toList()
        : const [];
    final fb = SellConfig.fallback(c);
    final colors = list('colors').map(SellColor.fromJson).toList();
    final shots = strings('shotList');
    final props = list('propertyTypes').map(SellPropertyType.fromJson).toList();
    final features = strings('features');
    return SellConfig(
      category: c,
      version: (json['version'] ?? '').toString(),
      limits: SellLimits.fromJson(
          json['limits'] is Map ? Map<String, dynamic>.from(json['limits']) : null, c),
      fuelTypes: list('fuelTypes').map(SellOption.fromJson).toList(),
      transmissionTypes: list('transmissionTypes').map(SellOption.fromJson).toList(),
      commercialVehicleTypes:
          list('commercialVehicleTypes').map(SellOption.fromJson).toList(),
      bodyTypes: list('bodyTypes').isEmpty
          ? fb.bodyTypes
          : list('bodyTypes').map(SellOption.fromJson).toList(),
      propertyTypes: props.isEmpty ? fb.propertyTypes : props,
      manufacturerCategory: (json['manufacturerCategory'] ?? fb.manufacturerCategory).toString(),
      features: features.isEmpty ? fb.features : features,
      shotList: shots.isEmpty ? fb.shotList : shots,
      colors: colors.isEmpty ? fb.colors : colors,
    );
  }

  Map<String, dynamic> toJson() => {
        'version': version,
        'category': category.apiValue,
        'limits': limits.toJson(),
        'fuelTypes': fuelTypes.map((e) => e.toJson()).toList(),
        'transmissionTypes': transmissionTypes.map((e) => e.toJson()).toList(),
        'commercialVehicleTypes': commercialVehicleTypes.map((e) => e.toJson()).toList(),
        'bodyTypes': bodyTypes.map((e) => {'value': e.name, 'label': e.label}).toList(),
        'propertyTypes': propertyTypes.map((e) => e.toJson()).toList(),
        'manufacturerCategory': manufacturerCategory,
        'features': features,
        'shotList': shotList,
        'colors': colors.map((e) => e.toJson()).toList(),
      };

  factory SellConfig.fallback(SellCategory c) {
    const colors = [
      SellColor('white', 'White', 0xFFFFFFFF),
      SellColor('silver', 'Silver', 0xFFC0C4CC),
      SellColor('grey', 'Grey', 0xFF8A8F98),
      SellColor('black', 'Black', 0xFF1B1B1B),
      SellColor('red', 'Red', 0xFFC62828),
      SellColor('blue', 'Blue', 0xFF1E4DB7),
      SellColor('brown', 'Brown', 0xFF7A5A3A),
      SellColor('green', 'Green', 0xFF2E7D32),
      SellColor('yellow', 'Yellow', 0xFFF2B705),
      SellColor('orange', 'Orange', 0xFFE8660D),
    ];
    const bodyTypes = [
      SellOption(id: 'flatbed', name: 'flatbed', label: 'Flatbed'),
      SellOption(id: 'container', name: 'container', label: 'Container'),
      SellOption(id: 'refrigerated', name: 'refrigerated', label: 'Refrigerated'),
      SellOption(id: 'tanker', name: 'tanker', label: 'Tanker'),
      SellOption(id: 'dump', name: 'dump', label: 'Dump / tipper'),
      SellOption(id: 'pickup', name: 'pickup', label: 'Pickup'),
      SellOption(id: 'box', name: 'box', label: 'Box'),
      SellOption(id: 'passenger', name: 'passenger', label: 'Passenger'),
    ];
    const propertyTypes = [
      SellPropertyType('apartment', 'Apartment', true),
      SellPropertyType('house', 'House', true),
      SellPropertyType('villa', 'Villa', true),
      SellPropertyType('plot', 'Plot', false),
      SellPropertyType('commercial', 'Commercial', false),
      SellPropertyType('office', 'Office', false),
      SellPropertyType('shop', 'Shop', false),
      SellPropertyType('warehouse', 'Warehouse', false),
    ];
    final List<String> features;
    final List<String> shots;
    switch (c) {
      case SellCategory.car:
        features = const ['Sunroof', 'Reverse camera', 'Touchscreen', 'Bluetooth', 'Alloy wheels', 'Airbags', 'ABS', 'Cruise control', 'Keyless entry', 'Leather seats'];
        shots = const ['Front', 'Rear', 'Side', 'Interior', 'Odometer'];
        break;
      case SellCategory.bike:
        features = const ['ABS', 'Disc brakes', 'Alloy wheels', 'Digital console', 'USB charging', 'Self start'];
        shots = const ['Left side', 'Right side', 'Front', 'Odometer', 'Tyres'];
        break;
      case SellCategory.commercial:
        features = const ['Power steering', 'AC cabin', 'GPS tracker', 'Music system'];
        shots = const ['Front', 'Rear', 'Side', 'Cabin', 'Odometer'];
        break;
      case SellCategory.property:
        features = const ['Lift', 'Power backup', 'Security', 'Covered parking', 'Well water', 'Municipal water', 'Gym', 'Swimming pool', 'Garden', 'Vastu compliant'];
        shots = const ['Exterior', 'Hall', 'Kitchen', 'Bedroom', 'Bathroom'];
        break;
    }
    return SellConfig(
      category: c,
      version: 'fallback',
      limits: SellLimits.defaults(c),
      fuelTypes: const [],
      transmissionTypes: const [],
      commercialVehicleTypes: const [],
      bodyTypes: bodyTypes,
      propertyTypes: propertyTypes,
      manufacturerCategory: c.defaultManufacturerCategory,
      features: features,
      shotList: shots,
      colors: colors,
      isFallback: true,
    );
  }

  bool isResidential(String? propertyType) =>
      propertyTypes.any((p) => p.value == propertyType && p.residential);
}
