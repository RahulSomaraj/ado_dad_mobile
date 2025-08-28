class VehicleTransmissionType {
  final String id;
  final String displayName;

  VehicleTransmissionType({
    required this.id,
    required this.displayName,
  });

  factory VehicleTransmissionType.fromJson(Map<String, dynamic> json) {
    return VehicleTransmissionType(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      displayName: (json['displayName'] ?? json['name'] ?? '').toString(),
    );
  }
  @override
  String toString() => displayName;
}
