import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DioClient {
  final FlutterSecureStorage _storage;
  late final Dio dio; // 인증이 필요한 API용 Dio 인스턴스
  late final Dio publicDio; // 인증이 필요 없는 API용 Dio 인스턴스 (로그인, 토큰 교환 등)

  final String _baseUrl = 'https://dartroll-nodejs.onrender.com';

  DioClient(this._storage) {
    publicDio = Dio(BaseOptions(baseUrl: _baseUrl));
    dio = Dio(BaseOptions(baseUrl: _baseUrl));

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // 요청 헤더에 액세스 토큰 추가
          final accessToken = await _storage.read(key: 'server_jwt');
          if (accessToken != null) {
            options.headers['Authorization'] = 'Bearer $accessToken';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          // 401 에러이고, 토큰 갱신 요청이 아닐 때
          if (e.response?.statusCode == 401 && e.requestOptions.path != '/api/auth/refresh') {
            final refreshToken = await _storage.read(key: 'server_refresh_token');

            if (refreshToken != null) {
              try {
                // 토큰 갱신 요청 (publicDio 사용)
                final refreshResponse = await publicDio.post(
                  '/api/auth/refresh',
                  data: {'refreshToken': refreshToken},
                );

                if (refreshResponse.statusCode == 200) {
                  // 새로운 토큰 저장
                  final newAccessToken = refreshResponse.data['access']['token'];
                  final newRefreshToken = refreshResponse.data['refresh']['token'];
                  await _storage.write(key: 'server_jwt', value: newAccessToken);
                  await _storage.write(key: 'server_refresh_token', value: newRefreshToken);

                  // 만료 시간도 함께 저장
                  final newExpiresAt = refreshResponse.data['access']['expiresAt'];
                  await _storage.write(key: 'server_jwt_expires_at', value: newExpiresAt);

                  // 원래 요청을 새 토큰으로 재시도
                  final originalRequest = e.requestOptions;
                  originalRequest.headers['Authorization'] = 'Bearer $newAccessToken';

                  final response = await dio.fetch(originalRequest);
                  return handler.resolve(response);
                }
              } catch (refreshError) {
                // 리프레시 실패 시 로그아웃 처리
                await _logout();
                return handler.next(e);
              }
            }
          }
          return handler.next(e);
        },
      ),
    );
  }

  Future<void> _logout() async {
    await _storage.deleteAll();
    // 여기서 로그인 화면으로 보내는 로직을 추가할 수 있습니다.
    // (예: GlobalKey<NavigatorState> 사용 또는 상태 관리)
  }
}