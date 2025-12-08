import 'package:cultureyo/src/core/network/dio_client.dart';
import 'package:dio/dio.dart';

class ChatService {
  final DioClient dioClient;

  ChatService({required this.dioClient});

  Future<void> createRoom(String otherId) async {
    final dio = dioClient.dio;

    final data = {
      'otherId': otherId,
    };

    try {
      await dio.post(
        '/api/chat/',
        data: data,
      );
    } on DioException catch (e) {
      // 에러 처리
      print('Failed to create chat room: $e');
      rethrow;
    }
  }
  Future<void> sendMessage(String roomId, String text) async {
    final dio = dioClient.dio;
    try {
      await dio.post(
        '/api/chat/message', // 서버 API 엔드포인트
        data: {
          'roomId': roomId,
          'text': text,
        },
      );
    } on DioException catch (e) {
      // 에러 처리
      print('Failed to send message: $e');
      rethrow;
    }
  }
}
