import 'package:flutter/material.dart';
import 'package:cultureyo/src/features/authentication/presentation/pages/login_page.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';

void main() {
  KakaoSdk.init(
    nativeAppKey: 'd8a04653cce480e97394d868eb83502a',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // 우측 상단의 'DEBUG' 배너 제거
      title: 'Cultureyo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const LoginPage(), // 앱 실행 시 첫 화면을 LoginPage로 지정
    );
  }
}
