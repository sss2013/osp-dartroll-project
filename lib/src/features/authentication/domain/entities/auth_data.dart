class AuthData {
  final String accessToken;
  final DateTime accessTokenExpiresAt;

  final String? refreshToken;
  final DateTime? refreshTokenExpiresAt;

  AuthData({
    required this.accessToken,
    required this.accessTokenExpiresAt,
    this.refreshToken,
    this.refreshTokenExpiresAt,
  });

  Map<String, dynamic> toJson() => {
    'access_token': accessToken,
    'refresh_token': refreshToken,
    'access_token_expires_at': accessTokenExpiresAt.toUtc().toIso8601String(),
    'refresh_token_expires_at': refreshTokenExpiresAt?.toUtc().toIso8601String(),
  };

  @override
  String toString() {
    return 'AuthData(accessToken: $accessToken, accessExp: ${accessTokenExpiresAt.toIso8601String()}, refreshToken: $refreshToken, refreshExp: ${refreshTokenExpiresAt?.toIso8601String()})';
  }

}