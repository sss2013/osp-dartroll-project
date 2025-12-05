// main.dart

import 'package:cultureyo/src/core/network/dio_client.dart';
import 'package:cultureyo/src/features/authentication/domain/usecases/auth_manager.dart';
import 'package:cultureyo/src/features/authentication/presentation/pages/login_page.dart';
import 'package:cultureyo/src/features/authentication/presentation/pages/splash_page.dart';
import 'package:cultureyo/src/features/profile/domain/user_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:cultureyo/src/features/home.dart';

// ⭐ [추가] PostService와 PerformanceService 임포트 경로
import 'package:cultureyo/src/features/community/service/post_service.dart';
import 'package:cultureyo/src/features/community/service/performance_service.dart';
// 💡 [추가] CommentService 임포트 경로
import 'package:cultureyo/src/features/community/service/comment_service.dart';


final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  final kakaoKey = dotenv.env['KAKAO_NATIVE_APP_KEY'];

  KakaoSdk.init(nativeAppKey: kakaoKey);

  const secureStorage = FlutterSecureStorage();
  final dioClient = DioClient(secureStorage);

  final authManager = AuthManager(
    dioClient: dioClient,
    secureStorage: secureStorage,
  );

  final userService = UserService(dioClient: dioClient);

  // ⭐ [추가] PostService 및 PerformanceService 인스턴스 생성 및 종속성 주입
  final postService = PostService(dioClient: dioClient);
  final performanceService = PerformanceService(dioClient: dioClient);

  // 💡 [추가] CommentService 인스턴스 생성 및 종속성 주입
  final commentService = CommentService(dioClient: dioClient);


  runApp(
      MultiProvider(providers: [
        ChangeNotifierProvider(create: (_) => authManager),
        Provider<UserService>(create: (_) => userService),

        // ⭐ [추가] Service Provider 등록
        Provider<PostService>(create: (_) => postService),
        Provider<PerformanceService>(create: (_) => performanceService),

        // 💡 [추가] CommentService Provider 등록
        Provider<CommentService>(create: (_) => commentService),

      ],
        child: const MyApp(),
      )
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {

    return MaterialApp(
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false, // 우측 상단의 'DEBUG' 배너 제거
        title: 'Cultureyo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
      //로그인 창 스킵하고 바로 홈화면으로 넘어가서 테스트하고 싶을 떄 사용
      //home: MainScreen()

      routes: {
        '/' : (context) => const SplashPage(),
        '/login' : (context) => const LoginPage()
      },
      initialRoute: '/',


    );
  }
}