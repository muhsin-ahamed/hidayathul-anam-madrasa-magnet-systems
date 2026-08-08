import 'package:flutter/material.dart';
import 'package:student_portal/data/repositories/dashboard_repository.dart';

class DashboardProvider extends ChangeNotifier {
  final DashboardRepository _dashboardRepo;

  DashboardStats? _stats;
  bool _isLoading = false;
  String? _error;

  DashboardProvider({required DashboardRepository dashboardRepo})
      : _dashboardRepo = dashboardRepo;

  DashboardStats? get stats => _stats;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchStats() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _stats = await _dashboardRepo.getDashboardStats();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
