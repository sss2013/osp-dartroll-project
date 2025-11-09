
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';

class KakaoLoginService {

  Future<bool> loginWithKakaoTalk() async {
    //카카오톡 설치 여부 확인
    if (await isKakaoTalkInstalled()) {
      try {
        await UserApi.instance.loginWithKakaoTalk();

        if (kDebugMode) {
          print('카카오톡으로 로그인 성공');
        }

        return true;
      } catch (error) {
        if (kDebugMode) {
          print('카카오톡으로 로그인 실패 $error');
        }
        //사용자가 의도적으로 뒤로 가기 등으로 화면을 빠져나온 경우
        if (error is PlatformException && error.code == 'CANCELED') {
          return false;
        }

        try {
          //카카오톡은 있는데 연결된 계정이 없을 때 카카오 계정으로 로그인
          await UserApi.instance.loginWithKakaoAccount();
          if (kDebugMode) {
            print('카카오계정으로 로그인 성공');
          }

          return true;
        } catch (error) {
          if (kDebugMode) {
            print('카카오계정으로 로그인 실패 $error');
          }
          return false;
        }
      }
    } else {
      try {
        //카카오톡 설치 X, 계정으로 로그인
        await UserApi.instance.loginWithKakaoAccount();
        if (kDebugMode) {
          print('카카오계정으로 로그인 성공');
        }

        return true;
      } catch (error) {
        if (kDebugMode) {
          print('카카오계정으로 로그인 실패 $error');
        }

        return false;
      }
    }
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