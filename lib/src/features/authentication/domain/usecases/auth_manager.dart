import 'package:cultureyo/src/features/authentication/domain/usecases/kakao_login_service.dart';
import 'package:cultureyo/src/features/authentication/domain/usecases/naver_login_service.dart';
import 'package:flutter/foundation.dart';


enum AuthStatus {none,kakao,naver,}

class AuthManager extends ChangeNotifier{
  final KakaoLoginService kakaoService;
  final NaverLoginService naverService;

  AuthStatus _status = AuthStatus.none;
  AuthStatus get status => _status;

  AuthManager({
    required this.kakaoService,
    required this.naverService,
  });

  Future<void> checkAuth() async {
    final kakao = await kakaoService.checkTokenWithKakao();
    final naver = await naverService.checkTokenWithNaver();

    if (kakao) {
      _status = AuthStatus.kakao;
    } else if (naver) {
      _status = AuthStatus.naver;
    } else {
      _status = AuthStatus.none;
    }

    notifyListeners();
  }

  void logout() {
    _status= AuthStatus.none;
    notifyListeners();
  }
}