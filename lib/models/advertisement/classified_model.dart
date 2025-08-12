import 'vehicle_model.dart';
import 'property_model.dart';

class ClassifiedData {
  final List<Vehicle> vehicles;
  final List<Property> properties;

  ClassifiedData({
    required this.vehicles,
    required this.properties,
  });

  factory ClassifiedData.fromJson(Map<String, dynamic> json) {
    return ClassifiedData(
      vehicles: (json['vehicles'] as List)
          .map((vehicle) => Vehicle.fromJson(vehicle))
          .toList(),
      properties: (json['properties'] as List)
          .map((property) => Property.fromJson(property))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "vehicles": vehicles.map((vehicle) => vehicle.toJson()).toList(),
      "properties": properties.map((property) => property.toJson()).toList(),
    };
  }
}
