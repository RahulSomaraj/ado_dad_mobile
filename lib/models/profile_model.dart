class UserProfile {
  final String id;
  final String name;
  final String email;
  final String phoneNumber;
  final String type;
  final String profilePic;

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.type,
    required this.profilePic,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json["_id"] ?? "",
      name: json["name"] ?? "",
      email: json["email"] ?? "",
      phoneNumber: json["phoneNumber"] ?? "",
      type: json["type"] ?? "",
      profilePic: json["profilePic"] ?? "default-profile-pic-url",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "_id": id,
      "name": name,
      "email": email,
      "phoneNumber": phoneNumber,
      "type": type,
      "profilePic": profilePic,
    };
  }
}
