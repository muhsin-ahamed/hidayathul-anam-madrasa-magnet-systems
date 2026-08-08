import 'package:dio/dio.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../storage/session_manager.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  static ApiClient get instance => _instance;

  late final Dio dio;
  
  // Stream to notify app when token expires (401 Unauthorized)
  final _unauthorizedController = StreamController<void>.broadcast();
  Stream<void> get onUnauthorized => _unauthorizedController.stream;

  ApiClient._internal() {
    const baseUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://localhost:5000/api', // Match Node.js backend port
    );

    dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await SessionManager.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
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
            // Token expired or invalid
            await SessionManager.clearSession();
            _unauthorizedController.add(null);
          }

          return handler.next(e);
        },
      ),
    );
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
