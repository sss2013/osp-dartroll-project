import 'dart:convert';

import 'package:cultureyo/src/core/network/dio_client.dart';
import 'package:cultureyo/src/features/event/data/event_detail.dart';
import 'package:dio/dio.dart';
import '../data/event.dart';

class EventService {
  final DioClient dioClient;

  EventService({required this.dioClient});

  Future<List<Event>> postGetEvents({
    required String area,
    required String genre,
  }) async {
    final dio = dioClient.publicDio;
    const path = '/api/getEvent';
    final data = {
      'idxName': 'performance',
      'area': area,
      'genre': genre,
    };

    try {
      final response = await dio.post(path, data: data);

      dynamic decodedBody = response.data;
      if (decodedBody is String) {
        decodedBody = jsonDecode(decodedBody);
      }

      if (decodedBody is Map<String, dynamic>) {
        final dynamic rawData = decodedBody['results'];
        if (rawData is List) {
          final events = rawData.map<Event>((e) {
            if (e is Map<String, dynamic>) return Event.fromJson(e);
            return Event.fromJson(Map<String, dynamic>.from(e));
          }).toList();
          return events;
        }
      }
      return [];
    } on DioException catch (e) {
      throw Exception('이벤트 불러오기 실패: ${e.message}');
    } catch (e) {
      throw Exception('예기치 못한 오류 발생: $e');
    }
  }


  Future<EventDetail> postGetEventDetail({
    required String contentId,
  }) async {
    final dio = dioClient.publicDio;

    final data = {
      'idxName': "performance",
      "contentId": contentId,
    };

    try {

      final res = await dio.post('/api/getEventDetail', data: data);
      if (res.statusCode != 200) {
        throw Exception('서버 응답 에러: ${res.statusCode}');
      }

      dynamic decodedBody = res.data;
      if (decodedBody is String) {
        decodedBody = jsonDecode(decodedBody);
      }

      if (decodedBody is Map<String, dynamic>) {
        final dynamic rawDetailData = decodedBody['detail'] ??
            decodedBody['data'] ?? decodedBody;
        if (rawDetailData is Map<String, dynamic>) {
          return EventDetail.fromJson(rawDetailData);
        }
        // fallback: 만약 최상위가 detail 없이 바로 필드가 있으면 사용
        return EventDetail.fromJson(Map<String, dynamic>.from(decodedBody));
      } else {
        throw Exception('상세 응답 형식 오류: 응답이 Map 형태가 아닙니다.');
      }
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final body = e.response?.data;
      throw Exception(
          '상세 정보 불러오기 실패: status=$status body=$body message=${e.message}');
    } catch (e) {
      throw Exception('상세 정보 파싱 실패: $e');
    }
  }
}