import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cultureyo/src/features/authentication/presentation/pages/login_page.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';


Future<void> main() async {
  await dotenv.load(fileName: '.env');

  final kakaoKey = dotenv.env['KAKAO_NATIVE_APP_KEY'];

  KakaoSdk.init(
    nativeAppKey : kakaoKey
  );
  if (kDebugMode) {
    print(kakaoKey);
  }
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
