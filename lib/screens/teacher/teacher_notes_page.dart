// teacher_notes_page.dart
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/repositories/repository_interfaces.dart';
import '../../models/models.dart';

class TeacherNotesPage extends StatefulWidget {
  const TeacherNotesPage({super.key});

  @override
  State<TeacherNotesPage> createState() => _TeacherNotesPageState();
}

class _TeacherNotesPageState extends State<TeacherNotesPage> {
  bool _isLoading = true;
  List<Note> _notes = [];
  List<Subject> _subjects = [];
  List<ActivityLog> _noteLogs = [];
  String? _selectedSubjectId;

  // Add notes dialog controllers
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  Uint8List? _selectedFileBytes;
  String? _selectedFileName;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _loadNotes() async {
    try {
      final teacher = context.read<Teacher>();
      final classId = teacher.assignedClassId ?? '';
      final notesRepo = context.read<NotesRepository>();
      final subjectsRepo = context.read<SubjectRepository>();
      final logsRepo = context.read<ActivityLogRepository>();

      final data = await Future.wait([
        notesRepo.getNotesByClass(classId),
        subjectsRepo.getSubjectsByClass(classId),
        logsRepo.getLogsByClass(classId).catchError((_) => <ActivityLog>[]),
      ]);

      if (mounted) {
        setState(() {
          _notes = data[0] as List<Note>;
          _subjects = data[1] as List<Subject>;
          final allLogs = data[2] as List<ActivityLog>;
          _noteLogs =
              allLogs
                  .where(
                    (l) =>
                        l.entityType == 'note' ||
                        l.action.toLowerCase().contains('note'),
                  )
                  .take(5)
                  .toList();
          if (_subjects.isNotEmpty && (_selectedSubjectId == null || !_subjects.any((s) => s.id == _selectedSubjectId))) {
            _selectedSubjectId = _subjects.first.id;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _pickFile(StateSetter dialogState) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.bytes != null) {
          dialogState(() {
            _selectedFileBytes = file.bytes;
            _selectedFileName = file.name;
          });
        }
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
    }
  }

  void _uploadNote() async {
    if (_titleController.text.trim().isEmpty || _selectedFileBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a title and select a file'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final teacher = context.read<Teacher>();
      final classId = teacher.assignedClassId ?? '';
      final notesRepo = context.read<NotesRepository>();
      final activityRepo = context.read<ActivityLogRepository>();

      final noteTitle = _titleController.text.trim();

      final effectiveSubjectId = (_selectedSubjectId != null && _subjects.any((s) => s.id == _selectedSubjectId))
          ? _selectedSubjectId
          : (_subjects.isNotEmpty ? _subjects.first.id : null);

      await notesRepo.uploadNote(
        title: noteTitle,
        description:
            _descController.text.trim().isEmpty
                ? null
                : _descController.text.trim(),
        classId: classId,
        subjectId: effectiveSubjectId,
        teacherId: teacher.profileId,
        fileBytes: _selectedFileBytes!,
        fileName: _selectedFileName!,
      );

      try {
        await activityRepo.logActivity(
          action: 'Uploaded Notes',
          entityType: 'note',
          description: 'Uploaded note: $noteTitle',
          classId: classId,
        );
      } catch (_) {}

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notes uploaded successfully!'),
            backgroundColor: Color(0xFF059669),
          ),
        );

        _titleController.clear();
        _descController.clear();
        _selectedFileBytes = null;
        _selectedFileName = null;

        await _loadNotes();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _deleteNote(Note note) async {
    final notesRepo = context.read<NotesRepository>();
    final activityRepo = context.read<ActivityLogRepository>();
    final teacher = context.read<Teacher>();
    final classId = teacher.assignedClassId ?? '';

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Delete Note'),
            content: Text('Are you sure you want to delete "${note.title}"?'),
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

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      await notesRepo.deleteNote(note.id);
      try {
        await activityRepo.logActivity(
          action: 'Deleted Note',
          entityType: 'note',
          entityId: note.id,
          description: 'Deleted note: ${note.title}',
          classId: classId,
        );
      } catch (_) {}
      if (mounted) _loadNotes();
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _openNote(Note note) async {
    try {
      final notesRepo = context.read<NotesRepository>();
      final signedUrl = await notesRepo.getSignedDownloadUrl(note.filePath);
      final uri = Uri.parse(signedUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open note: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, dialogState) {
            return AlertDialog(
              title: const Text('Upload New Learning Notes'),
              content: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.9 < 460 ? MediaQuery.of(context).size.width * 0.9 : 460),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Notes Title',
                        hintText: 'e.g. Lecture 12: Calculus Theorems',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _descController,
                      decoration: const InputDecoration(
                        labelText: 'Description (Optional)',
                        hintText: 'Short notes summary for students',
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue:
                          (_selectedSubjectId != null &&
                                  _subjects.any(
                                    (s) => s.id == _selectedSubjectId,
                                  ))
                              ? _selectedSubjectId
                              : null,
                      decoration: const InputDecoration(labelText: 'Subject'),
                      items: [
                        for (final sub in _subjects)
                          DropdownMenuItem(
                            value: sub.id,
                            child: Text(sub.subjectName),
                          ),
                      ],
                      onChanged:
                          (val) => dialogState(() => _selectedSubjectId = val),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      onPressed: () => _pickFile(dialogState),
                      icon: const Icon(Icons.attach_file),
                      label: Text(
                        _selectedFileName ?? 'Select Document File (PDF, DOCX, TXT)',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                  ),
                  onPressed:
                      _selectedFileBytes == null
                          ? null
                          : () {
                            Navigator.pop(context);
                            _uploadNote();
                          },
                  child: const Text('Upload'),
                ),
              ],
            );
          },
        );
      },
    );
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
                // Page Header
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
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment:
                            isMobile
                                ? CrossAxisAlignment.start
                                : CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Class Study Notes',
                                  style: TextStyle(
                                    fontFamily: 'Serif',
                                    fontSize: isMobile ? 20 : 26,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        isDark
                                            ? Colors.white
                                            : const Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Manage and organize class study materials.',
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
                            onPressed: _showAddDialog,
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

                // Notes Manager Section
                Text(
                  'Notes Manager',
                  style: TextStyle(
                    fontFamily: 'Serif',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 24),

                if (_notes.isEmpty)
                  // Empty State Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 64,
                    ),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor, width: 0.8),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color:
                                isDark
                                    ? const Color(0xFF334155)
                                    : const Color(0xFFF2F4F6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.library_books_outlined,
                            size: 32,
                            color: Color(0xFF45464D),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'No Notes Uploaded',
                          style: TextStyle(
                            fontFamily: 'Serif',
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color:
                                isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 440),
                          child: const Text(
                            'No notes uploaded for this class yet. Get started by uploading your first study material to share with your students.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Color(0xFF45464D),
                              height: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor:
                                isDark ? Colors.white : const Color(0xFF0F172A),
                            side: BorderSide(color: borderColor, width: 0.8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          onPressed: _showAddDialog,
                          child: const Text(
                            'Upload First Note',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  // Notes Data Table Card
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor, width: 0.8),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final double tableWidth =
                            constraints.maxWidth > 800
                                ? constraints.maxWidth
                                : 800;
                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SizedBox(
                            width: tableWidth,
                            child: Table(
                              columnWidths: const {
                                0: FlexColumnWidth(2.5),
                                1: FlexColumnWidth(1.5),
                                2: FlexColumnWidth(3),
                                3: FixedColumnWidth(150),
                                4: FixedColumnWidth(120),
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
                                      bottom: BorderSide(
                                        color: borderColor,
                                        width: 0.8,
                                      ),
                                    ),
                                  ),
                                  children: const [
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 16,
                                      ),
                                      child: Text(
                                        'Title',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF45464D),
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 16,
                                      ),
                                      child: Text(
                                        'Subject',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF45464D),
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 16,
                                      ),
                                      child: Text(
                                        'Description',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF45464D),
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 16,
                                      ),
                                      child: Text(
                                        'Upload Date',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF45464D),
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 16,
                                      ),
                                      child: Align(
                                        alignment: Alignment.centerRight,
                                        child: Text(
                                          'Actions',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF45464D),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                // Table Rows
                                for (int i = 0; i < _notes.length; i++)
                                  _buildNoteRow(
                                    note: _notes[i],
                                    borderColor: borderColor,
                                    isLast: i == _notes.length - 1,
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                const SizedBox(height: 32),

                // Recent Activity Section
                Text(
                  'Recent Activity',
                  style: TextStyle(
                    fontFamily: 'Serif',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 24),

                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor, width: 0.8),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      if (_noteLogs.isNotEmpty)
                        for (int i = 0; i < _noteLogs.length; i++)
                          _buildActivityItem(
                            icon: Icons.edit_note_outlined,
                            title: _noteLogs[i].action,
                            subtitle:
                                _noteLogs[i].description ?? 'Updated note details',
                            timeAgo: _noteLogs[i].createdAt
                                .toLocal()
                                .toString()
                                .substring(0, 16),
                            borderColor: borderColor,
                            isLast: i == _noteLogs.length - 1,
                          )
                      else ...[
                        _buildActivityItem(
                          icon: Icons.edit_note_outlined,
                          title: 'Updated Algebra Notes',
                          subtitle: 'Notes details revised for Class 10',
                          timeAgo: '2 hours ago',
                          borderColor: borderColor,
                        ),
                        _buildActivityItem(
                          icon: Icons.upload_file_outlined,
                          title: 'Uploaded Geometry Review',
                          subtitle: 'Added Geometry_Review_2026.pdf',
                          timeAgo: 'Yesterday',
                          borderColor: borderColor,
                        ),
                        _buildActivityItem(
                          icon: Icons.visibility_outlined,
                          title: 'Viewed Calculus Basics',
                          subtitle: 'Calculus_Basics.docx downloaded by students',
                          timeAgo: '2 days ago',
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

  TableRow _buildNoteRow({
    required Note note,
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Text(
            note.title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Text(
            note.subjectName ?? 'General',
            style: const TextStyle(fontSize: 14, color: Color(0xFF45464D)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Text(
            (note.description != null && note.description!.trim().isNotEmpty)
                ? note.description!
                : '',
            style: const TextStyle(fontSize: 14, color: Color(0xFF45464D)),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Text(
            note.uploadedAt.toLocal().toString().substring(0, 16),
            style: const TextStyle(fontSize: 14, color: Color(0xFF45464D)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  padding: const EdgeInsets.all(6),
                  tooltip: 'Open / View learning note',
                  onPressed: () => _openNote(note),
                  icon: const Icon(
                    Icons.open_in_new_outlined,
                    size: 18,
                    color: Color(0xFF0284C7),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  padding: const EdgeInsets.all(6),
                  tooltip: 'Delete learning notes',
                  onPressed: () => _deleteNote(note),
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: Color(0xFFEF4444),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String timeAgo,
    required Color borderColor,
    bool isLast = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border:
            isLast
                ? null
                : Border(bottom: BorderSide(color: borderColor, width: 0.8)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color:
                  isDark ? const Color(0xFF334155) : const Color(0xFFF2F4F6),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: const Color(0xFF45464D)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$subtitle • $timeAgo',
                  style: const TextStyle(
                    fontSize: 12,
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
}

