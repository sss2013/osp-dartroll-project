import 'package:cultureyo/src/features/authentication/domain/usecases/auth_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_naver_login/flutter_naver_login.dart';
import 'package:flutter_naver_login/interface/types/naver_login_result.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_naver_login/interface/types/naver_login_status.dart';
import 'package:flutter_naver_login/interface/types/naver_token.dart';
import 'package:cultureyo/src/features/authentication/domain/entities/auth_data.dart';
import 'package:dio/dio.dart';

class NaverLoginService implements AuthService {
  @override
  Future<AuthData?> login() async {
    try {
      final NaverLoginResult result = await FlutterNaverLogin.logIn();
      if (result.status == NaverLoginStatus.loggedIn) {
        final NaverToken token =
            await FlutterNaverLogin.getCurrentAccessToken();

        return await _buildAuthDataFromOAuthData(token);
      } else {
        if (kDebugMode) {
          print('네이버 로그인 실패 : ${result.errorMessage}');
        }
        return null;
      }
    } catch (error) {
      if (kDebugMode) {
        print('네이버 로그인 중 예외 발생 : $error');
      }
      return null;
    }
  }

  @override
  Future<TokenStatus> checkToken() async {
    const secureStorage = FlutterSecureStorage();
    final accessToken = await secureStorage.read(key: 'naver_access_token');
    final expiresAtStr =
        await secureStorage.read(key: 'naver_access_expires_at');
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
          'provider': 'naver',
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
      if (kDebugMode) {
        print('여기까지왔다면 뭔가 이상함');
        print(res.statusCode);
        print(res.statusMessage);
        print(res.data);
      }
      return TokenStatus.networkError;
    } catch (error) {
      if (kDebugMode) print('네이버 캐치 에러 : $error');
      return TokenStatus.networkError;
    }
  }

  @override
  Future<bool> sendTokenToServer(AuthData data) async {
    final Dio dio = Dio();
    const url = 'https://dartroll-nodejs.onrender.com/api/auth/SignIn';

    try {
      final payload = {
        'provider': 'naver',
        'accessToken': data.accessToken,
        'refreshToken': data.refreshToken,
        'accessExpiresAt': data.accessTokenExpiresAt.toUtc().toIso8601String(),
      };

      final resp = await dio.post(url, data: payload);
      if (kDebugMode) print(resp);
      if (resp.statusCode != null &&
          resp.statusCode! >= 200 &&
          resp.statusCode! < 300) {
        const secureStorage = FlutterSecureStorage();
        await secureStorage.write(
            key: 'naver_access_token', value: data.accessToken);
        await secureStorage.write(
            key: 'naver_access_expires_at',
            value: data.accessTokenExpiresAt.toUtc().toIso8601String());
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
    final accessToken = await secureStorage.read(key: 'naver_access_token');

    if (kDebugMode) {
      print('토큰 리프레시 진입');
      print('현재 액세스 토큰 : $accessToken}');
    }

    try {
      final payload = {
        'provider': 'naver',
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

  Future<AuthData?> _buildAuthDataFromOAuthData(NaverToken? token) async {
    if (token == null) return null;
    final now = DateTime.now().toUtc();

    DateTime? accessExpiresAt;

    try {
      accessExpiresAt = DateTime.parse(token.expiresAt).toUtc();
    } catch (e) {
      // 안전하게 무시(로그 남겨도 됨)
      if (kDebugMode) print('토큰 만료기한 파싱 중 예외: $e');
    }

    return AuthData(
      accessToken: token.accessToken,
      refreshToken: token.refreshToken,
      accessTokenExpiresAt: accessExpiresAt ?? now,
      refreshTokenExpiresAt: null,
    );
  }
}
