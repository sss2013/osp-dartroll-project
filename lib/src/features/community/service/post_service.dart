// lib/src/features/community/service/post_service.dart

import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:cultureyo/src/core/network/dio_client.dart';
import 'package:cultureyo/src/features/community/data/post_model.dart';
import 'package:cultureyo/src/features/community/data/performance_detail_model.dart';

// DioClient가 'package:dio/dio.dart'를 사용한다고 가정합니다.

class PostService {
  final DioClient dioClient;

  // ⭐️ 1. 서비스 계층 정의: DioClient를 종속성 주입 받음
  PostService({required this.dioClient});

  // --- API 호출 함수 목록 ---

  // 1. 게시글 목록 조회 (인증 불필요)
  // 현재 로직을 유지하면서 DioClient.publicDio를 사용하도록 변경
  Future<List<Post>> fetchPosts(String category) async {
    // 기존 로직: page=0&limit=100을 사용하여 모두 불러와 로컬에서 필터링
    final url = '/api/post/getAll?page=0&limit=100&tap=$category';

    log('🔍 [API_REQUEST] Fetching posts: $url', name: 'POST_SERVICE');

    try {
      // ⭐️ publicDio 사용: 인증 불필요
      final response = await dioClient.publicDio.get(url);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final List<dynamic> jsonList = response.data;

        log('✅ [API_RESPONSE] Count: ${jsonList.length}', name: 'POST_SERVICE');

        return jsonList.map((json) {
          // Post.fromApiJson 팩토리 메서드 재사용
          return Post.fromApiJson(json as Map<String, dynamic>, category: category);
        }).toList();

      } else {
        throw Exception('게시글 목록 로드 실패: ${response.statusCode}');
      }
    } on DioException catch (e) {
      log('🚨 [API_ERROR] DioException fetching posts: ${e.message}', name: 'POST_SERVICE');
      throw Exception('네트워크 오류로 게시글 목록을 불러올 수 없습니다.');
    } catch (e) {
      log('🚨 [API_ERROR] Unknown error fetching posts: $e', name: 'POST_SERVICE');
      rethrow;
    }
  }

  // 2. 조회수 증가 API 호출 (인증 불필요 - GET 요청)
  Future<void> increaseViewCount(String postId, String category) async {
    final url = '/api/post/$postId/views?tap=$category';
    log('🚀 [API_REQUEST] Increasing view count: $url', name: 'POST_SERVICE');

    try {
      // ⭐️ publicDio 사용: 인증 불필요
      await dioClient.publicDio.get(url).timeout(const Duration(seconds: 5));
      log('✅ [API_SUCCESS] View count increased for Post ID: $postId', name: 'POST_SERVICE');
    } on DioException catch (e) {
      // 조회수 증가는 실패해도 메인 흐름에 영향을 주지 않도록 로깅만 합니다.
      log('🚨 [API_ERROR] Failed to increase view count. Status: ${e.response?.statusCode}', name: 'POST_SERVICE');
    } catch (e) {
      log('🚨 [API_EXCEPTION] Error increasing view count: $e', name: 'POST_SERVICE');
    }
  }

  // 3. 공연 목록 조회 (인증 불필요 - POST 요청)
  Future<List<Map<String, dynamic>>> fetchSimplePerformances({
    required String region,
    required String genre,
  }) async {
    final body = {
      'idxName': 'performance',
      // '지역 미정'을 'empty'로 변환하는 기존 로직 유지
      'area': region == '지역 미정' ? 'empty' : region,
      'genre': genre,
    };

    log('🔍 [API_REQUEST] Body: $body', name: 'PERFORMANCE_SIMPLE');

    try {
      // ⭐️ publicDio 사용: 인증 불필요
      final response = await dioClient.publicDio.post(
        '/api/getSimple',
        data: body,
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = response.data;
        final List<dynamic> results = jsonData['results'] ?? [];

        return results
            .map<Map<String, dynamic>>((item) => {
          'id': item['id'].toString(),
          'title': item['title'].toString()
        })
            .toList();
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          message: "서버 오류 (Status: ${response.statusCode})",
        );
      }
    } on DioException {
      rethrow;
    } catch (e) {
      log('🚨 [API_ERROR] Exception: $e', name: 'PERFORMANCE_SIMPLE');
      throw Exception("공연 목록 로드 중 오류 발생.");
    }
  }

  // 4. 공연 상세 정보 조회 (인증 불필요 - POST 요청)
  Future<PerformanceDetail> fetchPerformanceDetail({
    required String idxName,
    required String contentId,
  }) async {
    final detailBody = {
      'idxName': idxName,
      'contentId': contentId,
    };

    try {
      // ⭐️ publicDio 사용: 인증 불필요
      final response = await dioClient.publicDio.post(
        '/api/getEventDetail',
        data: detailBody,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonDetail = response.data;
        // PerformanceDetail 모델 팩토리 메서드 재사용
        return PerformanceDetail.fromJson(jsonDetail);
      } else {
        throw Exception('공연 상세 정보 로드 실패: ${response.statusCode}');
      }
    } on DioException {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }


  // 5. 게시글 작성 (인증 필요)
  Future<Post> createPost({
    required String title,
    required String content,
    required String category,
    required PerformanceDetail detail,
  }) async {
    final String performanceUrl = detail.url ?? '';

    // ⭐️ [토큰 검증] UserId를 직접 보내는 대신, 토큰만 포함하여 요청
    final Map<String, dynamic> requestBody = {
      "title": title,
      "area": detail.area ?? '지역 미정',
      "genre": detail.genre ?? '장르 미정',
      "content": content,
      "tap": category,
      "url": performanceUrl,
      // ⚠️ Note: userId는 DioClient 미들웨어에서 토큰을 통해 자동 주입될 것으로 기대합니다.
    };

    log('▶️ [POST_CREATE_REQUEST] 요청 Body (토큰 제외): $requestBody', name: 'POST_SERVICE');

    try {
      // ⭐️ dio 사용: 토큰이 헤더에 자동 추가됨
      final response = await dioClient.dio.post(
        '/api/post/upload', // 게시글 작성 API 주소
        data: requestBody,
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = response.data;

        // 작성 성공 시 서버 응답을 Post 모델로 변환하여 반환
        return Post.fromApiJson(responseData, category: category);

      } else {
        throw Exception('게시물 작성 실패: ${response.statusCode}');
      }
    } on DioException {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }


  // 6. 게시글 수정 (인증 필요)
  Future<void> editPost({
    required String postId,
    required String category,
    required String newContent,
  }) async {
    // ⭐️ [토큰 검증] 기존 코드에서 userId를 body에 포함했지만, 이제 토큰 기반으로 변경합니다.
    final Map<String, dynamic> requestBody = {
      // "userId": "...", // ⚠️ 제거됨: UserId는 토큰으로 대체됨
      "tap": category,
      "content": newContent,
    };

    final url = '/api/post/$postId/postmodify';

    log('▶️ [POST_EDIT_REQUEST] URL: $url', name: 'POST_SERVICE');
    log('▶️ [POST_EDIT_REQUEST] Body (토큰 제외): $requestBody', name: 'POST_SERVICE');


    try {
      // ⭐️ dio 사용: 토큰이 헤더에 자동 추가됨. 백엔드는 토큰 ID와 게시물 작성자 ID를 대조합니다.
      final response = await dioClient.dio.post( // 기존 POST 요청 유지
        url,
        data: requestBody,
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        log('✅ [POST_EDIT_SUCCESS] 게시물 ID $postId 수정 완료', name: 'POST_SERVICE');
        return;
      } else if (response.statusCode == 403) {
        // 권한 없음 에러 처리
        throw Exception('수정 권한이 없습니다. 작성자가 아닙니다.');
      }
      else {
        throw Exception('게시물 수정 실패: ${response.statusCode}');
      }
    } on DioException {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  // 7. 게시글 삭제 (인증 필요)
  Future<void> deletePost({
    required String postId,
    required String category,
  }) async {
    // ⭐️ [토큰 검증] 기존 코드에서 userId를 body에 포함했지만, 이제 토큰 기반으로 변경합니다.
    final Map<String, dynamic> requestBody = {
      // "userId": "...", // ⚠️ 제거됨: UserId는 토큰으로 대체됨
      "tap": category,
    };

    // 현재 deletePost가 CommentService에 있었으나, PostService로 옮깁니다.
    final url = '/api/post/$postId/delete';

    log('▶️ [POST_DELETE_REQUEST] URL: $url', name: 'POST_SERVICE');

    try {
      // ⭐️ dio 사용: 토큰이 헤더에 자동 추가됨. 백엔드는 토큰 ID와 게시물 작성자 ID를 대조합니다.
      final response = await dioClient.dio.post( // 삭제도 POST 요청 사용 (서버 스펙 존중)
        url,
        data: requestBody,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        log('✅ [POST_DELETE_SUCCESS] 게시물 ID $postId 삭제 완료', name: 'POST_SERVICE');
        return;
      } else if (response.statusCode == 403) {
        throw Exception('삭제 권한이 없습니다. 작성자가 아닙니다.');
      } else {
        throw Exception('게시물 삭제 실패: ${response.statusCode}');
      }
    } on DioException {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }
}