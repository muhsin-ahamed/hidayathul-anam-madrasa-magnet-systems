import 'package:student_portal/core/services/dashboard_service.dart';

class DashboardStats {
  final int totalClasses;
  final int totalStudents;
  final int totalTeachers;
  final List<dynamic> recentActivity;

  DashboardStats({
    required this.totalClasses,
    required this.totalStudents,
    required this.totalTeachers,
    required this.recentActivity,
  });

  factory DashboardStats.fromMap(Map<String, dynamic> map) {
    return DashboardStats(
      totalClasses: map['total_classes'] ?? 0,
      totalStudents: map['total_students'] ?? 0,
      totalTeachers: map['total_teachers'] ?? 0,
      recentActivity: map['recent_activity'] ?? [],
    );
  }
}

class DashboardRepository {
  final DashboardService _dashboardService = DashboardService();

  Future<DashboardStats> getDashboardStats() async {
    final data = await _dashboardService.getDashboardStats();
    return DashboardStats.fromMap(data);
  }
}
