import 'package:cultureyo/src/features/authentication/domain/usecases/auth_manager.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LoginRedirectPage extends StatefulWidget {
  final String? accessToken;
  final String? refreshToken;
  final String? accessExpiresAt;

  const LoginRedirectPage({
    Key? key,
    required this.accessToken,
    required this.refreshToken,
    required this.accessExpiresAt,
  }) : super(key: key);

  @override
  _LoginRedirectPageState createState() => _LoginRedirectPageState();
}

class _LoginRedirectPageState extends State<LoginRedirectPage> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _processTokens();
    });
  }

  Future<void> _processTokens() async {
    // 1. URL에서 전달받은 토큰이 있는지 확인
    if (widget.accessToken != null && widget.refreshToken != null &&
        widget.accessExpiresAt != null) {
      context.read<AuthManager>().processWebLoginSuccess(
        accessToken: widget.accessToken!,
        refreshToken: widget.refreshToken,
        accessExpiresAt: widget.accessExpiresAt!,
      );
    } else {
      print('URL에 토큰 정보가 누락되었습니다.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}