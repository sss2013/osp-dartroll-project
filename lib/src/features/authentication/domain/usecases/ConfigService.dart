import 'dart:convert';
import 'package:http/http.dart' as http;

class ConfigService {
  static const String _baseUrl = 'http://10.27.98.46:8000';

  static Future<Map<String, dynamic>> fetchConfig() async {
    final response = await http.get(Uri.parse('$_baseUrl/config'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load config from server');
    }
  }
}