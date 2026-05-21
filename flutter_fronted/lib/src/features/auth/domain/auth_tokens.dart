class AuthTokens {
  const AuthTokens({
    required this.accessToken,
    required this.accessExpiresAt,
    required this.refreshToken,
  });

  final String accessToken;
  final int accessExpiresAt;
  final String refreshToken;

  Map<String, Object?> toJson() => {
    'access_token': accessToken,
    'access_expires_at': accessExpiresAt,
    'refresh_token': refreshToken,
  };

  static AuthTokens fromJson(Map<String, Object?> json) {
    return AuthTokens(
      accessToken: json['access_token'] as String,
      accessExpiresAt: (json['access_expires_at'] as num).toInt(),
      refreshToken: json['refresh_token'] as String,
    );
  }
}
