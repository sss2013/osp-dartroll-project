import 'package:cultureyo/src/features/authentication/domain/usecases/auth_manager.dart';
import 'package:cultureyo/src/features/authentication/presentation/pages/main_test_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
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
                  onPressed: () async {
                    final success =
                        await authManager.kakaoService.loginWithKakaoTalk();
                    if (!context.mounted) return;
                    if (success) {
                      await authManager.checkAuth();
                      Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const MainTestPage()));
                    }
                  },
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
                    final success =
                        await authManager.naverService.naverLogin();
                    if (!context.mounted) return;
                    if (success) {
                      await authManager.checkAuth();
                      Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const MainTestPage()));
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
