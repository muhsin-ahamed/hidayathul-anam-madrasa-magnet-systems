// super_admin_students_page.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/repository_interfaces.dart';
import '../../models/models.dart';
import '../../widgets/page_scaffold.dart';
import '../../widgets/portal_card.dart';
import '../../widgets/status_badge.dart';

class SuperAdminStudentsPage extends StatefulWidget {
  const SuperAdminStudentsPage({super.key});

  @override
  State<SuperAdminStudentsPage> createState() => _SuperAdminStudentsPageState();
}

class _SuperAdminStudentsPageState extends State<SuperAdminStudentsPage> {
  bool _isLoading = true;
  String? _error;

  List<Student> _students = [];
  List<ClassInfo> _classes = [];

  String _query = '';
  String _selectedClassId = 'All';
  String _statusFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final studentRepo = context.read<StudentRepository>();
      final classRepo = context.read<ClassRepository>();

      final data = await Future.wait([
        studentRepo.getAllStudents(),
        classRepo.getAllClasses(),
      ]);

      setState(() {
        _students = data[0] as List<Student>;
        _classes = data[1] as List<ClassInfo>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (context) => _StudentEditDialog(
        classes: _classes,
        existingStudents: _students,
        onSave: () {
          _loadData();
          context.read<ActivityLogRepository>().logActivity(
            action: 'Student Account Created',
            entityType: 'student',
            description: 'Created a new student record',
          );
        },
      ),
    );
  }

  void _showEditDialog(Student student) {
    showDialog(
      context: context,
      builder: (context) => _StudentEditDialog(
        student: student,
        classes: _classes,
        existingStudents: _students,
        onSave: () {
          _loadData();
          context.read<ActivityLogRepository>().logActivity(
            action: 'Student Details Updated',
            entityType: 'student',
            entityId: student.id,
            description: 'Updated details for student ${student.fullName}',
          );
        },
      ),
    );
  }

  void _showTransferDialog(Student student) {
    showDialog(
      context: context,
      builder: (context) => _TransferDialog(
        student: student,
        classes: _classes,
        onSave: () {
          _loadData();
          context.read<ActivityLogRepository>().logActivity(
            action: 'Student Transferred',
            entityType: 'student',
            entityId: student.id,
            description: 'Transferred ${student.fullName} to another class',
          );
        },
      ),
    );
  }

  void _toggleStatus(Student student) async {
    setState(() => _isLoading = true);
    // Capture repos before any await to avoid use_build_context_synchronously
    final repo = context.read<StudentRepository>();
    final logRepo = context.read<ActivityLogRepository>();
    try {
      if (student.isActive) {
        await repo.deactivateStudent(student.id);
      } else {
        // Activate
        final updated = Student(
          id: student.id,
          profileId: student.profileId,
          admissionNumber: student.admissionNumber,
          rollNumber: student.rollNumber,
          fullName: student.fullName,
          classId: student.classId,
          dateOfBirth: student.dateOfBirth,
          gender: student.gender,
          guardianName: student.guardianName,
          guardianPhone: student.guardianPhone,
          address: student.address,
          photoPath: student.photoPath,
          isActive: true,
          createdAt: student.createdAt,
          updatedAt: DateTime.now(),
          className: student.className,
          email: student.email,
          phone: student.phone,
        );
        await repo.updateStudent(updated);
      }
      await logRepo.logActivity(
        action: student.isActive ? 'Deactivated Student' : 'Activated Student',
        entityType: 'student',
        entityId: student.id,
        description:
            '${student.isActive ? 'Deactivated' : 'Activated'} student ${student.fullName}',
      );
      if (!mounted) return;
      _loadData();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  void _showDeleteDialog(Student student) {
    showDialog(
      context: context,
      builder: (context) => _DeleteStudentDialog(
        student: student,
        onDeleteSuccess: () {
          _loadData();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Student ${student.fullName} permanently deleted successfully'),
              backgroundColor: const Color(0xFF059669),
            ),
          );
        },
      ),
    );
  }


  String _getStudentClassName(Student student) {
    if (student.className != null &&
        student.className!.isNotEmpty &&
        student.className != 'Class') {
      return student.className!;
    }
    for (final cls in _classes) {
      if (cls.id == student.classId) {
        return cls.displayName;
      }
    }
    return 'N/A';
  }

  void _showDetailsDialog(Student student) async {
    showDialog(
      context: context,
      builder: (context) => _StudentDetailDialog(
        student: student,
        displayClassName: _getStudentClassName(student),
      ),
    );
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
              Text('Error loading students: $_error'),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final filteredStudents = _students.where((student) {
      final matchesSearch =
          _query.trim().isEmpty ||
          student.fullName.toLowerCase().contains(_query.toLowerCase()) ||
          student.rollNumber.toLowerCase().contains(_query.toLowerCase()) ||
          student.admissionNumber.toLowerCase().contains(
            _query.toLowerCase(),
          ) ||
          (student.email?.toLowerCase().contains(_query.toLowerCase()) ??
              false);
      final matchesClass =
          _selectedClassId == 'All' || student.classId == _selectedClassId;
      final matchesStatus =
          _statusFilter == 'All' ||
          (_statusFilter == 'Active' && student.isActive) ||
          (_statusFilter == 'Inactive' && !student.isActive);
      return matchesSearch && matchesClass && matchesStatus;
    }).toList();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PageScaffold(
      title: 'Students Register',
      trailing: FilledButton.icon(
        onPressed: _showAddDialog,
        icon: const Icon(Icons.person_add_alt_outlined),
        label: const Text('Add Student'),
      ),
      children: [
        PortalCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  SizedBox(
                    width: 320,
                    child: TextField(
                      onChanged: (val) => setState(() => _query = val),
                      decoration: const InputDecoration(
                        labelText: 'Search by Name/Roll/Admission',
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 220,
                    child: DropdownButtonFormField<String>(
                      initialValue: (_selectedClassId != 'All' && !_classes.any((c) => c.id == _selectedClassId)) ? 'All' : _selectedClassId,
                      decoration: const InputDecoration(
                        labelText: 'Class Filter',
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: 'All',
                          child: Text('All Classes'),
                        ),
                        for (final cls in _classes)
                          DropdownMenuItem(
                            value: cls.id,
                            child: Text(cls.displayName),
                          ),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedClassId = val);
                      },
                    ),
                  ),
                  SizedBox(
                    width: 160,
                    child: DropdownButtonFormField<String>(
                      initialValue: _statusFilter,
                      decoration: const InputDecoration(
                        labelText: 'Status Filter',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'All',
                          child: Text('All Status'),
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
                        if (val != null) setState(() => _statusFilter = val);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (filteredStudents.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40.0),
                  child: Center(child: Text('No students matched your search')),
                )
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    final minTableWidth = math.max(constraints.maxWidth, 950.0);
                    final dynamicColumnSpacing = constraints.maxWidth > 950
                        ? math.max(28.0, 28.0 + (constraints.maxWidth - 950) / 5)
                        : 28.0;
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minWidth: minTableWidth),
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.resolveWith(
                            (states) => isDark ? const Color(0xFF1E293B) : const Color(0xFFF4F6FB),
                          ),
                          headingTextStyle: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                            fontSize: 13,
                            letterSpacing: 0.2,
                          ),
                          columnSpacing: dynamicColumnSpacing,
                          horizontalMargin: 20,
                          dataRowMinHeight: 48,
                          dataRowMaxHeight: 56,
                          columns: const [
                            DataColumn(label: Text('Roll No')),
                            DataColumn(label: Text('Admission No')),
                            DataColumn(label: Text('Name')),
                            DataColumn(label: Text('Class')),
                            DataColumn(label: Text('Status')),
                            DataColumn(label: Text('Actions')),
                          ],
                          rows: [
                        for (final student in filteredStudents)
                          DataRow(
                            cells: [
                              DataCell(Text(student.rollNumber)),
                              DataCell(Text(student.admissionNumber)),
                              DataCell(Text(student.fullName, style: const TextStyle(fontWeight: FontWeight.w500))),
                              DataCell(Text(_getStudentClassName(student))),
                              DataCell(
                                StatusBadge(
                                  label: student.isActive
                                      ? 'Active'
                                      : 'Inactive',
                                  color: student.isActive
                                      ? const Color(0xFF059669)
                                      : const Color(0xFFDC2626),
                                ),
                              ),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      tooltip: 'View detail card',
                                      iconSize: 20,
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () =>
                                          _showDetailsDialog(student),
                                      icon: const Icon(
                                        Icons.visibility_outlined,
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Edit student details',
                                      iconSize: 20,
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () => _showEditDialog(student),
                                      icon: const Icon(Icons.edit_outlined),
                                    ),
                                    IconButton(
                                      tooltip: 'Transfer student class',
                                      iconSize: 20,
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () =>
                                          _showTransferDialog(student),
                                      icon: const Icon(Icons.move_up_outlined),
                                    ),
                                    IconButton(
                                      tooltip: student.isActive
                                          ? 'Deactivate student'
                                          : 'Activate student',
                                      iconSize: 24,
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () => _toggleStatus(student),
                                      icon: Icon(
                                        student.isActive
                                            ? Icons.toggle_on
                                            : Icons.toggle_off,
                                        color: student.isActive
                                            ? const Color(0xFF059669)
                                            : Colors.grey,
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Delete student permanently',
                                      iconSize: 20,
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () =>
                                          _showDeleteDialog(student),
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: Colors.red,
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

class _StudentEditDialog extends StatefulWidget {
  const _StudentEditDialog({
    this.student,
    required this.classes,
    this.existingStudents,
    required this.onSave,
  });

  final Student? student;
  final List<ClassInfo> classes;
  final List<Student>? existingStudents;
  final VoidCallback onSave;

  @override
  State<_StudentEditDialog> createState() => _StudentEditDialogState();
}

class _StudentEditDialogState extends State<_StudentEditDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _rollController;
  late TextEditingController _admissionController;
  late TextEditingController _emailController;
  late TextEditingController _guardianNameController;
  late TextEditingController _guardianPhoneController;
  late TextEditingController _addressController;

  String? _selectedClassId;
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
    _guardianNameController = TextEditingController(
      text: s?.guardianName ?? '',
    );
    _guardianPhoneController = TextEditingController(
      text: s?.guardianPhone ?? '',
    );
    _addressController = TextEditingController(text: s?.address ?? '');

    _selectedClassId =
        s?.classId ??
        (widget.classes.isNotEmpty ? widget.classes.first.id : null);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _rollController.dispose();
    _admissionController.dispose();
    _emailController.dispose();
    _guardianNameController.dispose();
    _guardianPhoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate() || _selectedClassId == null) return;

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
        (st) => st.id != s?.id && st.classId == _selectedClassId && st.rollNumber.trim().toLowerCase() == roll.toLowerCase(),
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

      if (_selectedClassId == null || _selectedClassId!.isEmpty) {
        throw Exception('Student must be assigned to a class.');
      }

      if (s == null) {
        final newStudent = Student(
          id: '',
          admissionNumber: _admissionController.text.trim(),
          rollNumber: _rollController.text.trim(),
          fullName: _nameController.text.trim(),
          classId: _selectedClassId!,
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

        if (!mounted) return;
        Navigator.of(context).pop();
        widget.onSave();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Student created successfully'),
            backgroundColor: Color(0xFF059669),
          ),
        );
      } else {
        final updatedStudent = Student(
          id: s.id,
          profileId: s.profileId,
          admissionNumber: _admissionController.text.trim(),
          rollNumber: _rollController.text.trim(),
          fullName: _nameController.text.trim(),
          classId: _selectedClassId!,
          guardianName: _guardianNameController.text.trim(),
          guardianPhone: _guardianPhoneController.text.trim(),
          address: _addressController.text.trim(),
          photoPath: s.photoPath,
          isActive: s.isActive,
          createdAt: s.createdAt,
          updatedAt: DateTime.now(),
        );
        await repo.updateStudent(updatedStudent);

        if (!mounted) return;
        Navigator.of(context).pop();
        widget.onSave();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Student updated successfully'),
            backgroundColor: Color(0xFF059669),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
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
      title: Text(isEdit ? 'Edit Student Details' : 'Add New Student'),
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
                DropdownButtonFormField<String>(
                  initialValue: (_selectedClassId != null && widget.classes.any((c) => c.id == _selectedClassId)) ? _selectedClassId : null,
                  decoration: const InputDecoration(
                    labelText: 'Class Assignment',
                  ),
                  items: [
                    for (final cls in widget.classes)
                      DropdownMenuItem<String>(
                        value: cls.id,
                        child: Text(cls.displayName),
                      ),
                  ],
                  onChanged: (val) => setState(() => _selectedClassId = val),
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Student must be assigned to a class.' : null,
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
              : Text(isEdit ? 'Save Changes' : 'Create Student'),
        ),
      ],
    );
  }
}

class _TransferDialog extends StatefulWidget {
  const _TransferDialog({
    required this.student,
    required this.classes,
    required this.onSave,
  });

  final Student student;
  final List<ClassInfo> classes;
  final VoidCallback onSave;

  @override
  State<_TransferDialog> createState() => _TransferDialogState();
}

class _TransferDialogState extends State<_TransferDialog> {
  String? _targetClassId;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _targetClassId = widget.student.classId;
  }

  void _submit() async {
    if (_targetClassId == null || _targetClassId == widget.student.classId) {
      Navigator.pop(context);
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repo = context.read<StudentRepository>();
      await repo.transferStudent(widget.student.id, _targetClassId!);
      if (mounted) {
        widget.onSave();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Student transferred successfully')),
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String get _currentClassName {
    if (widget.student.className != null &&
        widget.student.className!.isNotEmpty &&
        widget.student.className != 'Class') {
      return widget.student.className!;
    }
    for (final cls in widget.classes) {
      if (cls.id == widget.student.classId) {
        return cls.displayName;
      }
    }
    return 'Unknown';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Transfer: ${widget.student.fullName}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_error != null) ...[
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 8),
          ],
          Text('Current class: $_currentClassName'),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: (_targetClassId != null && widget.classes.any((c) => c.id == _targetClassId)) ? _targetClassId : null,
            decoration: const InputDecoration(labelText: 'Target Class'),
            items: [
              for (final cls in widget.classes)
                DropdownMenuItem(value: cls.id, child: Text(cls.displayName)),
            ],
            onChanged: (val) => setState(() => _targetClassId = val),
          ),
        ],
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
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Transfer'),
        ),
      ],
    );
  }
}

class _StudentDetailDialog extends StatelessWidget {
  const _StudentDetailDialog({required this.student, this.displayClassName});

  final Student student;
  final String? displayClassName;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Details: ${student.fullName}'),
      content: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.9 < 440 ? MediaQuery.of(context).size.width * 0.9 : 440),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('Name'),
                subtitle: Text(student.fullName),
              ),
              ListTile(
                leading: const Icon(Icons.class_outlined),
                title: const Text('Class Assignment'),
                subtitle: Text(displayClassName ?? student.className ?? 'N/A'),
              ),
              ListTile(
                leading: const Icon(Icons.numbers_outlined),
                title: const Text('Roll Number'),
                subtitle: Text(student.rollNumber),
              ),
              ListTile(
                leading: const Icon(Icons.badge_outlined),
                title: const Text('Admission Number'),
                subtitle: Text(student.admissionNumber),
              ),
              ListTile(
                leading: const Icon(Icons.mail_outline),
                title: const Text('Login Email'),
                subtitle: Text(student.email ?? 'No login associated'),
              ),
              ListTile(
                leading: const Icon(Icons.family_restroom_outlined),
                title: const Text('Guardian Details'),
                subtitle: Text(
                  '${student.guardianName ?? "N/A"} (${student.guardianPhone ?? "N/A"})',
                ),
              ),
              ListTile(
                leading: const Icon(Icons.home_outlined),
                title: const Text('Address'),
                subtitle: Text(student.address ?? 'N/A'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _DeleteStudentDialog extends StatefulWidget {
  final Student student;
  final VoidCallback onDeleteSuccess;

  const _DeleteStudentDialog({
    required this.student,
    required this.onDeleteSuccess,
  });

  @override
  State<_DeleteStudentDialog> createState() => _DeleteStudentDialogState();
}

class _DeleteStudentDialogState extends State<_DeleteStudentDialog> {
  bool _isLoading = false;

  void _submit() async {
    setState(() => _isLoading = true);

    try {
      final repo = context.read<StudentRepository>();
      await repo.deleteStudent(widget.student.id);

      if (mounted) {
        Navigator.pop(context); // Close dialog
        widget.onDeleteSuccess();
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close dialog anyway
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to delete student: ${e.toString().replaceAll('Exception: ', '')}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Delete Student Permanently'),
      content: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.9 < 400 ? MediaQuery.of(context).size.width * 0.9 : 400),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Are you sure you want to permanently delete ${widget.student.fullName}?\n\n'
              'This will permanently remove the student profile, the student record, and the login authentication account.\n\n'
              'This action cannot be undone.',
              style: const TextStyle(height: 1.4),
            ),
          ],
        ),
      ),
    ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Colors.red,
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
              : const Text('Permanently Delete'),
        ),
      ],
    );
  }
}
