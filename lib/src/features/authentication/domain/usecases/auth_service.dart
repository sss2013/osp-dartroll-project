import 'package:cultureyo/src/features/authentication/domain/entities/auth_data.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';

enum TokenStatus {
  valid,
  expired,
  none
}

abstract class AuthService {
  Future<AuthData?> login();

  Future<AuthData?> sendTokenToServer(String accessToken, String? refreshToken);

  Future<TokenStatus> checkToken();

  Future<AuthData?> refreshToken();
}

extension AuthServiceExtension on AuthService {
  Future<TokenStatus> defaultCheckToken(FlutterSecureStorage storage) async {
    final jwt = await storage.read(key: 'server_jwt');
    final expStr = await storage.read(key: 'server_jwt_expires_at');

    if (jwt == null || expStr == null) return TokenStatus.none;

    final exp = DateTime.parse(expStr).toUtc();
    final now = DateTime.now().toUtc();
    return now.isBefore(exp) ? TokenStatus.valid : TokenStatus.expired;
  }
}
