import 'package:cultureyo/src/features/authentication/domain/entities/auth_data.dart' show AuthData;
import 'package:cultureyo/src/features/authentication/domain/usecases/auth_service.dart';
import 'package:cultureyo/src/features/authentication/domain/usecases/kakao_login_service.dart';
import 'package:cultureyo/src/features/authentication/domain/usecases/naver_login_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

enum AuthStatus { none, kakao, naver }

class AuthManager extends ChangeNotifier {
  final KakaoLoginService kakaoService;
  final NaverLoginService naverService;
  final secureStorage = const FlutterSecureStorage();

  AuthStatus _status = AuthStatus.none;
  AuthStatus get status => _status;

  AuthManager({
    required this.kakaoService,
    required this.naverService,
  });

  Future<void> checkAuth() async {
    final kakaoStatus = await kakaoService.checkToken();
    if(kDebugMode) print('kakao 결과 : $kakaoStatus');
    if (kakaoStatus == TokenStatus.valid) {
      _status = AuthStatus.kakao;
      notifyListeners();
      return;
    } else if (kakaoStatus == TokenStatus.expired) {
      final refreshedData = await kakaoService.refreshToken();
      if (refreshedData != null) {
        await _saveToken(AuthStatus.kakao, refreshedData);
        _status = AuthStatus.kakao;
        notifyListeners();
        return;
      }
    } else if (kakaoStatus == TokenStatus.timeMisMatch) {
      if (kDebugMode) {
        print('카카오 : 로컬 시간과 서버시간이 너무 차이남');
      }
    } else if (kakaoStatus == TokenStatus.networkError) {
      if (kDebugMode) print('카카오 저장 토큰 없거나 또는 네트워크 오류');
    }

    final naverStatus = await naverService.checkToken();
    if(kDebugMode) print('naver 결과 : $naverStatus');
    if (naverStatus == TokenStatus.valid) {
      _status = AuthStatus.naver;
      notifyListeners();
      return;
    } else if (naverStatus == TokenStatus.expired) {
      final refreshedData = await naverService.refreshToken();
      if (refreshedData != null) {
        await _saveToken(AuthStatus.naver, refreshedData);
        _status = AuthStatus.naver;
        notifyListeners();
        return;
      }
    } else if (naverStatus == TokenStatus.timeMisMatch) {
      if (kDebugMode) {
        print('로컬 시간과 서버시간이 너무 차이남');
      }
    } else if (naverStatus == TokenStatus.networkError) {
      if (kDebugMode) print('네이버 저장 토큰 없거나 네트워크 오류');
    }

    _status = AuthStatus.none;
    notifyListeners();
  }

  Future<void> _saveToken(AuthStatus provider, AuthData data) async {
    await secureStorage.write(key: '${provider}_access_token', value: data.accessToken);
    await secureStorage.write(
      key: '${provider}_access_expires_at',
      value: data.accessTokenExpiresAt.toUtc().toIso8601String(),
    );
    if (kDebugMode) print('$provider 토큰 저장 완료');
  }

  Future<bool> checkInput() async {
    return false;
  }
}
