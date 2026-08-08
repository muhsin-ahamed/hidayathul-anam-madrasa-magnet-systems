// profile_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/repository_interfaces.dart';
import '../../models/models.dart';
import '../../widgets/page_scaffold.dart';
import '../../widgets/portal_card.dart';
import '../../widgets/responsive.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? _signedPhotoUrl;

  @override
  void initState() {
    super.initState();
    _loadPhotoUrl();
  }

  void _loadPhotoUrl() async {
    final student = context.read<Student>();
    if (student.photoPath != null && student.photoPath!.isNotEmpty) {
      try {
        final url = await context.read<StudentRepository>().getSignedPhotoUrl(
          student.photoPath!,
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
    final isDesktop = Responsive.isDesktop(context);
    final student = context.watch<Student>();

    return PageScaffold(
      title: 'Profile',
      children: [
        PortalCard(
          child: isDesktop
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ProfilePhoto(student: student, photoUrl: _signedPhotoUrl),
                    const SizedBox(width: 28),
                    Expanded(child: _ProfileDetails(student: student)),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ProfilePhoto(student: student, photoUrl: _signedPhotoUrl),
                    const SizedBox(height: 24),
                    _ProfileDetails(student: student),
                  ],
                ),
        ),
      ],
    );
  }
}


class _ProfilePhoto extends StatelessWidget {
  const _ProfilePhoto({required this.student, this.photoUrl});

  final Student student;
  final String? photoUrl;

  void _shareProfile(BuildContext context, Student student) {
    final String shareText = '''
HIDAYATHUL ANAM MADRASA Student Profile
Name: ${student.fullName}
Class: ${student.className ?? 'N/A'}
Roll Number: ${student.rollNumber}
Admission Number: ${student.admissionNumber}
Email: ${student.email ?? 'N/A'}
Phone: ${student.phone ?? 'N/A'}
Guardian: ${student.guardianName ?? 'N/A'}
''';

    Clipboard.setData(ClipboardData(text: shareText)).then((_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile details copied to clipboard!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    return Column(
      children: [
        Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: primaryColor.withValues(alpha: 0.15),
                  width: 3,
                ),
              ),
              child: CircleAvatar(
                radius: 58,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                backgroundImage: photoUrl != null ? NetworkImage(photoUrl!) : null,
                child: photoUrl == null
                    ? Text(
                        student.photoInitials,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w900,
                        ),
                      )
                    : null,
              ),
            ),
            Positioned(
              right: 2,
              bottom: 2,
              child: Material(
                color: primaryColor,
                elevation: 4,
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: IconButton(
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                  padding: EdgeInsets.zero,
                  icon: const Icon(
                    Icons.share,
                    size: 18,
                    color: Colors.white,
                  ),
                  tooltip: 'Share Profile Details',
                  onPressed: () => _shareProfile(context, student),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          student.fullName,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
        Text(
          student.className ?? 'Class Info',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
        ),
      ],
    );
  }
}

class _ProfileDetails extends StatelessWidget {
  const _ProfileDetails({required this.student});

  final Student student;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _ProfileField(
          icon: Icons.person_outline,
          label: 'Name',
          value: student.fullName,
          isDark: isDark,
        ),
        _ProfileField(
          icon: Icons.class_outlined,
          label: 'Class',
          value: student.className ?? 'TBA',
          isDark: isDark,
        ),
        _ProfileField(
          icon: Icons.confirmation_number_outlined,
          label: 'Roll Number',
          value: student.rollNumber,
          isDark: isDark,
        ),
        _ProfileField(
          icon: Icons.badge_outlined,
          label: 'Admission Number',
          value: student.admissionNumber,
          isDark: isDark,
        ),
        _ProfileField(
          icon: Icons.mail_outline,
          label: 'Email',
          value: student.email ?? 'No email associated',
          isDark: isDark,
        ),
        _ProfileField(
          icon: Icons.phone_outlined,
          label: 'Phone',
          value: student.phone ?? 'No phone associated',
          isDark: isDark,
        ),
        _ProfileField(
          icon: Icons.family_restroom_outlined,
          label: 'Guardian Name',
          value: student.guardianName ?? 'N/A',
          isDark: isDark,
        ),
        _ProfileField(
          icon: Icons.contact_phone_outlined,
          label: 'Guardian Phone',
          value: student.guardianPhone ?? 'N/A',
          isDark: isDark,
        ),
        _ProfileField(
          icon: Icons.cake_outlined,
          label: 'Date of Birth',
          value: student.dateOfBirth != null
              ? student.dateOfBirth!.toLocal().toString().substring(0, 10)
              : 'N/A',
          isDark: isDark,
        ),
        _ProfileField(
          icon: Icons.wc_outlined,
          label: 'Gender',
          value: student.gender ?? 'N/A',
          isDark: isDark,
        ),
        _ProfileField(
          icon: Icons.home_outlined,
          label: 'Address',
          value: student.address ?? 'N/A',
          wide: true,
          isDark: isDark,
        ),
      ],
    );
  }
}

class _ProfileField extends StatelessWidget {
  const _ProfileField({
    required this.icon,
    required this.label,
    required this.value,
    this.wide = false,
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool wide;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: wide ? 520 : 250,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.05),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
