// import 'package:freezed_annotation/freezed_annotation.dart';

// part 'add_model.freezed.dart';
// part 'add_model.g.dart';

// @freezed
// class AddModel with _$AddModel {
//   const factory AddModel({
//     required String id,
//     required String? description,
//     required int price,
//     required List<String?> images,
//     required String? location,
//     required String? category,
//     required bool isActive,
//     required String updatedAt,
//     required String postedBy,
//   }) = _AddModel;

//   factory AddModel.fromJson(Map<String, dynamic> json) =>
//       _$AddModelFromJson(json);
// }

// REMOVE these lines
// import 'package:freezed_annotation/freezed_annotation.dart';
// part 'add_model.freezed.dart';
// part 'add_model.g.dart';

// ✅ KEEP this import
// import 'dart:convert';

class AddModel {
  final String id;
  final String description;
  final int price;
  final List<String> images;
  final String location;
  final String category;
  final bool isActive;
  final String updatedAt;

  AddModel({
    required this.id,
    required this.description,
    required this.price,
    required this.images,
    required this.location,
    required this.category,
    required this.isActive,
    required this.updatedAt,
  });

  factory AddModel.fromJson(Map<String, dynamic> json) {
    return AddModel(
      id: json['id'] as String? ?? '',
      description: json['description'] as String? ?? '',
      price: json['price'] as int? ?? 0,
      images: (json['images'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      location: json['location'] as String? ?? '',
      category: json['category'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? false,
      updatedAt: json['updatedAt'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'price': price,
      'images': images,
      'location': location,
      'category': category,
      'isActive': isActive,
      'updatedAt': updatedAt,
    };
  }
}
