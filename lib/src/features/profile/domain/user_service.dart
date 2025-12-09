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

      if (response.statusCode != 200) { // 201은 보통 '생성됨'을 의미하므로, '업데이트'에서는 200이 더 적합합니다.
        throw Exception('Failed to check user name: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Failed to save user data: ${e.message}');
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  Future<bool> checkName(String name) async {
    final dio = dioClient.publicDio;

    try {
      final response = await dio.get('/api/user/checkName?name=$name');
      if (response.statusCode != 200) { // 201은 보통 '생성됨'을 의미하므로, '업데이트'에서는 200이 더 적합합니다.
        throw Exception('Failed to change user name: ${response.statusCode}');
      }

      final data = response.data;
      return data['exists'] as bool;
    } on DioException catch (e) {
      throw Exception('Failed to check user name: ${e.message}');
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  Future<bool> changeName(String newName) async {
    final check = await checkName(newName);

    if (check) {
      return false;
    }

    final dio = dioClient.dio;
    final data ={
      'newName': newName,
    };

    try {
      final response = await dio.post('/api/user/changeName',data:data);
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to change user name: ${response.statusCode}');
      }
      final result = response.data;
      return result['result'] as bool;
    } on DioException catch (e) {
      throw Exception('Failed to change user name: ${e.message}');
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

  Future<Map<String,dynamic>> loadUserName() async {
    final dio = dioClient.dio;
    try {
      final response = await dio.get('/api/user/loadUserData', queryParameters: {'fields': 'name'});
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to load user name: ${response.statusCode}');
      }

      final data = response.data;
      return data;

    } on DioException catch (e) {
      throw Exception('Failed to load user name: ${e.message}');
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  Future<Map<String,dynamic>> loadUserAll() async {
    final dio = dioClient.dio;
    try {
      final response = await dio.get('/api/user/loadUserData',queryParameters: {'fields':'*'});
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to load user name: ${response.statusCode}');
      }

      final data = response.data;
      return data;

    } on DioException catch (e) {
      throw Exception('Failed to load user name: ${e.message}');
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }
}
