// teacher_students_page.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:excel/excel.dart' hide Border;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/controllers/auth_controller.dart';
import '../../data/repositories/repository_interfaces.dart';
import '../../models/models.dart';
import '../../models/user_role.dart';

class TeacherStudentsPage extends StatefulWidget {
  const TeacherStudentsPage({super.key});

  @override
  State<TeacherStudentsPage> createState() => _TeacherStudentsPageState();
}

class _TeacherStudentsPageState extends State<TeacherStudentsPage> {
  bool _isLoading = true;
  String? _error;
  List<Student> _students = [];
  String _query = '';
  String _statusFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    try {
      final teacher = context.read<Teacher>();
      final classId = teacher.assignedClassId ?? '';
      final repo = context.read<StudentRepository>();
      final students = await repo.getStudentsByClass(classId);
      if (mounted) {
        setState(() {
          _students = students;
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

  void _showAddStudentDialog() {
    final teacher = context.read<Teacher>();
    final auth = context.read<AuthController>();
    final classId = teacher.assignedClassId ?? '';
    final teacherId = teacher.id;
    final role = auth.currentProfile?.role.dbValue ?? 'class_teacher';

    showDialog(
      context: context,
      builder:
          (dialogCtx) => _StudentFormDialog(
            classId: classId,
            teacherId: teacherId,
            role: role,
            existingStudents: _students,
            onSave: () {
              _loadStudents();
              context.read<ActivityLogRepository>().logActivity(
                action: 'Added Student',
                entityType: 'student',
                description: 'Added a new student to class',
                classId: classId,
              );
            },
          ),
    );
  }

  void _showUploadCsvDialog() {
    final teacher = context.read<Teacher>();
    final classId = teacher.assignedClassId ?? '';

    showDialog(
      context: context,
      builder:
          (dialogCtx) => _CsvUploadDialog(
            classId: classId,
            onSuccess: () {
              _loadStudents();
              context.read<ActivityLogRepository>().logActivity(
                action: 'Uploaded CSV',
                entityType: 'student',
                description: 'Uploaded student list via CSV',
                classId: classId,
              );
            },
          ),
    );
  }

  void _showEditStudentDialog(Student student) {
    final teacher = context.read<Teacher>();
    final auth = context.read<AuthController>();
    final classId = teacher.assignedClassId ?? '';
    final teacherId = teacher.id;
    final role = auth.currentProfile?.role.dbValue ?? 'class_teacher';

    showDialog(
      context: context,
      builder:
          (dialogCtx) => _StudentFormDialog(
            student: student,
            classId: classId,
            teacherId: teacherId,
            role: role,
            existingStudents: _students,
            onSave: () {
              _loadStudents();
              context.read<ActivityLogRepository>().logActivity(
                action: 'Updated Student',
                entityType: 'student',
                entityId: student.id,
                description: 'Updated student details for ${student.fullName}',
                classId: classId,
              );
            },
          ),
    );
  }

  void _toggleStudentStatus(Student student) async {
    final teacher = context.read<Teacher>();
    final classId = teacher.assignedClassId ?? '';
    final studentRepo = context.read<StudentRepository>();
    final activityRepo = context.read<ActivityLogRepository>();
    final action =
        student.isActive ? 'Deactivated Student' : 'Activated Student';
    try {
      setState(() => _isLoading = true);
      if (student.isActive) {
        await studentRepo.deactivateStudent(student.id);
      } else {
        final updated = Student(
          id: student.id,
          profileId: student.profileId,
          admissionNumber: student.admissionNumber,
          rollNumber: student.rollNumber,
          fullName: student.fullName,
          classId: student.classId,
          isActive: true,
          createdAt: student.createdAt,
          updatedAt: DateTime.now(),
        );
        await studentRepo.updateStudent(updated);
      }
      await activityRepo.logActivity(
        action: action,
        entityType: 'student',
        entityId: student.id,
        description: '$action ${student.fullName}',
        classId: classId,
      );
      if (!mounted) return;
      _loadStudents();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  void _deleteStudent(Student student) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Delete Student'),
            content: Text(
              'Are you sure you want to delete ${student.fullName}? This action will deactivate their account.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      _toggleStudentStatus(student);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor =
        isDark ? const Color(0xFF374151) : const Color(0xFFC4C6CF);
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
                  'Error loading students',
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
                    _loadStudents();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final filteredStudents =
        _students.where((student) {
          final matchesSearch =
              _query.trim().isEmpty ||
              student.fullName.toLowerCase().contains(_query.toLowerCase()) ||
              student.rollNumber.toLowerCase().contains(
                _query.toLowerCase(),
              ) ||
              student.admissionNumber.toLowerCase().contains(
                _query.toLowerCase(),
              ) ||
              (student.email?.toLowerCase().contains(_query.toLowerCase()) ??
                  false);
          final matchesStatus =
              _statusFilter == 'All' ||
              (_statusFilter == 'Active' && student.isActive) ||
              (_statusFilter == 'Inactive' && !student.isActive);
          return matchesSearch && matchesStatus;
        }).toList();

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F172A) : const Color(0xFFF7F9FB),
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1400),
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Page Header
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isMobile = constraints.maxWidth < 640;
                    return Flex(
                      direction: isMobile ? Axis.vertical : Axis.horizontal,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment:
                          isMobile
                              ? CrossAxisAlignment.start
                              : CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'My Students',
                              style: TextStyle(
                                fontFamily: 'Serif',
                                fontSize: isMobile ? 24 : 30,
                                fontWeight: FontWeight.bold,
                                color:
                                    isDark
                                        ? Colors.white
                                        : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Manage and view your assigned students.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF44474E),
                              ),
                            ),
                          ],
                        ),
                        if (isMobile) const SizedBox(height: 16),
                        Row(
                          children: [
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                backgroundColor: cardBg,
                                foregroundColor:
                                    isDark
                                        ? Colors.white
                                        : const Color(0xFF191C20),
                                side: BorderSide(
                                  color: borderColor,
                                  width: 0.8,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              onPressed: _showUploadCsvDialog,
                              icon: const Icon(
                                Icons.file_upload_outlined,
                                size: 18,
                              ),
                              label: const Text(
                                'Upload CSV',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0F172A),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                elevation: 1,
                              ),
                              onPressed: _showAddStudentDialog,
                              icon: const Icon(
                                Icons.person_add_outlined,
                                size: 18,
                              ),
                              label: const Text(
                                'Add Student',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 32),

                // Main Card
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: borderColor, width: 0.8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      // Toolbar (Blank Space Fixed)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isDark
                                  ? const Color(0xFF1E293B)
                                  : const Color(0xFFF7F9FB),
                          border: Border(
                            bottom: BorderSide(color: borderColor, width: 0.8),
                          ),
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final isSmall = constraints.maxWidth < 600;
                            return Flex(
                              direction:
                                  isSmall ? Axis.vertical : Axis.horizontal,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  flex: isSmall ? 0 : 1,
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 480,
                                    ),
                                    child: SizedBox(
                                      height: 40,
                                      child: TextField(
                                        onChanged:
                                            (val) =>
                                                setState(() => _query = val),
                                        style: const TextStyle(fontSize: 14),
                                        decoration: InputDecoration(
                                          hintText: 'Search students...',
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                vertical: 0,
                                              ),
                                          prefixIcon: const Icon(
                                            Icons.search,
                                            size: 20,
                                            color: Color(0xFF44474E),
                                          ),
                                          filled: true,
                                          fillColor: cardBg,
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(4),
                                            borderSide: BorderSide(
                                              color: borderColor,
                                              width: 0.8,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(4),
                                            borderSide: const BorderSide(
                                              color: Color(0xFF0F172A),
                                              width: 1,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                if (isSmall) const SizedBox(height: 16),
                                Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Container(
                                      width: isSmall ? constraints.maxWidth : 200,
                                      height: 40,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: cardBg,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: borderColor,
                                          width: 0.8,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.check_circle_outline,
                                            size: 18,
                                            color: Color(0xFF44474E),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: DropdownButtonHideUnderline(
                                              child: DropdownButton<String>(
                                                value:
                                                    const [
                                                      'All',
                                                      'Active',
                                                      'Inactive',
                                                    ].contains(_statusFilter)
                                                        ? _statusFilter
                                                        : 'All',
                                                isExpanded: true,
                                                icon: const Icon(
                                                  Icons.arrow_drop_down,
                                                  color: Color(0xFF44474E),
                                                ),
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color:
                                                      isDark
                                                          ? Colors.white
                                                          : const Color(
                                                            0xFF191C20,
                                                          ),
                                                ),
                                                items: const [
                                                  DropdownMenuItem(
                                                    value: 'All',
                                                    child: Text('All'),
                                                  ),
                                                  DropdownMenuItem(
                                                    value: 'Active',
                                                    child: Text('Active'),
                                                  ),
                                                  DropdownMenuItem(
                                                    value: 'Inactive',
                                                    child: Text('Inactive'),
                                                  ),
                                                ],
                                                onChanged: (val) {
                                                  if (val != null) {
                                                    setState(
                                                      () => _statusFilter = val,
                                                    );
                                                  }
                                                },
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Positioned(
                                      top: -8,
                                      left: 8,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                        ),
                                        color: cardBg,
                                        child: const Text(
                                          'STATUS FILTER',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                            color: Color(0xFF44474E),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        ),
                      ),

                      // Table View
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                        child: filteredStudents.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.symmetric(vertical: 48.0),
                                child: Center(
                                  child: Text(
                                    'No students found matching your filters',
                                    style: TextStyle(
                                      color: Color(0xFF44474E),
                                    ),
                                  ),
                                ),
                              )
                            : LayoutBuilder(
                                builder: (context, tableConstraints) {
                                  final double minTableWidth =
                                      tableConstraints.maxWidth > 840
                                          ? tableConstraints.maxWidth
                                          : 840;
                                  return SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        minWidth: minTableWidth,
                                      ),
                                      child: Table(
                                        columnWidths: const {
                                          0: FixedColumnWidth(120),
                                          1: FixedColumnWidth(170),
                                          2: FlexColumnWidth(3),
                                          3: FlexColumnWidth(3),
                                          4: FixedColumnWidth(120),
                                          5: FixedColumnWidth(130),
                                        },
                                        children: [
                                          // Header Row
                                          TableRow(
                                            decoration: BoxDecoration(
                                              border: Border(
                                                bottom: BorderSide(
                                                  color: borderColor,
                                                  width: 0.8,
                                                ),
                                              ),
                                            ),
                                            children: const [
                                              Padding(
                                                padding: EdgeInsets.symmetric(
                                                  vertical: 14,
                                                ),
                                                child: Text(
                                                  'ROLL NUMBER',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    letterSpacing: 0.5,
                                                    color: Color(0xFF44474E),
                                                  ),
                                                ),
                                              ),
                                              Padding(
                                                padding: EdgeInsets.symmetric(
                                                  vertical: 14,
                                                ),
                                                child: Text(
                                                  'ADMISSION NUMBER',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    letterSpacing: 0.5,
                                                    color: Color(0xFF44474E),
                                                  ),
                                                ),
                                              ),
                                              Padding(
                                                padding: EdgeInsets.symmetric(
                                                  vertical: 14,
                                                ),
                                                child: Text(
                                                  'NAME',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    letterSpacing: 0.5,
                                                    color: Color(0xFF44474E),
                                                  ),
                                                ),
                                              ),
                                              Padding(
                                                padding: EdgeInsets.symmetric(
                                                  vertical: 14,
                                                ),
                                                child: Text(
                                                  'EMAIL',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    letterSpacing: 0.5,
                                                    color: Color(0xFF44474E),
                                                  ),
                                                ),
                                              ),
                                              Padding(
                                                padding: EdgeInsets.symmetric(
                                                  vertical: 14,
                                                ),
                                                child: Text(
                                                  'STATUS',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    letterSpacing: 0.5,
                                                    color: Color(0xFF44474E),
                                                  ),
                                                ),
                                              ),
                                              Padding(
                                                padding: EdgeInsets.symmetric(
                                                  vertical: 14,
                                                ),
                                                child: Align(
                                                  alignment: Alignment.centerRight,
                                                  child: Text(
                                                    'ACTIONS',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.bold,
                                                      letterSpacing: 0.5,
                                                      color: Color(0xFF44474E),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),

                                          // Body Rows
                                          for (int i = 0; i < filteredStudents.length; i++)
                                            _buildStudentRow(
                                              student: filteredStudents[i],
                                              borderColor: borderColor,
                                              isLast: i == filteredStudents.length - 1,
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  TableRow _buildStudentRow({
    required Student student,
    required Color borderColor,
    bool isLast = false,
  }) {
    return TableRow(
      decoration: BoxDecoration(
        border:
            isLast
                ? null
                : Border(
                  bottom: BorderSide(
                    color: const Color(0xFFE6E8EB),
                    width: 0.8,
                  ),
                ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            student.rollNumber,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            student.admissionNumber,
            style: const TextStyle(fontSize: 14),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            student.fullName,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            student.email ?? 'No login associated',
            style: const TextStyle(fontSize: 14, color: Color(0xFF44474E)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color:
                    student.isActive
                        ? const Color(0xFFD1FAE5)
                        : const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(9999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color:
                          student.isActive
                              ? const Color(0xFF10B981)
                              : const Color(0xFFEF4444),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    student.isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color:
                          student.isActive
                              ? const Color(0xFF047857)
                              : const Color(0xFFB91C1C),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                tooltip: 'Edit',
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: const EdgeInsets.all(4),
                onPressed: () => _showEditStudentDialog(student),
                icon: const Icon(
                  Icons.edit_outlined,
                  size: 18,
                  color: Color(0xFF44474E),
                ),
              ),
              IconButton(
                tooltip:
                    student.isActive
                        ? 'Deactivate account'
                        : 'Activate account',
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: const EdgeInsets.all(4),
                onPressed: () => _toggleStudentStatus(student),
                icon: Icon(
                  student.isActive ? Icons.toggle_on : Icons.toggle_off,
                  size: 24,
                  color:
                      student.isActive
                          ? const Color(0xFF10B981)
                          : Colors.grey.shade400,
                ),
              ),
              IconButton(
                tooltip: 'Delete',
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: const EdgeInsets.all(4),
                onPressed: () => _deleteStudent(student),
                icon: const Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: Color(0xFFEF4444),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ParsedStudentRow {
  final String rollNumber;
  final String admissionNumber;
  final String fullName;
  final String? email;

  const _ParsedStudentRow({
    required this.rollNumber,
    required this.admissionNumber,
    required this.fullName,
    this.email,
  });
}

class _CsvUploadDialog extends StatefulWidget {
  const _CsvUploadDialog({required this.classId, required this.onSuccess});

  final String classId;
  final VoidCallback onSuccess;

  @override
  State<_CsvUploadDialog> createState() => _CsvUploadDialogState();
}

class _CsvUploadDialogState extends State<_CsvUploadDialog> {
  final TextEditingController _csvController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  String? _selectedFileName;
  List<_ParsedStudentRow> _parsedStudents = [];
  bool _showTextPaste = false;
  int _importedCount = 0;

  @override
  void dispose() {
    _csvController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'xlsx', 'xls'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null) {
        setState(() => _error = 'Could not read file data. Please try again.');
        return;
      }

      final ext = file.name.split('.').last.toLowerCase();
      List<_ParsedStudentRow> parsed = [];

      if (ext == 'xlsx' || ext == 'xls') {
        parsed = _parseExcelBytes(bytes);
      } else {
        String text;
        try {
          text = utf8.decode(bytes);
        } catch (_) {
          text = String.fromCharCodes(bytes);
        }
        parsed = _parseCsvText(text);
      }

      setState(() {
        _selectedFileName = file.name;
        _parsedStudents = parsed;
        _csvController.clear();
        _error = parsed.isEmpty
            ? 'No valid student records found in "${file.name}". Required columns: Roll Number, Admission Number, Full Name'
            : null;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to open or parse file: ${e.toString()}';
      });
    }
  }

  List<_ParsedStudentRow> _parseCsvText(String text) {
    final cleanText = text.replaceAll('\uFEFF', '').trim();
    if (cleanText.isEmpty) return [];

    final lines = cleanText.split(RegExp(r'\r?\n'));
    if (lines.isEmpty) return [];

    int rollIdx = 0;
    int admIdx = 1;
    int nameIdx = 2;
    int emailIdx = 3;

    int startRow = 0;

    String cleanCell(String s) {
      var trimmed = s.trim();
      if ((trimmed.startsWith('"') && trimmed.endsWith('"')) ||
          (trimmed.startsWith("'") && trimmed.endsWith("'"))) {
        if (trimmed.length >= 2) {
          trimmed = trimmed.substring(1, trimmed.length - 1).trim();
        }
      }
      return trimmed;
    }

    final firstLineParts = lines.first
        .split(RegExp(r'[,;\t]'))
        .map(cleanCell)
        .toList();
    final firstLineLower = firstLineParts.map((p) => p.toLowerCase()).toList();

    bool hasHeader = firstLineLower.any((p) =>
        p.contains('roll') || p.contains('adm') || p.contains('name') || p.contains('student'));

    if (hasHeader) {
      startRow = 1;
      for (int i = 0; i < firstLineLower.length; i++) {
        final p = firstLineLower[i];
        if (p.contains('roll')) {
          rollIdx = i;
        } else if (p.contains('adm')) {
          admIdx = i;
        } else if (p.contains('name') || p.contains('student')) {
          nameIdx = i;
        } else if (p.contains('email') || p.contains('mail')) {
          emailIdx = i;
        }
      }
    }

    List<_ParsedStudentRow> result = [];
    for (int i = startRow; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      final parts = line
          .split(RegExp(r'[,;\t]'))
          .map(cleanCell)
          .toList();

      String getPart(int idx) {
        if (idx < 0 || idx >= parts.length) return '';
        return parts[idx];
      }

      final roll = getPart(rollIdx);
      final adm = getPart(admIdx);
      final name = getPart(nameIdx);
      final emailRaw = getPart(emailIdx);
      final email = (emailRaw.isNotEmpty && emailRaw.contains('@')) ? emailRaw : null;

      if (roll.isNotEmpty && adm.isNotEmpty && name.isNotEmpty) {
        result.add(_ParsedStudentRow(
          rollNumber: roll,
          admissionNumber: adm,
          fullName: name,
          email: email,
        ));
      }
    }
    return result;
  }

  List<_ParsedStudentRow> _parseExcelBytes(Uint8List bytes) {
    List<_ParsedStudentRow> result = [];
    try {
      final excel = Excel.decodeBytes(bytes);
      for (var table in excel.tables.keys) {
        final sheet = excel.tables[table];
        if (sheet == null || sheet.maxRows == 0) continue;

        int rollIdx = 0;
        int admIdx = 1;
        int nameIdx = 2;
        int emailIdx = 3;

        int startRow = 0;
        final firstRow = sheet.rows.first;
        final firstRowStrings = firstRow
            .map((c) => c?.value?.toString().trim().toLowerCase() ?? '')
            .toList();

        bool hasHeader = firstRowStrings.any((s) =>
            s.contains('roll') || s.contains('adm') || s.contains('name') || s.contains('student'));

        if (hasHeader) {
          startRow = 1;
          for (int i = 0; i < firstRowStrings.length; i++) {
            final s = firstRowStrings[i];
            if (s.contains('roll')) {
              rollIdx = i;
            } else if (s.contains('adm')) {
              admIdx = i;
            } else if (s.contains('name') || s.contains('student')) {
              nameIdx = i;
            } else if (s.contains('email') || s.contains('mail')) {
              emailIdx = i;
            }
          }
        }

        for (int r = startRow; r < sheet.rows.length; r++) {
          final row = sheet.rows[r];
          if (row.isEmpty) continue;

          String getCell(int idx) {
            if (idx < 0 || idx >= row.length) return '';
            final val = row[idx]?.value;
            if (val == null) return '';
            return val.toString().trim();
          }

          final roll = getCell(rollIdx);
          final adm = getCell(admIdx);
          final name = getCell(nameIdx);
          final emailRaw = getCell(emailIdx);
          final email = (emailRaw.isNotEmpty && emailRaw.contains('@')) ? emailRaw : null;

          if (roll.isNotEmpty && adm.isNotEmpty && name.isNotEmpty) {
            result.add(_ParsedStudentRow(
              rollNumber: roll,
              admissionNumber: adm,
              fullName: name,
              email: email,
            ));
          }
        }

        if (result.isNotEmpty) break;
      }
    } catch (e) {
      debugPrint('Excel decode error: $e');
    }
    return result;
  }

  void _onTextChanged(String val) {
    if (_selectedFileName != null) {
      setState(() => _selectedFileName = null);
    }
    final parsed = _parseCsvText(val);
    setState(() {
      _parsedStudents = parsed;
      _error = (val.trim().isNotEmpty && parsed.isEmpty)
          ? 'No valid student records found in pasted text'
          : null;
    });
  }

  void _importStudents() async {
    if (_parsedStudents.isEmpty) {
      setState(() => _error = 'Please select an Excel/CSV file or paste CSV content first.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _importedCount = 0;
    });

    try {
      final repo = context.read<StudentRepository>();
      int count = 0;

      for (final s in _parsedStudents) {
        final student = Student(
          id: '',
          rollNumber: s.rollNumber,
          admissionNumber: s.admissionNumber,
          fullName: s.fullName,
          classId: widget.classId,
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await repo.createStudent(student, email: s.email, password: s.admissionNumber);
        count++;
        if (mounted) {
          setState(() {
            _importedCount = count;
          });
        }
      }

      if (mounted) {
        widget.onSuccess();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully imported $count students!'),
            backgroundColor: const Color(0xFF047857),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF374151) : const Color(0xFFE2E8F0);

    return AlertDialog(
      backgroundColor: dialogBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.file_upload_outlined, color: Color(0xFF0F172A), size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Upload Students (CSV / Excel)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.9 < 600
              ? MediaQuery.of(context).size.width * 0.9
              : 600,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Upload an Excel (.xlsx, .xls) or CSV (.csv) file from your computer to bulk import students.',
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 16),

              if (_error != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.red, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // File Drop / Picker Card
              InkWell(
                onTap: _isLoading ? null : _pickFile,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _selectedFileName != null ? const Color(0xFF10B981) : borderColor,
                      width: _selectedFileName != null ? 1.5 : 1.0,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _selectedFileName != null
                            ? Icons.check_circle_outline
                            : Icons.folder_open_outlined,
                        size: 40,
                        color: _selectedFileName != null
                            ? const Color(0xFF10B981)
                            : const Color(0xFF0F172A),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _selectedFileName ?? 'Click to Open Folder & Pick File',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _selectedFileName != null
                              ? const Color(0xFF10B981)
                              : (isDark ? Colors.white : const Color(0xFF0F172A)),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _selectedFileName != null
                            ? '${_parsedStudents.length} valid student records ready to import'
                            : 'Supported formats: .csv, .xlsx, .xls',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 14),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F172A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        onPressed: _isLoading ? null : _pickFile,
                        icon: const Icon(Icons.drive_folder_upload, size: 18),
                        label: Text(_selectedFileName != null ? 'Change File' : 'Browse Folder'),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Preview Table if records found
              if (_parsedStudents.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Preview (${_parsedStudents.length} Students)',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Showing top ${_parsedStudents.length > 5 ? 5 : _parsedStudents.length}',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  constraints: const BoxConstraints(maxHeight: 180),
                  decoration: BoxDecoration(
                    border: Border.all(color: borderColor),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: SingleChildScrollView(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columnSpacing: 20,
                        horizontalMargin: 12,
                        headingRowHeight: 36,
                        dataRowMinHeight: 32,
                        dataRowMaxHeight: 36,
                        columns: const [
                          DataColumn(label: Text('Roll No', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Adm No', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Email', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                        ],
                        rows: _parsedStudents.take(5).map((s) {
                          return DataRow(
                            cells: [
                              DataCell(Text(s.rollNumber, style: const TextStyle(fontSize: 12))),
                              DataCell(Text(s.admissionNumber, style: const TextStyle(fontSize: 12))),
                              DataCell(Text(s.fullName, style: const TextStyle(fontSize: 12))),
                              DataCell(Text(s.email ?? '-', style: const TextStyle(fontSize: 12))),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Manual text paste fallback option
              InkWell(
                onTap: () => setState(() => _showTextPaste = !_showTextPaste),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                        _showTextPaste ? Icons.arrow_drop_down : Icons.arrow_right,
                        color: const Color(0xFF64748B),
                      ),
                      const Text(
                        'Or paste raw CSV text manually',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (_showTextPaste) ...[
                const SizedBox(height: 8),
                TextField(
                  controller: _csvController,
                  maxLines: 4,
                  onChanged: _onTextChanged,
                  style: const TextStyle(fontSize: 13),
                  decoration: const InputDecoration(
                    hintText:
                        'Format:\nRollNumber, AdmissionNumber, FullName, Email (Optional)\n1, ADM2026, Ameera, ameera@example.com',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(12),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0F172A),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          ),
          onPressed: (_isLoading || _parsedStudents.isEmpty) ? null : _importStudents,
          icon: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.file_upload, size: 18),
          label: Text(
            _isLoading
                ? 'Importing ($_importedCount/${_parsedStudents.length})...'
                : 'Import Students (${_parsedStudents.length})',
          ),
        ),
      ],
    );
  }
}

class _StudentFormDialog extends StatefulWidget {
  const _StudentFormDialog({
    this.student,
    required this.classId,
    required this.teacherId,
    required this.role,
    this.existingStudents,
    required this.onSave,
  });

  final Student? student;
  final String classId;
  final String teacherId;
  final String role;
  final List<Student>? existingStudents;
  final VoidCallback onSave;

  @override
  State<_StudentFormDialog> createState() => _StudentFormDialogState();
}

class _StudentFormDialogState extends State<_StudentFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _rollController;
  late TextEditingController _admissionController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _guardianNameController;
  late TextEditingController _guardianPhoneController;
  late TextEditingController _addressController;

  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final s = widget.student;
    _nameController = TextEditingController(text: s?.fullName ?? '');
    _rollController = TextEditingController(text: s?.rollNumber ?? '');
    _admissionController = TextEditingController(
      text: s?.admissionNumber ?? '',
    );
    _emailController = TextEditingController(text: s?.email ?? '');
    _phoneController = TextEditingController(text: s?.phone ?? '');
    _guardianNameController = TextEditingController(
      text: s?.guardianName ?? '',
    );
    _guardianPhoneController = TextEditingController(
      text: s?.guardianPhone ?? '',
    );
    _addressController = TextEditingController(text: s?.address ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _rollController.dispose();
    _admissionController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _guardianNameController.dispose();
    _guardianPhoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final adm = _admissionController.text.trim();
    final roll = _rollController.text.trim();
    final s = widget.student;

    if (widget.existingStudents != null) {
      final isAdmDuplicate = widget.existingStudents!.any(
        (st) => st.id != s?.id && st.admissionNumber.trim().toLowerCase() == adm.toLowerCase(),
      );
      if (isAdmDuplicate) {
        setState(() {
          _error = 'Admission number already exists';
          _isLoading = false;
        });
        return;
      }

      final isRollDuplicate = widget.existingStudents!.any(
        (st) => st.id != s?.id && st.classId == widget.classId && st.rollNumber.trim().toLowerCase() == roll.toLowerCase(),
      );
      if (isRollDuplicate) {
        setState(() {
          _error = 'Roll number already exists';
          _isLoading = false;
        });
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final s = widget.student;
      final repo = context.read<StudentRepository>();

      if (s == null) {
        final newStudent = Student(
          id: '',
          admissionNumber: _admissionController.text.trim(),
          rollNumber: _rollController.text.trim(),
          fullName: _nameController.text.trim(),
          classId: widget.classId,
          guardianName: _guardianNameController.text.trim(),
          guardianPhone: _guardianPhoneController.text.trim(),
          address: _addressController.text.trim(),
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final email = _emailController.text.trim();
        await repo.createStudent(
          newStudent,
          email: email.isNotEmpty ? email : null,
          password: _admissionController.text.trim(),
        );
      } else {
        final updatedStudent = Student(
          id: s.id,
          profileId: s.profileId,
          admissionNumber: _admissionController.text.trim(),
          rollNumber: _rollController.text.trim(),
          fullName: _nameController.text.trim(),
          classId: widget.classId,
          guardianName: _guardianNameController.text.trim(),
          guardianPhone: _guardianPhoneController.text.trim(),
          address: _addressController.text.trim(),
          photoPath: s.photoPath,
          isActive: s.isActive,
          createdAt: s.createdAt,
          updatedAt: DateTime.now(),
        );
        await repo.updateStudent(updatedStudent);
      }

      if (mounted) {
        widget.onSave();
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.student != null;

    return AlertDialog(
      title: Text(isEdit ? 'Edit Student Details' : 'Add Student to Class'),
      content: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.9 < 500 ? MediaQuery.of(context).size.width * 0.9 : 500),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.red.shade300),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error!,
                            style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Student Full Name',
                  ),
                  validator: (val) =>
                      val == null || val.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _rollController,
                        decoration: const InputDecoration(
                          labelText: 'Roll Number',
                        ),
                        validator: (val) => val == null || val.trim().isEmpty
                            ? 'Required'
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _admissionController,
                        decoration: const InputDecoration(
                          labelText: 'Admission Number',
                        ),
                        validator: (val) => val == null || val.trim().isEmpty
                            ? 'Required'
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (!isEdit) ...[
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Login Email (Optional)',
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                ],
                TextFormField(
                  controller: _guardianNameController,
                  decoration: const InputDecoration(labelText: 'Guardian Name'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _guardianPhoneController,
                  decoration: const InputDecoration(
                    labelText: 'Guardian Phone',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(labelText: 'Address'),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0F172A),
            foregroundColor: Colors.white,
          ),
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(isEdit ? 'Save Changes' : 'Create Student'),
        ),
      ],
    );
  }
}

