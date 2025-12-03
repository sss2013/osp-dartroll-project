import 'dart:developer';
import 'package:dio/dio.dart'; // Dio, DioException 처리를 위해 필요
import 'package:cultureyo/src/core/network/dio_client.dart'; // DioClient를 사용
import 'package:cultureyo/src/features/community/data/comment_model.dart';
import 'dart:async';

class CommentService {
  final DioClient dioClient;

  // ⭐️ [변경] DioClient를 주입받는 생성자
  CommentService({required this.dioClient});

  // 1. 댓글 목록 가져오기 (GET)
  Future<List<Comment>> fetchComments(String postId) async {
    // 💡 [변경] DioClient의 BaseURL이 적용되므로, 상대 경로만 사용합니다.
    final String endpoint = '/api/post/$postId/comment';
    log('▶️ [COMMENT_FETCH_REQUEST] Endpoint: $endpoint', name: 'COMMENT_SERVICE_FETCH');

    try {
      // ⭐️ [변경] 댓글 읽기(조회)는 인증 없이 가능하다고 가정하고 publicDio 사용
      final response = await dioClient.publicDio.get(endpoint).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decodedBody = response.data; // Dio는 자동으로 JSON을 디코딩합니다.

        if (decodedBody is List) {
          log('✅ [PARSING_SUCCESS] Fetched ${decodedBody.length} comments.', name: 'COMMENT_SERVICE_FETCH');
          return decodedBody.map<Comment>((json) => Comment.fromJson(json as Map<String, dynamic>)).toList();
        }
      }

      log('🚨 [FETCH_FAILURE] Unexpected response status or format.', name: 'COMMENT_SERVICE_FETCH');
      return [];
    } on DioException catch (e) {
      log('🚨 [FETCH_ERROR] DioException: ${e.message}', name: 'COMMENT_SERVICE_FETCH');
      // Timeouts 포함 모든 DioException은 상위 계층으로 던집니다.
      rethrow;
    } catch (e) {
      log('🚨 [FETCH_ERROR] Unknown Exception: $e', name: 'COMMENT_SERVICE_FETCH');
      rethrow;
    }
  }

  // 2. 댓글/답글 작성 (POST)
  Future<bool> submitComment(
      String postId,
      String userId, // ⚠️ Note: 인증 토큰 기반으로 전환 시 이 userId는 무시되거나 제거되어야 합니다.
      String text,
      {String? parentId}
      ) async {
    final String endpoint = '/api/post/$postId/comment';

    final Map<String, dynamic> requestBody = {
      // 서버 요구사항에 따라 임시로 userId를 포함합니다.
      "userId": userId,
      "text": text,
    };

    if (parentId != null) {
      requestBody['parentId'] = parentId;
    }

    log('▶️ [COMMENT_CREATE_REQUEST] Endpoint: $endpoint', name: 'COMMENT_SERVICE_CREATE');
    log('▶️ [COMMENT_CREATE_BODY] Body (userId 포함): $requestBody', name: 'COMMENT_SERVICE_CREATE');

    try {
      // ⭐️ [변경] 댓글 작성(쓰기)은 인증이 필요하므로 dioClient.dio 사용
      final response = await dioClient.dio.post(
        endpoint,
        data: requestBody, // Dio에서는 body 대신 data를 사용
      ).timeout(const Duration(seconds: 15));

      log('Status Code: ${response.statusCode}', name: 'COMMENT_SERVICE_CREATE');

      return response.statusCode == 200 || response.statusCode == 201;

    } on DioException {
      rethrow;
    } catch (e) {
      log('🚨 [CREATE_ERROR] Unknown Exception: $e', name: 'COMMENT_SERVICE_CREATE');
      rethrow;
    }
  }

  // ⭐️ [제거됨] 3. 게시물 삭제 (deletePost) - PostService로 이동 완료

  // 4. 댓글 삭제 (POST)
  Future<bool> deleteComment(String commentId, String currentUserId) async {
    final String endpoint = '/api/post/$commentId/commentdelete';
    final Map<String, dynamic> requestBody = {"userId": currentUserId}; // 서버 요구사항에 따라 userId 포함

    log('▶️ [COMMENT_DELETE_REQUEST] Endpoint: $endpoint', name: 'COMMENT_SERVICE_COMMENT_DEL');
    log('▶️ [COMMENT_DELETE_BODY] Body (userId 포함): $requestBody', name: 'COMMENT_SERVICE_COMMENT_DEL');

    try {
      // ⭐️ [변경] 댓글 삭제는 인증이 필요하므로 dioClient.dio 사용
      final response = await dioClient.dio.post(
        endpoint,
        data: requestBody,
      ).timeout(const Duration(seconds: 15));

      log('Status Code: ${response.statusCode}', name: 'COMMENT_SERVICE_COMMENT_DEL');

      if (response.statusCode != 200 && response.statusCode != 201) {
        log('🚨 [COMMENT_DELETE_FAIL_RESPONSE] Body: ${response.data}', name: 'COMMENT_SERVICE_COMMENT_DEL');
      }

      return response.statusCode == 200 || response.statusCode == 201;

    } on DioException {
      rethrow;
    } catch (e) {
      log('🚨 [DELETE_ERROR] Unknown Exception: $e', name: 'COMMENT_SERVICE_COMMENT_DEL');
      rethrow;
    }
  }
}