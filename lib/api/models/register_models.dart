class RegisterResponse {
  const RegisterResponse({
    required this.success,
    this.message,
  });

  final bool success;
  final String? message;

  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    return RegisterResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String?,
    );
  }
}
