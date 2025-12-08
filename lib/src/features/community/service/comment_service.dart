// lib/src/features/community/service/comment_service.dart

import 'dart:async';
import 'dart:developer';
import 'package:dio/dio.dart';

import 'package:cultureyo/src/features/community/data/comment_model.dart';
import 'package:cultureyo/src/core/network/dio_client.dart';

// ⭐ [신규 추가] 댓글 신고 API 응답을 위한 모델 (API 명세 반영)
class CommentReportResult {
  final bool reported; // 토글 후 사용자의 최종 신고 상태 (신고함: true, 신고 안 함: false)
  final int reporteCount; // 신고 누적 횟수 (서버 필드명 repoteCount 반영)

  CommentReportResult({required this.reported, required this.reporteCount});

  factory CommentReportResult.fromJson(Map<String, dynamic> json) {
    return CommentReportResult(
      reported: json['repoted'] as bool? ?? false,
      reporteCount: json['repoteCount'] as int? ?? 0,
    );
  }
}

// ⭐ [신규 추가] 댓글 좋아요 API 응답을 위한 모델
class CommentLikeStatus {
  final bool liked; // 토글 후 사용자의 최종 좋아요 상태 (좋아요함: true, 좋아요 안 함: false)
  final int likeCount; // 최종 좋아요 수

  CommentLikeStatus({required this.liked, required this.likeCount});

  factory CommentLikeStatus.fromJson(Map<String, dynamic> json) {
    return CommentLikeStatus(
      liked: json['liked'] as bool? ?? false,
      likeCount: json['likeCount'] as int? ?? 0,
    );
  }
}


class CommentService {

  final DioClient dioClient;

  CommentService({required this.dioClient});

  // 1. 댓글 목록 가져오기 (GET)
  Future<List<Comment>> fetchComments(String postId) async {
    final dio = dioClient.dio;
    final String endpoint = '/api/post/$postId/comment';

    log('▶️ [COMMENT_FETCH_REQUEST] URL: $endpoint', name: 'API_SERVICE_FETCH');

    try {
      final response = await dio.get(endpoint);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final dynamic decodedBody = response.data;

        if (decodedBody is List) {
          log('✅ [PARSING_SUCCESS] Fetched ${decodedBody.length} comments.', name: 'API_SERVICE_FETCH');
          return decodedBody.map<Comment>((json) => Comment.fromJson(json as Map<String, dynamic>)).toList();
        }
      }

      log('🚨 [FETCH_FAILURE] Unexpected response status or format.', name: 'API_SERVICE_FETCH');
      return [];

    } on DioException catch (e) {
      log('🚨 [FETCH_ERROR] DioException: ${e.message}', name: 'API_SERVICE_FETCH');
      rethrow;
    } catch (e) {
      log('🚨 [FETCH_ERROR] Exception: $e', name: 'API_SERVICE_FETCH');
      rethrow;
    }
  }

  // 2. 댓글/답글 작성 (POST)
  Future<bool> submitComment(
      String postId,
      String text,
      {String? parentId}
      ) async {
    final dio = dioClient.dio;
    final String endpoint = '/api/post/$postId/comment';

    final Map<String, dynamic> requestBody = {
      "text": text,
    };

    if (parentId != null) {
      requestBody['parentId'] = parentId;
    }

    log('▶️ [COMMENT_CREATE_REQUEST] URL: $endpoint', name: 'API_SERVICE_CREATE');

    try {
      final response = await dio.post(
        endpoint,
        data: requestBody,
      );

      log('Status Code: ${response.statusCode}', name: 'API_SERVICE_CREATE');

      return response.statusCode == 200 || response.statusCode == 201;

    } on DioException catch (e) {
      log('🚨 [CREATE_ERROR] DioException: ${e.message}', name: 'API_SERVICE_CREATE');
      rethrow;
    } catch (e) {
      log('🚨 [CREATE_ERROR] Exception: $e', name: 'API_SERVICE_CREATE');
      rethrow;
    }
  }

  // 3. 댓글 삭제 (POST)
  Future<bool> deleteComment(String commentId) async {
    final dio = dioClient.dio;
    final String endpoint = '/api/post/$commentId/commentdelete';

    log('▶️ [COMMENT_DELETE_REQUEST] URL: $endpoint', name: 'API_SERVICE_COMMENT_DEL');

    try {
      final response = await dio.post(
        endpoint,
      );

      log('Status Code: ${response.statusCode}', name: 'API_SERVICE_COMMENT_DEL');

      if (response.statusCode != 200 && response.statusCode != 201) {
        log('🚨 [COMMENT_DELETE_FAIL_RESPONSE] Body: ${response.data}', name: 'API_SERVICE_COMMENT_DEL');
      }

      return response.statusCode == 200 || response.statusCode == 201;

    } on DioException catch (e) {
      log('🚨 [DELETE_ERROR] DioException: ${e.message}', name: 'API_SERVICE_COMMENT_DEL');
      rethrow;
    } catch (e) {
      log('🚨 [DELETE_ERROR] Exception: $e', name: 'API_SERVICE_COMMENT_DEL');
      rethrow;
    }
  }

  // 4. 댓글 신고 토글 (POST)
  Future<CommentReportResult> toggleCommentReport(String commentId) async {
    final dio = dioClient.dio;
    final String endpoint = '/api/post/$commentId/commentreport';

    log('▶️ [COMMENT_REPORT_REQUEST] URL: $endpoint', name: 'API_SERVICE_REPORT');

    try {
      final response = await dio.post(endpoint, data: {});

      log('Status Code: ${response.statusCode}', name: 'API_SERVICE_REPORT');

      if (response.statusCode == 200 || response.statusCode == 201) {

        final Map<String, dynamic> responseData = response.data;

        log('✅ [COMMENT_REPORT_SUCCESS] Data: $responseData', name: 'API_SERVICE_REPORT');

        return CommentReportResult.fromJson(responseData);

      } else {
        log('🚨 [REPORT_FAIL_RESPONSE] Body: ${response.data}', name: 'API_SERVICE_REPORT');
        throw Exception('댓글 신고 처리 실패 (상태 코드: ${response.statusCode})');
      }
    } on DioException catch (e) {
      log('🚨 [REPORT_ERROR] DioException: ${e.message}', name: 'API_SERVICE_REPORT');
      throw Exception('댓글 신고 처리 실패: ${e.response?.data['message']?.toString() ?? e.message}');
    } catch (e) {
      log('🚨 [REPORT_ERROR] Exception: $e', name: 'API_SERVICE_REPORT');
      rethrow;
    }
  }

  // ⭐ [신규 추가] 5. 댓글 좋아요 토글 (POST) - 토큰 인증 필요
  Future<CommentLikeStatus> toggleCommentLike(String commentId) async {
    final dio = dioClient.dio;
    // 엔드포인트: /api/post/:id/commentlike (:id는 댓글 ID)
    final String endpoint = '/api/post/$commentId/commentlike';

    log('▶️ [COMMENT_LIKE_REQUEST] URL: $endpoint', name: 'API_SERVICE_LIKE');

    try {
      // Body가 비어있으므로 빈 Map 전달 (토큰 인증 기반)
      final response = await dio.post(endpoint, data: {});

      log('Status Code: ${response.statusCode}', name: 'API_SERVICE_LIKE');

      if (response.statusCode == 200 || response.statusCode == 201) {

        final Map<String, dynamic> responseData = response.data;

        log('✅ [COMMENT_LIKE_SUCCESS] Data: $responseData', name: 'API_SERVICE_LIKE');

        // 서버 응답에서 liked와 likeCount를 파싱
        return CommentLikeStatus.fromJson(responseData);

      } else {
        log('🚨 [LIKE_FAIL_RESPONSE] Body: ${response.data}', name: 'API_SERVICE_LIKE');
        throw Exception('댓글 좋아요 처리 실패 (상태 코드: ${response.statusCode})');
      }
    } on DioException catch (e) {
      log('🚨 [LIKE_ERROR] DioException: ${e.message}', name: 'API_SERVICE_LIKE');
      throw Exception('댓글 좋아요 처리 실패: ${e.response?.data['message']?.toString() ?? e.message}');
    } catch (e) {
      log('🚨 [LIKE_ERROR] Exception: $e', name: 'API_SERVICE_LIKE');
      rethrow;
    }
  }
}