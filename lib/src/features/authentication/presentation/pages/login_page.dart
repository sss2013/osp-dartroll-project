import 'package:cultureyo/src/features/authentication/domain/entities/KakaoAuthData.dart';
import 'package:cultureyo/src/features/authentication/domain/usecases/auth_manager.dart';
import 'package:cultureyo/src/features/authentication/presentation/pages/user_info.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final Dio _dio = Dio();
  bool _loading = false;

  Future<bool> _sendTokensToServer(KakaoAuthData data) async {
    const url = 'https://dartroll-nodejs.onrender.com/api/auth/kakaoSignIn';

    try {
      final payload = {
        'provider': 'kakao',
        'accessToken': data.accessToken,
        'refreshToken': data.refreshToken,
        'accessExpiresAt':
            data.accessTokenExpiresAt.toUtc().toIso8601String(),
        'refreshExpiresAt':
            data.refreshTokenExpiresAt?.toUtc().toIso8601String()
      };

      final resp = await _dio.post(url, data: payload);
      if (kDebugMode) print(resp);
      if (resp.statusCode != null &&
          resp.statusCode! >= 200 &&
          resp.statusCode! < 300) {
        // 서버가 자체 토큰을 반환하면 저장 (예시)
        // final serverToken = resp.data['token'] as String?;
        // if (serverToken != null) await _secureStorage.write(key: 'server_token', value: serverToken);
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) print('서버 전송 실패 : $e');
      return false;
    }
  }

  void _onKakaoPressed(AuthManager authManager) async {
    setState(() => _loading = true);

    try {
      final result = await authManager.kakaoService.loginWithKakaoTalk();

      if (!mounted) return;
      if (result == null) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('로그인이 취소되었거나 실패했습니다.')),
        );
        return;
      }

      if (kDebugMode)
        print('받은 AuthDate : accessExpires=${result.accessTokenExpiresAt}');

      final ok = await _sendTokensToServer(result);

      if (ok) {
        await authManager.checkAuth();

        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => NameInputPage()));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('서버에서 로그인 처리에 실패했습니다. 나중에 다시 시도해주세요')));
      }
    } catch (e) {
      setState(() {
        _loading = false;
      });
      if (kDebugMode) print('카카오 로그인 처리 중 오류: $e');
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('로그인 중 오류가 발생했습니다')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final authManager = context.read<AuthManager>();
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Container(
          height: screenHeight,
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const Spacer(flex: 3),

              // 로고
              Center(
                child: Image.asset(
                  'assets/images/logos/Culture.png',
                  width: 300,
                  fit: BoxFit.contain,
                ),
              ),

              const Spacer(flex: 2),

              // 카카오 로그인 (둥글게 제외)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _loading ? null : () => _onKakaoPressed(authManager),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFEE500),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12), // 기존 값 유지
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    children: [
                      Image.asset(
                        'assets/images/icons/kakao_icon.png',
                        width: 24,
                        height: 24,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '카카오로 로그인하기',
                          style: TextStyle(
                            color: Colors.black.withValues(),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 네이버 로그인 (둥글게 제외)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    final success = await authManager.naverService.naverLogin();
                    if (!context.mounted) return;
                    if (success) {
                      await authManager.checkAuth();
                      Navigator.pushReplacement(context,
                          MaterialPageRoute(builder: (_) => NameInputPage()));
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF03C75A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12), // 기존 값 유지
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    children: [
                      Image.asset(
                        'assets/images/icons/naver_icon.png',
                        width: 24,
                        height: 24,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          '네이버로 로그인하기',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }
}
