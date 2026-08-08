import 'package:dio/dio.dart';
import 'package:student_portal/core/api/api_client.dart';
import 'package:student_portal/core/api/api_endpoints.dart';

class AuthService {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.login,
        data: {
          'username': username,
          'password': password,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Map<String, dynamic>> getMe() async {
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.me);
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> logout() async {
    try {
      await _apiClient.dio.post('${ApiEndpoints.baseUrl}/auth/logout');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await _apiClient.dio.put(
        '/teacher/change-password',
        data: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
