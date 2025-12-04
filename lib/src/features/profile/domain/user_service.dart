import 'package:cultureyo/src/core/network/dio_client.dart';
import 'package:dio/dio.dart';

class UserService {
  final DioClient dioClient;

  UserService({required this.dioClient});

  Future<void> saveUserData({
    required String name,
    required int year,
    // required int month,
    // required int day,
    required Set<String> categories,
    required Set<String> regions,
  }) async {
    final dio = dioClient.dio;
    // final birthdate = '$year-${month.toString().padLeft(2,'0')}-${day.toString().padLeft(2,'0')}';
    final data = {
      'name': name,
      'birth': year,
      'categories': categories.toList(),
      'regions': regions.toList(),
    };

    try {
      final response = await dio.post('/api/user/saveProfile', data: data);

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to save user data: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Failed to save user data: ${e.message}');
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  Future<String> loadUserId() async {
    final dio = dioClient.dio;
    try {
      final response = await dio.get('/api/user/loadUserId');
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to load user name: ${response.statusCode}');
      }

      final data = response.data;
      return data['id'] as String;
    } on DioException catch (e) {
      throw Exception('Failed to load user name: ${e.message}');
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  Future<String> loadUserData(int option) async {
    final dio = dioClient.dio;
    try {
      final response = await dio.get('/api/user/loadUserName?option=$option');
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to load user name: ${response.statusCode}');
      }

      final data = response.data;
      if (option==1){
        return data['name'] as String;
      }  else {
        return data;
      }
    } on DioException catch (e) {
      throw Exception('Failed to load user name: ${e.message}');
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }
}
