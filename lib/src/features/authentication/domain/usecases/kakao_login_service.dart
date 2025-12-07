import 'package:cultureyo/src/features/authentication/domain/usecases/auth_service.dart';
import 'package:cultureyo/src/features/authentication/domain/entities/auth_data.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart'; // kIsWeb을 사용하기 위해 필요
import 'package:url_launcher/url_launcher.dart'; // 웹 로그인을 위해 필요
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class KakaoLoginService implements AuthService {
  final Dio publicDio;
  final FlutterSecureStorage secureStorage;

  KakaoLoginService({required this.publicDio, required this.secureStorage});

  @override
  Future<AuthData?> login() async {
    if (kIsWeb) {
      try {
        const String clientId = '1877aa29dce5eaa7f30222a03936f257';
        const String redirectUri =
            'https://dartroll-nodejs-sub.onrender.com/api/auth/kakao/callback';
        final Uri kakaoLoginUrl = Uri.parse(
          'https://kauth.kakao.com/oauth/authorize?client_id=$clientId&redirect_uri=$redirectUri&response_type=code',
        );

        // 4. url_launcher를 사용해 현재 탭에서 카카오 로그인 페이지를 엽니다.
        if (await canLaunchUrl(kakaoLoginUrl)) {
          await launchUrl(kakaoLoginUrl, webOnlyWindowName: '_self');
        } else {
          throw Exception('Could not launch $kakaoLoginUrl');
        }

        // 웹에서는 페이지를 리디렉션 시키는 것이 목적이므로,
        // 이 login 함수는 직접적인 AuthData를 반환하지 않습니다.
        // 인증 결과는 백엔드에서 /login-success 페이지로 리디렉션되어 전달됩니다.
        return null;
      } catch (e) {
        print('카카오 웹 로그인 시작 에러: $e');
        return null;
      }
    } else {
      try {
        OAuthToken result;
        if (await isKakaoTalkInstalled()) {
          result = await UserApi.instance.loginWithKakaoTalk();
        } else {
          result = await UserApi.instance.loginWithKakaoAccount();
        }
        return await sendTokenToServer(result.accessToken, result.refreshToken);
      } catch (_) {
        return null;
      }
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
