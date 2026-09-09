class VehicleTransmissionType {
  final String id;
  final String displayName;

  /// Vehicle category this type applies to (e.g. 'two_wheeler'), if the
  /// backend provides one. Null means "applies to all categories".
  final String? vehicleCategory;

  VehicleTransmissionType({
    required this.id,
    required this.displayName,
    this.vehicleCategory,
  });

  /// True when this type is usable for [category] (null category = any).
  bool appliesTo(String? category) {
    if (category == null) return true;
    final own = vehicleCategory;
    if (own == null || own.isEmpty) return true;
    return own == category;
  }

  factory VehicleTransmissionType.fromJson(Map<String, dynamic> json) {
    return VehicleTransmissionType(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      displayName: (json['displayName'] ?? json['name'] ?? '').toString(),
      vehicleCategory: _readCategory(json),
    );
  }
  static String? _readCategory(Map<String, dynamic> json) {
    final raw = json['vehicleCategory'] ?? json['category'];
    if (raw == null) return null;
    if (raw is Map) {
      final nested = raw['name'] ?? raw['slug'] ?? raw['_id'] ?? raw['id'];
      return nested?.toString();
    }
    final str = raw.toString();
    return str.isEmpty ? null : str;
  }

  @override
  String toString() => displayName;
}
