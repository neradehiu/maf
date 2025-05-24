class AuthResponse {
  final String? token;
  final String message;

  AuthResponse({this.token, required this.message});

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'],
      message: json['message'],
    );
  }
}
