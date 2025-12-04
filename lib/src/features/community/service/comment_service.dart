// lib/src/features/community/service/comment_service.dart

import 'dart:async';
import 'dart:developer';
import 'package:dio/dio.dart'; // 💡 [추가] Dio 패키지 임포트
// 💡 [제거] import 'package:http/http.dart' as http;
// 💡 [제거] import 'dart:convert';

import 'package:cultureyo/src/features/community/data/comment_model.dart';
// 💡 [추가] DioClient 임포트
import 'package:cultureyo/src/core/network/dio_client.dart';

class CommentService {
  // 💡 [제거] 기존 _baseUrl 제거 (DioClient가 관리)
  // static const String _baseUrl = 'https://dartroll-nodejs.onrender.com/api/post';
  // static const int _timeoutSeconds = 15; // DioClient에서 관리하므로 제거

  // 💡 [추가] DioClient 주입
  final DioClient dioClient;

  CommentService({required this.dioClient}); // 💡 [변경] 생성자 수정

  // 1. 댓글 목록 가져오기 (GET) - 인증 필요 (게시물 상세 페이지 접근 시 인증)
  Future<List<Comment>> fetchComments(String postId) async {
    final dio = dioClient.dio; // 💡 [변경] 인증된 Dio 인스턴스 사용
    // 💡 [변경] 상대 URL 사용
    final String endpoint = '/api/post/$postId/comment';

    log('▶️ [COMMENT_FETCH_REQUEST] URL: $endpoint', name: 'API_SERVICE_FETCH');

    try {
      // 💡 [변경] Dio.get 사용
      final response = await dio.get(endpoint);

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Dio 응답의 data는 이미 List<dynamic>으로 디코딩되어 있습니다.
        final dynamic decodedBody = response.data;

        if (decodedBody is List) {
          log('✅ [PARSING_SUCCESS] Fetched ${decodedBody.length} comments.', name: 'API_SERVICE_FETCH');
          return decodedBody.map<Comment>((json) => Comment.fromJson(json as Map<String, dynamic>)).toList();
        }
      }

      log('🚨 [FETCH_FAILURE] Unexpected response status or format.', name: 'API_SERVICE_FETCH');
      return []; // 기존 로직과 동일하게 빈 리스트 반환

    } on DioException catch (e) { // 💡 [변경] DioException 처리
      log('🚨 [FETCH_ERROR] DioException: ${e.message}', name: 'API_SERVICE_FETCH');
      rethrow; // 기존 로직과 동일하게 재throw
    } catch (e) {
      log('🚨 [FETCH_ERROR] Exception: $e', name: 'API_SERVICE_FETCH');
      rethrow; // 기존 로직과 동일하게 재throw
    }
  }

  // 2. 댓글/답글 작성 (POST) - 인증 필요 (dio 사용)
  Future<bool> submitComment(
      String postId,
      String userId,
      String text,
      {String? parentId}
      ) async {
    final dio = dioClient.dio; // 💡 [변경] 인증된 Dio 인스턴스 사용
    // 💡 [변경] 상대 URL 사용
    final String endpoint = '/api/post/$postId/comment';

    final Map<String, dynamic> requestBody = {
      "userId": userId,
      "text": text,
    };

    if (parentId != null) {
      requestBody['parentId'] = parentId;
    }

    log('▶️ [COMMENT_CREATE_REQUEST] URL: $endpoint', name: 'API_SERVICE_CREATE');

    try {
      // 💡 [변경] Dio.post 사용. data에 Map을 전달하면 Dio가 자동으로 JSON 인코딩 처리.
      final response = await dio.post(
        endpoint,
        data: requestBody,
      );

      log('Status Code: ${response.statusCode}', name: 'API_SERVICE_CREATE');

      return response.statusCode == 200 || response.statusCode == 201;

    } on DioException catch (e) { // 💡 [변경] DioException 처리
      log('🚨 [CREATE_ERROR] DioException: ${e.message}', name: 'API_SERVICE_CREATE');
      rethrow; // 기존 로직과 동일하게 재throw
    } catch (e) {
      log('🚨 [CREATE_ERROR] Exception: $e', name: 'API_SERVICE_CREATE');
      rethrow; // 기존 로직과 동일하게 재throw
    }
  }

  // 3. 댓글 삭제 (POST) - 인증 필요 (dio 사용)
  Future<bool> deleteComment(String commentId, String currentUserId) async {
    final dio = dioClient.dio; // 💡 [변경] 인증된 Dio 인스턴스 사용
    // 💡 [변경] 상대 URL 사용
    final String endpoint = '/api/post/$commentId/commentdelete';
    final Map<String, dynamic> requestBody = {"userId": currentUserId};

    log('▶️ [COMMENT_DELETE_REQUEST] URL: $endpoint', name: 'API_SERVICE_COMMENT_DEL');

    try {
      // 💡 [변경] Dio.post 사용
      final response = await dio.post(
        endpoint,
        data: requestBody,
      );

      log('Status Code: ${response.statusCode}', name: 'API_SERVICE_COMMENT_DEL');

      if (response.statusCode != 200 && response.statusCode != 201) {
        // DioException이 발생하지 않았다면 여기서 로그
        log('🚨 [COMMENT_DELETE_FAIL_RESPONSE] Body: ${response.data}', name: 'API_SERVICE_COMMENT_DEL');
      }

      return response.statusCode == 200 || response.statusCode == 201;

    } on DioException catch (e) { // 💡 [변경] DioException 처리
      log('🚨 [DELETE_ERROR] DioException: ${e.message}', name: 'API_SERVICE_COMMENT_DEL');
      rethrow; // 기존 로직과 동일하게 재throw
    } catch (e) {
      log('🚨 [DELETE_ERROR] Exception: $e', name: 'API_SERVICE_COMMENT_DEL');
      rethrow; // 기존 로직과 동일하게 재throw
    }
  }
}