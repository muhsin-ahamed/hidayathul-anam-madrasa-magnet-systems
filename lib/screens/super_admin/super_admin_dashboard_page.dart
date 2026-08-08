// super_admin_dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/repository_interfaces.dart';
import '../../data/providers/dashboard_provider.dart';
import '../../models/models.dart';
import '../../widgets/page_scaffold.dart';
import '../../widgets/portal_card.dart';
import '../../widgets/responsive_grid.dart';

class SuperAdminDashboardPage extends StatefulWidget {
  const SuperAdminDashboardPage({super.key});

  @override
  State<SuperAdminDashboardPage> createState() =>
      _SuperAdminDashboardPageState();
}

class _SuperAdminDashboardPageState extends State<SuperAdminDashboardPage> {
  bool _isLoading = true;
  String? _error;

  int _totalStudents = 0;
  int _totalTeachers = 0;
  int _totalClasses = 0;
  int _generatedHallTickets = 0;
  List<ClassInfo> _classes = [];
  List<ActivityLog> _recentLogs = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      final dashboardProvider = context.read<DashboardProvider>();
      final classRepo = context.read<ClassRepository>();
      final studentRepo = context.read<StudentRepository>();

      // Fetch concurrently
      await dashboardProvider.fetchStats();
      final data = await Future.wait([
        classRepo.getAllClasses(),
        studentRepo.getAllStudents(),
      ]);

      final classes = data[0] as List<ClassInfo>;
      final students = data[1] as List<Student>;
      
      final stats = dashboardProvider.stats;
      
      _totalStudents = stats?.totalStudents ?? 0;
      _totalTeachers = stats?.totalTeachers ?? 0;
      _totalClasses = stats?.totalClasses ?? 0;
      _classes = classes;
      _recentLogs = (stats?.recentActivity ?? []).map((x) => ActivityLog.fromMap(x)).toList();

      // Fetch all hall tickets size
      _generatedHallTickets = students
          .where((s) => s.isActive)
          .length;

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $_error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadDashboardData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final statCardsData = [
      _StatCardItem(
        title: 'Total Students',
        value: '$_totalStudents',
        subtitle: 'Overall Madrasa',
        icon: Icons.school,
        iconBgColor: const Color(0xFFEFF6FF),
        iconColor: const Color(0xFF2563EB),
      ),
      _StatCardItem(
        title: 'Total Teachers',
        value: '$_totalTeachers',
        subtitle: 'Overall Madrasa',
        icon: Icons.co_present,
        iconBgColor: const Color(0xFFF0FDF4),
        iconColor: const Color(0xFF16A34A),
      ),
      _StatCardItem(
        title: 'Total Classes',
        value: '$_totalClasses',
        subtitle: 'Overall Madrasa',
        icon: Icons.meeting_room,
        iconBgColor: const Color(0xFFFAF5FF),
        iconColor: const Color(0xFF9333EA),
      ),
      _StatCardItem(
        title: 'Hall Tickets',
        value: '$_generatedHallTickets',
        subtitle: 'Overall Madrasa',
        icon: Icons.badge,
        iconBgColor: const Color(0xFFFFF7ED),
        iconColor: const Color(0xFFEA580C),
      ),
    ];

    return PageScaffold(
      title: 'Global Statistics',
      children: [
        ResponsiveGrid(
          mainAxisExtent: 170,
          children: [
            for (final stat in statCardsData)
              _DashboardStatCard(item: stat),
          ],
        ),
        const SizedBox(height: 28),
        ResponsiveGrid(
          desktopColumns: 2,
          tabletColumns: 1,
          mainAxisExtent: 440,
          children: [
            // Class-wise Performance & Enrollment Section
            PortalCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Class-wise Performance & Enrollment',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.more_horiz),
                        onPressed: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _classes.isEmpty
                        ? const Center(child: Text('No classes found'))
                        : ListView.separated(
                            itemCount: _classes.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final cls = _classes[index];
                              return Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.08)
                                        : const Color(0xFFE0E3E5),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF334155) : const Color(0xFFECEEF0),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.book_outlined,
                                        size: 20,
                                        color: isDark ? Colors.grey.shade300 : const Color(0xFF45464D),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            cls.displayName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Teacher: ${cls.classTeacherName ?? "None Assigned"}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isDark ? Colors.grey.shade400 : const Color(0xFF45464D),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF1E3A8A).withValues(alpha: 0.4) : const Color(0xFFEFF6FF),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: isDark ? const Color(0xFF1E40AF) : const Color(0xFFDBEAFE),
                                        ),
                                      ),
                                      child: Text(
                                        '${cls.studentCount ?? 0} Students',
                                        style: TextStyle(
                                          color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
            // Global Activity Logs Section
            PortalCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Global Activity Logs',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text(
                          'View All',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _recentLogs.isEmpty
                        ? const Center(child: Text('No activity logs found'))
                        : ListView.builder(
                            itemCount: _recentLogs.length,
                            itemBuilder: (context, index) {
                              final log = _recentLogs[index];
                              final isLast = index == _recentLogs.length - 1;
                              return IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Timeline vertical line and dot
                                    SizedBox(
                                      width: 28,
                                      child: Column(
                                        children: [
                                          Container(
                                            width: 14,
                                            height: 14,
                                            margin: const EdgeInsets.only(top: 4),
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: isDark ? const Color(0xFF0F172A) : Colors.white,
                                              border: Border.all(
                                                color: isDark ? Colors.grey.shade600 : const Color(0xFFC6C6CD),
                                                width: 2,
                                              ),
                                            ),
                                            child: Center(
                                              child: Container(
                                                width: 4,
                                                height: 4,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: isDark ? Colors.grey.shade400 : const Color(0xFF76777D),
                                                ),
                                              ),
                                            ),
                                          ),
                                          if (!isLast)
                                            Expanded(
                                              child: Container(
                                                width: 2,
                                                color: isDark ? Colors.grey.shade800 : const Color(0xFFE0E3E5),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // Log item contents
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.only(bottom: 20),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        Icons.history,
                                                        size: 16,
                                                        color: isDark ? Colors.grey.shade400 : const Color(0xFF45464D),
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Expanded(
                                                        child: Text(
                                                          log.action,
                                                          style: const TextStyle(
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 14,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    log.description ?? 'System operation',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: isDark ? Colors.grey.shade400 : const Color(0xFF45464D),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Text(
                                              log.createdAt.toLocal().toString().substring(0, 10),
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: isDark ? Colors.grey.shade500 : const Color(0xFF76777D),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCardItem {
  const _StatCardItem({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
}

class _DashboardStatCard extends StatelessWidget {
  const _DashboardStatCard({required this.item});

  final _StatCardItem item;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PortalCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isDark ? item.iconColor.withValues(alpha: 0.15) : item.iconBgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  item.icon,
                  color: item.iconColor,
                  size: 22,
                ),
              ),
              const Icon(
                Icons.trending_up,
                color: Color(0xFF22C55E),
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.value,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                item.title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey.shade300 : const Color(0xFF45464D),
                ),
              ),
              Text(
                item.subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.grey.shade500 : const Color(0xFF76777D),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

