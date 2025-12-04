class AuthData {
  final String serverJwt;
  final DateTime serverJwtExpiresAt;
  final String? refreshToken;
  final DateTime? refreshTokenExpiresAt;

  // final String? provider;
  // final DateTime? providerAccessToken;

  AuthData({
    required this.serverJwt,
    required this.serverJwtExpiresAt,
    this.refreshToken,
    this.refreshTokenExpiresAt,
  });
}