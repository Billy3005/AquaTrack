import 'package:dio/dio.dart';
import '../config/app_config.dart';

/// Simple authentication service for CORS testing
class SimpleAuthService {
  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  /// Simple login for CORS testing
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        AppConfig.simpleLoginUrl,
        data: {'email': email, 'password': password},
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Login failed: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout) {
        throw Exception('Connection timeout');
      } else if (e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Receive timeout');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Login error: $e');
    }
  }

  /// Test CORS connectivity
  static Future<bool> testCORS() async {
    try {
      final response = await _dio.get('http://localhost:8000/cors-test');
      return response.statusCode == 200;
    } catch (e) {
      print('CORS test failed: $e');
      return false;
    }
  }
}
