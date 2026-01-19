class VehicleVariant {
  final String id;
  final String name;

  VehicleVariant({required this.id, required this.name});

  factory VehicleVariant.fromJson(Map<String, dynamic> json) {
    return VehicleVariant(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: (json['name'] ?? json['displayName'] ?? '').toString(),
    );
  }

  @override
  String toString() => name;
}
