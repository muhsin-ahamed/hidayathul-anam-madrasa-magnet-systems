// super_admin_academic_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/repository_interfaces.dart';
import '../../models/models.dart';
import '../../widgets/page_scaffold.dart';
import '../../widgets/portal_card.dart';
import '../../widgets/responsive.dart';
import '../../widgets/status_badge.dart';
import '../../core/constants/subjects.dart';

class SuperAdminAcademicPage extends StatefulWidget {
  const SuperAdminAcademicPage({super.key});

  @override
  State<SuperAdminAcademicPage> createState() => _SuperAdminAcademicPageState();
}

class _SuperAdminAcademicPageState extends State<SuperAdminAcademicPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _isLoading = true;
  String? _error;

  List<ClassInfo> _classes = [];
  List<Subject> _subjects = [];
  List<Exam> _exams = [];
  List<ActivityLog> _logs = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadSetupData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSetupData() async {
    try {
      final classRepo = context.read<ClassRepository>();
      final subjectRepo = context.read<SubjectRepository>();
      final examRepo = context.read<ExamRepository>();
      final logRepo = context.read<ActivityLogRepository>();

      // Fetch classes, exams, logs, and subjects concurrently in parallel
      final results = await Future.wait([
        classRepo.getAllClasses(),
        examRepo.getAllExams(),
        logRepo.getAllLogs(),
        subjectRepo.getSubjectsByClass(''),
      ]);

      final classes = results[0] as List<ClassInfo>;
      final exams = results[1] as List<Exam>;
      final logs = results[2] as List<ActivityLog>;
      var allSubjects = results[3] as List<Subject>;

      // Fallback: If global subject fetch returned empty but classes exist, fetch class subjects in parallel
      if (allSubjects.isEmpty && classes.isNotEmpty) {
        final subjectLists = await Future.wait(
          classes.map((c) => subjectRepo.getSubjectsByClass(c.id)),
        );
        allSubjects = subjectLists.expand((subs) => subs).toList();
      }

      if (!mounted) return;

      setState(() {
        _classes = classes;
        _subjects = allSubjects;
        _exams = exams;
        _logs = logs;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _showAddSubjectDialog() {
    showDialog(
      context: context,
      builder: (context) =>
          _SubjectFormDialog(classes: _classes, onSave: _loadSetupData),
    );
  }

  void _showAddExamDialog() {
    showDialog(
      context: context,
      builder: (context) =>
          _ExamFormDialog(classes: _classes, onSave: _loadSetupData),
    );
  }

  void _lockHallTicket(Exam exam, bool lock) async {
    final examRepo = context.read<ExamRepository>();
    final logRepo = context.read<ActivityLogRepository>();
    setState(() => _isLoading = true);
    try {
      await examRepo.setHallTicketsLocked(exam.id, lock);
      await logRepo.logActivity(
        action: lock ? 'Locked Hall Tickets' : 'Released Hall Tickets',
        entityType: 'exam',
        entityId: exam.id,
        description:
            '${lock ? 'Locked' : 'Released'} hall tickets for ${exam.examName}',
        classId: exam.classId,
      );
      _loadSetupData();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  void _publishResults(Exam exam, bool publish) async {
    final examRepo = context.read<ExamRepository>();
    final logRepo = context.read<ActivityLogRepository>();
    setState(() => _isLoading = true);
    try {
      await examRepo.setResultsPublished(exam.id, publish);
      await logRepo.logActivity(
        action: publish ? 'Published Results' : 'Unpublished Results',
        entityType: 'exam',
        entityId: exam.id,
        description:
            '${publish ? 'Published' : 'Unpublished'} results for ${exam.examName}',
        classId: exam.classId,
      );
      _loadSetupData();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  void _deleteExam(Exam exam) async {
    final examRepo = context.read<ExamRepository>();
    final logRepo = context.read<ActivityLogRepository>();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Exam'),
        content: Text(
          'Are you sure you want to delete "${exam.examName}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await examRepo.deleteExam(exam.id);
      await logRepo.logActivity(
        action: 'Deleted Exam',
        entityType: 'exam',
        entityId: exam.id,
        description: 'Deleted exam ${exam.examName}',
        classId: exam.classId,
      );
      _loadSetupData();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
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
              Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: _loadSetupData, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final isMobile = Responsive.isMobile(context);

    return PageScaffold(
      title: 'Academic Settings',
      children: [
        TabBar(
          controller: _tabController,
          isScrollable: isMobile,
          tabAlignment: isMobile ? TabAlignment.start : null,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(icon: Icon(Icons.menu_book), text: 'Subjects'),
            Tab(icon: Icon(Icons.event_note), text: 'Exams & Sessions'),
            Tab(icon: Icon(Icons.history), text: 'Audit Trails'),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 600,
          child: TabBarView(
            controller: _tabController,
            children: [
              // SUBJECTS TAB
              _buildSubjectsTab(),

              // EXAMS TAB
              _buildExamsTab(),

              // AUDIT LOGS TAB
              _buildLogsTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubjectsTab() {
    final isMobile = Responsive.isMobile(context);
    return PortalCard(
      padding: EdgeInsets.all(isMobile ? 12 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              const Text(
                'Class Subjects Catalog',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              FilledButton.icon(
                onPressed: _showAddSubjectDialog,
                icon: const Icon(Icons.add),
                label: const Text('Add Subject'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _subjects.isEmpty
                ? const Center(child: Text('No subjects created yet'))
                : ListView.builder(
                    itemCount: _subjects.length,
                    itemBuilder: (context, index) {
                      final s = _subjects[index];
                      final cls = _classes.firstWhere(
                        (c) => c.id == s.classId,
                        orElse: () => ClassInfo(
                          id: '',
                          className: 'Unknown',
                          academicYear: '',
                          createdAt: DateTime.now(),
                          updatedAt: DateTime.now(),
                        ),
                      );
                      return ListTile(
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 8 : 16,
                          vertical: 4,
                        ),
                        leading: const CircleAvatar(
                          child: Icon(Icons.book_outlined),
                        ),
                        title: Text(s.subjectName),
                        subtitle: Text(
                          '${cls.displayName} | Max: ${s.maximumMarks} | Pass: ${s.passMarks}',
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildExamsTab() {
    final isMobile = Responsive.isMobile(context);
    return PortalCard(
      padding: EdgeInsets.all(isMobile ? 12 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              const Text(
                'Exams Term Manager',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              FilledButton.icon(
                onPressed: _showAddExamDialog,
                icon: const Icon(Icons.add),
                label: const Text('New Exam'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _exams.isEmpty
                ? const Center(child: Text('No exams scheduled yet'))
                : ListView.builder(
                    itemCount: _exams.length,
                    itemBuilder: (context, index) {
                      final exam = _exams[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    exam.examName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  StatusBadge(
                                    label: exam.resultsPublished
                                        ? 'Results Published'
                                        : 'Draft',
                                    color: exam.resultsPublished
                                        ? const Color(0xFF059669)
                                        : Colors.orange,
                                  ),
                                  StatusBadge(
                                    label: exam.hallTicketLocked
                                        ? 'Tickets Locked'
                                        : 'Tickets Active',
                                    color: exam.hallTicketLocked
                                        ? const Color(0xFFDC2626)
                                        : Colors.green,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Class Assignment: ${exam.className ?? "N/A"}',
                              ),
                              Text(
                                'Date of Examination: ${exam.startDate?.toLocal().toString().substring(0, 10) ?? "TBA"}',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              const Divider(),
                              Wrap(
                                alignment: isMobile
                                    ? WrapAlignment.start
                                    : WrapAlignment.end,
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: () => _lockHallTicket(
                                      exam,
                                      !exam.hallTicketLocked,
                                    ),
                                    icon: Icon(
                                      exam.hallTicketLocked
                                          ? Icons.lock_open
                                          : Icons.lock_outline,
                                    ),
                                    label: Text(
                                      exam.hallTicketLocked
                                          ? 'Unlock Tickets'
                                          : 'Lock Tickets',
                                    ),
                                  ),
                                  FilledButton.icon(
                                    onPressed: () => _publishResults(
                                      exam,
                                      !exam.resultsPublished,
                                    ),
                                    icon: Icon(
                                      exam.resultsPublished
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                    ),
                                    label: Text(
                                      exam.resultsPublished
                                          ? 'Unpublish Results'
                                          : 'Publish Results',
                                    ),
                                  ),
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red,
                                      side: const BorderSide(color: Colors.red),
                                    ),
                                    onPressed: () => _deleteExam(exam),
                                    icon: const Icon(Icons.delete_outline),
                                    label: const Text('Delete Exam'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogsTab() {
    final isMobile = Responsive.isMobile(context);
    return PortalCard(
      padding: EdgeInsets.all(isMobile ? 12 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Madrasa Audit Logs',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _logs.isEmpty
                ? const Center(child: Text('No activity logged yet'))
                : ListView.builder(
                    itemCount: _logs.length,
                    itemBuilder: (context, index) {
                      final log = _logs[index];
                      final dateStr =
                          log.createdAt.toLocal().toString().substring(0, 16);
                      if (isMobile) {
                        return ListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          leading: const Icon(Icons.bolt, color: Colors.blue),
                          title: Text(log.action),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (log.description != null)
                                Text(log.description!),
                              const SizedBox(height: 2),
                              Text(
                                dateStr,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return ListTile(
                        leading: const Icon(Icons.bolt, color: Colors.blue),
                        title: Text(log.action),
                        subtitle: Text(log.description ?? 'System update'),
                        trailing: Text(dateStr),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _SubjectFormDialog extends StatefulWidget {
  const _SubjectFormDialog({required this.classes, required this.onSave});

  final List<ClassInfo> classes;
  final VoidCallback onSave;

  @override
  State<_SubjectFormDialog> createState() => _SubjectFormDialogState();
}

class _SubjectFormDialogState extends State<_SubjectFormDialog> {
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _maxController = TextEditingController(text: '100');
  final _passController = TextEditingController(text: '35');

  String? _classId;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final allowedSubjects = getSubjectsForClass(_classId, classes: widget.classes);
    return AlertDialog(
      title: const Text('Add Subject'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: (_classId != null && widget.classes.any((c) => c.id == _classId)) ? _classId : null,
              decoration: const InputDecoration(labelText: 'Class Assignment *'),
              items: [
                for (final cls in widget.classes)
                  DropdownMenuItem(value: cls.id, child: Text(cls.displayName)),
              ],
              onChanged: (val) {
                setState(() {
                  _classId = val;
                  final newAllowed = getSubjectsForClass(val, classes: widget.classes);
                  _nameController.text = newAllowed.isNotEmpty ? newAllowed.first : '';
                  _codeController.text = _nameController.text;
                });
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: allowedSubjects.contains(_nameController.text)
                  ? _nameController.text
                  : (allowedSubjects.isNotEmpty ? allowedSubjects.first : null),
              decoration: const InputDecoration(labelText: 'Subject Name *'),
              items: [
                for (final subName in allowedSubjects)
                  DropdownMenuItem(value: subName, child: Text(subName)),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _nameController.text = val;
                    _codeController.text = val;
                  });
                }
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _codeController,
              decoration: const InputDecoration(labelText: 'Subject Code'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _maxController,
                    decoration: const InputDecoration(labelText: 'Max Marks'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _passController,
                    decoration: const InputDecoration(labelText: 'Pass Marks'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isLoading
              ? null
              : () async {
                  if (_nameController.text.trim().isEmpty || _classId == null) {
                    return;
                  }
                  final repo = context.read<SubjectRepository>();
                  final navigator = Navigator.of(context);
                  if (!mounted) return;
                  setState(() => _isLoading = true);
                  try {
                    final sub = Subject(
                      id: '',
                      subjectName: _nameController.text.trim(),
                      subjectCode: _codeController.text.trim(),
                      classId: _classId!,
                      maximumMarks: double.tryParse(_maxController.text) ?? 100,
                      passMarks: double.tryParse(_passController.text) ?? 35,
                      createdAt: DateTime.now(),
                    );
                    await repo.createSubject(sub);
                    if (mounted) {
                      widget.onSave();
                      navigator.pop();
                    }
                  } catch (_) {}
                },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _ExamFormDialog extends StatefulWidget {
  const _ExamFormDialog({required this.classes, required this.onSave});

  final List<ClassInfo> classes;
  final VoidCallback onSave;

  @override
  State<_ExamFormDialog> createState() => _ExamFormDialogState();
}

class _ExamFormDialogState extends State<_ExamFormDialog> {
  final _nameController = TextEditingController();
  final _centerController = TextEditingController(
    text: 'HIDAYATHUL ANAM MADRASA Main Campus',
  );

  String? _classId;
  DateTime _startDate = DateTime.now().add(const Duration(days: 7));
  bool _isLoading = false;

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Schedule Term Exam'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Exam Name (e.g. Mid-Term)',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _centerController,
              decoration: const InputDecoration(labelText: 'Exam Center'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: (_classId != null && (_classId == 'all' || widget.classes.any((c) => c.id == _classId))) ? _classId : null,
              decoration: const InputDecoration(labelText: 'Class Assignment'),
              items: [
                const DropdownMenuItem(value: 'all', child: Text('All Class')),
                for (final cls in widget.classes)
                  DropdownMenuItem(value: cls.id, child: Text(cls.displayName)),
              ],
              onChanged: (val) => setState(() => _classId = val),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _selectStartDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date of Examination',
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  '${_startDate.year}-${_startDate.month.toString().padLeft(2, '0')}-${_startDate.day.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isLoading
              ? null
              : () async {
                  if (_nameController.text.trim().isEmpty || _classId == null) {
                    return;
                  }
                  final repo = context.read<ExamRepository>();
                  final navigator = Navigator.of(context);
                  if (!mounted) return;
                  setState(() => _isLoading = true);
                  try {
                    if (_classId == 'all') {
                      await Future.wait(
                        widget.classes.map((cls) => repo.createExam(
                          Exam(
                            id: '',
                            examName: _nameController.text.trim(),
                            classId: cls.id,
                            examCenter: _centerController.text.trim(),
                            startDate: _startDate,
                            createdAt: DateTime.now(),
                            updatedAt: DateTime.now(),
                          ),
                        )),
                      );
                    } else {
                      final exam = Exam(
                        id: '',
                        examName: _nameController.text.trim(),
                        classId: _classId!,
                        examCenter: _centerController.text.trim(),
                        startDate: _startDate,
                        createdAt: DateTime.now(),
                        updatedAt: DateTime.now(),
                      );
                      await repo.createExam(exam);
                    }
                    if (mounted) {
                      widget.onSave();
                      navigator.pop();
                    }
                  } catch (_) {
                    if (mounted) {
                      setState(() => _isLoading = false);
                    }
                  }
                },
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Create'),
        ),
      ],
    );
  }
}

