class VehicleModel {
  final String id;
  final String displayName;

  VehicleModel({required this.id, required this.displayName});

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    return VehicleModel(
      id: json['_id'],
      displayName: json['displayName'],
    );
  }

  @override
  String toString() => displayName;
}
