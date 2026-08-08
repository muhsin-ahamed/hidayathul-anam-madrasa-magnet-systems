// hall_ticket_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/repositories/repository_interfaces.dart';
import '../../models/models.dart';
import '../../widgets/page_scaffold.dart';
import '../../widgets/portal_card.dart';
import '../../widgets/responsive.dart';

class HallTicketPage extends StatefulWidget {
  const HallTicketPage({super.key});

  @override
  State<HallTicketPage> createState() => _HallTicketPageState();
}

class _HallTicketPageState extends State<HallTicketPage> {
  bool _isLoading = true;
  String? _error;
  HallTicket? _hallTicket;
  Exam? _activeExam;
  List<ExamSubject> _examSchedules = [];

  @override
  void initState() {
    super.initState();
    _loadHallTicket();
  }

  Future<void> _loadHallTicket() async {
    try {
      final student = context.read<Student>();
      final hallTicketRepo = context.read<HallTicketRepository>();
      final examRepo = context.read<ExamRepository>();

      // Fetch all exams for class first to find active term
      final exams = await examRepo.getExamsByClass(student.classId);
      if (exams.isEmpty) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Find the first exam that is not results_published (or just the latest exam)
      final activeExam = exams.firstWhere(
        (e) => !e.resultsPublished,
        orElse: () => exams.first,
      );

      // Fetch hall ticket for this student and exam
      final ticket = await hallTicketRepo.getHallTicketByStudentAndExam(
        student.id,
        activeExam.id,
      );
      List<ExamSubject> schedules = [];
      if (ticket != null) {
        schedules = await examRepo.getExamSubjects(activeExam.id);
      }

      if (mounted) {
        setState(() {
          _activeExam = activeExam;
          _hallTicket = ticket;
          _examSchedules = schedules;
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

  Future<void> _downloadHallTicket() async {
    final ticket = _hallTicket;
    if (ticket == null || ticket.filePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hall ticket PDF is not available yet.')),
      );
      return;
    }

    try {
      final hallTicketRepo = context.read<HallTicketRepository>();
      final signedUrl = await hallTicketRepo.getSignedHallTicketUrl(
        ticket.filePath!,
      );
      final uri = Uri.parse(signedUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Could not launch browser to download note');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
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
                  'Error loading hall ticket',
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
                    _loadHallTicket();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final ticket = _hallTicket;
    final exam = _activeExam;

    if (ticket == null || exam == null) {
      return PageScaffold(
        title: 'Hall Ticket',
        children: [
          PortalCard(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 48.0),
                child: Column(
                  children: [
                    const Icon(
                      Icons.confirmation_number_outlined,
                      size: 64,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Active Exam Hall Ticket Found',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Hall tickets are generated and published by class teachers before exams.',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    final isLocked = exam.hallTicketLocked || ticket.status == 'locked';

    return PageScaffold(
      title: 'Hall Ticket',
      trailing: !isLocked && ticket.filePath != null
          ? FilledButton.icon(
              onPressed: _downloadHallTicket,
              icon: const Icon(Icons.download_outlined),
              label: const Text('Download Hall Ticket'),
            )
          : null,
      children: [
        if (isLocked) ...[
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.lock_outline, color: Colors.orange),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Your hall ticket for ${exam.examName} is locked by the admin cell. Please contact the office to release it.',
                    style: const TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        PortalCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 16,
                runSpacing: 12,
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    width: 72,
                    height: 72,
                    fit: BoxFit.contain,
                  ),
                  Column(
                    crossAxisAlignment: isDesktop
                        ? CrossAxisAlignment.start
                        : CrossAxisAlignment.center,
                    children: [
                      Text(
                        'SAMASTHA KERALA ISLAM MATHA VIDYABHYASA BOARD (SKIMVB)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'HIDAYATHUL ANAM MADRASA',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'OFFICIAL EXAMINATION HALL TICKET',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(),
              ),
              isDesktop
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _HallTicketDetails(
                            student: student,
                            ticket: ticket,
                            exam: exam,
                          ),
                        ),
                        const SizedBox(width: 24),
                        _StudentPhotoPanel(student: student),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _StudentPhotoPanel(student: student),
                        const SizedBox(height: 20),
                        _HallTicketDetails(
                          student: student,
                          ticket: ticket,
                          exam: exam,
                        ),
                      ],
                    ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        PortalCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Exam Subject Schedules',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 14),
              if (_examSchedules.isEmpty)
                const Center(
                  child: Text('No subject schedules published for this exam'),
                )
              else
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 680),
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Subject')),
                        DataColumn(label: Text('Subject Code')),
                        DataColumn(label: Text('Exam Date')),
                        DataColumn(label: Text('Time')),
                      ],
                      rows: [
                        for (final schedule in _examSchedules)
                          DataRow(
                            cells: [
                              DataCell(Text(schedule.subjectName ?? 'Unknown')),
                              DataCell(Text(schedule.subjectCode ?? 'N/A')),
                              DataCell(
                                Text(
                                  schedule.examDate != null
                                      ? schedule.examDate!
                                            .toLocal()
                                            .toString()
                                            .substring(0, 10)
                                      : 'TBA',
                                ),
                              ),
                              DataCell(
                                Text(
                                  schedule.startTime != null
                                      ? '${schedule.startTime} - ${schedule.endTime ?? ''}'
                                      : 'TBA',
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HallTicketDetails extends StatelessWidget {
  const _HallTicketDetails({
    required this.student,
    required this.ticket,
    required this.exam,
  });

  final Student student;
  final HallTicket ticket;
  final Exam exam;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DetailRow(label: 'Student Name', value: student.fullName),
        _DetailRow(label: 'Class', value: student.className ?? 'N/A'),
        _DetailRow(label: 'Roll Number', value: student.rollNumber),
        _DetailRow(label: 'Admission No', value: student.admissionNumber),
        _DetailRow(label: 'Exam Name', value: exam.examName),
        _DetailRow(
          label: 'Exam Center',
          value: exam.examCenter ?? 'Madrasa Campus',
        ),
        _DetailRow(label: 'Reporting Time', value: exam.reportingTime ?? 'TBA'),
        _DetailRow(label: 'Ticket Number', value: ticket.hallTicketNumber),
        _DetailRow(
          label: 'Status',
          value: exam.hallTicketLocked || ticket.status == 'locked'
              ? 'Locked'
              : 'Generated & Active',
        ),
      ],
    );
  }
}

class _StudentPhotoPanel extends StatefulWidget {
  const _StudentPhotoPanel({required this.student});

  final Student student;

  @override
  State<_StudentPhotoPanel> createState() => _StudentPhotoPanelState();
}

class _StudentPhotoPanelState extends State<_StudentPhotoPanel> {
  String? _signedPhotoUrl;

  @override
  void initState() {
    super.initState();
    _loadPhotoUrl();
  }

  void _loadPhotoUrl() async {
    if (widget.student.photoPath != null &&
        widget.student.photoPath!.isNotEmpty) {
      try {
        final url = await context.read<StudentRepository>().getSignedPhotoUrl(
          widget.student.photoPath!,
        );
        if (mounted) {
          setState(() {
            _signedPhotoUrl = url;
          });
        }
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1E293B)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 54,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            backgroundImage: _signedPhotoUrl != null
                ? NetworkImage(_signedPhotoUrl!)
                : null,
            child: _signedPhotoUrl == null
                ? Text(
                    widget.student.photoInitials,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w900,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 12),
          Text(
            'Student Photo',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
