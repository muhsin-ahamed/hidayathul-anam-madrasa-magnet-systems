import 'package:dio/dio.dart';
import 'package:student_portal/core/api/api_client.dart';
import 'package:student_portal/core/api/api_endpoints.dart';

class DashboardService {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.dashboard);
      return response.data['data'];
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
