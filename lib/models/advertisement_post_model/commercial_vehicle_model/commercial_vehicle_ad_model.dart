class CommercialVehicleAdModel {
  // final String title;
  final String description;
  final int price;
  final String location;
  final List<String> images;
  final String vehicleType;
  final String commercialVehicleType;
  final String bodyType;
  final String manufacturerId;
  final String modelId;
  final String variantId;
  final int year;
  final int mileage;
  final String transmissionTypeId;
  final String fuelTypeId;
  final String color;
  final int payloadCapacity;
  final String payloadUnit;
  final int axleCount;
  final bool hasInsurance;
  final bool hasFitness;
  final bool hasPermit;
  final List<String> additionalFeatures;
  final int seatingCapacity;

  CommercialVehicleAdModel({
    // required this.title,
    required this.description,
    required this.price,
    required this.location,
    required this.images,
    required this.vehicleType,
    required this.commercialVehicleType,
    required this.bodyType,
    required this.manufacturerId,
    required this.modelId,
    required this.variantId,
    required this.year,
    required this.mileage,
    required this.transmissionTypeId,
    required this.fuelTypeId,
    required this.color,
    required this.payloadCapacity,
    required this.payloadUnit,
    required this.axleCount,
    required this.hasInsurance,
    required this.hasFitness,
    required this.hasPermit,
    required this.additionalFeatures,
    required this.seatingCapacity,
  });

  Map<String, dynamic> toJson() {
    return {
      // 'title': title,
      'description': description,
      'price': price,
      'location': location,
      'images': images,
      'vehicleType': vehicleType,
      'commercialVehicleType': commercialVehicleType,
      'bodyType': bodyType,
      'manufacturerId': manufacturerId,
      'modelId': modelId,
      'variantId': variantId,
      'year': year,
      'mileage': mileage,
      'transmissionTypeId': transmissionTypeId,
      'fuelTypeId': fuelTypeId,
      'color': color,
      'payloadCapacity': payloadCapacity,
      'payloadUnit': payloadUnit,
      'axleCount': axleCount,
      'hasInsurance': hasInsurance,
      'hasFitness': hasFitness,
      'hasPermit': hasPermit,
      'additionalFeatures': additionalFeatures,
      'seatingCapacity': seatingCapacity,
    };
  }
}
