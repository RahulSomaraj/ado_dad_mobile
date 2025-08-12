class Property {
  final String propertyType;
  final String adType;
  final int bhk;
  final int bathrooms;
  final String furnished;
  final String projectStatus;
  final int maintenanceCost;
  final int totalFloors;
  final int floorNo;
  final int carParking;
  final String facing;
  final String listedBy;
  final List<String> imageUrls;
  final int sqft; // ✅ New field for property size
  final String city; // ✅ New field for city
  final String district;

  Property({
    required this.propertyType,
    required this.adType,
    required this.bhk,
    required this.bathrooms,
    required this.furnished,
    required this.projectStatus,
    required this.maintenanceCost,
    required this.totalFloors,
    required this.floorNo,
    required this.carParking,
    required this.facing,
    required this.listedBy,
    required this.imageUrls,
    required this.sqft,
    required this.city,
    required this.district,
  });

  /// **Factory constructor to create `Property` from JSON**
  factory Property.fromJson(Map<String, dynamic> json) {
    return Property(
      propertyType: json["propertyType"] ?? "",
      adType: json["adType"] ?? "",
      bhk: json["bhk"] ?? 0,
      bathrooms: json["bathrooms"] ?? 0,
      furnished: json["furnished"] ?? "",
      projectStatus: json["projectStatus"] ?? "",
      maintenanceCost: json["maintenanceCost"] ?? 0,
      totalFloors: json["totalFloors"] ?? 0,
      floorNo: json["floorNo"] ?? 0,
      carParking: json["carParking"] ?? 0,
      facing: json["facing"] ?? "",
      listedBy: json["listedBy"] ?? "",
      imageUrls: List<String>.from(json["imageUrls"] ?? []),
      sqft: json["sqft"] ?? 0,
      city: json["city"] ?? "",
      district: json["district"] ?? "",
    );
  }

  /// **Convert `Property` object to JSON**
  Map<String, dynamic> toJson() {
    return {
      "propertyType": propertyType,
      "adType": adType,
      "bhk": bhk,
      "bathrooms": bathrooms,
      "furnished": furnished,
      "projectStatus": projectStatus,
      "maintenanceCost": maintenanceCost,
      "totalFloors": totalFloors,
      "floorNo": floorNo,
      "carParking": carParking,
      "facing": facing,
      "listedBy": listedBy,
      "imageUrls": imageUrls,
    };
  }
}
