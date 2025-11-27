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

      final status = authManager.status;
      if (status == AuthStatus.kakao || status==AuthStatus.naver || status == AuthStatus.authenticated) {
        final inputComplete = await authManager.checkInput();
        if (inputComplete  != true) {
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (_) => NameInputPage()));
        } else {
          Navigator.pushReplacement(context, MaterialPageRoute(builder : (_) => MainScreen()));
        }
        return ;
      }

      if (status==AuthStatus.authenticated) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder : (_) => MainScreen()));
        return ;
      }
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const LoginPage()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
        body: Center(child: CircularProgressIndicator())
    );
  }
}