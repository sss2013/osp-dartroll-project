import 'package:cultureyo/src/features/authentication/domain/entities/KakaoAuthData.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:intl/intl.dart';

class KakaoLoginService {
  Future<KakaoAuthData?> loginWithKakaoTalk() async {
    //카카오톡 설치 여부 확인
    if (await isKakaoTalkInstalled()) {
      try {
        final OAuthToken result = await UserApi.instance.loginWithKakaoTalk();

        if (kDebugMode) {
          print('카카오톡으로 로그인 성공');
        }

        return await _buildAuthDataFromOAuthToken(result);
      } on PlatformException catch (error) {
        if (kDebugMode) {
          print('카카오톡으로 로그인 실패 (PlatformException) $error');
        }
        //사용자가 의도적으로 뒤로 가기 등으로 화면을 빠져나온 경우
        if (error.code == 'CANCELED') {
          return null;
        }

        final OAuthToken result =
        await UserApi.instance.loginWithKakaoAccount();
        if (kDebugMode) print('카카오계정으로 로그인 성공(대체): $result');

        return await _buildAuthDataFromOAuthToken(result);
      } catch (error) {
        if (kDebugMode) print('카카오톡 로그인 기타 실패 $error');

        try {
          final OAuthToken result =
          await UserApi.instance.loginWithKakaoAccount();
          if (kDebugMode) print('카카오계정으로 로그인 성공: $result');
          return await _buildAuthDataFromOAuthToken(result);
        } catch (e) {
          if (kDebugMode) print('로그인 실패 최종 : $e');
          return null;
        }
      }
    }
  }

  Future<KakaoAuthData> _buildAuthDataFromOAuthToken(OAuthToken token) async {
    final now = DateTime.now().toUtc();

    DateTime? accessExpiresAt;
    DateTime? refreshExpiresAt;

    try {
      final dyn = token as dynamic;

      // 액세스 만료: DateTime 필드 우선 사용
      if (dyn.expiresAt is DateTime) {
        accessExpiresAt = (dyn.expiresAt as DateTime).toUtc();
      } else if (dyn.accessTokenExpiresAt is DateTime) {
        accessExpiresAt = (dyn.accessTokenExpiresAt as DateTime).toUtc();
      } else if (dyn.expiresAt is String) {
        accessExpiresAt = DateTime.parse(dyn.expiresAt as String).toUtc();
      } else if (dyn.expiresIn is int) {
        // 만약 남은 초(seconds)로 오는 케이스
        accessExpiresAt = now.add(Duration(seconds: dyn.expiresIn as int));
      }

      // 리프레시 만료: DateTime 필드 우선 사용
      if (dyn.refreshTokenExpiresAt is DateTime) {
        refreshExpiresAt = (dyn.refreshTokenExpiresAt as DateTime).toUtc();
      } else if (dyn.refreshTokenExpiresAt is String) {
        refreshExpiresAt =
            DateTime.parse(dyn.refreshTokenExpiresAt as String).toUtc();
      } else if (dyn.refreshTokenExpiresIn is int) {
        refreshExpiresAt =
            now.add(Duration(seconds: dyn.refreshTokenExpiresIn as int));
      }
    } catch (e) {
      // 안전하게 무시(로그 남겨도 됨)
      if (kDebugMode) print('토큰 만료 파싱 중 예외: $e');
    }

    if (accessExpiresAt == null) {
      try {
        final info = await UserApi.instance.accessTokenInfo();
        accessExpiresAt = now.add(Duration(seconds: info.expiresIn));
      } catch (e) {
        if (kDebugMode) print('accessTokenInfo 조회 실패: $e');
        accessExpiresAt = null; // 필요시 now로 세팅할 수도 있음
      }
    }

    return KakaoAuthData(
        accessToken: token.accessToken,
        refreshToken: token.refreshToken,
        accessTokenExpiresAt: accessExpiresAt ?? now,
        refreshTokenExpiresAt: refreshExpiresAt,
    );
  }

  Future<bool> checkTokenWithKakao() async {
    if (await AuthApi.instance.hasToken()) {
      try {
        AccessTokenInfo tokenInfo = await UserApi.instance.accessTokenInfo();
      } catch (error) {
        if (error is KakaoException && error.isInvalidTokenError()) {
          if (kDebugMode) {
            print('토큰 만료 $error');
            //TODO: 리프레시 토큰 조회하여 있으면 재발급 진행
          } else {
            if (kDebugMode) {
              print('액세스 토큰 정보 조회 실패 $error');
            }
          }
          return false;
        }
      }
    } else {
      if (kDebugMode) {
        print('발급된 토큰 없음');
      }
      return false;
    }
    return true;
  }


}
