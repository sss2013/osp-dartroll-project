// lib/src/features/community/service/comment_service.dart (게시물 삭제 로직 제거)

import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:cultureyo/src/features/community/data/comment_model.dart';
import 'dart:async';

class CommentService {
  static const String _baseUrl = 'https://dartroll-nodejs.onrender.com/api/post';
  static const int _timeoutSeconds = 15;

  // 1. 댓글 목록 가져오기 (GET)
  Future<List<Comment>> fetchComments(String postId) async {
    // ... (기존 로직 유지) ...
    final String endpoint = '$_baseUrl/$postId/comment';
    log('▶️ [COMMENT_FETCH_REQUEST] URL: $endpoint', name: 'API_SERVICE_FETCH');
    try {
      final response = await http.get(Uri.parse(endpoint)).timeout(const Duration(seconds: _timeoutSeconds));
      if (response.statusCode == 200 || response.statusCode == 201) {
        final decodedBody = jsonDecode(response.body);
        if (decodedBody is List) {
          log('✅ [PARSING_SUCCESS] Fetched ${decodedBody.length} comments.', name: 'API_SERVICE_FETCH');
          return decodedBody.map<Comment>((json) => Comment.fromJson(json)).toList();
        }
      }
      log('🚨 [FETCH_FAILURE] Unexpected response status or format.', name: 'API_SERVICE_FETCH');
      return [];
    } on TimeoutException {
      log('🚨 [FETCH_TIMEOUT] 서버 응답 시간 초과', name: 'API_SERVICE_FETCH');
      rethrow;
    } catch (e) {
      log('🚨 [FETCH_ERROR] Exception: $e', name: 'API_SERVICE_FETCH');
      rethrow;
    }
  }

  // 2. 댓글/답글 작성 (POST)
  Future<bool> submitComment(
      String postId,
      String userId,
      String text,
      {String? parentId}
      ) async {
    // ... (기존 로직 유지) ...
    final String endpoint = '$_baseUrl/$postId/comment';

    final Map<String, dynamic> requestBody = {
      "userId": userId,
      "text": text,
    };

    if (parentId != null) {
      requestBody['parentId'] = parentId;
    }

    log('▶️ [COMMENT_CREATE_REQUEST] URL: $endpoint', name: 'API_SERVICE_CREATE');
    log('▶️ [COMMENT_CREATE_BODY] Body: ${jsonEncode(requestBody)}', name: 'API_SERVICE_CREATE');


    try {
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: _timeoutSeconds));

      log('Status Code: ${response.statusCode}', name: 'API_SERVICE_CREATE');

      return response.statusCode == 200 || response.statusCode == 201;

    } on TimeoutException {
      log('🚨 [CREATE_TIMEOUT] 서버 응답 시간 초과', name: 'API_SERVICE_CREATE');
      rethrow;
    } catch (e) {
      log('🚨 [CREATE_ERROR] Exception: $e', name: 'API_SERVICE_CREATE');
      rethrow;
    }
  }

  // 3. 댓글 삭제 (POST)
  Future<bool> deleteComment(String commentId, String currentUserId) async {
    final String endpoint = '$_baseUrl/$commentId/commentdelete';
    final Map<String, dynamic> requestBody = {"userId": currentUserId};
    final String encodedBody = jsonEncode(requestBody);

    log('▶️ [COMMENT_DELETE_REQUEST] URL: $endpoint', name: 'API_SERVICE_COMMENT_DEL');
    log('▶️ [COMMENT_DELETE_BODY] Body: $encodedBody', name: 'API_SERVICE_COMMENT_DEL');

    try {
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
        body: encodedBody,
      ).timeout(const Duration(seconds: _timeoutSeconds));

      log('Status Code: ${response.statusCode}', name: 'API_SERVICE_COMMENT_DEL');

      if (response.statusCode != 200 && response.statusCode != 201) {
        log('🚨 [COMMENT_DELETE_FAIL_RESPONSE] Body: ${response.body}', name: 'API_SERVICE_COMMENT_DEL');
      }

      return response.statusCode == 200 || response.statusCode == 201;

    } on TimeoutException {
      log('🚨 [DELETE_TIMEOUT] 서버 응답 시간 초과', name: 'API_SERVICE_COMMENT_DEL');
      rethrow;
    } catch (e) {
      log('🚨 [DELETE_ERROR] Exception: $e', name: 'API_SERVICE_COMMENT_DEL');
      rethrow;
    }
  }
}