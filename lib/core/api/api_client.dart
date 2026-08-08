import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:student_portal/core/api/api_endpoints.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  static ApiClient get instance => _instance;

  final Dio _dio = Dio();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  static const String tokenKey = 'jwt_token';

  // Stream to notify app when token expires (401 Unauthorized)
  final _unauthorizedController = StreamController<void>.broadcast();
  Stream<void> get onUnauthorized => _unauthorizedController.stream;

  ApiClient._internal() {
    _dio.options.baseUrl = ApiEndpoints.baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 15);
    _dio.options.receiveTimeout = const Duration(seconds: 15);
    _dio.options.headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (!options.path.contains('/auth/login')) {
            final token = await _storage.read(key: tokenKey);
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          if (kDebugMode) {
            debugPrint('-> ${options.method} ${options.uri}');
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          if (kDebugMode) {
            debugPrint('<- ${response.statusCode} ${response.requestOptions.uri}');
          }
          return handler.next(response);
        },
        onError: (DioException e, handler) async {
          if (kDebugMode) {
            debugPrint('<- ERROR ${e.response?.statusCode} ${e.requestOptions.uri}');
            debugPrint('Message: ${e.message}');
          }

          if (e.response?.statusCode == 401) {
            await clearToken();
            _unauthorizedController.add(null);
          }
          
          return handler.next(e);
        },
      ),
    );
  }

  Dio get dio => _dio;

  Future<void> saveToken(String token) async {
    await _storage.write(key: tokenKey, value: token);
  }

  Future<void> clearToken() async {
    await _storage.delete(key: tokenKey);
  }
  
  Future<String?> getToken() async {
    return await _storage.read(key: tokenKey);
  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;

  factory ApiException.fromDioException(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return ApiException('Connection timed out. Please check your internet.', error.response?.statusCode);
    }
    
    if (error.type == DioExceptionType.connectionError) {
      return ApiException('Network connection unavailable.', error.response?.statusCode);
    }

    if (error.response != null) {
      final data = error.response!.data;
      if (data is Map<String, dynamic> && data.containsKey('message')) {
        return ApiException(data['message'], error.response!.statusCode);
      }
      if (error.response!.statusCode == 401) {
        return ApiException('Session expired. Please login again.', 401);
      }
      if (error.response!.statusCode == 403) {
        return ApiException('Permission denied.', 403);
      }
      if (error.response!.statusCode == 404) {
        return ApiException('Resource not found.', 404);
      }
      if (error.response!.statusCode == 500) {
        return ApiException('Internal server error.', 500);
      }
    }

    return ApiException('An unexpected error occurred.', error.response?.statusCode);
  }
}
