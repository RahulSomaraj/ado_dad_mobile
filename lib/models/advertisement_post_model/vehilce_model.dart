class VehicleModel {
  final String id;
  final String name;

  VehicleModel({required this.id, required this.name});

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    return VehicleModel(
      id: json['_id'],
      name: json['name'],
    );
  }

  @override
  String toString() => name;
}
