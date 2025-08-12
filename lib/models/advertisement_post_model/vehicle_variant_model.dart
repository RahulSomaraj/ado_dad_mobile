class VehicleVariant {
  final String id;
  final String name;

  VehicleVariant({required this.id, required this.name});

  factory VehicleVariant.fromJson(Map<String, dynamic> json) {
    return VehicleVariant(
      id: json['_id'],
      name: json['name'],
    );
  }

  @override
  String toString() => name;
}
