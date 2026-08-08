// student_shell.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../data/controllers/auth_controller.dart';
import '../../data/repositories/repository_interfaces.dart';
import '../../models/models.dart';
import '../../theme/theme_manager.dart';
import '../../widgets/responsive.dart';

class StudentShell extends StatefulWidget {
  const StudentShell({super.key, required this.child});

  final Widget child;

  @override
  State<StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends State<StudentShell> {
  Student? _student;
  bool _isLoading = true;
  String? _error;

  static const _destinations = [
    _StudentDestination('Dashboard', Icons.dashboard_outlined),
    _StudentDestination('Result', Icons.fact_check_outlined),
    _StudentDestination('Notes', Icons.library_books_outlined),
    _StudentDestination('Hall Ticket', Icons.confirmation_number_outlined),
    _StudentDestination('Profile', Icons.person_outline),
  ];

  int get _selectedIndex {
    final path = GoRouterState.of(context).uri.path;
    if (path.startsWith('/student/dashboard')) return 0;
    if (path.startsWith('/student/result')) return 1;
    if (path.startsWith('/student/notes')) return 2;
    if (path.startsWith('/student/hall-ticket')) return 3;
    if (path.startsWith('/student/profile')) return 4;
    return 0;
  }

  void _selectPage(int index) {
    final paths = [
      '/student/dashboard',
      '/student/result',
      '/student/notes',
      '/student/hall-ticket',
      '/student/profile',
    ];
    context.go(paths[index]);
  }

  @override
  void initState() {
    super.initState();
    _loadStudentData();
  }

  Future<void> _loadStudentData() async {
    try {
      final authController = context.read<AuthController>();
      final profileId = authController.currentProfile?.id;
      debugPrint('========== [StudentShell] Loading student data for profileId: $profileId ==========');
      if (profileId != null) {
        final student = await context
            .read<StudentRepository>()
            .getStudentByProfileId(profileId);
        debugPrint('========== [StudentShell] Student loaded: ${student?.fullName} (Roll: ${student?.rollNumber}, Class: ${student?.className}) ==========');
        if (mounted) {
          setState(() {
            _student = student;
            _isLoading = false;
          });
        }
      } else {
        debugPrint('========== [StudentShell] Error: User not authenticated ==========');
        if (mounted) {
          setState(() {
            _error = 'User not authenticated.';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('========== [StudentShell] Error loading student data: $e ==========');
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  void _handleLogout() async {
    final authController = context.read<AuthController>();
    await authController.logout();
    if (mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null || _student == null) {
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
                  'Failed to load student profile',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  _error ?? 'Student record not found.',
                  style: TextStyle(color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                      _error = null;
                    });
                    _loadStudentData();
                  },
                  child: const Text('Retry'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _handleLogout,
                  child: const Text('Logout'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Expose the active student model to all descendants in the shell
    return Provider<Student>.value(
      value: _student!,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < AppBreakpoints.tablet;

          return Scaffold(
            appBar: PreferredSize(
              preferredSize: Size.fromHeight(isMobile ? 76 : 126),
              child: _StudentTopBar(
                selectedIndex: _selectedIndex,
                destinations: _destinations,
                onDestinationSelected: _selectPage,
                onLogout: _handleLogout,
                isMobile: isMobile,
                student: _student!,
              ),
            ),
            body: widget.child,
            bottomNavigationBar: isMobile
                ? NavigationBar(
                    selectedIndex: _selectedIndex < _destinations.length ? _selectedIndex : 0,
                    onDestinationSelected: _selectPage,
                    labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
                    destinations: [
                      for (final destination in _destinations)
                        NavigationDestination(
                          icon: Icon(destination.icon),
                          label: destination.label,
                        ),
                    ],
                  )
                : null,
          );
        },
      ),
    );
  }
}

class _StudentTopBar extends StatelessWidget {
  const _StudentTopBar({
    required this.selectedIndex,
    required this.destinations,
    required this.onDestinationSelected,
    required this.onLogout,
    required this.isMobile,
    required this.student,
  });

  final int selectedIndex;
  final List<_StudentDestination> destinations;
  final ValueChanged<int> onDestinationSelected;
  final VoidCallback onLogout;
  final bool isMobile;
  final Student student;

  @override
  Widget build(BuildContext context) {
    final padding = Responsive.pagePadding(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(padding, 10, padding, 10),
          child: Column(
            children: [
              Row(
                children: [
                  _StudentBrand(isMobile: isMobile),
                  const Spacer(),
                  ValueListenableBuilder<ThemeMode>(
                    valueListenable: ThemeManager.themeModeNotifier,
                    builder: (context, themeMode, _) {
                      return IconButton(
                        onPressed: ThemeManager.toggleTheme,
                        icon: Icon(ThemeManager.getThemeIcon(themeMode)),
                        tooltip: ThemeManager.getThemeTooltip(themeMode),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  _StudentUserMenu(
                    onProfile: () => onDestinationSelected(4),
                    onLogout: onLogout,
                    isMobile: isMobile,
                    student: student,
                  ),
                ],
              ),
              if (!isMobile) ...[
                const SizedBox(height: 14),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (var index = 0; index < destinations.length; index++)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _StudentNavButton(
                            destination: destinations[index],
                            selected: selectedIndex == index,
                            onTap: () => onDestinationSelected(index),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StudentBrand extends StatelessWidget {
  const _StudentBrand({required this.isMobile});

  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    final mark = Image.asset(
      'assets/images/logo.png',
      width: 44,
      height: 44,
      fit: BoxFit.contain,
    );

    if (isMobile) return mark;

    return Row(
      children: [
        mark,
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'HIDAYATHUL ANAM MADRASA Portal',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -0.2,
              ),
            ),
            Text(
              'Student workspace',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey.shade400
                    : Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StudentUserMenu extends StatelessWidget {
  const _StudentUserMenu({
    required this.onProfile,
    required this.onLogout,
    required this.isMobile,
    required this.student,
  });

  final VoidCallback onProfile;
  final VoidCallback onLogout;
  final bool isMobile;
  final Student student;

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
    final maxNameWidth = isMobile ? 112.0 : 160.0;

    return PopupMenuButton<String>(
      tooltip: 'Student menu',
      offset: const Offset(0, 48),
      onSelected: (value) {
        if (value == 'profile') {
          onProfile();
        } else if (value == 'share') {
          _shareProfile(context, student);
        } else if (value == 'logout') {
          onLogout();
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: 'profile',
          child: ListTile(
            leading: Icon(Icons.person_outline),
            title: Text('Profile'),
            dense: true,
          ),
        ),
        PopupMenuDivider(),
        PopupMenuItem(
          value: 'share',
          child: ListTile(
            leading: Icon(Icons.share_outlined),
            title: Text('Share Profile'),
            dense: true,
          ),
        ),
        PopupMenuDivider(),
        PopupMenuItem(
          value: 'logout',
          child: ListTile(
            leading: Icon(Icons.logout),
            title: Text('Logout'),
            dense: true,
          ),
        ),
      ],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxNameWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  student.fullName,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                Text(
                  student.className ?? 'Class',
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey.shade400
                        : Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.15),
                width: 2,
              ),
            ),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                student.photoInitials,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.keyboard_arrow_down, size: 20),
        ],
      ),
    );
  }
}

class _StudentNavButton extends StatefulWidget {
  const _StudentNavButton({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final _StudentDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_StudentNavButton> createState() => _StudentNavButtonState();
}

class _StudentNavButtonState extends State<_StudentNavButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = widget.selected;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color bgColor = Colors.transparent;
    if (isSelected) {
      bgColor = colorScheme.primary.withValues(alpha: 0.08);
    } else if (_isHovered) {
      bgColor = isDark
          ? Colors.white.withValues(alpha: 0.05)
          : Colors.black.withValues(alpha: 0.03);
    }

    final unselectedColor = isDark
        ? Colors.grey.shade400
        : Colors.grey.shade700;
    final unselectedTextColor = isDark
        ? Colors.grey.shade300
        : Colors.grey.shade800;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? colorScheme.primary.withValues(alpha: 0.16)
                  : Colors.transparent,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.destination.icon,
                size: 19,
                color: isSelected ? colorScheme.primary : unselectedColor,
              ),
              const SizedBox(width: 8),
              Text(
                widget.destination.label,
                style: TextStyle(
                  color: isSelected ? colorScheme.primary : unselectedTextColor,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StudentDestination {
  const _StudentDestination(this.label, this.icon);

  final String label;
  final IconData icon;
}
