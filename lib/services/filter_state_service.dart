class FilterStateService {
  static final FilterStateService _instance = FilterStateService._internal();
  factory FilterStateService() => _instance;
  FilterStateService._internal();

  // Property filter states
  final Map<String, PropertyFilterState> _propertyFilterStates = {};

  // Car filter states
  final Map<String, CarFilterState> _carFilterStates = {};

  // Property filter state management
  void savePropertyFilterState(String categoryId, PropertyFilterState state) {
    _propertyFilterStates[categoryId] = state;
  }

  PropertyFilterState? getPropertyFilterState(String categoryId) {
    return _propertyFilterStates[categoryId];
  }

  void clearPropertyFilterState(String categoryId) {
    _propertyFilterStates.remove(categoryId);
  }

  // Car filter state management
  void saveCarFilterState(String categoryId, CarFilterState state) {
    _carFilterStates[categoryId] = state;
  }

  CarFilterState? getCarFilterState(String categoryId) {
    return _carFilterStates[categoryId];
  }

  void clearCarFilterState(String categoryId) {
    _carFilterStates.remove(categoryId);
  }

  // Clear all states
  void clearAllStates() {
    _propertyFilterStates.clear();
    _carFilterStates.clear();
  }
}

class PropertyFilterState {
  final Set<String> selectedPropertyTypes;
  final String? minBedrooms;
  final String? maxBedrooms;
  final String? minPrice;
  final String? maxPrice;
  final String? minArea;
  final String? maxArea;
  final bool? isFurnished;
  final bool? hasParking;
  final String propertyTypeQuery;

  PropertyFilterState({
    this.selectedPropertyTypes = const {},
    this.minBedrooms,
    this.maxBedrooms,
    this.minPrice,
    this.maxPrice,
    this.minArea,
    this.maxArea,
    this.isFurnished,
    this.hasParking,
    this.propertyTypeQuery = '',
  });

  PropertyFilterState copyWith({
    Set<String>? selectedPropertyTypes,
    String? minBedrooms,
    String? maxBedrooms,
    String? minPrice,
    String? maxPrice,
    String? minArea,
    String? maxArea,
    bool? isFurnished,
    bool? hasParking,
    String? propertyTypeQuery,
  }) {
    return PropertyFilterState(
      selectedPropertyTypes:
          selectedPropertyTypes ?? this.selectedPropertyTypes,
      minBedrooms: minBedrooms ?? this.minBedrooms,
      maxBedrooms: maxBedrooms ?? this.maxBedrooms,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      minArea: minArea ?? this.minArea,
      maxArea: maxArea ?? this.maxArea,
      isFurnished: isFurnished ?? this.isFurnished,
      hasParking: hasParking ?? this.hasParking,
      propertyTypeQuery: propertyTypeQuery ?? this.propertyTypeQuery,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'propertyTypes': selectedPropertyTypes.toList(),
      'minBedrooms': minBedrooms,
      'maxBedrooms': maxBedrooms,
      'minPrice': minPrice,
      'maxPrice': maxPrice,
      'minArea': minArea,
      'maxArea': maxArea,
      'isFurnished': isFurnished,
      'hasParking': hasParking,
    };
  }

  bool get isEmpty {
    return selectedPropertyTypes.isEmpty &&
        minBedrooms == null &&
        maxBedrooms == null &&
        minPrice == null &&
        maxPrice == null &&
        minArea == null &&
        maxArea == null &&
        isFurnished == null &&
        hasParking == null;
  }
}

class CarFilterState {
  final Set<String> selectedManufacturerIds;
  final Set<String> selectedFuelTypeIds;
  final Set<String> selectedTransmissionTypeIds;
  final Set<String> selectedModelIds;
  final String? minYear;
  final String? maxYear;
  final String? minPrice;
  final String? maxPrice;
  final String brandQuery;
  final String modelQuery;

  CarFilterState({
    this.selectedManufacturerIds = const {},
    this.selectedFuelTypeIds = const {},
    this.selectedTransmissionTypeIds = const {},
    this.selectedModelIds = const {},
    this.minYear,
    this.maxYear,
    this.minPrice,
    this.maxPrice,
    this.brandQuery = '',
    this.modelQuery = '',
  });

  CarFilterState copyWith({
    Set<String>? selectedManufacturerIds,
    Set<String>? selectedFuelTypeIds,
    Set<String>? selectedTransmissionTypeIds,
    Set<String>? selectedModelIds,
    String? minYear,
    String? maxYear,
    String? minPrice,
    String? maxPrice,
    String? brandQuery,
    String? modelQuery,
  }) {
    return CarFilterState(
      selectedManufacturerIds:
          selectedManufacturerIds ?? this.selectedManufacturerIds,
      selectedFuelTypeIds: selectedFuelTypeIds ?? this.selectedFuelTypeIds,
      selectedTransmissionTypeIds:
          selectedTransmissionTypeIds ?? this.selectedTransmissionTypeIds,
      selectedModelIds: selectedModelIds ?? this.selectedModelIds,
      minYear: minYear ?? this.minYear,
      maxYear: maxYear ?? this.maxYear,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      brandQuery: brandQuery ?? this.brandQuery,
      modelQuery: modelQuery ?? this.modelQuery,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'manufacturerIds': selectedManufacturerIds.toList(),
      'fuelTypeIds': selectedFuelTypeIds.toList(),
      'transmissionTypeIds': selectedTransmissionTypeIds.toList(),
      'modelIds': selectedModelIds.toList(),
      'minYear': minYear,
      'maxYear': maxYear,
      'minPrice': minPrice,
      'maxPrice': maxPrice,
    };
  }

  bool get isEmpty {
    return selectedManufacturerIds.isEmpty &&
        selectedFuelTypeIds.isEmpty &&
        selectedTransmissionTypeIds.isEmpty &&
        selectedModelIds.isEmpty &&
        minYear == null &&
        maxYear == null &&
        minPrice == null &&
        maxPrice == null;
  }
}
