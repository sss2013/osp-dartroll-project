import 'package:cultureyo/src/features/authentication/domain/usecases/auth_service.dart';
import 'package:flutter_naver_login/flutter_naver_login.dart';
import 'package:flutter_naver_login/interface/types/naver_login_result.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_naver_login/interface/types/naver_login_status.dart';
import 'package:cultureyo/src/features/authentication/domain/entities/auth_data.dart';
import 'package:dio/dio.dart';

class NaverLoginService implements AuthService {
  final Dio publicDio;
  final FlutterSecureStorage secureStorage;

  NaverLoginService({required this.publicDio, required this.secureStorage});

  @override
  Future<AuthData?> login() async {
    try {
      final NaverLoginResult loginResult = await FlutterNaverLogin.logIn();
      if (loginResult.status == NaverLoginStatus.loggedIn) {
        final result = await FlutterNaverLogin.getCurrentAccessToken();
        return await sendTokenToServer(result.accessToken, result.refreshToken);
      }
      return null;
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
          'provider': 'Naver',
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
