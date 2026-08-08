// super_admin_teachers_page.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/repositories/repository_interfaces.dart';
import '../../models/models.dart';
import '../../widgets/page_scaffold.dart';
import '../../widgets/portal_card.dart';
import '../../widgets/status_badge.dart';

class SuperAdminTeachersPage extends StatefulWidget {
  const SuperAdminTeachersPage({super.key});

  @override
  State<SuperAdminTeachersPage> createState() => _SuperAdminTeachersPageState();
}

class _SuperAdminTeachersPageState extends State<SuperAdminTeachersPage> {
  bool _isLoading = true;


  List<Teacher> _teachers = [];
  List<ClassInfo> _classes = [];
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final teacherRepo = context.read<TeacherRepository>();
      final classRepo = context.read<ClassRepository>();

      final data = await Future.wait([
        teacherRepo.getAllTeachers(),
        classRepo.getAllClasses(),
      ]);

      setState(() {
        _teachers = data[0] as List<Teacher>;
        _classes = data[1] as List<ClassInfo>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (context) => _TeacherEditDialog(
        classes: _classes,
        onSave: () {
          _loadData();
          context.read<ActivityLogRepository>().logActivity(
            action: 'Teacher Account Created',
            entityType: 'teacher',
            description: 'Created a new teacher record via Edge Function',
          );
        },
      ),
    );
  }

  void _showEditDialog(Teacher teacher) {
    showDialog(
      context: context,
      builder: (context) => _TeacherEditDialog(
        teacher: teacher,
        classes: _classes,
        onSave: () {
          _loadData();
          context.read<ActivityLogRepository>().logActivity(
            action: 'Teacher Details Updated',
            entityType: 'teacher',
            entityId: teacher.id,
            description: 'Updated details for teacher ${teacher.fullName}',
          );
        },
      ),
    );
  }

  void _toggleStatus(Teacher teacher) async {
    setState(() => _isLoading = true);
    // Capture repos before any await to avoid use_build_context_synchronously
    final profileRepo = context.read<ProfileRepository>();
    final logRepo = context.read<ActivityLogRepository>();
    try {
      if (teacher.isActive) {
        await profileRepo.deactivateUser(teacher.profileId);
      } else {
        // Activate via profiles update
        final profile = await profileRepo.getProfile(teacher.profileId);
        final updated = Profile(
          id: profile.id,
          fullName: profile.fullName,
          email: profile.email,
          phone: profile.phone,
          role: profile.role,
          isActive: true,
          createdAt: profile.createdAt,
          updatedAt: DateTime.now(),
        );
        await profileRepo.updateProfile(updated);
      }
      await logRepo.logActivity(
        action: teacher.isActive ? 'Deactivated Teacher' : 'Activated Teacher',
        entityType: 'teacher',
        entityId: teacher.id,
        description:
            '${teacher.isActive ? 'Deactivated' : 'Activated'} teacher account for ${teacher.fullName}',
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

  void _showDeleteDialog(Teacher teacher) {
    showDialog(
      context: context,
      builder: (context) => _DeleteTeacherDialog(
        teacher: teacher,
        onDeleteSuccess: () {
          _loadData();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Teacher ${teacher.fullName} permanently deleted successfully'),
              backgroundColor: const Color(0xFF059669),
            ),
          );
        },
      ),
    );
  }


  String _getTeacherDisplayName(Teacher teacher) {
    if (teacher.fullName.trim().isNotEmpty) {
      return teacher.fullName.trim();
    }
    if (teacher.username != null && teacher.username!.trim().isNotEmpty) {
      return teacher.username!.trim();
    }
    return 'N/A';
  }

  String _getAssignedClassName(Teacher teacher) {
    if (teacher.assignedClassName != null && teacher.assignedClassName!.trim().isNotEmpty) {
      return teacher.assignedClassName!.trim();
    }
    if (teacher.assignedClassId != null) {
      for (final c in _classes) {
        if (c.id == teacher.assignedClassId) return c.displayName;
      }
    }
    for (final c in _classes) {
      if (c.classTeacherId == teacher.profileId) return c.displayName;
    }
    return 'N/A';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final filteredTeachers = _teachers.where((teacher) {
      final matchesSearch =
          _query.trim().isEmpty ||
          teacher.fullName.toLowerCase().contains(_query.toLowerCase()) ||
          (teacher.email?.toLowerCase().contains(_query.toLowerCase()) ??
              false);
      return matchesSearch;
    }).toList();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PageScaffold(
      title: 'Teachers Management',
      trailing: FilledButton.icon(
        onPressed: _showAddDialog,
        icon: const Icon(Icons.person_add_alt_outlined),
        label: const Text('Add Teacher'),
      ),
      children: [
        PortalCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: double.infinity,
                child: TextField(
                  onChanged: (val) => setState(() => _query = val),
                  decoration: const InputDecoration(
                    labelText: 'Search teachers by name or email',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (filteredTeachers.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40.0),
                  child: Center(child: Text('No teachers found')),
                )
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    final minTableWidth = math.max(constraints.maxWidth, 800.0);
                    final dynamicColumnSpacing = constraints.maxWidth > 800
                        ? math.max(28.0, 28.0 + (constraints.maxWidth - 800) / 5)
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
                            DataColumn(label: Text('Name')),
                            DataColumn(label: Text('Email')),
                            DataColumn(label: Text('Assigned Class')),
                            DataColumn(label: Text('Status')),
                            DataColumn(label: Text('Actions')),
                          ],
                          rows: [
                            for (final teacher in filteredTeachers)
                              DataRow(
                                cells: [
                                  DataCell(Text(_getTeacherDisplayName(teacher))),
                                  DataCell(Text(teacher.email ?? 'N/A')),
                                  DataCell(
                                    Text(_getAssignedClassName(teacher)),
                                  ),
                                  DataCell(
                                    StatusBadge(
                                      label: teacher.isActive
                                          ? 'Active'
                                          : 'Inactive',
                                      color: teacher.isActive
                                          ? const Color(0xFF059669)
                                          : const Color(0xFFDC2626),
                                    ),
                                  ),
                                  DataCell(
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          tooltip: 'Edit details',
                                          onPressed: () => _showEditDialog(teacher),
                                          icon: const Icon(Icons.edit_outlined),
                                        ),
                                        IconButton(
                                          tooltip: teacher.isActive
                                              ? 'Deactivate teacher'
                                              : 'Activate teacher',
                                          onPressed: () => _toggleStatus(teacher),
                                          icon: Icon(
                                            teacher.isActive
                                                ? Icons.toggle_on
                                                : Icons.toggle_off,
                                            color: teacher.isActive
                                                ? const Color(0xFF059669)
                                                : Colors.grey,
                                          ),
                                        ),
                                        IconButton(
                                          tooltip: 'Delete teacher permanently',
                                          onPressed: () => _showDeleteDialog(teacher),
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

class _TeacherEditDialog extends StatefulWidget {
  const _TeacherEditDialog({
    this.teacher,
    required this.classes,
    required this.onSave,
  });

  final Teacher? teacher;
  final List<ClassInfo> classes;
  final VoidCallback onSave;

  @override
  State<_TeacherEditDialog> createState() => _TeacherEditDialogState();
}

class _TeacherEditDialogState extends State<_TeacherEditDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _passwordController;

  String? _selectedClassId;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final t = widget.teacher;
    _nameController = TextEditingController(text: t?.fullName ?? '');
    _emailController = TextEditingController(text: t?.email ?? '');
    _phoneController = TextEditingController(text: t?.phone ?? '');
    _passwordController = TextEditingController(text: 'Nizar@123');

    // Class options
    _selectedClassId = t?.assignedClassId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final t = widget.teacher;
      // Capture repos before any await to avoid use_build_context_synchronously
      final repo = context.read<TeacherRepository>();
      final classRepo = context.read<ClassRepository>();

      if (_selectedClassId == null || _selectedClassId!.isEmpty) {
        throw Exception('Class is required.');
      }

      if (t == null) {
        // Create teacher
        final newTeacher = Teacher(
          id: '',
          profileId: '',
          joinedDate: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          fullName: _nameController.text.trim(),
        );

        final initialPassword = _passwordController.text.trim().isEmpty
            ? 'Nizar@123'
            : _passwordController.text.trim();

        await repo.createTeacher(
          newTeacher,
          fullName: _nameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim().isEmpty
              ? null
              : _phoneController.text.trim(),
          classId: _selectedClassId!,
          password: initialPassword,
        );

        if (!mounted) return;
        Navigator.of(context).pop();
        widget.onSave();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Teacher created successfully'),
            backgroundColor: Color(0xFF059669),
          ),
        );
      } else {
        // Update teacher
        final updatedTeacher = Teacher(
          id: t.id,
          profileId: t.profileId,
          joinedDate: t.joinedDate,
          createdAt: t.createdAt,
          updatedAt: DateTime.now(),
          fullName: _nameController.text.trim(),
        );

        await repo.updateTeacher(
          updatedTeacher,
          _nameController.text.trim(),
          _phoneController.text.trim().isEmpty
              ? null
              : _phoneController.text.trim(),
        );

        // Update class assignment
        if (_selectedClassId != t.assignedClassId) {
          // Unassign from old class
          if (t.assignedClassId != null) {
            await classRepo.assignTeacher(t.assignedClassId!, null);
          }
          // Assign to new class
          if (_selectedClassId != null) {
            await classRepo.assignTeacher(_selectedClassId!, t.profileId);
          }
        }

        if (!mounted) return;
        Navigator.of(context).pop();
        widget.onSave();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Teacher updated successfully'),
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
    final isEdit = widget.teacher != null;

    // Filter available classes (either not assigned or currently assigned to this teacher)
    final classItems = widget.classes.where((c) {
      if (!c.isActive) return false;
      if (c.classTeacherId == null) return true;
      if (isEdit && c.classTeacherId == widget.teacher?.profileId) return true;
      return false;
    }).toList();

    return AlertDialog(
      title: Text(isEdit ? 'Edit Teacher Details' : 'Add New Class Teacher'),
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
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 12),
                ],
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Teacher Full Name',
                  ),
                  validator: (val) =>
                      val == null || val.trim().isEmpty ? 'Required' : null,
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
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Initial Password',
                      hintText: 'Defaults to Nizar@123 if empty',
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 12),
                ],
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number (Optional)',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _selectedClassId,
                  decoration: const InputDecoration(
                    labelText: 'Assign Class Room',
                  ),
                  items: [
                    for (final cls in classItems)
                      DropdownMenuItem<String>(
                        value: cls.id,
                        child: Text(cls.displayName),
                      ),
                  ],
                  onChanged: (val) => setState(() => _selectedClassId = val),
                  validator: (val) => val == null || val.isEmpty ? 'Class is required.' : null,
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
              : Text(isEdit ? 'Save Changes' : 'Create Teacher'),
        ),
      ],
    );
  }
}

class _DeleteTeacherDialog extends StatefulWidget {
  final Teacher teacher;
  final VoidCallback onDeleteSuccess;

  const _DeleteTeacherDialog({
    required this.teacher,
    required this.onDeleteSuccess,
  });

  @override
  State<_DeleteTeacherDialog> createState() => _DeleteTeacherDialogState();
}

class _DeleteTeacherDialogState extends State<_DeleteTeacherDialog> {
  bool _isLoading = false;
  String? _error;

  void _submit() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repo = context.read<TeacherRepository>();
      await repo.deleteTeacher(widget.teacher.id);

      if (mounted) {
        Navigator.pop(context); // Close dialog
        widget.onDeleteSuccess();
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close dialog anyway
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete teacher: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Delete Teacher Permanently'),
      content: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.9 < 400 ? MediaQuery.of(context).size.width * 0.9 : 400),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_error != null) ...[
              Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 12),
            ],
            Text(
              'Are you sure you want to permanently delete ${widget.teacher.fullName}?\n\n'
              'This will permanently remove the teacher profile, the teacher record, the assigned class teacher reference, and the login authentication account.\n\n'
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

