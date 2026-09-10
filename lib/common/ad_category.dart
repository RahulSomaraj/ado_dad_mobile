/// The four advertisement categories the backend knows about.
///
/// Replaces the raw string literals `'two_wheeler'`, `'private_vehicle'`,
/// `'commercial_vehicle'` and `'property'` that are compared by hand in a
/// dozen places (sell flow, edit forms, filters, search, my-ads, showroom,
/// seller profile, ad detail). Parse once at the boundary with [fromApi] and
/// switch on the enum instead.
///
/// Pure Dart — no Flutter imports — so models and repositories can use it too.
///
/// NOTE: the `'showroom'` `categoryId` that appears in `cayegory_model.dart`
/// is *not* an ad category (it routes to the showroom list, it is never an
/// advertisement's `category` field), so it is deliberately not a member here
/// and [fromApi] returns `null` for it.
library;

enum AdCategory {
  /// Bikes and scooters — API `two_wheeler`.
  twoWheeler,

  /// Cars and premium vehicles — API `private_vehicle`.
  privateVehicle,

  /// Trucks, autos and buses — API `commercial_vehicle`.
  commercialVehicle,

  /// Real estate, for sale or for rent — API `property`.
  property;

  /// Parses a raw category string coming from the API, a route payload or a
  /// stored filter value.
  ///
  /// Tolerant by design: input is trimmed, lower-cased and stripped of
  /// separators, so `'two_wheeler'`, `'two-wheeler'`, `'Two Wheeler'`,
  /// `'twoWheeler'` and `'two_wheelers'` all parse to
  /// [AdCategory.twoWheeler]. Anything containing `propert` (`'property'`,
  /// `'Properties'`) parses to [AdCategory.property], matching the
  /// `category.toLowerCase().contains('propert')` check the cards used.
  ///
  /// Returns `null` for `null`, blank or unrecognised input — callers decide
  /// what an unknown category means (usually: hide the category-specific UI).
  static AdCategory? fromApi(String? raw) {
    if (raw == null) return null;
    // Collapse every spelling to bare letters: 'Two Wheeler', 'two-wheeler',
    // 'twoWheeler' and 'two_wheeler' all become 'twowheeler'.
    final String key = raw.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
    if (key.isEmpty) return null;
    switch (key) {
      case 'twowheeler':
      case 'twowheelers':
      case 'bike':
      case 'bikes':
        return AdCategory.twoWheeler;
      case 'privatevehicle':
      case 'privatevehicles':
      case 'car':
      case 'cars':
        return AdCategory.privateVehicle;
      case 'commercialvehicle':
      case 'commercialvehicles':
        return AdCategory.commercialVehicle;
    }
    if (key.startsWith('propert') || key == 'realestate') {
      return AdCategory.property;
    }
    return null;
  }

  /// The exact string the backend sends and expects. Round-trips with
  /// [fromApi]: `AdCategory.fromApi(c.apiValue) == c` for every member.
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
    }
  }

  /// Human-readable name for headings, chips and filter labels.
  String get label {
    switch (this) {
      case AdCategory.twoWheeler:
        return 'Two wheeler';
      case AdCategory.privateVehicle:
        return 'Car';
      case AdCategory.commercialVehicle:
        return 'Commercial vehicle';
      case AdCategory.property:
        return 'Property';
    }
  }

  /// Route for the "post a new ad" form of this category.
  ///
  /// Verified against `lib/common/app_routes.dart` (paths declared at lines
  /// 229 / 243 / 257 / 271).
  String get addRoute {
    switch (this) {
      case AdCategory.twoWheeler:
        return '/add-two-wheeler-form';
      case AdCategory.privateVehicle:
        return '/add-private-vehicle-form';
      case AdCategory.commercialVehicle:
        return '/add-commercial-vehicle-form';
      case AdCategory.property:
        return '/add-property-form';
    }
  }

  /// Route for the "edit an existing ad" form of this category.
  ///
  /// Verified against `lib/common/app_routes.dart` (paths declared at lines
  /// 285 / 293 / 301 / 309). Note these are *not* suffixed with `-form`,
  /// unlike [addRoute].
  String get editRoute {
    switch (this) {
      case AdCategory.twoWheeler:
        return '/edit-two-wheeler';
      case AdCategory.privateVehicle:
        return '/edit-private-vehicle';
      case AdCategory.commercialVehicle:
        return '/edit-commercial-vehicle';
      case AdCategory.property:
        return '/edit-property';
    }
  }

  /// True for the three vehicle categories — the ones that have a
  /// manufacturer, model, year, fuel type, transmission and mileage, and for
  /// which an EMI estimate makes sense.
  bool get isVehicle => this != AdCategory.property;

  /// True only for [AdCategory.property] — bedrooms, bathrooms, area, and a
  /// sale/rent listing type instead of vehicle specs.
  bool get isProperty => this == AdCategory.property;
}
