import 'dart:async';
import 'package:student_portal/core/api/api_client.dart';
import 'package:student_portal/core/services/auth_service.dart';
import 'package:student_portal/models/models.dart';
import 'package:student_portal/data/repositories/repository_interfaces.dart' as interfaces;

class AuthRepository implements interfaces.AuthRepository {
  final AuthService _authService = AuthService();
  final ApiClient _apiClient = ApiClient();

  final _authStatusController = StreamController<Profile?>.broadcast();
  
  @override
  Stream<Profile?> get onAuthStateChanged => _authStatusController.stream;

  AuthRepository() {
    _apiClient.onUnauthorized.listen((_) {
      _authStatusController.add(null);
    });
  }

  @override
  Future<Profile?> login(String usernameOrEmail, String password) async {
    final data = await _authService.login(usernameOrEmail, password);
    final token = data['token'] ?? data['data']?['token'];
    final profileData = data['user'] ?? data['data']?['user'] ?? data['data']?['profile'] ?? data['data'];

    if (token != null) {
      await _apiClient.saveToken(token.toString());
    }

    if (profileData != null && profileData is Map<String, dynamic>) {
      final profile = Profile.fromMap(profileData);
      _authStatusController.add(profile);
      return profile;
    }
    return null;
  }

  @override
  Future<Profile?> getCurrentSessionProfile() async {
    final token = await _apiClient.getToken();
    if (token == null || token.isEmpty) return null;

    try {
      final data = await _authService.getMe();
      final profileData = data['data'] ?? data['user'] ?? data['profile'];
      if (profileData != null && profileData is Map<String, dynamic>) {
        final profile = Profile.fromMap(profileData);
        _authStatusController.add(profile);
        return profile;
      }
    } catch (_) {
      await logout();
      return null;
    }
    return null;
  }

  @override
  Future<void> logout() async {
    try {
      await _authService.logout();
    } catch (_) {} // Ignore logout errors
    await _apiClient.clearToken();
    _authStatusController.add(null);
  }
  
  @override
  Future<void> sendPasswordResetEmail(String email) async {
    // Implement if needed by API
  }
  
  @override
  Future<void> updatePassword(String newPassword, {String? currentPassword}) async {
    await _authService.changePassword(
      currentPassword: currentPassword ?? '',
      newPassword: newPassword,
    );
  }
}
