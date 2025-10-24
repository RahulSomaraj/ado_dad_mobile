class UserProfile {
  final String id;
  final String name;
  final String email;
  final String phoneNumber;
  final String type;
  final String? profilePic;

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.type,
    this.profilePic,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json["_id"] ?? "",
      name: json["name"] ?? "",
      email: json["email"] ?? "",
      phoneNumber: json["phoneNumber"] ?? "",
      type: json["type"] ?? "",
      profilePic: json["profilePic"],
    );
  }

  // Map<String, dynamic> toJson() {
  //   final Map<String, dynamic> json = {
  //     "_id": id,
  //     "name": name,
  //     "email": email,
  //     "phoneNumber": phoneNumber,
  //     "type": type,
  //   };

  //   // Only include profilePic if it's not null and not empty
  //   // Allow all profile picture values including 'default-profile-pic-url' - let backend handle validation
  //   if (profilePic != null && profilePic!.isNotEmpty) {
  //     json["profilePic"] = profilePic;
  //   }

  //   return json;
  // }

  Map<String, dynamic> toJson() {
    return {
      "_id": id,
      "name": name,
      "email": email,
      "phoneNumber": phoneNumber,
      "type": type,
      "profilePic": profilePic, // ✅ always include it
    };
  }

  UserProfile copyWith({
    String? id,
    String? name,
    String? email,
    String? phoneNumber,
    String? type,
    String? profilePic,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      type: type ?? this.type,
      profilePic: profilePic ?? this.profilePic,
    );
  }
}
