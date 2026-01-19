class VehicleManufacturer {
  final String id;
  final String displayName;

  /// Backend vehicle category for this manufacturer
  /// (e.g. 'two_wheeler', 'private_vehicle') used to filter brands per category in UI.
  final String? vehicleCategory;

  VehicleManufacturer({
    required this.id,
    required this.displayName,
    this.vehicleCategory,
  });

  factory VehicleManufacturer.fromJson(Map<String, dynamic> json) {
    return VehicleManufacturer(
      id: json['_id']?.toString() ?? '',
      displayName: json['displayName']?.toString() ?? '',
      vehicleCategory: json['vehicleCategory']?.toString(),
    );
  }

  @override
  String toString() => displayName;
}
