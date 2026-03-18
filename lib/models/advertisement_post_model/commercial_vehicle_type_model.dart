class CommercialVehicleType {
  final String id;
  final String name;
  final String displayName;
  final bool isActive;
  final int sortOrder;

  const CommercialVehicleType({
    required this.id,
    required this.name,
    required this.displayName,
    required this.isActive,
    required this.sortOrder,
  });

  factory CommercialVehicleType.fromJson(Map<String, dynamic> json) {
    return CommercialVehicleType(
      id: (json['_id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      displayName: (json['displayName'] ?? json['name'] ?? '').toString(),
      isActive: json['isActive'] == true,
      sortOrder: (json['sortOrder'] is int)
          ? json['sortOrder'] as int
          : int.tryParse((json['sortOrder'] ?? '0').toString()) ?? 0,
    );
  }

  @override
  String toString() => displayName;
}
