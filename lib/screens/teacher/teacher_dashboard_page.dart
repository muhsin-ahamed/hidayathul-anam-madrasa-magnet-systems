// teacher_dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/repository_interfaces.dart';
import '../../models/models.dart';

class TeacherDashboardPage extends StatefulWidget {
  const TeacherDashboardPage({super.key});

  @override
  State<TeacherDashboardPage> createState() => _TeacherDashboardPageState();
}

class _TeacherDashboardPageState extends State<TeacherDashboardPage> {
  bool _isLoading = true;
  String? _error;

  int _totalStudents = 0;
  int _activeStudents = 0;
  int _uploadedNotesCount = 0;
  int _generatedHallTicketsCount = 0;
  List<ActivityLog> _recentLogs = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      final teacher = context.read<Teacher>();
      final classId = teacher.assignedClassId ?? '';

      final studentRepo = context.read<StudentRepository>();
      final notesRepo = context.read<NotesRepository>();
      final hallTicketRepo = context.read<HallTicketRepository>();
      final logsRepo = context.read<ActivityLogRepository>();

      // Fetch concurrently
      final data = await Future.wait([
        studentRepo.getStudentsByClass(classId),
        notesRepo.getNotesByClass(classId),
        hallTicketRepo.getHallTicketsByClass(classId),
        logsRepo.getLogsByClass(classId),
      ]);

      final students = data[0] as List<Student>;
      final notes = data[1] as List<Note>;
      final tickets = data[2] as List<HallTicket>;
      final logs = data[3] as List<ActivityLog>;

      if (mounted) {
        setState(() {
          _totalStudents = students.length;
          _activeStudents = students.where((s) => s.isActive).length;
          _uploadedNotesCount = notes.length;
          _generatedHallTicketsCount = tickets.length;
          _recentLogs = logs.take(6).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor =
        isDark ? const Color(0xFF374151) : const Color(0xFFC6C6CD);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF7F9FB),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF0F172A)),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor:
            isDark ? const Color(0xFF0F172A) : const Color(0xFFF7F9FB),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Error loading dashboard',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(_error!, style: TextStyle(color: Colors.grey.shade600)),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                      _error = null;
                    });
                    _loadDashboardData();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F172A) : const Color(0xFFF7F9FB),
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1280),
            padding: EdgeInsets.all(
              MediaQuery.of(context).size.width < 600 ? 16 : 32,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                Container(
                  padding: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: borderColor, width: 0.8),
                    ),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isMobile = constraints.maxWidth < 600;
                      if (isMobile) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Teacher Dashboard',
                              style: TextStyle(
                                fontFamily: 'Serif',
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color:
                                    isDark
                                        ? Colors.white
                                        : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Academic Overview & Management',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF45464D),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0F172A),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  elevation: 1,
                                ),
                                onPressed: () => context.go('/teacher/notes'),
                                icon: const Icon(
                                  Icons.upload_file_outlined,
                                  size: 18,
                                ),
                                label: const Text(
                                  'Upload New Note',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Teacher Dashboard',
                                  style: TextStyle(
                                    fontFamily: 'Serif',
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        isDark
                                            ? Colors.white
                                            : const Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Academic Overview & Management',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF45464D),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0F172A),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              elevation: 1,
                            ),
                            onPressed: () => context.go('/teacher/notes'),
                            icon: const Icon(
                              Icons.upload_file_outlined,
                              size: 20,
                            ),
                            label: const Text(
                              'Upload New Note',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 32),

                // Metrics Grid (Sizing Fixed)
                LayoutBuilder(
                  builder: (context, constraints) {
                    int crossAxisCount = 4;
                    double childAspectRatio = 1.45;
                    if (constraints.maxWidth < 640) {
                      crossAxisCount = 1;
                      childAspectRatio = 2.0;
                    } else if (constraints.maxWidth < 1024) {
                      crossAxisCount = 2;
                      childAspectRatio = 1.55;
                    }

                    return GridView.count(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 24,
                      mainAxisSpacing: 24,
                      childAspectRatio: childAspectRatio,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildMetricCard(
                          context: context,
                          icon: Icons.groups_outlined,
                          title: 'Total Students',
                          value: '$_totalStudents',
                          badgeText: 'Active Class',
                          badgeBg: const Color(0xFFFFDBCA),
                          badgeTextColor: const Color(0xFF9B4500),
                          cardBg: cardBg,
                          borderColor: borderColor,
                        ),
                        _buildMetricCard(
                          context: context,
                          icon: Icons.how_to_reg_outlined,
                          title: 'Active Students',
                          value: '$_activeStudents',
                          badgeText: '100% Registered',
                          badgeBg: const Color(0xFFDAE2FD),
                          badgeTextColor: const Color(0xFF131B2E),
                          cardBg: cardBg,
                          borderColor: borderColor,
                        ),
                        _buildMetricCard(
                          context: context,
                          icon: Icons.library_books_outlined,
                          title: 'Notes Uploaded',
                          value: '$_uploadedNotesCount',
                          cardBg: cardBg,
                          borderColor: borderColor,
                        ),
                        _buildMetricCard(
                          context: context,
                          icon: Icons.badge_outlined,
                          title: 'Hall Tickets',
                          value: '$_generatedHallTicketsCount',
                          cardBg: cardBg,
                          borderColor: borderColor,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 32),

                // Quick Action Shortcuts Bar
                Text(
                  'Quick Management Actions',
                  style: TextStyle(
                    fontFamily: 'Serif',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isMobile = constraints.maxWidth < 640;
                    return Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        _buildShortcutButton(
                          context: context,
                          icon: Icons.group_outlined,
                          label: 'My Students',
                          route: '/teacher/students',
                          isMobile: isMobile,
                        ),
                        _buildShortcutButton(
                          context: context,
                          icon: Icons.fact_check_outlined,
                          label: 'Upload Results',
                          route: '/teacher/results',
                          isMobile: isMobile,
                        ),
                        _buildShortcutButton(
                          context: context,
                          icon: Icons.description_outlined,
                          label: 'Study Notes',
                          route: '/teacher/notes',
                          isMobile: isMobile,
                        ),
                        _buildShortcutButton(
                          context: context,
                          icon: Icons.confirmation_number_outlined,
                          label: 'Hall Tickets',
                          route: '/teacher/halltickets',
                          isMobile: isMobile,
                        ),
                        _buildShortcutButton(
                          context: context,
                          icon: Icons.campaign_outlined,
                          label: 'Announcements',
                          route: '/teacher/announcements',
                          isMobile: isMobile,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 32),

                // Recent Class Activity Section (Modern List UI)
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isMobile = constraints.maxWidth < 600;
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Recent Class Activity',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Serif',
                              fontSize: isMobile ? 18 : 24,
                              fontWeight: FontWeight.bold,
                              color:
                                  isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              horizontal: isMobile ? 8 : 12,
                              vertical: isMobile ? 4 : 8,
                            ),
                          ),
                          onPressed: _loadDashboardData,
                          icon: const Icon(Icons.refresh_outlined, size: 16),
                          label: Text(
                            isMobile ? 'Refresh' : 'Refresh Logs',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF9B4500),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),

                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor, width: 0.8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      if (_recentLogs.isNotEmpty)
                        for (int i = 0; i < _recentLogs.length; i++)
                          _buildActivityListItem(
                            context: context,
                            icon: _getActivityIcon(_recentLogs[i].action),
                            title: _recentLogs[i].action,
                            description:
                                _recentLogs[i].description ??
                                'Activity performed in class portal',
                            timeAgo: _recentLogs[i].createdAt
                                .toLocal()
                                .toString()
                                .substring(0, 16),
                            borderColor: borderColor,
                            isLast: i == _recentLogs.length - 1,
                          )
                      else ...[
                        _buildActivityListItem(
                          context: context,
                          icon: Icons.person_add_outlined,
                          title: 'Added New Student',
                          description:
                              'Enrolled student Mohammed Nizar into class roster',
                          timeAgo: '2 hours ago',
                          borderColor: borderColor,
                        ),
                        _buildActivityListItem(
                          context: context,
                          icon: Icons.upload_file_outlined,
                          title: 'Uploaded Study Notes',
                          description:
                              'Calculus_Theorems_Lecture_12.pdf uploaded',
                          timeAgo: 'Yesterday',
                          borderColor: borderColor,
                        ),
                        _buildActivityListItem(
                          context: context,
                          icon: Icons.fact_check_outlined,
                          title: 'Uploaded Examination Results',
                          description:
                              'Mid-Term Assessment results processed for 42 students',
                          timeAgo: '2 days ago',
                          borderColor: borderColor,
                        ),
                        _buildActivityListItem(
                          context: context,
                          icon: Icons.confirmation_number_outlined,
                          title: 'Generated Hall Tickets',
                          description:
                              'End-Semester Examination hall tickets generated',
                          timeAgo: '3 days ago',
                          borderColor: borderColor,
                          isLast: true,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String value,
    String? badgeText,
    Color? badgeBg,
    Color? badgeTextColor,
    required Color cardBg,
    required Color borderColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color:
                      isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFF2F4F6),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color:
                      isDark ? Colors.grey.shade300 : const Color(0xFF0F172A),
                ),
              ),
              if (badgeText != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: badgeTextColor,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF45464D),
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'Serif',
                  fontSize: 28,
                  height: 1.1,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShortcutButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String route,
    required bool isMobile,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor =
        isDark ? const Color(0xFF374151) : const Color(0xFFC6C6CD);

    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        side: BorderSide(color: borderColor, width: 0.8),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: () => context.go(route),
      icon: Icon(icon, size: 18, color: const Color(0xFF9B4500)),
      label: Text(
        label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildActivityListItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required String timeAgo,
    required Color borderColor,
    bool isLast = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border:
            isLast
                ? null
                : Border(bottom: BorderSide(color: borderColor, width: 0.8)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color:
                  isDark ? const Color(0xFF334155) : const Color(0xFFF2F4F6),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: const Color(0xFF45464D)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      timeAgo,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF76777D),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF45464D),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getActivityIcon(String action) {
    final act = action.toLowerCase();
    if (act.contains('note')) return Icons.description_outlined;
    if (act.contains('student')) return Icons.person_add_outlined;
    if (act.contains('result')) return Icons.fact_check_outlined;
    if (act.contains('ticket') || act.contains('exam')) {
      return Icons.confirmation_number_outlined;
    }
    return Icons.notifications_active_outlined;
  }
}


