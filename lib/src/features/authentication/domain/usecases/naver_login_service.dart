import 'package:flutter/foundation.dart';
import 'package:flutter_naver_login/flutter_naver_login.dart';
import 'package:flutter_naver_login/interface/types/naver_login_result.dart';
import 'package:flutter_naver_login/interface/types/naver_login_status.dart';
import 'package:flutter_naver_login/interface/types/naver_token.dart';

class NaverLoginService {
  Future<bool> naverLogin() async {

    try {
      final NaverLoginResult result = await FlutterNaverLogin.logIn();
      if (result.status == NaverLoginStatus.loggedIn) {
        return true;
      } else{
        if(kDebugMode){
          print('로그인 결과 : ${result.status}');
          print('액세스 토큰  : ${result.accessToken}');
        }
      }
    } catch (error) {
      if(kDebugMode){
        print('login failed $error');
      }
    }
    return false;
  }
  Future<bool> checkTokenWithNaver() async {
    try {
      final NaverToken token = await FlutterNaverLogin.getCurrentAccessToken();
      if (token.isValid()) {

        if (kDebugMode) {
          print('Access Token: ${token.accessToken}');
          print('Refresh Token: ${token.refreshToken}');
          print('Token Type: ${token.tokenType}');
          print('Expires At: ${token.expiresAt}');
        }
        return true;
      }
    } catch (error){
      if(kDebugMode){
        print('Failed to get token : $error');
      }
    }
    return false;
  }

}