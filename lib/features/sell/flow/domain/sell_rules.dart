import 'sell_category.dart';
import 'sell_config.dart';
import 'sell_format.dart';
import 'sell_models.dart';

/// Client rules, kept in step with the server validator (`validateCreateAdV2`)
/// so a seller sees the same message before and after posting.
class SellRules {
  SellRules._();

  static bool _empty(dynamic v) => v == null || (v is String && v.trim().isEmpty);
  static num? _num(dynamic v) => v is num ? v : num.tryParse('${v ?? ''}');

  /// Field errors for one step. Keys are [SellKeys].
  static Map<String, String> validateStep(
    SellStep step,
    SellCategory c,
    Map<String, dynamic> v,
    List<SellMediaItem> media,
    SellConfig config,
  ) {
    final e = <String, String>{};
    final l = config.limits;
    switch (step) {
      case SellStep.photos:
        final photos = media.where((m) => !m.isVideo).length;
        if (photos < l.minPhotos) e[SellKeys.photos] = 'Add at least one photo';
        break;
      case SellStep.details:
        if (c.isVehicle) _vehicle(c, v, config, e);
        if (c == SellCategory.commercial) _commercial(v, e);
        if (c == SellCategory.property) _property(v, config, e);
        break;
      case SellStep.pricePlace:
        final price = _num(v[SellKeys.price]);
        final rent = v[SellKeys.listingType] == 'rent';
        if (price == null) {
          e[SellKeys.price] = rent ? 'Enter the monthly rent' : 'Enter a price';
        } else if (price < l.priceMin) {
          e[SellKeys.price] = 'Enter a price above ₹0';
        } else if (price > l.priceMax) {
          e[SellKeys.price] = 'Price looks too high. Check the zeros';
        }
        if (_empty(v[SellKeys.location]) &&
            (v[SellKeys.latitude] == null || v[SellKeys.longitude] == null)) {
          e[SellKeys.location] = 'Choose where buyers can see it';
        }
        final title = '${v[SellKeys.title] ?? ''}'.trim();
        // Only a title the seller typed is checked; a generated one outside the
        // limits is dropped from the payload and the server writes its own.
        if (v[SellKeys.titleEdited] == true &&
            title.isNotEmpty &&
            (title.length < l.titleMin || title.length > l.titleMax)) {
          e[SellKeys.title] = 'Use ${l.titleMin}–${l.titleMax} characters';
        }
        final desc = '${v[SellKeys.description] ?? ''}'.trim();
        if (desc.length < l.descriptionMin) {
          e[SellKeys.description] = desc.isEmpty
              ? 'Tell buyers a little about it'
              : 'Add a few more words (at least ${l.descriptionMin} characters)';
        } else if (desc.length > l.descriptionMax) {
          e[SellKeys.description] = 'Keep it under ${l.descriptionMax} characters';
        }
        break;
      case SellStep.review:
        break;
    }
    return e;
  }

  static void _vehicle(SellCategory c, Map<String, dynamic> v, SellConfig config,
      Map<String, String> e) {
    final l = config.limits;
    if (_empty(v[SellKeys.brandId]) || _empty(v[SellKeys.modelId])) {
      e[SellKeys.brandId] = 'Choose the brand and model';
    }
    final year = _num(v[SellKeys.year]);
    if (year == null) {
      e[SellKeys.year] = 'Pick the year';
    } else if (year < l.yearMin || year > l.yearMax) {
      e[SellKeys.year] = 'Pick a year from ${l.yearMin} to ${l.yearMax}';
    }
    final km = _num(v[SellKeys.mileage]);
    if (km == null) {
      e[SellKeys.mileage] = 'Enter the kilometres shown on the odometer';
    } else if (km < 0 || km > l.mileageMax) {
      e[SellKeys.mileage] = 'Check the kilometres (up to ${SellFormat.indianGroup(l.mileageMax)})';
    }
    if (_empty(v[SellKeys.fuelTypeId])) e[SellKeys.fuelTypeId] = 'Choose the fuel';
    if (c != SellCategory.bike && _empty(v[SellKeys.transmissionTypeId])) {
      e[SellKeys.transmissionTypeId] = 'Choose the transmission';
    }
    if (_empty(v[SellKeys.color])) e[SellKeys.color] = 'Choose a colour';
  }

  static void _commercial(Map<String, dynamic> v, Map<String, String> e) {
    if (_empty(v[SellKeys.commercialType])) {
      e[SellKeys.commercialType] = 'Choose the vehicle type';
    }
    final axles = _num(v[SellKeys.axleCount]);
    if (axles != null && (axles < 1 || axles > 10)) {
      e[SellKeys.axleCount] = 'Axles must be between 1 and 10';
    }
    final payload = _num(v[SellKeys.payloadCapacity]);
    if (payload != null && payload < 0) {
      e[SellKeys.payloadCapacity] = 'Enter the payload';
    }
  }

  static void _property(Map<String, dynamic> v, SellConfig config, Map<String, String> e) {
    final type = v[SellKeys.propertyType] as String?;
    if (_empty(type)) {
      e[SellKeys.propertyType] = 'Choose the property type';
      return;
    }
    if (config.isResidential(type)) {
      if (_num(v[SellKeys.bedrooms]) == null) e[SellKeys.bedrooms] = 'Add bedrooms';
      if (_num(v[SellKeys.bathrooms]) == null) e[SellKeys.bathrooms] = 'Add bathrooms';
    }
    final isPlot = type == 'plot';
    final areaKey = isPlot ? SellKeys.landArea : SellKeys.builtArea;
    final area = _num(v[areaKey]);
    if (area == null || area <= 0) {
      e[areaKey] = isPlot ? 'Enter the plot area' : 'Enter the built-up area';
    }
  }

  /// Which step owns a local key, for "Fix ›" jumps.
  static SellStep stepForKey(String key) {
    const pricePlace = {
      SellKeys.price, SellKeys.location, SellKeys.latitude, SellKeys.longitude,
      SellKeys.title, SellKeys.description,
    };
    if (key == SellKeys.photos) return SellStep.photos;
    if (pricePlace.contains(key)) return SellStep.pricePlace;
    return SellStep.details;
  }

  /// Server key (`vehicle.color`, `data.price`) → local key.
  static String localKeyFor(String serverKey) {
    final parts = serverKey.split('.');
    var field = parts.length > 1 ? parts[1] : parts.first;
    field = field.replaceAll(RegExp(r'\[\d+\]$'), '');
    switch (field) {
      case 'mediaIds':
      case 'images':
      case 'videoMediaId':
        return SellKeys.photos;
      case 'manufacturerId':
      case 'modelId':
      case 'variantId':
        return SellKeys.brandId;
      case 'commercialVehicleType':
        return SellKeys.commercialType;
      case 'areaSqft':
        return SellKeys.builtArea;
      case 'landAreaSqft':
        return SellKeys.landArea;
      case 'latitude':
      case 'longitude':
        return SellKeys.location;
      case 'amenities':
      case 'additionalFeatures':
        return SellKeys.features;
      default:
        return field;
    }
  }

  /// Human label for a local key, used in the failure banner list.
  static String labelFor(String key) {
    const labels = {
      SellKeys.photos: 'Photos',
      SellKeys.brandId: 'Brand & model',
      SellKeys.year: 'Year',
      SellKeys.mileage: 'KM driven',
      SellKeys.fuelTypeId: 'Fuel',
      SellKeys.transmissionTypeId: 'Transmission',
      SellKeys.color: 'Colour',
      SellKeys.ownerCount: 'Owner',
      SellKeys.commercialType: 'Vehicle type',
      SellKeys.bodyType: 'Body type',
      SellKeys.payloadCapacity: 'Payload',
      SellKeys.axleCount: 'Axles',
      SellKeys.seatingCapacity: 'Seats',
      SellKeys.propertyType: 'Type',
      SellKeys.bedrooms: 'Bedrooms',
      SellKeys.bathrooms: 'Bathrooms',
      SellKeys.builtArea: 'Built-up area',
      SellKeys.landArea: 'Land area',
      SellKeys.floor: 'Floor',
      SellKeys.price: 'Price',
      SellKeys.location: 'Location',
      SellKeys.title: 'Title',
      SellKeys.description: 'Description',
    };
    return labels[key] ?? key;
  }

  /// "2019 Maruti Suzuki Swift VXi" / "3 BHK House in Kakkanad".
  static String suggestedTitle(SellCategory c, Map<String, dynamic> v) {
    String? s(String k) {
      final x = v[k];
      return (x == null || '$x'.trim().isEmpty) ? null : '$x'.trim();
    }

    if (c.isVehicle) {
      return [s(SellKeys.year), s(SellKeys.brandName), s(SellKeys.modelName), s(SellKeys.variantName)]
          .whereType<String>()
          .join(' ');
    }
    final type = s(SellKeys.propertyType);
    if (type == null) return '';
    final label = type[0].toUpperCase() + type.substring(1);
    final beds = s(SellKeys.bedrooms);
    final place = s(SellKeys.location)?.split(',').first;
    final head = beds != null && label != 'Plot' ? '$beds BHK $label' : label;
    final verb = v[SellKeys.listingType] == 'rent' ? 'for rent' : 'for sale';
    return [head, verb, if (place != null) 'in $place'].join(' ');
  }

  static int? _int(dynamic x) => _num(x)?.round();
  static bool? _bool(dynamic x) => x is bool ? x : null;

  /// Request body for `POST /v2/ads` (see SELL_API_CONTRACT.md §4).
  static Map<String, dynamic> buildPayload(
    SellCategory c,
    Map<String, dynamic> v,
    List<SellMediaItem> media,
  ) {
    final photos = media.where((m) => !m.isVideo && m.isDone).map((m) => m.mediaId!).toList();
    final video = media.where((m) => m.isVideo && m.isDone).map((m) => m.mediaId!).firstOrNull;
    var title = '${v[SellKeys.title] ?? ''}'.trim();
    if (title.isEmpty) title = suggestedTitle(c, v);

    final data = <String, dynamic>{
      if (title.length >= 10 && title.length <= 70) 'title': title,
      'description': '${v[SellKeys.description] ?? ''}'.trim(),
      'price': _int(v[SellKeys.price]),
      if (!_empty(v[SellKeys.location])) 'location': '${v[SellKeys.location]}'.trim(),
      if (v[SellKeys.latitude] != null) 'latitude': _num(v[SellKeys.latitude]),
      if (v[SellKeys.longitude] != null) 'longitude': _num(v[SellKeys.longitude]),
      'mediaIds': photos,
      if (video != null) 'videoMediaId': video,
    };
    final body = <String, dynamic>{'category': c.apiValue, 'data': data};

    if (c.isVehicle) {
      final owner = _int(v[SellKeys.ownerCount]);
      final variant = v[SellKeys.variantId];
      final vehicle = <String, dynamic>{
        'vehicleType': c.vehicleType,
        'manufacturerId': v[SellKeys.brandId],
        'modelId': v[SellKeys.modelId],
        if (variant is String && variant.isNotEmpty) 'variantId': variant,
        'year': _int(v[SellKeys.year]),
        'mileage': _int(v[SellKeys.mileage]),
        'fuelTypeId': v[SellKeys.fuelTypeId],
        if (!_empty(v[SellKeys.transmissionTypeId]))
          'transmissionTypeId': v[SellKeys.transmissionTypeId],
        'color': v[SellKeys.color],
        if (owner != null) 'ownerCount': owner,
        if (owner != null) 'isFirstOwner': owner == 1,
        if (_bool(v[SellKeys.hasInsurance]) != null) 'hasInsurance': v[SellKeys.hasInsurance],
        if (_bool(v[SellKeys.hasRcBook]) != null) 'hasRcBook': v[SellKeys.hasRcBook],
        'additionalFeatures': List<String>.from((v[SellKeys.features] as List?) ?? const []),
      };
      if (c == SellCategory.commercial) {
        vehicle.addAll({
          'commercialVehicleType': v[SellKeys.commercialType],
          if (!_empty(v[SellKeys.bodyType])) 'bodyType': v[SellKeys.bodyType],
          if (_num(v[SellKeys.payloadCapacity]) != null) 'payloadCapacity': _num(v[SellKeys.payloadCapacity]),
          if (_num(v[SellKeys.payloadCapacity]) != null) 'payloadUnit': v[SellKeys.payloadUnit] ?? 'kg',
          if (_int(v[SellKeys.axleCount]) != null) 'axleCount': _int(v[SellKeys.axleCount]),
          if (_int(v[SellKeys.seatingCapacity]) != null) 'seatingCapacity': _int(v[SellKeys.seatingCapacity]),
          if (_bool(v[SellKeys.hasFitness]) != null) 'hasFitness': v[SellKeys.hasFitness],
          if (_bool(v[SellKeys.hasPermit]) != null) 'hasPermit': v[SellKeys.hasPermit],
        });
        body['commercial'] = vehicle;
      } else {
        body['vehicle'] = vehicle;
      }
      return body;
    }

    final type = v[SellKeys.propertyType] as String?;
    final isPlot = type == 'plot';
    final residential = const {'apartment', 'house', 'villa'}.contains(type);
    double? sqft(String valueKey, String unitKey) {
      final n = _num(v[valueKey]);
      if (n == null) return null;
      return SellFormat.toSqft(n.toDouble(), (v[unitKey] ?? 'sqft') as String);
    }

    final land = sqft(SellKeys.landArea, SellKeys.landUnit);
    final built = isPlot ? land : sqft(SellKeys.builtArea, SellKeys.builtUnit);
    final furnishing = v[SellKeys.furnishing] as String?;
    body['property'] = <String, dynamic>{
      'listingType': isPlot ? 'sell' : (v[SellKeys.listingType] ?? 'sell'),
      'propertyType': type,
      if (residential) 'bedrooms': _int(v[SellKeys.bedrooms]),
      if (residential) 'bathrooms': _int(v[SellKeys.bathrooms]),
      if (built != null) 'areaSqft': double.parse(built.toStringAsFixed(2)),
      if (land != null) 'landAreaSqft': double.parse(land.toStringAsFixed(2)),
      if (type == 'apartment' && _int(v[SellKeys.floor]) != null) 'floor': _int(v[SellKeys.floor]),
      if (!isPlot && furnishing != null) 'furnishing': furnishing,
      if (!isPlot && furnishing != null) 'isFurnished': furnishing != 'unfurnished',
      if (!isPlot && _bool(v[SellKeys.hasParking]) != null) 'hasParking': v[SellKeys.hasParking],
      if (!isPlot && _bool(v[SellKeys.hasGarden]) != null) 'hasGarden': v[SellKeys.hasGarden],
      if (!isPlot) 'amenities': List<String>.from((v[SellKeys.features] as List?) ?? const []),
    };
    return body;
  }
}
