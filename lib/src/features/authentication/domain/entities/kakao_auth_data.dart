class KakaoAuthData {
  final String accessToken;
  final String? refreshToken;
  final DateTime accessTokenExpiresAt;
  final DateTime? refreshTokenExpiresAt;

  KakaoAuthData({
    required this.accessToken,
    this.refreshToken,
    required this.accessTokenExpiresAt,
    this.refreshTokenExpiresAt,
  });

  Map<String, dynamic> toJson() => {
    'access_token': accessToken,
    'refresh_token': refreshToken,
    'access_token_expires_at': accessTokenExpiresAt.toUtc().toIso8601String(),
    'refresh_token_expires_at': refreshTokenExpiresAt?.toUtc().toIso8601String(),
  };

  // @override
  // String toString() {
  //   return 'KakaoAuthData(accessToken: $accessToken, accessExp: ${accessTokenExpiresAt.toIso8601String()}, refreshToken: $refreshToken, refreshExp: ${refreshTokenExpiresAt?.toIso8601String()})';
  // }
}