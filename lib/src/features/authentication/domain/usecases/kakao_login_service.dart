import 'package:cultureyo/src/features/authentication/domain/usecases/auth_service.dart';
import 'package:flutter/foundation.dart';
import 'package:cultureyo/src/features/authentication/domain/entities/auth_data.dart';
import 'package:flutter/services.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class KakaoLoginService implements AuthService{
  @override
  Future<AuthData?> login() async {
    try {
      OAuthToken result;
      if (await isKakaoTalkInstalled()) {
        result = await UserApi.instance.loginWithKakaoTalk();
      } else {
        result = await UserApi.instance.loginWithKakaoAccount();
      }

      return _buildAuthDataFromOAuthToken(result);
    } on PlatformException catch (error) {
      //사용자가 의도적으로 뒤로 가기 등으로 화면을 빠져나온 경우
      if (error.code == 'CANCELED') {
        return null;
      }
      if (kDebugMode) {
        print('카카오 로그인 중 오류 : $error');
      }
      return null;
      //   final OAuthToken result =
      //   await UserApi.instance.loginWithKakaoAccount();
      //   if (kDebugMode) print('카카오계정으로 로그인 성공(대체): $result');
      //
      //   return await _buildAuthDataFromOAuthToken(result);
      // } catch (error) {
      //   if (kDebugMode) print('카카오톡 로그인 기타 실패 $error');
      //
      //   try {
      //     final OAuthToken result =
      //     await UserApi.instance.loginWithKakaoAccount();
      //     if (kDebugMode) print('카카오계정으로 로그인 성공: $result');
      //     return await _buildAuthDataFromOAuthToken(result);
      //   } catch (e) {
      //     if (kDebugMode) print('로그인 실패 최종 : $e');
      //     return null;
      //   }
      // }
    }
  }

  Future<AuthData?> _buildAuthDataFromOAuthToken(OAuthToken token) async {
    final accessExpiresAt = (token.expiresAt).toUtc();
    final refreshExpiresAt = (token.refreshTokenExpiresAt)?.toUtc();

    return AuthData(
      accessToken: token.accessToken,
      refreshToken: token.refreshToken,
      accessTokenExpiresAt: accessExpiresAt,
      refreshTokenExpiresAt: refreshExpiresAt,
    );
  }

  @override
  Future<TokenStatus> checkToken() async {
    const secureStorage = FlutterSecureStorage();
    final accessToken = await secureStorage.read(key: 'kakao_access_token');
    final expiresAtStr = await secureStorage.read(
        key: 'kakao_access_expires_at');
    const url = 'https://dartroll-nodejs.onrender.com/api/auth/checkToken';


    if (accessToken == null || expiresAtStr == null) {
      return TokenStatus.networkError;
    }

    final expiresAt = DateTime.parse(expiresAtStr);
    final now = DateTime.now().toUtc();

    try {
      final dio = Dio();
      final res = await dio.post(
        url,
        data: {
          'provider': 'kakao',
          'accessToken': accessToken,
          'localTime': now.toIso8601String(),
          'expiresAt': expiresAt.toIso8601String()
        },
        options: Options(validateStatus: (_) => true),
      );

      if (res.statusCode == 200) return TokenStatus.valid;
      if (res.statusCode == 401) return TokenStatus.expired;
      if (res.statusCode == 422) {
        final errorCode = res.data['error'];
        if (errorCode == 'time difference too large') {
          return TokenStatus.timeMisMatch;
        } else if (errorCode == 'token expiry mismatch') {
          return TokenStatus.tokenMisMatch;
        }
      }
      return TokenStatus.networkError;
    } catch (error) {
      return TokenStatus.networkError;
    }
  }

  @override
  Future<bool> sendTokenToServer(AuthData data) async {
    final Dio dio = Dio();
    const url = 'https://dartroll-nodejs.onrender.com/api/auth/SignIn';

    try {
      final payload = {
        'provider': 'kakao',
        'accessToken': data.accessToken,
        'refreshToken': data.refreshToken,
        'accessExpiresAt': data.accessTokenExpiresAt.toUtc().toIso8601String(),
        'refreshExpiresAt': data.refreshTokenExpiresAt
            ?.toUtc()
            .toIso8601String(),
      };

      final resp = await dio.post(url, data: payload);

      if (resp.statusCode != null &&
          resp.statusCode! >= 200 &&
          resp.statusCode! < 300) {
        const secureStorage = FlutterSecureStorage();
        await secureStorage.write(
            key: 'kakao_access_token', value: data.accessToken);
        await secureStorage.write(
            key: 'kakao_access_expires_at',
            value: data.accessTokenExpiresAt.toUtc().toIso8601String()
        );
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) print('서버 전송 실패 : $e');
      return false;
    }
  }

  @override
  Future<AuthData?> refreshToken() async {
    const url = 'https://dartroll-nodejs.onrender.com/api/auth/refresh';
    final Dio dio = Dio();
    const secureStorage = FlutterSecureStorage();
    final accessToken = await secureStorage.read(key: 'kakao_access_token');

    if (kDebugMode) {
      print('현재 액세스 토큰 : $accessToken}');
    }

    try {
      final payload = {
        'provider': 'kakao',
        'accessToken': accessToken,
      };
      final res = await dio.post(
        url,
        data: payload,
        options: Options(
          validateStatus: (status) {
            return true;
          },
        ),
      );

      if (res.statusCode == 200 && res.data['token'] != null) {
        final newAccessToken = res.data['token'] as String;
        final newExpiresAt = DateTime.parse(res.data['expiresAt']).toUtc();

        return AuthData(
          accessToken: newAccessToken,
          refreshToken: null,
          accessTokenExpiresAt: newExpiresAt,
          refreshTokenExpiresAt: null,
        );
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('서버 전송 실패 : $e');
      }
      return null;
    }
  }
}
