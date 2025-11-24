import 'package:cultureyo/src/features/authentication/domain/usecases/auth_manager.dart';
import 'package:cultureyo/src/features/authentication/presentation/pages/user_info.dart';
import 'package:cultureyo/src/features/home.dart';
import 'package:flutter/material.dart';
import 'login_page.dart';
import 'package:provider/provider.dart';


class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final authManager = context.read<AuthManager>();
      await authManager.checkAuth();

      if (!mounted) return;
      switch (authManager.status) {
        case AuthStatus.kakao:
        case AuthStatus.naver:
          if (await authManager.checkInput() != true) {
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (_) => NameInputPage()));
            break;
          } else {
            Navigator.pushReplacement(context, MaterialPageRoute(builder : (_) => MainScreen()));
          }
        case AuthStatus.none:
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (_) =>  const LoginPage()));
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
        body: Center(child: CircularProgressIndicator())
    );
  }
}