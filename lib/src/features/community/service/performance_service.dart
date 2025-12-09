// lib/src/features/community/service/performance_service.dart

import 'dart:async';
import 'dart:developer';
import 'package:dio/dio.dart'; // 💡 [추가] Dio 패키지 사용

// 필요한 모델 임포트 (경로 조정 필요)
import 'package:cultureyo/src/features/community/data/performance_detail_model.dart';
// 💡 [추가] DioClient 임포트
import 'package:cultureyo/src/core/network/dio_client.dart';


// UI 표시를 위한 간단한 Performance 모델 재정의 (유지)
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
  // 💡 [제거] 기존 _baseUrl 제거
  // static const int _timeoutSeconds = 15; // DioClient에서 관리하므로 제거

  // 💡 [추가] DioClient 주입
  final DioClient dioClient;

  PerformanceService({required this.dioClient}); // 💡 [변경] 생성자 수정

  /// 공연 목록을 필터링하여 가져옵니다. (인증 불필요 - publicDio 사용)
  Future<List<Map<String, dynamic>>> fetchSimplePerformances({
    required String idxName,
    required String area,
    required String genre,
  }) async {
    final publicDio = dioClient.publicDio;
    // 💡 [변경] 상대 URL 사용
    final String endpoint = '/api/getSimple';

    final Map<String, dynamic> body = {
      'idxName': idxName,
      // '지역 미정' 처리 로직 유지
      'area': area == '지역 미정' ? 'empty' : area,
      'genre': genre,
    };

    log('🔍 [API_REQUEST] URL: $endpoint', name: 'PERF_SERVICE_LIST');

    try {
      // 💡 [변경] Dio.post 사용. data에 Map을 전달하면 Dio가 자동으로 JSON 인코딩 처리.
      final response = await publicDio.post(
        endpoint,
        data: body,
      );

      if (response.statusCode == 200) {
        // Dio 응답 data는 이미 Map으로 디코딩되어 있습니다.
        final Map<String, dynamic> jsonData = response.data;
        final List<dynamic> results = jsonData['results'] ?? [];

        log('✅ [API_RESPONSE] Count: ${results.length}', name: 'PERF_SERVICE_LIST');

        // UI에서 필요한 정보만 Map 형태로 반환
        return results.map<Map<String, dynamic>>((item) => {
          'id': item['id'].toString(), // 'prefix:number' 형태
          'title': item['title'].toString(),
        }).toList();

      } else {
        // Dio는 보통 2xx가 아니면 Exception을 던지므로 이 코드는 방어적입니다.
        log('🚨 [API_ERROR] Status: ${response.statusCode}, Body: ${response.data}', name: 'PERF_SERVICE_LIST');
        throw Exception('공연 목록 조회 실패 (서버 오류: ${response.statusCode})');
      }
    } on DioException catch (e) { // 💡 [변경] DioException 처리
      log('🚨 [DIO_EXCEPTION] ${e.message}', name: 'PERF_SERVICE_LIST');
      // 기존 로직과 동일하게 TimeoutException 등 구체적인 오류를 던집니다.
      throw Exception('공연 목록 조회 실패: ${e.message}');
    } catch (e) {
      log('🚨 [API_EXCEPTION] $e', name: 'PERF_SERVICE_LIST');
      throw Exception('네트워크 오류 또는 서버 접속 오류');
    }
  }


  /// 특정 공연의 상세 정보를 가져옵니다. (인증 불필요 - publicDio 사용)
  Future<PerformanceDetail> fetchEventDetail({
    required String idxName,
    required String contentId,
  }) async {
    final publicDio = dioClient.publicDio;
    // 💡 [변경] 상대 URL 사용
    final String endpoint = '/api/getEventDetail';

    final detailBody = {
      'idxName': idxName,
      'contentId': contentId,
    };

    log('🔍 [API_REQUEST] URL: $endpoint', name: 'PERF_SERVICE_DETAIL');

    try {
      // 💡 [변경] Dio.post 사용
      final detailResponse = await publicDio.post(
        endpoint,
        data: detailBody,
      );

      if (detailResponse.statusCode == 200) {
        // Dio 응답 data는 이미 Map으로 디코딩되어 있습니다.
        final Map<String, dynamic> jsonDetail = detailResponse.data;
        log('✅ [API_RESPONSE] Detail fetched.', name: 'PERF_SERVICE_DETAIL');

        return PerformanceDetail.fromJson(jsonDetail);
      } else {
        log('🚨 [API_ERROR] Status: ${detailResponse.statusCode}, Body: ${detailResponse.data}', name: 'PERF_SERVICE_DETAIL');
        throw Exception('공연 상세 정보 조회 실패 (서버 오류: ${detailResponse.statusCode})');
      }
    } on DioException catch (e) { // 💡 [변경] DioException 처리
      log('🚨 [DIO_EXCEPTION] ${e.message}', name: 'PERF_SERVICE_DETAIL');
      throw Exception('공연 상세 정보 요청 실패: ${e.message}');
    } catch (e) {
      log('🚨 [API_EXCEPTION] $e', name: 'PERF_SERVICE_DETAIL');
      throw Exception('네트워크 오류 또는 서버 접속 오류');
    }
  }
}