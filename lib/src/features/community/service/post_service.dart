// lib/src/features/community/service/post_service.dart

import 'dart:async';
import 'dart:developer';
import 'package:dio/dio.dart'; // 💡 [변경] Dio 패키지 사용
import 'package:cultureyo/src/features/community/data/post_model.dart';
// 💡 [추가] DioClient 임포트
import 'package:cultureyo/src/core/network/dio_client.dart';

class PostService {
  // 💡 [제거] 기존 _baseUrl 제거 (DioClient가 관리)

  // 💡 [추가] DioClient 주입
  final DioClient dioClient;

  // 💡 [유지] 타임아웃 상수는 유지하되 Dio에서는 BaseOptions에서 관리하므로 여기서 사용하지는 않습니다.
  static const int _timeoutSeconds = 15;

  PostService({required this.dioClient}); // 💡 [변경] 생성자 수정

  // 1. 게시글 목록을 가져오는 API 함수 (인증 불필요 - publicDio 사용)
  Future<List<Post>> fetchPosts(String category) async {
    final publicDio = dioClient.publicDio;
    // 💡 [변경] 상대 URL 사용
    final url = '/api/post/getAll?page=0&limit=100&tap=$category';

    log('🔍 [API_REQUEST] Fetching posts from service: $url', name: 'POST_SERVICE');

    try {
      final response = await publicDio.get(url); // 💡 [변경] Dio.get 사용

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Dio 응답의 data는 이미 디코딩된 JSON List<dynamic> 입니다.
        final List<dynamic> jsonList = response.data;

        log('✅ [API_RESPONSE] Count: ${jsonList.length}', name: 'POST_SERVICE');

        return jsonList.map((json) {
          return Post.fromApiJson(json as Map<String, dynamic>, category: category);
        }).toList();

      } else {
        // Dio는 2xx 외의 응답은 DioException을 던지는 것이 일반적이지만,
        // 혹시 모를 경우를 대비하여 명시적 처리 코드는 유지합니다.
        log('🚨 [API_ERROR] Status: ${response.statusCode}', name: 'POST_SERVICE');
        throw Exception('게시물 목록 조회 실패 (상태 코드: ${response.statusCode})');
      }
    } on DioException catch (e) { // 💡 [변경] DioException 처리
      log('🚨 [DIO_EXCEPTION] $e', name: 'POST_SERVICE');
      // DioException 발생 시 빈 리스트 대신 에러를 던져 UI에서 처리하도록 변경합니다.
      // (기존에는 빈 리스트를 반환했으나, UI에 실패를 명확히 알리기 위해 throw)
      // BoardPage에서 catch (e) 블록이 이를 처리합니다.
      throw Exception('게시물 목록 조회 실패: ${e.message}');
    } catch (e) {
      log('🚨 [API_EXCEPTION] $e', name: 'POST_SERVICE');
      throw Exception('예상치 못한 오류 발생: $e');
    }
  }

  // 2. 조회수 증가 API 호출 함수 (인증 불필요 - publicDio 사용)
  Future<void> increaseViewCount(String postId, String category) async {
    final publicDio = dioClient.publicDio;
    // 💡 [변경] 상대 URL 사용
    final url = '/api/post/$postId/views?tap=$category';
    log('🚀 [API_REQUEST] Increasing view count from service: $url', name: 'POST_SERVICE_VIEW');

    try {
      // 💡 [변경] Dio.get 사용
      // DioClient의 BaseOptions에 타임아웃이 설정되어 있으나, 이 요청에만 5초를 적용하려면 options를 사용해야 합니다.
      // 일관성을 위해 DioClient의 기본 옵션을 따릅니다.
      await publicDio.get(url);

      log('✅ [API_SUCCESS] View count increased for Post ID: $postId', name: 'POST_SERVICE_VIEW');

    } on DioException catch (e) { // 💡 [변경] DioException 처리
      // 조회수 증가는 실패해도 앱 흐름에 치명적이지 않으므로, 에러를 던지지 않고 로그만 남깁니다.
      // (기존 http.get과 동일하게 TimeoutException 등 모든 예외를 로그로 처리)
      log('🚨 [DIO_EXCEPTION] Error increasing view count: ${e.message}', name: 'POST_SERVICE_VIEW');
    } catch (e) {
      log('🚨 [API_EXCEPTION] Unexpected error: $e', name: 'POST_SERVICE_VIEW');
    }
  }

  // 3. 게시물 삭제 (인증 필요 - dio 사용)
  Future<bool> deletePost(String postId, String userId, String tapCategory) async {
    final dio = dioClient.dio;
    // 💡 [변경] 상대 URL 사용
    final String endpoint = '/api/post/$postId/postdelete';
    final Map<String, dynamic> requestBody = {"userId": userId, "tap": tapCategory};

    log('▶️ [POST_DELETE_REQUEST] URL: $endpoint', name: 'API_SERVICE_POST_DEL');

    try {
      // 💡 [변경] Dio.post 사용 (Dio는 data 인자로 body를 전달)
      final response = await dio.post(
        endpoint,
        data: requestBody,
      );

      log('Status Code: ${response.statusCode}', name: 'API_SERVICE_POST_DEL');

      // Dio는 2xx가 아닌 경우 DioException을 던지지만, 명시적으로 확인.
      if (response.statusCode != 200 && response.statusCode != 201) {
        log('🚨 [POST_DELETE_FAIL_RESPONSE] Body: ${response.data}', name: 'API_SERVICE_POST_DEL');
        return false;
      }

      return true;

    } on DioException catch (e) { // 💡 [변경] DioException 처리
      log('🚨 [DIO_EXCEPTION] Delete failed: ${e.message}', name: 'API_SERVICE_POST_DEL');
      // 기존 로직과 동일하게 재throw (BoardPage의 UI에서 처리하도록 유도)
      throw Exception('게시물 삭제 실패: ${e.message}');
    } catch (e) {
      log('🚨 [DELETE_ERROR] Exception: $e', name: 'API_SERVICE_POST_DEL');
      rethrow;
    }
  }

  // 4. 게시물 수정 (인증 필요 - dio 사용)
  Future<bool> modifyPost(String postId, String userId, String category, String content) async {
    final dio = dioClient.dio;
    // 💡 [변경] 상대 URL 사용
    final String endpoint = '/api/post/$postId/postmodify';
    final Map<String, dynamic> requestBody = {
      "userId": userId,
      "tap": category,
      "content": content,
    };

    log('▶️ [POST_MODIFY_REQUEST] URL: $endpoint', name: 'API_SERVICE_POST_MOD');

    try {
      // 💡 [변경] Dio.post 사용
      final response = await dio.post(
        endpoint,
        data: requestBody,
      );

      log('Status Code: ${response.statusCode}', name: 'API_SERVICE_POST_MOD');

      if (response.statusCode != 200 && response.statusCode != 201) {
        log('🚨 [POST_MODIFY_FAIL_RESPONSE] Body: ${response.data}', name: 'API_SERVICE_POST_MOD');
        return false;
      }

      return true;

    } on DioException catch (e) { // 💡 [변경] DioException 처리
      log('🚨 [DIO_EXCEPTION] Modify failed: ${e.message}', name: 'API_SERVICE_POST_MOD');
      throw Exception('게시물 수정 실패: ${e.message}');
    } catch (e) {
      log('🚨 [MODIFY_ERROR] Exception: $e', name: 'API_SERVICE_POST_MOD');
      rethrow;
    }
  }

  // 5. 게시물 작성 (인증 필요 - dio 사용)
  Future<String?> createPost(Map<String, dynamic> requestBody) async {
    final dio = dioClient.dio;
    // 💡 [변경] 상대 URL 사용
    final String endpoint = '/api/post/upload';

    log('▶️ [POST_CREATE_REQUEST] URL: $endpoint', name: 'API_SERVICE_POST_CRT');

    try {
      // 💡 [변경] Dio.post 사용
      final response = await dio.post(
        endpoint,
        data: requestBody,
      );

      log('Status Code: ${response.statusCode}', name: 'API_SERVICE_POST_CRT');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Dio 응답의 data는 이미 디코딩된 Map<String, dynamic> 입니다.
        final Map<String, dynamic> responseData = response.data;
        final String? postId = responseData['id']?.toString();

        if (postId == null || postId.isEmpty) {
          log('🚨 [POST_CREATE_FAIL_PARSE] 서버가 게시물 ID를 반환하지 않음', name: 'API_SERVICE_POST_CRT');
          return null;
        }

        log('✅ [POST_CREATE_SUCCESS] Post ID: $postId', name: 'API_SERVICE_POST_CRT');
        return postId;

      } else {
        log('🚨 [POST_CREATE_FAIL_RESPONSE] Body: ${response.data}', name: 'API_SERVICE_POST_CRT');
        return null;
      }
    } on DioException catch (e) { // 💡 [변경] DioException 처리
      log('🚨 [DIO_EXCEPTION] Create failed: ${e.message}', name: 'API_SERVICE_POST_CRT');
      throw Exception('게시물 작성 실패: ${e.message}');
    } catch (e) {
      log('🚨 [CREATE_ERROR] Exception: $e', name: 'API_SERVICE_POST_CRT');
      rethrow;
    }
  }
}