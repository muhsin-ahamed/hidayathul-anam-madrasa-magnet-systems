// student_dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/repository_interfaces.dart';
import '../../models/models.dart';
import '../../widgets/page_scaffold.dart';
import '../../widgets/portal_card.dart';
import '../../widgets/responsive.dart';
import '../../widgets/responsive_grid.dart';
import '../../widgets/section_title.dart';
import '../../widgets/status_badge.dart';

class StudentDashboardPage extends StatefulWidget {
  const StudentDashboardPage({super.key, required this.onNavigate});

  final ValueChanged<int> onNavigate;

  @override
  State<StudentDashboardPage> createState() => _StudentDashboardPageState();
}

class _StudentDashboardPageState extends State<StudentDashboardPage> {
  bool _isLoading = true;
  String? _error;

  double _averagePercentage = 0.0;
  String _latestResultValue = 'No results';
  int _notesCount = 0;
  String _hallTicketStatus = 'Not Generated';
  List<Exam> _upcomingExamsList = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      final student = context.read<Student>();

      final resultsRepo = context.read<ResultRepository>();
      final notesRepo = context.read<NotesRepository>();
      final hallTicketRepo = context.read<HallTicketRepository>();
      final examRepo = context.read<ExamRepository>();

      // Fetch concurrently
      final data = await Future.wait([
        resultsRepo.getResultsByStudent(student.id),
        notesRepo.getNotesByClass(student.classId),
        hallTicketRepo.getHallTicketsByStudent(student.id),
        examRepo.getExamsByClass(student.classId),
      ]);

      final results = data[0] as List<Result>;
      final notes = data[1] as List<Note>;
      final tickets = data[2] as List<HallTicket>;
      final exams = data[3] as List<Exam>;

      // Process results
      final publishedResults = results.where((r) => r.isPublished).toList();
      double totalObtained = 0.0;
      double totalMax = 0.0;
      for (final r in publishedResults) {
        if (r.marksObtained != null) {
          totalObtained += r.marksObtained!;
          totalMax += r.maximumMarks;
        }
      }
      if (totalMax > 0) {
        _averagePercentage = (totalObtained / totalMax) * 100;
        _latestResultValue = '${_averagePercentage.toStringAsFixed(1)}%';
      }

      // Process notes
      _notesCount = notes.where((n) => n.isPublished).length;

      // Process hall ticket
      if (tickets.isNotEmpty) {
        final ticket = tickets.first;
        _hallTicketStatus =
            ticket.status[0].toUpperCase() + ticket.status.substring(1);
      }

      // Process exams (only upcoming/recent ones)
      _upcomingExamsList = exams.where((e) {
        if (e.startDate == null) return true;
        return e.startDate!.isAfter(
          DateTime.now().subtract(const Duration(days: 1)),
        );
      }).toList();

      if (mounted) {
        setState(() {
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
    final student = context.watch<Student>();

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null) {
      return Scaffold(
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

    return PageScaffold(
      title: 'Dashboard',
      children: [
        _WelcomeCard(
          student: student,
          onProfileTap: () => widget.onNavigate(4),
        ),
        const SizedBox(height: 16),
        ResponsiveGrid(
          tabletColumns: 2,
          mainAxisExtent: 178,
          children: [
            _DashboardInfoCard(
              title: 'Latest Result',
              value: _latestResultValue,
              subtitle: _latestResultValue == 'No results'
                  ? 'No results published yet'
                  : 'Overall average percentage',
              icon: Icons.emoji_events_outlined,
              color: const Color(0xFF2563EB),
              onTap: () => widget.onNavigate(1),
            ),
            _DashboardInfoCard(
              title: 'Study Notes',
              value: '$_notesCount Files',
              subtitle: 'Published class learning materials',
              icon: Icons.library_books_outlined,
              color: const Color(0xFF059669),
              onTap: () => widget.onNavigate(2),
            ),
            _DashboardInfoCard(
              title: 'Hall Ticket',
              value: _hallTicketStatus,
              subtitle: _hallTicketStatus == 'Locked'
                  ? 'Hall ticket is locked by exam cell'
                  : 'Status of upcoming term exam ticket',
              icon: Icons.confirmation_number_outlined,
              color: const Color(0xFFF97316),
              onTap: () => widget.onNavigate(3),
            ),
            _DashboardInfoCard(
              title: 'Status',
              value: student.isActive ? 'Active' : 'Inactive',
              subtitle: 'Current enrollment status',
              icon: Icons.event_available_outlined,
              color: const Color(0xFF7C3AED),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _UpcomingExamsSection(exams: _upcomingExamsList),
      ],
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({
    required this.student,
    required this.onProfileTap,
  });

  final Student student;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary,
            Color.lerp(colorScheme.primary, colorScheme.secondary, 0.4)!,
            colorScheme.secondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: PortalCard(
        color: Colors.transparent,
        border: Border.all(color: Colors.transparent),
        isHoverable: false,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back, ${student.fullName.split(' ').first} 👋',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your ${student.className ?? 'Class'} workspace is up to date and active.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      ElevatedButton.icon(
                        onPressed: onProfileTap,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: colorScheme.primary,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.person_outline, size: 18),
                        label: const Text(
                          'View Profile',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (!Responsive.isMobile(context)) ...[
              const SizedBox(width: 24),
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white24, width: 1),
                ),
                child: const Icon(
                  Icons.workspace_premium_outlined,
                  size: 48,
                  color: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DashboardInfoCard extends StatelessWidget {
  const _DashboardInfoCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.onTap,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return PortalCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color),
              ),
              const Spacer(),
              if (onTap != null) const Icon(Icons.arrow_forward, size: 18),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}


class _UpcomingExamsSection extends StatelessWidget {
  const _UpcomingExamsSection({required this.exams});

  final List<Exam> exams;

  @override
  Widget build(BuildContext context) {
    return PortalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(title: 'Upcoming Exams'),
          const SizedBox(height: 14),
          if (exams.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Center(
                child: Text(
                  'No upcoming exams scheduled',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
            )
          else
            for (final exam in exams)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.event_note_outlined),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            exam.examName,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          Text(
                            'Starts: ${exam.startDate != null ? exam.startDate!.toLocal().toString().substring(0, 10) : 'TBA'}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                    ),
                    StatusBadge(
                      label: exam.resultsPublished ? 'Published' : 'Scheduled',
                      color: exam.resultsPublished
                          ? const Color(0xFF059669)
                          : const Color(0xFF2563EB),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}
