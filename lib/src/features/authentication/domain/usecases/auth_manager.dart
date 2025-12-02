import 'dart:async';
import 'package:cultureyo/main.dart';
import 'package:cultureyo/src/features/authentication/domain/entities/auth_data.dart'
    show AuthData;
import 'package:cultureyo/src/features/authentication/domain/usecases/kakao_login_service.dart';
import 'package:cultureyo/src/features/authentication/domain/usecases/naver_login_service.dart';
import 'package:cultureyo/src/features/authentication/domain/usecases/auth_service.dart';
import 'package:cultureyo/src/core/network/dio_client.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AuthStatus { none, kakao, naver, authenticated }

class AuthManager extends ChangeNotifier {
  final KakaoLoginService kakaoService;
  final NaverLoginService naverService;
  final DioClient dioClient;
  final FlutterSecureStorage secureStorage;

  late StreamSubscription _authSubscription;

  AuthStatus _status = AuthStatus.none;

  AuthStatus get status => _status;

  AuthManager({
    required this.dioClient,
    required this.secureStorage,
  })  : kakaoService = KakaoLoginService(
            publicDio: dioClient.publicDio, secureStorage: secureStorage),
        naverService = NaverLoginService(
            publicDio: dioClient.publicDio, secureStorage: secureStorage) {
    _authSubscription = dioClient.onAuthenticationFailed.listen((_) {
      _handleSessionExpired();
    });
  }

  Future<void> _handleSessionExpired() async {
    _status = AuthStatus.none;
    notifyListeners();

    if (navigatorKey.currentState != null) {
      navigatorKey.currentState!
          .pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  Future<void> checkAuth() async {
    final tokenStatus = await kakaoService.checkToken();

    if (tokenStatus == TokenStatus.valid) {
      _status = AuthStatus.kakao;
      notifyListeners();
      return;
    }

    if (tokenStatus == TokenStatus.expired) {
      final refreshed = await _manualRefresh();
      if (refreshed) {
        _status = AuthStatus.authenticated;
        notifyListeners();
        return;
      }
    }

    _status = AuthStatus.none;
    notifyListeners();
  }

  Future<bool> _manualRefresh() async {
    final refreshToken = await secureStorage.read(key: 'server_refresh_token');
    if (refreshToken == null) return false;

    if (kDebugMode) {
      print('Attempting manual refresh with token: $refreshToken');
    }

    try {
      final response = await dioClient.publicDio.post(
        '/api/auth/refresh',
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200) {
        final authData = AuthData(
          serverJwt: response.data['access']['token'],
          serverJwtExpiresAt:
              DateTime.parse(response.data['access']['expiresAt']),
          refreshToken: response.data['refresh']?['token'],
        );
        await _saveServerTokens(authData);
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Manual refresh failed: $e');
      }
      return false;
    }
  }

  Future<bool> _refreshAny() async {
    final refreshToken = await secureStorage.read(key: 'server_refresh_token');
    if (refreshToken == null) return false;

    final refreshed =
        await kakaoService.refreshToken() ?? await naverService.refreshToken();
    if (refreshed != null) {
      await _saveServerTokens(refreshed);
      return true;
    }
    return false;
  }

  Future<bool> signInWithKakao() async {
    final auth = await kakaoService.login();
    if (auth != null) {
      await _saveServerTokens(auth);
      _status = AuthStatus.kakao;
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> signInWithNaver() async {
    final auth = await naverService.login();
    if (auth != null) {
      await _saveServerTokens(auth);
      _status = AuthStatus.naver;
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> _saveServerTokens(AuthData data) async {
    await secureStorage.write(key: 'server_jwt', value: data.serverJwt);
    await secureStorage.write(
        key: 'server_jwt_expires_at',
        value: data.serverJwtExpiresAt.toUtc().toIso8601String());

    if (data.refreshToken != null) {
      await secureStorage.write(
          key: 'server_refresh_token', value: data.refreshToken);
      if (data.refreshTokenExpiresAt != null) {
        await secureStorage.write(
            key: 'server_refresh_expires_at',
            value: data.refreshTokenExpiresAt!.toUtc().toIso8601String());
      }
    } else {
      await secureStorage.delete(key: 'server_refresh_token');
      await secureStorage.delete(key: 'server_refresh_expires_at');
    }
  }

  Future<bool> checkInput() async {
    final pref = await SharedPreferences.getInstance();
    final bool isComplete = pref.getBool('isProfileComplete') ?? false;
    return isComplete;
  }
}
