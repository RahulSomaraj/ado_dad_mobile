class VehicleFuelType {
  final String id;
  final String displayName;

  VehicleFuelType({
    required this.id,
    required this.displayName,
  });

  factory VehicleFuelType.fromJson(Map<String, dynamic> json) {
    return VehicleFuelType(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      displayName: (json['displayName'] ?? json['name'] ?? '').toString(),
    );
  }
  @override
  String toString() => displayName;
}
