class LoginRequest {
  const LoginRequest({
    required this.email,
    required this.password,
    required this.role,
  });

  final String email;
  final String password;
  final String role;

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
        'role': role,
      };
}

class LoginUser {
  const LoginUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String name;
  final String email;
  final String role;
  final bool isActive;
  final String? createdAt;
  final String? updatedAt;

  factory LoginUser.fromJson(Map<String, dynamic> json) {
    final isActiveRaw = json['is_active'];
    return LoginUser(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? '',
      isActive: isActiveRaw == true ||
          isActiveRaw == 1 ||
          isActiveRaw == '1',
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }
}

class LoginResponse {
  const LoginResponse({
    required this.success,
    this.token,
    this.user,
    this.message,
  });

  final bool success;
  final String? token;
  final LoginUser? user;
  final String? message;

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    final userRaw = json['user'];
    return LoginResponse(
      success: json['success'] as bool? ?? false,
      token: json['token'] as String?,
      user: userRaw is Map<String, dynamic>
          ? LoginUser.fromJson(userRaw)
          : null,
      message: json['message'] as String?,
    );
  }
}
