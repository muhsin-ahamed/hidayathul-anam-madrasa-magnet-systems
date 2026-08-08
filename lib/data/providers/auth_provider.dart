import 'package:flutter/material.dart';
import 'package:student_portal/data/repositories/auth_repository.dart';
import 'package:student_portal/models/models.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepo;

  Profile? _currentProfile;
  bool _isLoading = true;
  String? _error;

  AuthProvider({required AuthRepository authRepo}) : _authRepo = authRepo {
    _init();
  }

  Profile? get currentProfile => _currentProfile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentProfile != null;

  void _init() async {
    _authRepo.onAuthStateChanged.listen((profile) {
      _currentProfile = profile;
      _isLoading = false;
      _error = null;
      notifyListeners();
    });

    try {
      _currentProfile = await _authRepo.getCurrentSessionProfile();
    } catch (e) {
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

    try {
      _currentProfile = await _authRepo.login(email.trim(), password.trim());
    } catch (e) {
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
}
