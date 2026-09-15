/// The four ad categories, replacing raw string comparisons like
/// `ad.category == 'property'` scattered across screens.
enum AdCategory {
  twoWheeler,
  privateVehicle,
  commercialVehicle,
  property,
  unknown;

  /// Tolerant of case, dashes and spaces: "commercial-vehicle",
  /// "Commercial Vehicle" and "commercial_vehicle" all resolve.
  static AdCategory fromApi(String? raw) {
    final v = (raw ?? '')
        .toLowerCase()
        .replaceAll(RegExp(r'[\s\-]+'), '_')
        .trim();
    switch (v) {
      case 'two_wheeler':
      case 'twowheeler':
      case 'bike':
        return AdCategory.twoWheeler;
      case 'private_vehicle':
      case 'privatevehicle':
      case 'car':
        return AdCategory.privateVehicle;
      case 'commercial_vehicle':
      case 'commercialvehicle':
        return AdCategory.commercialVehicle;
      case 'property':
      case 'properties':
        return AdCategory.property;
      default:
        if (v.contains('propert')) return AdCategory.property;
        return AdCategory.unknown;
    }
  }

  String get apiValue {
    switch (this) {
      case AdCategory.twoWheeler:
        return 'two_wheeler';
      case AdCategory.privateVehicle:
        return 'private_vehicle';
      case AdCategory.commercialVehicle:
        return 'commercial_vehicle';
      case AdCategory.property:
        return 'property';
      case AdCategory.unknown:
        return '';
    }
  }

  String get label {
    switch (this) {
      case AdCategory.twoWheeler:
        return 'Two-wheeler';
      case AdCategory.privateVehicle:
        return 'Car';
      case AdCategory.commercialVehicle:
        return 'Commercial vehicle';
      case AdCategory.property:
        return 'Property';
      case AdCategory.unknown:
        return 'Ad';
    }
  }

  /// Edit routes (no `-form` suffix; the post routes have one).
  String? get editRoute {
    switch (this) {
      case AdCategory.twoWheeler:
        return '/edit-two-wheeler';
      case AdCategory.privateVehicle:
        return '/edit-private-vehicle';
      case AdCategory.commercialVehicle:
        return '/edit-commercial-vehicle';
      case AdCategory.property:
        return '/edit-property';
      case AdCategory.unknown:
        return null;
    }
  }

  bool get isVehicle =>
      this == AdCategory.twoWheeler ||
      this == AdCategory.privateVehicle ||
      this == AdCategory.commercialVehicle;

  bool get isProperty => this == AdCategory.property;
}
