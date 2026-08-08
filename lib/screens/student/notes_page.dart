// notes_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/repositories/repository_interfaces.dart';
import '../../models/models.dart';
import '../../widgets/page_scaffold.dart';
import '../../widgets/portal_card.dart';
import '../../widgets/responsive_grid.dart';

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  bool _isLoading = true;
  String? _error;
  List<Note> _notes = [];
  List<Subject> _subjects = [];
  String _query = '';
  String _selectedSubject = 'All Subjects';

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    try {
      final student = context.read<Student>();
      final notesRepo = context.read<NotesRepository>();
      final subjectsRepo = context.read<SubjectRepository>();

      final data = await Future.wait([
        notesRepo.getNotesByClass(student.classId),
        subjectsRepo.getSubjectsByClass(student.classId),
      ]);

      if (mounted) {
        setState(() {
          _notes = (data[0] as List<Note>).where((n) => n.isPublished).toList();
          _subjects = data[1] as List<Subject>;
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

  Future<void> _downloadNote(Note note) async {
    try {
      final notesRepo = context.read<NotesRepository>();
      final signedUrl = await notesRepo.getSignedDownloadUrl(note.filePath);
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
                  'Error loading notes',
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
                    _loadNotes();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final filteredNotes = _notes.where((note) {
      final matchesSearch =
          _query.trim().isEmpty ||
          note.title.toLowerCase().contains(_query.toLowerCase()) ||
          (note.description?.toLowerCase().contains(_query.toLowerCase()) ??
              false) ||
          (note.subjectName?.toLowerCase().contains(_query.toLowerCase()) ??
              false) ||
          (note.teacherName?.toLowerCase().contains(_query.toLowerCase()) ??
              false);
      final matchesSubject =
          _selectedSubject == 'All Subjects' ||
          note.subjectName == _selectedSubject;
      return matchesSearch && matchesSubject;
    }).toList();

    return PageScaffold(
      title: 'Notes',
      children: [
        PortalCard(
          child: Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              SizedBox(
                width: 360,
                child: TextField(
                  onChanged: (value) => setState(() => _query = value),
                  decoration: const InputDecoration(
                    labelText: 'Search notes',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
              SizedBox(
                width: 220,
                child: DropdownButtonFormField<String>(
                  initialValue: (_selectedSubject == 'All Subjects' || _subjects.any((s) => s.subjectName == _selectedSubject)) ? _selectedSubject : 'All Subjects',
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Subject'),
                  items: [
                    const DropdownMenuItem(
                      value: 'All Subjects',
                      child: Text('All Subjects'),
                    ),
                    for (final subject in _subjects)
                      DropdownMenuItem(
                        value: subject.subjectName,
                        child: Text(subject.subjectName),
                      ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _selectedSubject = value);
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (filteredNotes.isEmpty)
          const PortalCard(child: Center(child: Text('No notes found')))
        else
          ResponsiveGrid(
            desktopColumns: 3,
            tabletColumns: 2,
            mainAxisExtent: 270,
            children: [
              for (final note in filteredNotes)
                _NoteCard(note: note, onDownload: () => _downloadNote(note)),
            ],
          ),
      ],
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.note, required this.onDownload});

  final Note note;
  final VoidCallback onDownload;

  IconData get _icon {
    final name = note.fileName?.toLowerCase() ?? '';
    if (name.endsWith('.pdf')) return Icons.picture_as_pdf_outlined;
    if (name.endsWith('.png') ||
        name.endsWith('.jpg') ||
        name.endsWith('.jpeg')) {
      return Icons.image_outlined;
    }
    if (name.endsWith('.doc') || name.endsWith('.docx')) {
      return Icons.article_outlined;
    }
    return Icons.library_books_outlined;
  }

  @override
  Widget build(BuildContext context) {
    return PortalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _icon,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      note.subjectName ?? 'General Note',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      note.className ?? 'Class Note',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            note.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Teacher: ${note.teacherName ?? 'Staff'}',
            style: const TextStyle(fontSize: 13, color: Color(0xFF45464D)),
          ),
          const SizedBox(height: 4),
          Text(
            'Uploaded: ${note.uploadedAt.toLocal().toString().substring(0, 10)}',
            style: const TextStyle(fontSize: 13, color: Color(0xFF45464D)),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onDownload,
              icon: const Icon(Icons.download_outlined),
              label: const Text('Download'),
            ),
          ),
        ],
      ),
    );
  }
}
