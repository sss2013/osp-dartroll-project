import 'package:cultureyo/src/core/network/dio_client.dart';
import 'package:cultureyo/src/features/authentication/domain/usecases/auth_manager.dart';
import 'package:cultureyo/src/features/authentication/presentation/pages/login_page.dart';
import 'package:cultureyo/src/features/authentication/presentation/pages/splash_page.dart';
import 'package:cultureyo/src/features/community/service/chat_service.dart';

import 'package:cultureyo/src/features/profile/domain/user_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'package:cultureyo/src/features/community/service/post_service.dart';
import 'package:cultureyo/src/features/community/service/performance_service.dart';
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
  final postService = PostService(dioClient: dioClient);
  final performanceService = PerformanceService(dioClient: dioClient);
  final commentService = CommentService(dioClient: dioClient);
  final chatService = ChatService(dioClient: dioClient);

  runApp(

      MultiProvider(providers: [
        ChangeNotifierProvider(create: (_) => authManager),
        Provider<UserService>(create: (_) => userService),
        Provider<PostService>(create: (_) => postService),
        Provider<PerformanceService>(create: (_) => performanceService),
        Provider<CommentService>(create: (_) => commentService),
        Provider<ChatService>(create: (_) => chatService),
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
      title: 'Cultureyo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),

      routes: {
        '/' : (context) => const SplashPage(),
        '/login' : (context) => const LoginPage()
      },
      initialRoute: '/',
    );
  }
}