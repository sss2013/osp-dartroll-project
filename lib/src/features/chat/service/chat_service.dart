import 'package:cultureyo/src/core/network/dio_client.dart';
import 'package:cultureyo/src/features/chat/data/chat_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ChatService {
  final DioClient dioClient;

  ChatService({required this.dioClient});

  Future<List<ChatRoom>> findMyRoom() async {
    final dio = dioClient.dio;
    try {
      final response = await dio.get(
        '/api/chat/',
      );
      if (response.data is List) {
        return (response.data as List)
            .map((json) => ChatRoom.fromJson(json))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      if (kDebugMode) {
        print('Failed to fetch chat rooms: $e');
      }
      rethrow;
    }
  }
  Future<List<Message>> getMessages(String roomId) async {
    final dio = dioClient.dio;
    try {
      final response = await dio.get('/api/chat/$roomId/messages');
      if (response.data is List) {
        return (response.data as List)
            .map((json) => Message.fromJson(json))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      if (kDebugMode) print('Failed to fetch messages for room $roomId: $e');
      rethrow;
    }
  }
  Future<void> createRoom(String otherName) async {
    final dio = dioClient.dio;

    final data = {
      'otherName': otherName,
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
        '/api/chat/saveMessage', // 서버 API 엔드포인트
        data: {
          'roomId': roomId,
          'content': text,
        },
      );
    } on DioException catch (e) {
      // 에러 처리
      print('Failed to send message: $e');
      rethrow;
    }
  }
}
