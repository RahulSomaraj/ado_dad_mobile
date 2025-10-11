class PropertyAdModel {
  // final String title;
  final String description;
  final int price;
  final String location;
  final List<String> images;
  final String propertyType;
  final int bedrooms;
  final int bathrooms;
  final int areaSqft;
  final int floor;
  final bool isFurnished;
  final bool hasParking;
  final bool hasGarden;
  final List<String> amenities;
  final String? link; // Video URL

  PropertyAdModel({
    // required this.title,
    required this.description,
    required this.price,
    required this.location,
    required this.images,
    required this.propertyType,
    required this.bedrooms,
    required this.bathrooms,
    required this.areaSqft,
    required this.floor,
    required this.isFurnished,
    required this.hasParking,
    required this.hasGarden,
    required this.amenities,
    this.link,
  });

  Map<String, dynamic> toJson() {
    return {
      // 'title': title,
      'description': description,
      'price': price,
      'location': location,
      'images': images,
      'propertyType': propertyType,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'areaSqft': areaSqft,
      'floor': floor,
      'isFurnished': isFurnished,
      'hasParking': hasParking,
      'hasGarden': hasGarden,
      'amenities': amenities,
      'link': link,
    };
  }
}
