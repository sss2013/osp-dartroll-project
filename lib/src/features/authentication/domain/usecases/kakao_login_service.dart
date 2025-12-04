import 'package:cultureyo/src/features/authentication/domain/usecases/auth_service.dart';
import 'package:cultureyo/src/features/authentication/domain/entities/auth_data.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class KakaoLoginService implements AuthService {
  final Dio publicDio;
  final FlutterSecureStorage secureStorage;

  KakaoLoginService({required this.publicDio, required this.secureStorage});

  @override
  Future<AuthData?> login() async {
    try {
      OAuthToken result;
      if (await isKakaoTalkInstalled()) {
        result = await UserApi.instance.loginWithKakaoTalk();
      } else {
        result = await UserApi.instance.loginWithKakaoAccount();
      }
      return await sendTokenToServer(
          result.accessToken, result.refreshToken);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<AuthData?> sendTokenToServer(
      String accessToken, String? refreshToken) async {
    try {
      final resp = await publicDio.post(
        '/api/auth/exchange',
        data: {
          'provider': 'Kakao',
          'accessToken': accessToken,
          'refreshToken': refreshToken
        },
        options: Options(validateStatus: (_) => true),
      );

      if (resp.statusCode == 200) {
        final serverJwt = resp.data['access']['token'] as String;
        final serverExp =
        DateTime.parse(resp.data['access']['expiresAt']).toUtc();
        final refresh = resp.data['refresh']?['token'] as String?;
        final refreshExpStr = resp.data['refresh']?['expiresAt'] as String?;
        final refreshExp = refreshExpStr != null
            ? DateTime.parse(refreshExpStr).toUtc()
            : null;

        return AuthData(
            serverJwt: serverJwt,
            serverJwtExpiresAt: serverExp,
            refreshToken: refresh,
            refreshTokenExpiresAt: refreshExp);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<TokenStatus> checkToken() => defaultCheckToken(secureStorage);

  @override
  Future<AuthData?> refreshToken() async {
    return null;
  }
}
