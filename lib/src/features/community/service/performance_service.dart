// lib/src/features/community/service/performance_service.dart

import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;

// 필요한 모델 임포트 (경로 조정 필요)
import 'package:cultureyo/src/features/community/data/performance_detail_model.dart';

// UI 표시를 위한 간단한 Performance 모델 재정의 (Service 외부 노출용)
class PerformanceSimple {
  final String id; // 'prefix:number' 형태
  final String idxName;
  final String contentId;
  final String title;

  PerformanceSimple({
    required this.id,
    required this.idxName,
    required this.contentId,
    required this.title,
  });
}

class PerformanceService {
  final String _baseUrl = 'https://dartroll-nodejs.onrender.com/api';
  static const int _timeoutSeconds = 15;

  /// 공연 목록을 필터링하여 가져옵니다.
  ///
  /// [idxName]: 'performance', 'festival', 'experience'
  /// [area]: 선택된 지역 ('지역 미정'이면 'empty')
  /// [genre]: 선택된 장르명
  Future<List<Map<String, dynamic>>> fetchSimplePerformances({
    required String idxName,
    required String area,
    required String genre,
  }) async {
    final String endpoint = '$_baseUrl/getSimple';

    final Map<String, dynamic> body = {
      'idxName': idxName,
      'area': area == '지역 미정' ? 'empty' : area,
      'genre': genre,
    };
    final String encodedBody = jsonEncode(body);

    log('🔍 [API_REQUEST] URL: $endpoint', name: 'PERF_SERVICE_LIST');
    log('🔍 [API_REQUEST] Body: $encodedBody', name: 'PERF_SERVICE_LIST');

    try {
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
        body: encodedBody,
      ).timeout(const Duration(seconds: _timeoutSeconds));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = jsonDecode(response.body);
        final List<dynamic> results = jsonData['results'] ?? [];

        log('✅ [API_RESPONSE] Count: ${results.length}', name: 'PERF_SERVICE_LIST');

        // UI에서 필요한 정보만 Map 형태로 반환
        return results.map<Map<String, dynamic>>((item) => {
          'id': item['id'].toString(), // 'prefix:number' 형태
          'title': item['title'].toString(),
        }).toList();

      } else {
        log('🚨 [API_ERROR] Status: ${response.statusCode}, Body: ${response.body}', name: 'PERF_SERVICE_LIST');
        throw Exception('공연 목록 조회 실패 (서버 오류: ${response.statusCode})');
      }
    } on TimeoutException {
      log('🚨 [API_TIMEOUT]', name: 'PERF_SERVICE_LIST');
      throw TimeoutException('공연 목록 조회 요청 시간 초과');
    } catch (e) {
      log('🚨 [API_EXCEPTION] $e', name: 'PERF_SERVICE_LIST');
      throw Exception('네트워크 오류 또는 서버 접속 오류');
    }
  }


  /// 특정 공연의 상세 정보를 가져옵니다.
  ///
  /// [idxName]: 'performance', 'festival', 'experience'
  /// [contentId]: 공연 고유 번호
  Future<PerformanceDetail> fetchEventDetail({
    required String idxName,
    required String contentId,
  }) async {
    final String endpoint = '$_baseUrl/getEventDetail';

    final detailBody = {
      'idxName': idxName,
      'contentId': contentId,
    };
    final String encodedBody = jsonEncode(detailBody);

    log('🔍 [API_REQUEST] URL: $endpoint', name: 'PERF_SERVICE_DETAIL');
    log('🔍 [API_REQUEST] Body: $encodedBody', name: 'PERF_SERVICE_DETAIL');

    try {
      final detailResponse = await http.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
        body: encodedBody,
      ).timeout(const Duration(seconds: _timeoutSeconds));

      if (detailResponse.statusCode == 200) {
        final Map<String, dynamic> jsonDetail = jsonDecode(detailResponse.body);
        log('✅ [API_RESPONSE] Detail fetched.', name: 'PERF_SERVICE_DETAIL');

        return PerformanceDetail.fromJson(jsonDetail);
      } else {
        log('🚨 [API_ERROR] Status: ${detailResponse.statusCode}, Body: ${detailResponse.body}', name: 'PERF_SERVICE_DETAIL');
        throw Exception('공연 상세 정보 조회 실패 (서버 오류: ${detailResponse.statusCode})');
      }
    } on TimeoutException {
      log('🚨 [API_TIMEOUT]', name: 'PERF_SERVICE_DETAIL');
      throw TimeoutException('공연 상세 정보 요청 시간 초과');
    } catch (e) {
      log('🚨 [API_EXCEPTION] $e', name: 'PERF_SERVICE_DETAIL');
      throw Exception('네트워크 오류 또는 서버 접속 오류');
    }
  }
}