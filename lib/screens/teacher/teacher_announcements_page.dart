import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/repository_interfaces.dart';
import '../../models/models.dart';
import '../../widgets/page_scaffold.dart';
import '../../widgets/portal_card.dart';
import '../../widgets/section_title.dart';
import '../../widgets/status_badge.dart';

class TeacherAnnouncementsPage extends StatefulWidget {
  const TeacherAnnouncementsPage({super.key});

  @override
  State<TeacherAnnouncementsPage> createState() =>
      _TeacherAnnouncementsPageState();
}

class _TeacherAnnouncementsPageState extends State<TeacherAnnouncementsPage> {
  bool _isLoading = true;
  String? _error;
  List<Announcement> _announcements = [];

  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadAnnouncements() async {
    try {
      final teacher = context.read<Teacher>();
      final classId = teacher.assignedClassId ?? '';
      final repo = context.read<AnnouncementRepository>();
      final announcements = await repo.getAnnouncementsForTeacher(classId);

      setState(() {
        _announcements = announcements;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _publishAnnouncement() async {
    if (_titleController.text.trim().isEmpty ||
        _messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    setState(() => _isSaving = true);

    try {
      final teacher = context.read<Teacher>();
      final classId = teacher.assignedClassId ?? '';
      final repo = context.read<AnnouncementRepository>();
      final activityRepo = context.read<ActivityLogRepository>();

      final announcement = Announcement(
        id: '',
        title: _titleController.text.trim(),
        message: _messageController.text.trim(),
        targetType: 'class',
        targetClassId: classId,
        publishedBy: teacher.profileId,
        publishedAt: DateTime.now(),
        isActive: true,
      );

      await repo.publishAnnouncement(announcement);

      // Log action
      await activityRepo.logActivity(
        action: 'Published Announcement',
        entityType: 'announcement',
        description:
            'Published class announcement: ${_titleController.text.trim()}',
        classId: classId,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Announcement published successfully!')),
      );

      _titleController.clear();
      _messageController.clear();
      setState(() => _isSaving = false);
      _loadAnnouncements();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  void _deactivateAnnouncement(Announcement announcement) async {
    final teacher = context.read<Teacher>();
    final classId = teacher.assignedClassId ?? '';
    final repo = context.read<AnnouncementRepository>();
    final activityRepo = context.read<ActivityLogRepository>();

    setState(() => _isLoading = true);
    try {
      await repo.deactivateAnnouncement(announcement.id);
      await activityRepo.logActivity(
        action: 'Deactivated Announcement',
        entityType: 'announcement',
        entityId: announcement.id,
        description: 'Deactivated announcement: ${announcement.title}',
        classId: classId,
      );
      if (!mounted) return;
      _loadAnnouncements();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, dialogState) {
            return AlertDialog(
              title: const Text('Publish New Class Announcement'),
              content: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.9 < 440 ? MediaQuery.of(context).size.width * 0.9 : 440),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: 'Title'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        labelText: 'Announcement Message',
                      ),
                      maxLines: 4,
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
                FilledButton(
                  onPressed: _isSaving
                      ? null
                      : () {
                          Navigator.pop(context);
                          _publishAnnouncement();
                        },
                  child: const Text('Publish'),
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
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error loading announcements: $_error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadAnnouncements,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return PageScaffold(
      title: 'Class Announcements',
      trailing: FilledButton.icon(
        onPressed: _showAddDialog,
        icon: const Icon(Icons.campaign_outlined),
        label: const Text('Add Announcement'),
      ),
      children: [
        PortalCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle(title: 'Announcements List'),
              const SizedBox(height: 14),
              if (_announcements.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40.0),
                  child: Center(
                    child: Text('No announcements posted for this class yet.'),
                  ),
                )
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    final minTableWidth = math.max(constraints.maxWidth, 800.0);
                    final dynamicColumnSpacing = constraints.maxWidth > 800
                        ? math.max(24.0, 24.0 + (constraints.maxWidth - 800) / 5)
                        : 24.0;
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minWidth: minTableWidth),
                        child: DataTable(
                          columnSpacing: dynamicColumnSpacing,
                          columns: const [
                            DataColumn(label: Text('Title')),
                            DataColumn(label: Text('Message')),
                            DataColumn(label: Text('Date Published')),
                            DataColumn(label: Text('Status')),
                            DataColumn(label: Text('Actions')),
                          ],
                      rows: [
                        for (final announcement in _announcements)
                          DataRow(
                            cells: [
                              DataCell(Text(announcement.title)),
                              DataCell(
                                Text(
                                  announcement.message,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              DataCell(
                                Text(
                                  announcement.publishedAt
                                      .toLocal()
                                      .toString()
                                      .substring(0, 16),
                                ),
                              ),
                              DataCell(
                                StatusBadge(
                                  label: announcement.isActive
                                      ? 'Active'
                                      : 'Inactive',
                                  color: announcement.isActive
                                      ? const Color(0xFF059669)
                                      : Colors.grey,
                                ),
                              ),
                              DataCell(
                                announcement.isActive
                                    ? IconButton(
                                        tooltip: 'Deactivate announcement',
                                        onPressed: () =>
                                            _deactivateAnnouncement(
                                              announcement,
                                            ),
                                        icon: const Icon(
                                          Icons.cancel_outlined,
                                          color: Colors.red,
                                        ),
                                      )
                                    : const SizedBox.shrink(),
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
