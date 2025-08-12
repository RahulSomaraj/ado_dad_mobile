class LoginResponse {
  final String id;
  final String token;
  final String refreshToken;
  final String name;
  final String email;
  final String userType;

  LoginResponse({
    required this.id,
    required this.token,
    required this.refreshToken,
    required this.name,
    required this.email,
    required this.userType,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      id: json['id'].toString(),
      token: json['token'],
      refreshToken: json['refreshToken'],
      name: json['name'] ?? '',
      email: json['email'],
      userType: json['userType'],
    );
  }
}
