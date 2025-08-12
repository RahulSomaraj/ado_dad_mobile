class VehicleManufacturer {
  final String id;
  final String displayName;

  VehicleManufacturer({
    required this.id,
    required this.displayName,
  });

  factory VehicleManufacturer.fromJson(Map<String, dynamic> json) {
    return VehicleManufacturer(
      id: json['_id'],
      displayName: json['displayName'],
    );
  }

  @override
  String toString() => displayName;
}
