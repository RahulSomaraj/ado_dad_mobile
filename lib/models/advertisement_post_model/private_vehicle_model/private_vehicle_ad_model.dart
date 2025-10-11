class PrivateVehicleAdModel {
  // final String title;
  final String description;
  final int price;
  final String location;
  final List<String> images;
  final String vehicleType;
  final String manufacturerId;
  final String modelId;
  final String variantId;
  final int year;
  final int mileage;
  final String transmissionTypeId;
  final String fuelTypeId;
  final String color;
  final bool isFirstOwner;
  final bool hasInsurance;
  final bool hasRcBook;
  final List<String> additionalFeatures;
  final String? link; // Video URL

  PrivateVehicleAdModel({
    // required this.title,
    required this.description,
    required this.price,
    required this.location,
    required this.images,
    required this.vehicleType,
    required this.manufacturerId,
    required this.modelId,
    required this.variantId,
    required this.year,
    required this.mileage,
    required this.transmissionTypeId,
    required this.fuelTypeId,
    required this.color,
    required this.isFirstOwner,
    required this.hasInsurance,
    required this.hasRcBook,
    required this.additionalFeatures,
    this.link,
  });

  Map<String, dynamic> toJson() {
    return {
      // 'title': title,
      'description': description,
      'price': price,
      'location': location,
      'images': images,
      'vehicleType': vehicleType,
      'manufacturerId': manufacturerId,
      'modelId': modelId,
      'variantId': variantId,
      'year': year,
      'mileage': mileage,
      'transmissionTypeId': transmissionTypeId,
      'fuelTypeId': fuelTypeId,
      'color': color,
      'isFirstOwner': isFirstOwner,
      'hasInsurance': hasInsurance,
      'hasRcBook': hasRcBook,
      'additionalFeatures': additionalFeatures,
      'link': link,
    };
  }
}
