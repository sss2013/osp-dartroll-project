// lib/src/features/community/service/post_service.dart

import 'dart:async';
import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:cultureyo/src/features/community/data/post_model.dart';
import 'package:cultureyo/src/core/network/dio_client.dart';
// UserService import 제거됨

class PostService {
  final DioClient dioClient;
  // UserService 필드 제거됨
  static const int _timeoutSeconds = 15;

  // ⭐ [수정] 생성자에서 UserService 제거
  PostService({required this.dioClient});

  // 1. 게시글 목록을 가져오는 API 함수 (인증 불필요 - publicDio 사용)
  Future<List<Post>> fetchPosts(String category) async {
    final publicDio = dioClient.publicDio;
    final url = '/api/post/getAll?page=0&limit=100&tap=$category';

    log('🔍 [API_REQUEST] Fetching posts from service: $url', name: 'POST_SERVICE');

    try {
      final response = await publicDio.get(url);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final List<dynamic> jsonList = response.data;

        log('✅ [API_RESPONSE] Count: ${jsonList.length}', name: 'POST_SERVICE');

        return jsonList.map((json) {
          return Post.fromApiJson(
            json as Map<String, dynamic>,
            category: category,
          );
        }).toList();

      } else {
        log('🚨 [API_ERROR] Status: ${response.statusCode}', name: 'POST_SERVICE');
        throw Exception('게시물 목록 조회 실패 (상태 코드: ${response.statusCode})');
      }
    } on DioException catch (e) {
      log('🚨 [DIO_EXCEPTION] $e', name: 'POST_SERVICE');
      throw Exception('게시물 목록 조회 실패: ${e.message}');
    } catch (e) {
      log('🚨 [API_EXCEPTION] $e', name: 'POST_SERVICE');
      throw Exception('예상치 못한 오류 발생: $e');
    }
  }

  // 2. 조회수 증가 API 호출 함수 (생략... 변경 없음)
  Future<void> increaseViewCount(String postId, String category) async {
    final publicDio = dioClient.publicDio;
    final url = '/api/post/$postId/views?tap=$category';
    log('🚀 [API_REQUEST] Increasing view count from service: $url', name: 'POST_SERVICE_VIEW');

    try {
      await publicDio.get(url);
      log('✅ [API_SUCCESS] View count increased for Post ID: $postId', name: 'POST_SERVICE_VIEW');
    } on DioException catch (e) {
      log('🚨 [DIO_EXCEPTION] Error increasing view count: ${e.message}', name: 'POST_SERVICE_VIEW');
    } catch (e) {
      log('🚨 [API_EXCEPTION] Unexpected error: $e', name: 'POST_SERVICE_VIEW');
    }
  }

  // 3. 게시물 삭제 (생략... 변경 없음)
  Future<bool> deletePost(String postId, String tapCategory) async {
    final dio = dioClient.dio;
    final String endpoint = '/api/post/$postId/postdelete';
    final Map<String, dynamic> requestBody = {"tap": tapCategory};

    log('▶️ [POST_DELETE_REQUEST] URL: $endpoint', name: 'API_SERVICE_POST_DEL');

    try {
      final response = await dio.post(
        endpoint,
        data: requestBody,
      );
      log('Status Code: ${response.statusCode}', name: 'API_SERVICE_POST_DEL');

      if (response.statusCode != 200 && response.statusCode != 201) {
        log('🚨 [POST_DELETE_FAIL_RESPONSE] Body: ${response.data}', name: 'API_SERVICE_POST_DEL');
        return false;
      }
      return true;

    } on DioException catch (e) {
      log('🚨 [DIO_EXCEPTION] Delete failed: ${e.message}', name: 'API_SERVICE_POST_DEL');
      throw Exception('게시물 삭제 실패: ${e.message}');
    } catch (e) {
      log('🚨 [DELETE_ERROR] Exception: $e', name: 'API_SERVICE_POST_DEL');
      rethrow;
    }
  }

  // 4. 게시물 수정 (생략... 변경 없음)
  Future<bool> modifyPost(String postId, String category, String content) async {
    final dio = dioClient.dio;
    final String endpoint = '/api/post/$postId/postmodify';
    final Map<String, dynamic> requestBody = {
      "tap": category,
      "content": content,
    };

    log('▶️ [POST_MODIFY_REQUEST] URL: $endpoint', name: 'API_SERVICE_POST_MOD');

    try {
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
    } on DioException catch (e) {
      log('🚨 [DIO_EXCEPTION] Modify failed: ${e.message}', name: 'API_SERVICE_POST_MOD');
      throw Exception('게시물 수정 실패: ${e.message}');
    } catch (e) {
      log('🚨 [MODIFY_ERROR] Exception: $e', name: 'API_SERVICE_POST_MOD');
      rethrow;
    }
  }

  // 5. 게시물 작성 (생략... 변경 없음)
  Future<String?> createPost(Map<String, dynamic> requestBody) async {
    final dio = dioClient.dio;
    final String endpoint = '/api/post/upload';

    log('▶️ [POST_CREATE_REQUEST] URL: $endpoint', name: 'API_SERVICE_POST_CRT');

    try {
      final response = await dio.post(
        endpoint,
        data: requestBody,
      );

      log('Status Code: ${response.statusCode}', name: 'API_SERVICE_POST_CRT');

      if (response.statusCode == 200 || response.statusCode == 201) {
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
    } on DioException catch (e) {
      log('🚨 [DIO_EXCEPTION] Create failed: ${e.message}', name: 'API_SERVICE_POST_CRT');
      throw Exception('게시물 작성 실패: ${e.message}');
    } catch (e) {
      log('🚨 [CREATE_ERROR] Exception: $e', name: 'API_SERVICE_POST_CRT');
      rethrow;
    }
  }

  // ⭐ [최종 수정] 6. 게시글 좋아요 토글
  Future<int> toggleLike(String postId, String tapCategory) async {
    final dio = dioClient.dio;
    final String endpoint = '/api/post/$postId/like';

    final Map<String, dynamic> requestBody = {
      "tap": tapCategory,
    };

    log('▶️ [POST_LIKE_TOGGLE_REQUEST] URL: $endpoint', name: 'API_SERVICE_POST_LIKE');

    try {
      final response = await dio.post(
        endpoint,
        data: requestBody,
      );

      log('Status Code: ${response.statusCode}', name: 'API_SERVICE_POST_LIKE');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = response.data;

        // ⭐ [핵심 로직] like 배열의 길이만 계산
        final List<dynamic> likeListDynamic = responseData['like'] is List
            ? responseData['like'] as List<dynamic>
            : [];

        final int likesCount = likeListDynamic.length;

        log('✅ [POST_LIKE_SUCCESS] Count: $likesCount', name: 'API_SERVICE_POST_LIKE');
        return likesCount;

      } else {
        log('🚨 [POST_LIKE_FAIL_RESPONSE] Body: ${response.data}', name: 'API_SERVICE_POST_LIKE');
        throw Exception('좋아요 처리 실패 (상태 코드: ${response.statusCode})');
      }
    } on DioException catch (e) {
      log('🚨 [DIO_EXCEPTION] Like toggle failed: ${e.message}', name: 'API_SERVICE_POST_LIKE');
      throw Exception('좋아요 처리 실패: ${e.response?.data['message']?.toString() ?? e.message}');
    } catch (e) {
      log('🚨 [LIKE_TOGGLE_ERROR] Exception: $e', name: 'API_SERVICE_POST_LIKE');
      rethrow;
    }
  }
  // ⭐ [추가] 7. 게시글 신고 API
  Future<PostReportStatus> toggleReportPost(String postId, String tapCategory) async {
    final dio = dioClient.dio; // 토큰 필요 (인증된 Dio 클라이언트)
    final String endpoint = '/api/post/$postId/report';

    final Map<String, dynamic> requestBody = {
      "tap": tapCategory, // 카테고리 (리뷰/친구찾기)를 body에 담아 전송
    };

    log('▶️ [POST_REPORT_REQUEST] URL: $endpoint', name: 'API_SERVICE_POST_REPORT');

    try {
      final response = await dio.post(
        endpoint,
        data: requestBody,
      );

      log('Status Code: ${response.statusCode}', name: 'API_SERVICE_POST_REPORT');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = response.data;

        final PostReportStatus reportStatus = PostReportStatus.fromJson(responseData);

        log('✅ [POST_REPORT_SUCCESS] Reported: ${reportStatus.reported}, Count: ${reportStatus.reporteCount}', name: 'API_SERVICE_POST_REPORT');

        return reportStatus;

      } else {
        log('🚨 [POST_REPORT_FAIL_RESPONSE] Body: ${response.data}', name: 'API_SERVICE_POST_REPORT');
        throw Exception('게시글 신고 처리 실패 (상태 코드: ${response.statusCode})');
      }
    } on DioException catch (e) {
      log('🚨 [DIO_EXCEPTION] Report failed: ${e.message}', name: 'API_SERVICE_POST_REPORT');
      throw Exception('게시글 신고 실패: ${e.response?.data['message']?.toString() ?? e.message}');
    } catch (e) {
      log('🚨 [REPORT_ERROR] Exception: $e', name: 'API_SERVICE_POST_REPORT');
      rethrow;
    }
  }
}