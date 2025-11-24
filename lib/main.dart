import 'package:cultureyo/src/features/authentication/domain/usecases/auth_manager.dart';
import 'package:cultureyo/src/features/authentication/domain/usecases/kakao_login_service.dart';
import 'package:cultureyo/src/features/authentication/domain/usecases/naver_login_service.dart';
import 'package:cultureyo/src/features/authentication/presentation/pages/splash_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  final kakaoKey = dotenv.env['KAKAO_NATIVE_APP_KEY'];

  KakaoSdk.init(nativeAppKey: kakaoKey);
  if (kDebugMode) {
    print(kakaoKey);
  }

  final kakaoService = KakaoLoginService();
  final naverService = NaverLoginService();
  final authManager = AuthManager(
    kakaoService: kakaoService,
    naverService: naverService,
  );

  runApp(
      ChangeNotifierProvider(
        create : (_) => authManager,
        child : const MyApp(),
      )
  );
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
      home: const SplashPage()
    );
  }
}
