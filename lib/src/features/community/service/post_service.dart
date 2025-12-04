// lib/src/features/community/service/post_service.dart

import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:cultureyo/src/features/community/data/post_model.dart';

class PostService {
  final String _baseUrl = 'https://dartroll-nodejs.onrender.com/api/post';
  // 💡 [추가] CommentService와 동일하게 타임아웃 상수를 정의하여 일관성 유지
  static const int _timeoutSeconds = 15;

  // 1. 게시글 목록을 가져오는 API 함수 (기존 _fetchPosts 로직)
  Future<List<Post>> fetchPosts(String category) async {
    // ... (기존 로직 유지) ...
    final url = '$_baseUrl/getAll?page=0&limit=100&tap=$category';

    log('🔍 [API_REQUEST] Fetching posts from service: $url', name: 'POST_SERVICE');

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final List<dynamic> jsonList = jsonDecode(response.body);

        log('✅ [API_RESPONSE] Count: ${jsonList.length}', name: 'POST_SERVICE');

        return jsonList.map((json) {
          return Post.fromApiJson(json as Map<String, dynamic>, category: category);
        }).toList();

      } else {
        log('🚨 [API_ERROR] Status: ${response.statusCode}', name: 'POST_SERVICE');
        return [];
      }
    } catch (e) {
      log('🚨 [API_EXCEPTION] $e', name: 'POST_SERVICE');
      return [];
    }
  }

  // 2. 조회수 증가 API 호출 함수 (기존 _increaseViewCount 로직)
  Future<void> increaseViewCount(String postId, String category) async {
    final url = '$_baseUrl/$postId/views?tap=$category';
    log('🚀 [API_REQUEST] Increasing view count from service: $url', name: 'POST_SERVICE_VIEW');

    try {
      // 기존 5초 타임아웃 유지
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200 || response.statusCode == 201) {
        log('✅ [API_SUCCESS] View count increased for Post ID: $postId', name: 'POST_SERVICE_VIEW');
      } else {
        log('🚨 [API_ERROR] Failed to increase view count. Status: ${response.statusCode}', name: 'POST_SERVICE_VIEW');
      }
    } on TimeoutException {
      log('🚨 [API_EXCEPTION] Timeout increasing view count.', name: 'POST_SERVICE_VIEW');
    } catch (e) {
      log('🚨 [API_EXCEPTION] Error increasing view count: $e', name: 'POST_SERVICE_VIEW');
    }
  }

  // 3. 게시물 삭제 (POST) - CommentService에서 이관
  Future<bool> deletePost(String postId, String userId, String tapCategory) async {
    final String endpoint = '$_baseUrl/$postId/postdelete';
    final Map<String, dynamic> requestBody = {"userId": userId, "tap": tapCategory};
    final String encodedBody = jsonEncode(requestBody);

    log('▶️ [POST_DELETE_REQUEST] URL: $endpoint', name: 'API_SERVICE_POST_DEL');
    log('▶️ [POST_DELETE_BODY] Body: $encodedBody', name: 'API_SERVICE_POST_DEL');

    try {
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
        body: encodedBody,
      ).timeout(const Duration(seconds: _timeoutSeconds)); // 15초 타임아웃 적용

      log('Status Code: ${response.statusCode}', name: 'API_SERVICE_POST_DEL');

      if (response.statusCode != 200 && response.statusCode != 201) {
        log('🚨 [POST_DELETE_FAIL_RESPONSE] Body: ${response.body}', name: 'API_SERVICE_POST_DEL');
      }

      return response.statusCode == 200 || response.statusCode == 201;

    } on TimeoutException {
      log('🚨 [DELETE_TIMEOUT] 서버 응답 시간 초과', name: 'API_SERVICE_POST_DEL');
      rethrow;
    } catch (e) {
      log('🚨 [DELETE_ERROR] Exception: $e', name: 'API_SERVICE_POST_DEL');
      rethrow;
    }
  }

  // 4. ⭐ [추가됨] 게시물 수정 (POST) - PostEditPage에서 이관
  Future<bool> modifyPost(String postId, String userId, String category, String content) async {
    final String endpoint = '$_baseUrl/$postId/postmodify';
    final Map<String, dynamic> requestBody = {
      "userId": userId,
      "tap": category,
      "content": content,
    };
    final String encodedBody = jsonEncode(requestBody);

    log('▶️ [POST_MODIFY_REQUEST] URL: $endpoint', name: 'API_SERVICE_POST_MOD');
    log('▶️ [POST_MODIFY_BODY] Body: $encodedBody', name: 'API_SERVICE_POST_MOD');

    try {
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
        body: encodedBody,
      ).timeout(const Duration(seconds: _timeoutSeconds));

      log('Status Code: ${response.statusCode}', name: 'API_SERVICE_POST_MOD');

      if (response.statusCode != 200 && response.statusCode != 201) {
        log('🚨 [POST_MODIFY_FAIL_RESPONSE] Body: ${response.body}', name: 'API_SERVICE_POST_MOD');
      }

      return response.statusCode == 200 || response.statusCode == 201;

    } on TimeoutException {
      log('🚨 [MODIFY_TIMEOUT] 서버 응답 시간 초과', name: 'API_SERVICE_POST_MOD');
      rethrow;
    } catch (e) {
      log('🚨 [MODIFY_ERROR] Exception: $e', name: 'API_SERVICE_POST_MOD');
      rethrow;
    }
  }

  // 5. ⭐ [추가됨] 게시물 작성 (POST) - PostWritePage에서 이관
  Future<String?> createPost(Map<String, dynamic> requestBody) async {
    final String endpoint = '$_baseUrl/upload';
    final String encodedBody = jsonEncode(requestBody);

    log('▶️ [POST_CREATE_REQUEST] URL: $endpoint', name: 'API_SERVICE_POST_CRT');
    log('▶️ [POST_CREATE_BODY] Body: $encodedBody', name: 'API_SERVICE_POST_CRT');

    try {
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
        body: encodedBody,
      ).timeout(const Duration(seconds: _timeoutSeconds));

      log('Status Code: ${response.statusCode}', name: 'API_SERVICE_POST_CRT');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final String? postId = responseData['id']?.toString();

        if (postId == null || postId.isEmpty) {
          log('🚨 [POST_CREATE_FAIL_PARSE] 서버가 게시물 ID를 반환하지 않음', name: 'API_SERVICE_POST_CRT');
          return null;
        }

        log('✅ [POST_CREATE_SUCCESS] Post ID: $postId', name: 'API_SERVICE_POST_CRT');
        return postId;

      } else {
        log('🚨 [POST_CREATE_FAIL_RESPONSE] Body: ${response.body}', name: 'API_SERVICE_POST_CRT');
        return null;
      }
    } on TimeoutException {
      log('🚨 [CREATE_TIMEOUT] 서버 응답 시간 초과', name: 'API_SERVICE_POST_CRT');
      rethrow;
    } catch (e) {
      log('🚨 [CREATE_ERROR] Exception: $e', name: 'API_SERVICE_POST_CRT');
      rethrow;
    }
  }
}
