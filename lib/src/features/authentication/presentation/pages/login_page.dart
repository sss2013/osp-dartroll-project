import 'package:cultureyo/src/features/authentication/domain/usecases/auth_manager.dart';
import 'package:cultureyo/src/features/profile/usecases/name_input_page.dart';
import 'package:cultureyo/src/features/profile/usecases/user_info.dart';
import 'package:cultureyo/src/features/home.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

enum Auth { naver, kakao }

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _loading = false;

  Future<void> _handleLoginResult(
      BuildContext context, AuthManager authManager, bool success) async {
    if (!mounted) return;
    setState(() => _loading = false);

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('서버 로그인 처리에 실패했습니다. 다시 시도해주세요')));
      return;
    }

    try {
      final inputResult = await authManager.checkInput();
      if (!mounted) return;

      if (inputResult) {
        Navigator.pushAndRemoveUntil(context,
            MaterialPageRoute(builder: (_) => MainScreen()), (route) => false);
      } else {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const NameInputPage()));
      }
    } catch (e) {
      if (kDebugMode) print('checkInput 중 에러 : $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('처리 중 오류가 발생했습니다')),
      );
    }
  }

  Future<void> _onPressed(AuthManager authManager, Auth provider) async {
    if (_loading) return;
    setState(() => _loading = true);

    try {
      bool success = false;
      if (provider == Auth.kakao) {
        success = await authManager.signInWithKakao();
      } else {
        success = await authManager.signInWithNaver();
      }
      await _handleLoginResult(context, authManager, success);
    } catch (e) {
      if (kDebugMode) print('로그인 중 에러: $e');
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
                  onPressed: _loading
                      ? null
                      : () => _onPressed(authManager, Auth.kakao),
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
                  onPressed: _loading
                      ? null
                      : () => _onPressed(authManager, Auth.naver),
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
