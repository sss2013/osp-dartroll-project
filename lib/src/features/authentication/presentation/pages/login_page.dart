import 'package:cultureyo/src/features/authentication/domain/usecases/auth_manager.dart';
import 'package:cultureyo/src/features/authentication/presentation/pages/user_info.dart';
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
      BuildContext context, AuthManager authManager, dynamic result, Auth provider) async {
    late final bool ok;
    if (!mounted) return;
    if (result == null) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인이 취소되었거나 실패했습니다.')),
      );
      return;
    }

    if (provider == Auth.kakao) {
      ok = await authManager.kakaoService.sendTokenToServer(result);
    } else {
      ok = await authManager.naverService.sendTokenToServer(result);
    }

    if (ok) {
      final inputResult = await authManager.checkInput();
      setState(() => _loading = false);
      if (inputResult != true) {
        if (!mounted) return ;
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => NameInputPage()));
      } else {
        if (!mounted) return ;
        Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => MainScreen()));
      }
    } else {
      setState(() => _loading = false);

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('서버에서 로그인 처리에 실패했습니다. 나중에 다시 시도해주세요')));
    }
  }

  void _onPressed(AuthManager authManager, Auth provider) async {
    setState(() => _loading = true);

    dynamic result;
    try {
      if (provider == Auth.kakao) {
        result = await authManager.kakaoService.login();
        await _handleLoginResult(context, authManager, result, Auth.kakao);
      } else {
        result = await authManager.naverService.login();
        await _handleLoginResult(context, authManager, result, Auth.naver);
      }

    } catch (e) {
      if (kDebugMode) {
        print('로그인 처리중 에러 발생, $e');
      }
      setState(() {
        _loading = false;
      });
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
