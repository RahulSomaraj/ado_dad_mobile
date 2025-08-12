import 'vehicle_details_model.dart';

class Vehicle {
  final String type;
  final String modelType;
  final String adTitle;
  final String description;
  final int price;
  final List<String> imageUrls;
  final String state;
  final String city;
  final String district;
  final bool isApproved;
  final bool isFavorite;
  final String category;
  final VehicleDetails vehicleDetails;
  final bool isPremium;
  final bool isShowroom;
  final int kmDriven;

  Vehicle(
      {required this.type,
      required this.modelType,
      required this.adTitle,
      required this.description,
      required this.price,
      required this.imageUrls,
      required this.state,
      required this.city,
      required this.district,
      required this.isApproved,
      required this.isFavorite,
      required this.category,
      required this.vehicleDetails,
      required this.isPremium,
      required this.isShowroom,
      required this.kmDriven});

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      type: json["type"] ?? "",
      modelType: json["modelType"] ?? "",
      adTitle: json["adTitle"] ?? "",
      description: json["description"] ?? "",
      price: json["price"] ?? 0,
      imageUrls: List<String>.from(json["imageUrls"] ?? []),
      state: json["state"] ?? "",
      city: json["city"] ?? "",
      district: json["district"] ?? "",
      isApproved: json["isApproved"] ?? false,
      isFavorite: json["isFavorite"] ?? false,
      category: json["category"] ?? "",
      vehicleDetails: VehicleDetails.fromJson(json["vehicle"]),
      isPremium: json["isPremium"] ?? false,
      isShowroom: json["isShowroom"] ?? false,
      kmDriven: json["kmDriven"] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "type": type,
      "modelType": modelType,
      "adTitle": adTitle,
      "description": description,
      "price": price,
      "imageUrls": imageUrls,
      "state": state,
      "city": city,
      "district": district,
      "isApproved": isApproved,
      "isFavorite": isFavorite,
      "category": category,
      "vehicle": vehicleDetails.toJson(),
      "isPremium": isPremium,
      "isShowroom": isShowroom,
      "kmDriven": kmDriven,
    };
  }
}
