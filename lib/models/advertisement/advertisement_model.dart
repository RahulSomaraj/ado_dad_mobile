class AdvertisementModel {
  final String id;
  final String type;
  final String description;
  final int price;
  final String state;
  final String city;
  final String? district;
  final Category? category;
  final List<String>? imageUrls;

  // Define the Category class

  AdvertisementModel({
    required this.id,
    required this.type,
    required this.description,
    required this.price,
    required this.state,
    required this.city,
    this.district,
    required this.category,
    this.imageUrls,
  });

  factory AdvertisementModel.fromJson(Map<String, dynamic> json) {
    return AdvertisementModel(
      id: json['_id'] ?? '',
      type: json['type'],
      description: json['description'],
      price: json['price'],
      state: json['state'],
      city: json['city'],
      district: json['district'],
      category:
          json['category'] != null ? Category.fromJson(json['category']) : null,
      imageUrls: List<String>.from(json["imageUrls"] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'type': type,
      'description': description,
      'price': price,
      'state': state,
      'city': city,
      'district': district,
      'category': category?.id,
      "imageUrls": imageUrls,
    };
  }
}

class Category {
  final String id;
  final String name;

  Category({required this.id, required this.name});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}

class DetailedCategory extends Category {
  final String? icon;
  final String? parent;
  final DateTime? deletedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  DetailedCategory({
    required String id,
    required String name,
    this.icon,
    this.parent,
    this.deletedAt,
    this.createdAt,
    this.updatedAt,
  }) : super(id: id, name: name);

  factory DetailedCategory.fromJson(Map<String, dynamic> json) {
    return DetailedCategory(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      icon: json['icon'],
      parent: json['parent'],
      deletedAt:
          json['deletedAt'] != null ? DateTime.parse(json['deletedAt']) : null,
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'icon': icon,
      'parent': parent,
      'deletedAt': deletedAt?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
