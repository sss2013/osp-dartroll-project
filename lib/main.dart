// main.dart

import 'package:cultureyo/src/core/network/dio_client.dart';
import 'package:cultureyo/src/features/authentication/domain/usecases/auth_manager.dart';
import 'package:cultureyo/src/features/authentication/presentation/pages/login_page.dart';
import 'package:cultureyo/src/features/authentication/presentation/pages/splash_page.dart';
import 'package:cultureyo/src/features/profile/domain/user_service.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:cultureyo/src/features/authentication/presentation/pages/login_redirect_page.dart';
import 'package:cultureyo/src/features/home.dart';

// ⭐ [추가] PostService와 PerformanceService 임포트 경로
import 'package:cultureyo/src/features/community/service/post_service.dart';
import 'package:cultureyo/src/features/community/service/performance_service.dart';

// 💡 [추가] CommentService 임포트 경로
import 'package:cultureyo/src/features/community/service/comment_service.dart';


final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  setUrlStrategy(const HashUrlStrategy());
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
      debugShowCheckedModeBanner: false,
      // 우측 상단의 'DEBUG' 배너 제거
      title: 'Cultureyo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),

      onGenerateRoute: (settings) {
        if (settings.name != null &&
            settings.name!.startsWith('/login-success')) {
          final uri = Uri.parse(settings.name!);
          final accessToken = uri.queryParameters['accessToken'];
          final refreshToken = uri.queryParameters['refreshToken'];
          final accessExpiresAt = uri.queryParameters['accessExpiresAt'];

          // LoginRedirectPage로 정보 전달
          return MaterialPageRoute(
            builder: (context) =>
                LoginRedirectPage(
                  accessToken: accessToken,
                  refreshToken: refreshToken,
                  accessExpiresAt: accessExpiresAt,
                ),
          );
        }
        if (settings.name == '/login') {
          return MaterialPageRoute(builder: (_) => const LoginPage());
        }

        return MaterialPageRoute(builder: (_) => const SplashPage());
      },

      home: Consumer<AuthManager>(
        builder: (context, authManager, child) {
          // AuthManager의 상태에 따라 다른 화면을 보여줍니다.
          switch (authManager.status) {
            case AuthStatus.authenticated:
            case AuthStatus.kakao:
            case AuthStatus.naver:
              return MainScreen(); // 인증된 사용자는 메인 화면으로
            case AuthStatus.none:
            default:
              return const SplashPage(); // 기본 상태는 스플래시 화면 (여기서 checkAuth() 호출)
          }
        },
      ),
    );
  }
}