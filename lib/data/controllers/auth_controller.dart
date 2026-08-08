// auth_controller.dart
import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../models/user_role.dart';
import '../repositories/repository_interfaces.dart';

class AuthController extends ChangeNotifier {
  final AuthRepository _authRepo;
  final ProfileRepository _profileRepo;

  Profile? _currentProfile;
  bool _isLoading = true;
  String? _error;

  AuthController({
    required AuthRepository authRepo,
    required ProfileRepository profileRepo,
  }) : _authRepo = authRepo,
       _profileRepo = profileRepo {
    _init();
  }

  ProfileRepository get profileRepo => _profileRepo;
  Profile? get currentProfile => _currentProfile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentProfile != null;

  void updateCurrentProfile(Profile updatedProfile) {
    _currentProfile = updatedProfile;
    notifyListeners();
  }

  void _init() async {
    _authRepo.onAuthStateChanged.listen((profile) {
      debugPrint('========== [AuthController] Auth state changed: ${profile?.email} (Role: ${profile?.role.dbValue}) ==========');
      _currentProfile = profile;
      _isLoading = false;
      _error = null;
      notifyListeners();
    });

    try {
      debugPrint('========== [AuthController] Initializing session profile... ==========');
      _currentProfile = await _authRepo.getCurrentSessionProfile();
      debugPrint('========== [AuthController] Loaded profile: ${_currentProfile?.email} (Role: ${_currentProfile?.role.dbValue}) ==========');
    } catch (e) {
      debugPrint('========== [AuthController] Session init error: $e ==========');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    debugPrint('========== [AuthController] Login start for: $email ==========');

    try {
      _currentProfile = await _authRepo.login(email.trim(), password.trim());
      debugPrint('========== [AuthController] Login success for: ${_currentProfile?.email} (Role: ${_currentProfile?.role.dbValue}) ==========');
    } catch (e) {
      debugPrint('========== [AuthController] Login failed for: $email | Error: $e ==========');
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _authRepo.logout();
      _currentProfile = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    try {
      await _authRepo.updatePassword(newPassword, currentPassword: currentPassword);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _authRepo.sendPasswordResetEmail(email);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> resetPassword(String newPassword) async {
    try {
      await _authRepo.updatePassword(newPassword);
    } catch (e) {
      rethrow;
    }
  }
}
