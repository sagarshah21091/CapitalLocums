class ForgotPasswordRequest {
  const ForgotPasswordRequest({required this.email});

  final String email;

  Map<String, dynamic> toJson() => {'email': email.trim()};
}

class ForgotPasswordResponse {
  const ForgotPasswordResponse({
    required this.success,
    this.message,
  });

  final bool success;
  final String? message;

  factory ForgotPasswordResponse.fromJson(Map<String, dynamic> json) {
    return ForgotPasswordResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String?,
    );
  }
}
