class SignupModel {
  final String id;
  final String? profilePic;
  final String? type;
  final String name;
  final String phoneNumber;
  final String email;
  final String? password;
  final String? username;
  final bool? isDeleted;
  final String? otp;
  final DateTime? otpExpires;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  SignupModel({
    required this.id,
    this.profilePic,
    this.type,
    required this.name,
    required this.phoneNumber,
    required this.email,
    this.password,
    this.username,
    this.isDeleted,
    this.otp,
    this.otpExpires,
    this.createdAt,
    this.updatedAt,
  });

  factory SignupModel.fromJson(Map<String, dynamic> json) {
    return SignupModel(
      id: json['_id'] ?? '',
      profilePic: json['profilePic'],
      type: json['type'],
      name: json['name'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      email: json['email'] ?? '',
      password: json['password'],
      username: json['username'],
      isDeleted: json['isDeleted'],
      otp: json['otp'],
      otpExpires: json['otpExpires'] != null
          ? DateTime.tryParse(json['otpExpires'])
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : null,
    );
  }

  // Map<String, dynamic> toJson() {
  //   final Map<String, dynamic> data = {};
  //   if (id.isNotEmpty) data['_id'] = id;
  //   if (profilePic != null) data['profilePic'] = profilePic;
  //   if (type != null) data['type'] = type;
  //   data['name'] = name;
  //   data['phoneNumber'] = phoneNumber;
  //   data['email'] = email;
  //   if (password != null) data['password'] = password;
  //   if (username != null) data['username'] = username;
  //   if (isDeleted != null) data['isDeleted'] = isDeleted;
  //   if (otp != null) data['otp'] = otp;
  //   if (otpExpires != null) data['otpExpires'] = otpExpires!.toIso8601String();
  //   if (createdAt != null) data['createdAt'] = createdAt!.toIso8601String();
  //   if (updatedAt != null) data['updatedAt'] = updatedAt!.toIso8601String();
  //   return data;
  // }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "email": email,
      "phoneNumber": phoneNumber,
      "password": password,
      "type": type ?? "NU",
      // "type": type,
    };
  }

  SignupModel copyWith({
    String? profilePic,
    String? type,
    String? name,
    String? phoneNumber,
    String? email,
    String? password,
    String? username,
    bool? isDeleted,
    String? otp,
    DateTime? otpExpires,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SignupModel(
      id: id,
      profilePic: profilePic ?? this.profilePic,
      type: type ?? this.type,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      password: password ?? this.password,
      username: username ?? this.username,
      isDeleted: isDeleted ?? this.isDeleted,
      otp: otp ?? this.otp,
      otpExpires: otpExpires ?? this.otpExpires,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class UserResponse {
  final List<SignupModel> users;
  final int totalPages;
  final int currentPage;

  UserResponse({
    required this.users,
    required this.totalPages,
    required this.currentPage,
  });

  factory UserResponse.fromJson(Map<String, dynamic> json) {
    return UserResponse(
      users: (json['users'] as List)
          .map((user) => SignupModel.fromJson(user))
          .toList(),
      totalPages: json['totalPages'] ?? 1,
      currentPage: json['currentPage'] ?? 1,
    );
  }
}
