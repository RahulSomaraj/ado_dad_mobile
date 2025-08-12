import 'dart:convert';

class BannerModel {
  final String id;
  final String title;
  final String desktopImage;
  final String phoneImage;
  final String tabletImage;
  final String link;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int v;

  BannerModel({
    required this.id,
    required this.title,
    required this.desktopImage,
    required this.phoneImage,
    required this.tabletImage,
    required this.link,
    required this.createdAt,
    required this.updatedAt,
    required this.v,
  });

  /// Convert JSON to `BannerModel`
  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      desktopImage: json['desktopImage'] ?? '',
      phoneImage: json['phoneImage'] ?? '',
      tabletImage: json['tabletImage'] ?? '',
      link: json['link'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      v: json['__v'] ?? 0,
    );
  }

  /// Convert `BannerModel` to JSON
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'desktopImage': desktopImage,
      'phoneImage': phoneImage,
      'tabletImage': tabletImage,
      'link': link,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      '__v': v,
    };
  }
}

/// **Main Model for the API Response**
class BannerResponse {
  final List<BannerModel> banners;
  final int totalPages;
  final int currentPage;

  BannerResponse({
    required this.banners,
    required this.totalPages,
    required this.currentPage,
  });

  /// Convert JSON to `BannerResponse`
  factory BannerResponse.fromJson(Map<String, dynamic> json) {
    return BannerResponse(
      banners: (json['banners'] as List<dynamic>)
          .map((banner) => BannerModel.fromJson(banner))
          .toList(),
      totalPages: json['totalPages'] ?? 1,
      currentPage: json['currentPage'] ?? 1,
    );
  }

  /// Convert `BannerResponse` to JSON
  Map<String, dynamic> toJson() {
    return {
      'banners': banners.map((banner) => banner.toJson()).toList(),
      'totalPages': totalPages,
      'currentPage': currentPage,
    };
  }
}

/// **Helper method to parse JSON String into `BannerResponse`**
BannerResponse parseBannerResponse(String jsonString) {
  final Map<String, dynamic> jsonData = json.decode(jsonString);
  return BannerResponse.fromJson(jsonData);
}
