// teacher_hall_tickets_page.dart
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/repository_interfaces.dart';
import '../../models/models.dart';

class TeacherHallTicketsPage extends StatefulWidget {
  const TeacherHallTicketsPage({super.key});

  @override
  State<TeacherHallTicketsPage> createState() => _TeacherHallTicketsPageState();
}

class _TeacherHallTicketsPageState extends State<TeacherHallTicketsPage> {
  bool _isLoading = true;
  String? _error;

  List<Exam> _exams = [];
  List<HallTicket> _hallTickets = [];
  String? _selectedExamId;
  String? _selectedFileName;

  @override
  void initState() {
    super.initState();
    _loadSetupData();
  }

  Future<void> _loadSetupData() async {
    try {
      final teacher = context.read<Teacher>();
      final classId = teacher.assignedClassId ?? '';
      final examRepo = context.read<ExamRepository>();

      final exams = await examRepo.getExamsByClass(classId);

      if (mounted) {
        setState(() {
          _exams = exams;
          if (_exams.isNotEmpty) {
            _selectedExamId = _exams.first.id;
          }
        });
      }

      await _loadHallTickets();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadHallTickets() async {
    if (_selectedExamId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final teacher = context.read<Teacher>();
      final classId = teacher.assignedClassId ?? '';
      final hallTicketRepo = context.read<HallTicketRepository>();
      final tickets = await hallTicketRepo.getHallTicketsByClass(classId);

      if (mounted) {
        setState(() {
          _hallTickets =
              tickets.where((t) => t.examId == _selectedExamId).toList();
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

  void _pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'csv'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFileName = result.files.first.name;
        });
      }
    } catch (e) {
      debugPrint('Error picking files: $e');
    }
  }

  void _generateTickets() async {
    if (_selectedExamId == null) return;

    final teacher = context.read<Teacher>();
    final classId = teacher.assignedClassId ?? '';
    final exam = _exams.firstWhere((e) => e.id == _selectedExamId);
    final hallTicketRepo = context.read<HallTicketRepository>();
    final activityRepo = context.read<ActivityLogRepository>();

    setState(() => _isLoading = true);

    try {
      await hallTicketRepo.generateHallTickets(_selectedExamId!, classId);

      await activityRepo.logActivity(
        action: 'Generated Hall Tickets',
        entityType: 'exam',
        entityId: _selectedExamId,
        description: 'Generated hall tickets for class for ${exam.examName}',
        classId: classId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hall tickets generated successfully!')),
        );
        setState(() => _selectedFileName = null);
        _loadHallTickets();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
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
          child: Card(
            color: Colors.red.shade50,
            margin: const EdgeInsets.all(32),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Error loading hall tickets: $_error',
                    style: TextStyle(
                      color: Colors.red.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadSetupData,
                    child: const Text('Retry Loading Data'),
                  ),
                ],
              ),
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
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Page Header Section
                Text(
                  'Upload Halltickets',
                  style: TextStyle(
                    fontFamily: 'Serif',
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: const Text(
                    'Upload and distribute examination documents to your class. Ensure all files adhere to the university\'s digital formatting guidelines.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF45464D),
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  width: 96,
                  height: 1,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                const SizedBox(height: 32),

                // Upload Interface Grid
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isDesktop = constraints.maxWidth >= 992;
                    return isDesktop
                        ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: _buildUploadCard(
                                isDark: isDark,
                                borderColor: borderColor,
                                cardBg: cardBg,
                              ),
                            ),
                            const SizedBox(width: 32),
                            Expanded(
                              flex: 1,
                              child: _buildGuidelinesCard(
                                isDark: isDark,
                                borderColor: borderColor,
                              ),
                            ),
                          ],
                        )
                        : Column(
                          children: [
                            _buildUploadCard(
                              isDark: isDark,
                              borderColor: borderColor,
                              cardBg: cardBg,
                            ),
                            const SizedBox(height: 32),
                            _buildGuidelinesCard(
                              isDark: isDark,
                              borderColor: borderColor,
                            ),
                          ],
                        );
                  },
                ),
                const SizedBox(height: 48),

                // Recent Uploads Section
                _buildRecentUploadsSection(
                  isDark: isDark,
                  borderColor: borderColor,
                  cardBg: cardBg,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUploadCard({
    required bool isDark,
    required Color borderColor,
    required Color cardBg,
  }) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Examination Cycle Selector
          Text(
            'Examination Cycle',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue:
                (_selectedExamId != null &&
                        _exams.any((e) => e.id == _selectedExamId))
                    ? _selectedExamId
                    : null,
            decoration: InputDecoration(
              filled: true,
              fillColor:
                  isDark
                      ? const Color(0xFF0F172A)
                      : const Color(0xFFF7F9FB),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: borderColor, width: 0.8),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: borderColor, width: 0.8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            items: [
              for (final exam in _exams)
                DropdownMenuItem(
                  value: exam.id,
                  child: Text(
                    exam.examName,
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ),
            ],
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _selectedExamId = val;
                  _isLoading = true;
                });
                _loadHallTickets();
              }
            },
          ),
          const SizedBox(height: 32),

          // Drag & Drop Zone
          InkWell(
            onTap: _pickFiles,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
              decoration: BoxDecoration(
                color:
                    isDark
                        ? const Color(0xFF0F172A)
                        : const Color(0xFFF7F9FB),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: borderColor,
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color:
                          isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFE0E3E5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.upload_file_outlined,
                      size: 32,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _selectedFileName != null
                        ? 'Selected File: $_selectedFileName'
                        : 'Select files to upload',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Serif',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: const Text(
                      'Drag and drop your generated PDF or CSV batch files here, or click to browse your local repository.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF45464D),
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildFormatBadge('.PDF', isDark, borderColor),
                      _buildFormatBadge('.CSV', isDark, borderColor),
                      _buildFormatBadge('Max 50MB', isDark, borderColor),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Action Buttons
          Container(
            padding: const EdgeInsets.only(top: 24),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: borderColor, width: 0.8),
              ),
            ),
            child: Wrap(
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 12,
              children: [
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor:
                        isDark ? Colors.white : const Color(0xFF0F172A),
                    side: BorderSide(color: borderColor, width: 0.8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  onPressed: () {
                    setState(() => _selectedFileName = null);
                  },
                  child: const Text(
                    'Cancel Upload',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  onPressed: _generateTickets,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Proceed to Review',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, size: 18),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuidelinesCard({
    required bool isDark,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF7F9FB),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, size: 22, color: Color(0xFF0F172A)),
              const SizedBox(width: 8),
              Text(
                'Guidelines',
                style: TextStyle(
                  fontFamily: 'Serif',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildGuidelineRow(
            icon: Icons.check_circle_outline,
            text:
                'Ensure student ID mappings in CSV files exactly match the master university database records.',
            borderColor: borderColor,
          ),
          _buildGuidelineRow(
            icon: Icons.picture_as_pdf_outlined,
            text:
                'If uploading PDFs directly, filenames must follow the nomenclature: [StudentID]_[ExamCode].pdf',
            borderColor: borderColor,
          ),
          _buildGuidelineRow(
            icon: Icons.lock_outline,
            text:
                'All uploaded documents are automatically watermarked with the institutional seal upon processing.',
            borderColor: borderColor,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentUploadsSection({
    required bool isDark,
    required Color borderColor,
    required Color cardBg,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Uploads',
              style: TextStyle(
                fontFamily: 'Serif',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            TextButton.icon(
              onPressed: _loadHallTickets,
              icon: const Icon(Icons.arrow_outward, size: 16),
              label: const Text(
                'View Complete History',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF9B4500),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: borderColor, width: 0.8),
          ),
          clipBehavior: Clip.antiAlias,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double minTableWidth =
                  constraints.maxWidth > 900.0 ? constraints.maxWidth : 900.0;
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: minTableWidth),
                  child: Table(
                    columnWidths: const {
                      0: FixedColumnWidth(120),
                      1: FlexColumnWidth(2.5),
                      2: FlexColumnWidth(2),
                      3: FixedColumnWidth(110),
                      4: FixedColumnWidth(190),
                      5: FixedColumnWidth(140),
                      6: FixedColumnWidth(90),
                    },
                    children: [
                      // Table Header
                      TableRow(
                        decoration: BoxDecoration(
                          color:
                              isDark
                                  ? const Color(0xFF1E293B)
                                  : const Color(0xFFF7F9FB),
                          border: Border(
                            bottom: BorderSide(color: borderColor, width: 0.8),
                          ),
                        ),
                        children: const [
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 16,
                            ),
                            child: Text(
                              'BATCH ID',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF45464D),
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 16,
                            ),
                            child: Text(
                              'EXAMINATION',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF45464D),
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 16,
                            ),
                            child: Text(
                              'CLASS',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF45464D),
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 16,
                            ),
                            child: Text(
                              'STUDENTS',
                              softWrap: false,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF45464D),
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 16,
                            ),
                            child: Text(
                              'DATE UPLOADED',
                              softWrap: false,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF45464D),
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 16,
                            ),
                            child: Text(
                              'STATUS',
                              softWrap: false,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF45464D),
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 16,
                            ),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                'ACTIONS',
                                softWrap: false,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF45464D),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Dynamic or Sample Rows
                      if (_hallTickets.isNotEmpty)
                        for (int i = 0; i < _hallTickets.length; i++)
                          _buildTicketRow(
                            batchId: 'BCH-8${821 + i}',
                            exam:
                                _exams
                                    .firstWhere(
                                      (e) => e.id == _hallTickets[i].examId,
                                      orElse:
                                          () => Exam(
                                            id: '',
                                            examName: 'End-Semester 2024',
                                            classId: '',
                                            createdAt: DateTime.now(),
                                            updatedAt: DateTime.now(),
                                          ),
                                    )
                                    .examName,
                            className:
                                _hallTickets[i].studentName != null
                                    ? _hallTickets[i].studentName!
                                    : 'Assigned Class',
                            studentsCount: '1',
                            dateUploaded: _hallTickets[i].generatedAt
                                .toLocal()
                                .toString()
                                .substring(0, 16),
                            status: _hallTickets[i].status.toUpperCase(),
                            isPublished: _hallTickets[i].status != 'locked',
                            borderColor: borderColor,
                            isLast: i == _hallTickets.length - 1,
                          )
                      else ...[
                        _buildTicketRow(
                          batchId: 'BCH-8821',
                          exam: 'End-Semester Nov 2024',
                          className: 'Computer Science - VI',
                          studentsCount: '142',
                          dateUploaded: 'Oct 24, 2024 • 14:30',
                          status: 'Processing',
                          isProcessing: true,
                          borderColor: borderColor,
                        ),
                        _buildTicketRow(
                          batchId: 'BCH-8790',
                          exam: 'End-Semester Nov 2024',
                          className: 'Information Tech - VI',
                          studentsCount: '118',
                          dateUploaded: 'Oct 23, 2024 • 09:15',
                          status: 'Published',
                          isPublished: true,
                          borderColor: borderColor,
                        ),
                        _buildTicketRow(
                          batchId: 'BCH-8542',
                          exam: 'Mid-Semester Oct 2024',
                          className: 'Computer Science - VI',
                          studentsCount: '145',
                          dateUploaded: 'Sep 15, 2024 • 11:00',
                          status: 'Published',
                          isPublished: true,
                          borderColor: borderColor,
                          isLast: true,
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  TableRow _buildTicketRow({
    required String batchId,
    required String exam,
    required String className,
    required String studentsCount,
    required String dateUploaded,
    required String status,
    bool isPublished = false,
    bool isProcessing = false,
    required Color borderColor,
    bool isLast = false,
  }) {
    return TableRow(
      decoration: BoxDecoration(
        border:
            isLast
                ? null
                : Border(bottom: BorderSide(color: borderColor, width: 0.8)),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          child: Text(
            batchId,
            style: const TextStyle(
              fontSize: 13,
              fontFamily: 'Monospace',
              color: Color(0xFF45464D),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          child: Text(
            exam,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          child: Text(
            className,
            style: const TextStyle(fontSize: 13, color: Color(0xFF45464D)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          child: Text(
            studentsCount,
            style: const TextStyle(fontSize: 13, color: Color(0xFF45464D)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          child: Text(
            dateUploaded,
            style: const TextStyle(fontSize: 13, color: Color(0xFF45464D)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color:
                    isPublished
                        ? const Color(0xFF0F172A)
                        : const Color(0xFFE0E3E5),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isPublished ? Colors.white : const Color(0xFF45464D),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    status,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color:
                          isPublished ? Colors.white : const Color(0xFF45464D),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              tooltip: 'View Details',
              onPressed: () {},
              icon: const Icon(
                Icons.visibility_outlined,
                size: 20,
                color: Color(0xFF45464D),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormatBadge(String label, bool isDark, Color borderColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF334155) : const Color(0xFFECEEF0),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Color(0xFF45464D),
        ),
      ),
    );
  }

  Widget _buildGuidelineRow({
    required IconData icon,
    required String text,
    required Color borderColor,
    bool isLast = false,
  }) {
    return Container(
      padding: const EdgeInsets.only(bottom: 16),
      margin: EdgeInsets.only(bottom: isLast ? 0 : 16),
      decoration: BoxDecoration(
        border:
            isLast
                ? null
                : Border(bottom: BorderSide(color: borderColor, width: 0.8)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: const Color(0xFF0F172A)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF45464D),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

