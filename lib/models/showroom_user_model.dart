class ShowroomUser {
  final String id;
  final String name;
  final String email;
  final String? phoneNumber;
  final String? profilePic;
  final String type;
  final String? createdAt;
  final String? updatedAt;

  ShowroomUser({
    required this.id,
    required this.name,
    required this.email,
    this.phoneNumber,
    this.profilePic,
    required this.type,
    this.createdAt,
    this.updatedAt,
  });

  factory ShowroomUser.fromJson(Map<String, dynamic> json) {
    try {
      print('🔍 Parsing ShowroomUser from JSON: $json');

      final id = json['_id']?.toString() ?? '';
      final name = json['name'] ?? '';
      final email = json['email'] ?? '';
      final phoneNumber = json['phoneNumber'];
      final profilePic = json['profilePic'];
      final type = json['type'] ?? '';
      final createdAt = json['createdAt'];
      final updatedAt = json['updatedAt'];

      print('🔍 Parsed values:');
      print('🔍 - id: $id');
      print('🔍 - name: $name');
      print('🔍 - email: $email');
      print('🔍 - phoneNumber: $phoneNumber');
      print('🔍 - profilePic: $profilePic');
      print('🔍 - type: $type');

      return ShowroomUser(
        id: id,
        name: name,
        email: email,
        phoneNumber: phoneNumber,
        profilePic: profilePic,
        type: type,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
    } catch (e) {
      print('❌ Error parsing ShowroomUser from JSON: $e');
      print('❌ JSON data: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'profilePic': profilePic,
      'type': type,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
