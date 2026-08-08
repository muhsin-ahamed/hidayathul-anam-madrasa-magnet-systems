// super_admin_classes_page.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/repository_interfaces.dart';
import '../../models/models.dart';
import '../../widgets/page_scaffold.dart';
import '../../widgets/portal_card.dart';
import '../../widgets/section_title.dart';
import '../../widgets/status_badge.dart';

class SuperAdminClassesPage extends StatefulWidget {
  const SuperAdminClassesPage({super.key});

  @override
  State<SuperAdminClassesPage> createState() => _SuperAdminClassesPageState();
}

class _SuperAdminClassesPageState extends State<SuperAdminClassesPage> {
  bool _isLoading = true;
  String? _error;

  List<ClassInfo> _classes = [];
  List<Teacher> _teachers = [];
  List<Student> _students = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final classRepo = context.read<ClassRepository>();
      final teacherRepo = context.read<TeacherRepository>();
      final studentRepo = context.read<StudentRepository>();

      final data = await Future.wait([
        classRepo.getAllClasses(),
        teacherRepo.getAllTeachers(),
        studentRepo.getAllStudents(),
      ]);

      setState(() {
        _classes = data[0] as List<ClassInfo>;
        _teachers = data[1] as List<Teacher>;
        _students = data[2] as List<Student>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _getTeacherName(ClassInfo cls) {
    if (cls.classTeacherName != null && cls.classTeacherName!.trim().isNotEmpty) {
      return cls.classTeacherName!;
    }
    if (cls.classTeacherId != null && cls.classTeacherId!.trim().isNotEmpty) {
      final t = _teachers.cast<Teacher?>().firstWhere(
            (t) => t?.profileId == cls.classTeacherId || t?.id == cls.classTeacherId,
            orElse: () => null,
          );
      if (t != null) return t.fullName;
    }
    final t = _teachers.cast<Teacher?>().firstWhere(
          (t) =>
              t?.assignedClassId == cls.id ||
              t?.assignedClassName == cls.displayName ||
              t?.assignedClassName == cls.className ||
              (cls.section != null && t?.assignedClassName == '${cls.className} - ${cls.section}'),
          orElse: () => null,
        );
    if (t != null) return t.fullName;

    return 'None Assigned';
  }

  int _getStudentCount(ClassInfo cls) {
    final countFromStudents = _students.where((s) {
      if (s.classId == cls.id) return true;
      if (s.className == cls.displayName || s.className == cls.className) return true;
      final clsNum = cls.className.replaceAll(RegExp(r'[^0-9]'), '');
      final sNum = s.className?.replaceAll(RegExp(r'[^0-9]'), '') ??
          s.classId.replaceAll(RegExp(r'[^0-9]'), '');
      if (clsNum.isNotEmpty && clsNum == sNum) return true;
      return false;
    }).length;

    if (countFromStudents > 0) return countFromStudents;
    return cls.studentCount ?? 0;
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (context) => _ClassEditDialog(
        teachers: _teachers,
        onSave: () {
          _loadData();
          context.read<ActivityLogRepository>().logActivity(
            action: 'Class Created',
            entityType: 'class',
            description: 'Created a new class level record',
          );
        },
      ),
    );
  }

  void _showEditDialog(ClassInfo classInfo) {
    showDialog(
      context: context,
      builder: (context) => _ClassEditDialog(
        classInfo: classInfo,
        teachers: _teachers,
        onSave: () {
          _loadData();
          context.read<ActivityLogRepository>().logActivity(
            action: 'Class Updated',
            entityType: 'class',
            entityId: classInfo.id,
            description: 'Updated settings for class ${classInfo.displayName}',
          );
        },
      ),
    );
  }

  void _toggleStatus(ClassInfo classInfo) async {
    final repo = context.read<ClassRepository>();
    final logRepo = context.read<ActivityLogRepository>();
    setState(() => _isLoading = true);
    try {
      if (classInfo.isActive) {
        await repo.deactivateClass(classInfo.id);
      } else {
        // Activate via update
        final updated = ClassInfo(
          id: classInfo.id,
          className: classInfo.className,
          section: classInfo.section,
          academicYear: classInfo.academicYear,
          classTeacherId: classInfo.classTeacherId,
          isActive: true,
          createdAt: classInfo.createdAt,
          updatedAt: DateTime.now(),
        );
        await repo.updateClass(updated);
      }
      await logRepo.logActivity(
        action: classInfo.isActive ? 'Deactivated Class' : 'Activated Class',
        entityType: 'class',
        entityId: classInfo.id,
        description:
            '${classInfo.isActive ? 'Deactivated' : 'Activated'} class level ${classInfo.displayName}',
      );
      _loadData();
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
              Text('Error: $_error'),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PageScaffold(
      title: 'Classrooms Management',
      trailing: FilledButton.icon(
        onPressed: _showAddDialog,
        icon: const Icon(Icons.add_home_outlined),
        label: const Text('Add Class'),
      ),
      children: [
        PortalCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionTitle(title: 'Active Classrooms'),
              const SizedBox(height: 14),
              if (_classes.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40.0),
                  child: Center(child: Text('No class records configured')),
                )
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    final minTableWidth = math.max(constraints.maxWidth, 800.0);
                    final dynamicColumnSpacing = constraints.maxWidth > 800
                        ? math.max(28.0, 28.0 + (constraints.maxWidth - 800) / 6)
                        : 28.0;
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minWidth: minTableWidth),
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.resolveWith(
                            (states) => isDark
                                ? const Color(0xFF1E293B)
                                : const Color(0xFFF4F6FB),
                          ),
                          headingTextStyle: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF475569),
                            fontSize: 13,
                            letterSpacing: 0.2,
                          ),
                          columnSpacing: dynamicColumnSpacing,
                          horizontalMargin: 20,
                          dataRowMinHeight: 48,
                          dataRowMaxHeight: 56,
                          columns: const [
                            DataColumn(label: Text('Class Name')),
                            DataColumn(label: Text('Section')),
                            DataColumn(label: Text('Academic Year')),
                            DataColumn(label: Text('Class Teacher')),
                            DataColumn(label: Text('Students Count')),
                            DataColumn(label: Text('Status')),
                            DataColumn(label: Text('Actions')),
                          ],
                          rows: [
                            for (final cls in _classes)
                              DataRow(
                                cells: [
                                  DataCell(Text(cls.className)),
                                  DataCell(Text(cls.section ?? 'N/A')),
                                  DataCell(Text(cls.academicYear)),
                                  DataCell(
                                    Text(_getTeacherName(cls)),
                                  ),
                                  DataCell(
                                    Text('${_getStudentCount(cls)} Students'),
                                  ),
                                  DataCell(
                                    StatusBadge(
                                      label: cls.isActive ? 'Active' : 'Inactive',
                                      color: cls.isActive
                                          ? const Color(0xFF059669)
                                          : const Color(0xFFDC2626),
                                    ),
                                  ),
                                  DataCell(
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          tooltip: 'Edit classroom configurations',
                                          onPressed: () => _showEditDialog(cls),
                                          icon: const Icon(Icons.edit_outlined),
                                        ),
                                        IconButton(
                                          tooltip: cls.isActive
                                              ? 'Deactivate class'
                                              : 'Activate class',
                                          onPressed: () => _toggleStatus(cls),
                                          icon: Icon(
                                            cls.isActive
                                                ? Icons.toggle_on
                                                : Icons.toggle_off,
                                            color: cls.isActive
                                                ? const Color(0xFF059669)
                                                : Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ClassEditDialog extends StatefulWidget {
  const _ClassEditDialog({
    this.classInfo,
    required this.teachers,
    required this.onSave,
  });

  final ClassInfo? classInfo;
  final List<Teacher> teachers;
  final VoidCallback onSave;

  @override
  State<_ClassEditDialog> createState() => _ClassEditDialogState();
}

class _ClassEditDialogState extends State<_ClassEditDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _sectionController;
  late TextEditingController _yearController;

  String? _selectedTeacherId;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final c = widget.classInfo;
    _nameController = TextEditingController(text: c?.className ?? '');
    _sectionController = TextEditingController(text: c?.section ?? '');
    _yearController = TextEditingController(
      text: c?.academicYear ?? '2026-2027',
    );

    _selectedTeacherId = c?.classTeacherId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _sectionController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final c = widget.classInfo;
      final repo = context.read<ClassRepository>();

      final selectedTeacher = widget.teachers.cast<Teacher?>().firstWhere(
            (t) => t?.profileId == _selectedTeacherId || t?.id == _selectedTeacherId,
            orElse: () => null,
          );

      if (c == null) {
        final newClass = ClassInfo(
          id: '',
          className: _nameController.text.trim(),
          section: _sectionController.text.trim().isEmpty
              ? null
              : _sectionController.text.trim(),
          academicYear: _yearController.text.trim(),
          classTeacherId: _selectedTeacherId,
          classTeacherName: selectedTeacher?.fullName,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await repo.createClass(newClass);
      } else {
        final updatedClass = ClassInfo(
          id: c.id,
          className: _nameController.text.trim(),
          section: _sectionController.text.trim().isEmpty
              ? null
              : _sectionController.text.trim(),
          academicYear: _yearController.text.trim(),
          classTeacherId: _selectedTeacherId,
          classTeacherName: selectedTeacher?.fullName,
          studentCount: c.studentCount,
          isActive: c.isActive,
          createdAt: c.createdAt,
          updatedAt: DateTime.now(),
        );
        await repo.updateClass(updatedClass);
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
    final isEdit = widget.classInfo != null;

    return AlertDialog(
      title: Text(isEdit ? 'Edit Class Details' : 'Create New Class'),
      content: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.9 < 440 ? MediaQuery.of(context).size.width * 0.9 : 440),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_error != null) ...[
                Text(_error!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 12),
              ],
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Class Name (e.g. Class 10)',
                ),
                validator: (val) =>
                    val == null || val.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _sectionController,
                decoration: const InputDecoration(
                  labelText: 'Section (e.g. A)',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _yearController,
                decoration: const InputDecoration(labelText: 'Academic Year'),
                validator: (val) =>
                    val == null || val.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: (_selectedTeacherId != null && widget.teachers.any((t) => t.profileId == _selectedTeacherId)) ? _selectedTeacherId : null,
                decoration: const InputDecoration(
                  labelText: 'Assign Class Teacher',
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('No assigned teacher'),
                  ),
                  for (final teacher in widget.teachers)
                    DropdownMenuItem(
                      value: teacher.profileId,
                      child: Text(teacher.fullName),
                    ),
                ],
                onChanged: (val) => setState(() => _selectedTeacherId = val),
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
        FilledButton(
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
              : Text(isEdit ? 'Save Changes' : 'Create Class'),
        ),
      ],
    );
  }
}
