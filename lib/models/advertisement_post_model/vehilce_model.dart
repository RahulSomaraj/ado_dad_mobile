class VehicleModel {
  final String id;
  final String displayName;

  /// Fuel and gearbox types this model is actually built with, as display
  /// names ("Petrol", "Automatic") — `VehicleModel.fuelTypes` /
  /// `transmissionTypes` on the server.
  ///
  /// `GET /vehicle-inventory/models` returns the whole document (no
  /// projection), so these have always been on the wire; the app just dropped
  /// them. They are what lets the sell flow state a fact — an Activa is
  /// gearless, a Dominar is geared — instead of asking the seller to pick.
  /// Empty when the catalogue has not filled them in.
  final List<String> fuelTypes;
  final List<String> transmissionTypes;

  VehicleModel({
    required this.id,
    required this.displayName,
    this.fuelTypes = const [],
    this.transmissionTypes = const [],
  });

  static List<String> _names(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .map((e) => '$e'.trim())
        .where((s) => s.isNotEmpty)
        .toList(growable: false);
  }

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    return VehicleModel(
      id: json['_id'],
      displayName: json['displayName'],
      fuelTypes: _names(json['fuelTypes']),
      transmissionTypes: _names(json['transmissionTypes']),
    );
  }

  @override
  String toString() => displayName;
}
