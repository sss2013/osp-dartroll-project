import 'package:cultureyo/src/features/authentication/domain/usecases/auth_manager.dart';
import 'package:cultureyo/src/features/chat/service/chat_service.dart';
import 'package:cultureyo/src/features/profile/usecases/name_input_page.dart';
import 'package:cultureyo/src/features/home.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
    _initialize();
  }

  Future<void> _initialize() async {
    await Future.delayed(Duration.zero);
    if (!mounted) return;

    final authManager = context.read<AuthManager>();

    await authManager.checkAuth();
    if (!mounted) return;

    final status = authManager.status;

    if(kDebugMode) {
      print('Auth Status: $status');
    }

    if (status != AuthStatus.none) {
      final inputComplete = await authManager.checkInput();
      if (!mounted) return;
      if(kDebugMode) { print ('Input Complete: $inputComplete'); }
      if (inputComplete) {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => MainScreen()));
      } else {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const NameInputPage()));
      }
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
