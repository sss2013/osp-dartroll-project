import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DioClient {
  final FlutterSecureStorage _storage;
  late final Dio dio; // 인증이 필요한 API용 Dio 인스턴스
  late final Dio publicDio; // 인증이 필요 없는 API용 Dio 인스턴스 (로그인, 토큰 교환 등)

  final String _baseUrl = 'https://dartroll-nodejs.onrender.com';

  bool _isRefreshing = false;
  List<Map<String, dynamic>> _failedRequests = [];

  //인증 실패를 알리기 위한 스트림 컨트롤러
  final _authFailedController = StreamController<void>.broadcast();

  //외부에서 구독할 스트림 Getter
  Stream<void> get onAuthenticationFailed => _authFailedController.stream;

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
          // 401 에러이고, 리프레시 요청이 아닐 때
          if ((e.response?.statusCode == 401 ||
                  e.response?.statusCode == 403) &&
              e.requestOptions.path != '/api/auth/refresh') {
            if (_isRefreshing) {
              _failedRequests.add({
                'options': e.requestOptions,
                'handler': handler,
              });
              //이 단계에서 handler.next 호출하면 에러가 전파, 기다림.
              return;
            }

            _isRefreshing = true;
            final refreshToken =
                await _storage.read(key: 'server_refresh_token');
            if (refreshToken != null) {
              try {
                final refreshResponse = await publicDio.post(
                  '/api/auth/refresh',
                  data: {'refreshToken': refreshToken},
                );

                if (refreshResponse.statusCode == 200) {
                  final newAccessToken =
                      refreshResponse.data['access']['token'];
                  final newRefreshToken =
                      refreshResponse.data['refresh']['token'];
                  final newExpiresAt =
                      refreshResponse.data['access']['expiresAt'];

                  await _storage.write(
                      key: 'server_jwt', value: newAccessToken);
                  await _storage.write(
                      key: 'server_refresh_token', value: newRefreshToken);
                  await _storage.write(
                      key: 'server_jwt_expires_at', value: newExpiresAt);

                  _isRefreshing = false;

                  // 원래 요청을 새 토큰으로 재시도
                  e.requestOptions.headers['Authorization'] =
                      'Bearer $newAccessToken';
                  final response = await dio.fetch(e.requestOptions);
                  _processFailedRequests(newAccessToken);

                  return handler.resolve(response);
                }
              } catch (refreshError) {
                _isRefreshing = false;
                _clearFailedRequests(refreshError);
                await _notifyAuthFailure();
                return handler.next(e);
              }
            } else {
              _isRefreshing = false;
              await _notifyAuthFailure();
            }
          }
          return handler.next(e);
        },
      ),
    );
  }

  void _processFailedRequests(String newAccessToken) {
    for (var request in _failedRequests) {
      final RequestOptions options = request['options'];
      final ErrorInterceptorHandler handler = request['handler'];

      options.headers['Authorization'] = 'Bearer $newAccessToken';

      // 재시도
      dio.fetch(options).then((response) {
        handler.resolve(response);
      }).catchError((e) {
        handler.reject(e as DioException);
      });
    }
    _failedRequests = [];
  }

  void _clearFailedRequests(Object error) {
    for (var request in _failedRequests) {
      final ErrorInterceptorHandler handler = request['handler'];
      handler.reject(DioException(
          requestOptions: request['options'],
          error: error,
          type: DioExceptionType.unknown));
    }
    _failedRequests = [];
  }

  Future<void> _notifyAuthFailure() async {
    await _storage.deleteAll();
    _authFailedController.add(null);
  }

  //메모리 해제
  void dispose() {
    _authFailedController.close();
  }
}
