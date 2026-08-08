// teacher_shell.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../data/controllers/auth_controller.dart';
import '../../data/repositories/repository_interfaces.dart';
import '../../models/models.dart';
import '../../theme/theme_manager.dart';
import '../../widgets/responsive.dart';
import '../../widgets/image_crop_dialog.dart';

class TeacherShellScope extends InheritedWidget {
  const TeacherShellScope({
    super.key,
    required this.teacher,
    required this.onTeacherUpdated,
    required super.child,
  });

  final Teacher teacher;
  final ValueChanged<Teacher> onTeacherUpdated;

  static TeacherShellScope? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<TeacherShellScope>();
  }

  @override
  bool updateShouldNotify(TeacherShellScope oldWidget) {
    return teacher != oldWidget.teacher;
  }
}

class TeacherShell extends StatefulWidget {
  const TeacherShell({super.key, required this.child});

  final Widget child;

  @override
  State<TeacherShell> createState() => _TeacherShellState();
}

class _TeacherShellState extends State<TeacherShell> {
  Teacher? _teacher;
  bool _isLoading = true;
  String? _error;
  final TextEditingController _searchController = TextEditingController();

  void _updateTeacher(Teacher updatedTeacher) {
    if (mounted) {
      setState(() {
        _teacher = updatedTeacher;
      });
    }
  }

  static const _destinations = [
    _TeacherDestination('Dashboard', Icons.dashboard_outlined),
    _TeacherDestination('Students', Icons.groups_outlined),
    _TeacherDestination('Results', Icons.fact_check_outlined),
    _TeacherDestination('Notes', Icons.description_outlined),
    _TeacherDestination('Tickets', Icons.badge_outlined),
    _TeacherDestination('Settings', Icons.settings_outlined),
    _TeacherDestination('Support', Icons.help_outline),
  ];

  int get _selectedIndex {
    final path = GoRouterState.of(context).uri.path;
    if (path.startsWith('/teacher/dashboard')) return 0;
    if (path.startsWith('/teacher/students')) return 1;
    if (path.startsWith('/teacher/results')) return 2;
    if (path.startsWith('/teacher/notes')) return 3;
    if (path.startsWith('/teacher/hall-tickets')) return 4;
    if (path.startsWith('/teacher/settings')) return 5;
    if (path.startsWith('/teacher/support')) return 6;
    return 0;
  }

  void _selectPage(int index) {
    final paths = [
      '/teacher/dashboard',
      '/teacher/students',
      '/teacher/results',
      '/teacher/notes',
      '/teacher/hall-tickets',
      '/teacher/settings',
      '/teacher/support',
    ];
    if (index >= 0 && index < paths.length) {
      context.go(paths[index]);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadTeacherData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTeacherData() async {
    try {
      final authController = context.read<AuthController>();
      final profileId = authController.currentProfile?.id;
      debugPrint(
        '========== [TeacherShell] Loading teacher data for profileId: $profileId ==========',
      );
      if (profileId != null) {
        final teacher = await context
            .read<TeacherRepository>()
            .getTeacherByProfileId(profileId);
        debugPrint(
          '========== [TeacherShell] Teacher loaded: ${teacher.fullName} (Class: ${teacher.assignedClassName}) ==========',
        );
        if (mounted) {
          setState(() {
            _teacher = teacher;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _error = 'User not authenticated.';
            _isLoading = false;
          });
        }
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
      return const Scaffold(
        backgroundColor: Color(0xFFF7F9FB),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF000000)),
        ),
      );
    }

    if (_error != null || _teacher == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7F9FB),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Failed to load teacher workspace',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  _error ?? 'Teacher profile not found.',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF000000),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                      _error = null;
                    });
                    _loadTeacherData();
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

    final teacher = _teacher!;
    if (teacher.assignedClassId == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7F9FB),
        appBar: AppBar(
          title: const Text('Teacher Portal'),
          backgroundColor: Colors.white,
          actions: [
            IconButton(
              onPressed: _handleLogout,
              icon: const Icon(Icons.logout),
            ),
          ],
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.sensor_occupied_outlined,
                  size: 72,
                  color: Colors.orange,
                ),
                const SizedBox(height: 24),
                Text(
                  'No Class Assigned',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'You are not currently assigned to any class. Please ask the super admin or headmaster to assign you a class.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Provider<Teacher>.value(
      value: teacher,
      child: TeacherShellScope(
        teacher: teacher,
        onTeacherUpdated: _updateTeacher,
        child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < AppBreakpoints.tablet;

          if (!isMobile) {
            return Scaffold(
              backgroundColor:
                  isDark ? const Color(0xFF0F172A) : const Color(0xFFF7F9FB),
              body: Row(
                children: [
                  _TeacherSidebar(
                    destinations: _destinations,
                    selectedIndex: _selectedIndex,
                    onDestinationSelected: _selectPage,
                    onLogout: _handleLogout,
                    teacher: teacher,
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        _TeacherTopHeader(
                          teacher: teacher,
                          searchController: _searchController,
                          onLogout: _handleLogout,
                        ),
                        Expanded(child: widget.child),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          return Scaffold(
            backgroundColor:
                isDark ? const Color(0xFF0F172A) : const Color(0xFFF7F9FB),
            appBar: AppBar(
              automaticallyImplyLeading: false,
              title: const Text(
                'Academic Portal',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              backgroundColor:
                  isDark ? const Color(0xFF1E293B) : Colors.white,
              elevation: 0,
              actions: [
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
              ],
            ),
            body: Column(
              children: [
                _TeacherTopHeader(
                  teacher: teacher,
                  searchController: _searchController,
                  isMobile: true,
                  onLogout: _handleLogout,
                ),
                Expanded(child: widget.child),
              ],
            ),
            bottomNavigationBar: NavigationBar(
              selectedIndex: _selectedIndex < 5 ? _selectedIndex : 0,
              onDestinationSelected: _selectPage,
              labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
              destinations: [
                for (var i = 0; i < 5; i++)
                  NavigationDestination(
                    icon: Icon(_destinations[i].icon),
                    label: _destinations[i].label,
                  ),
              ],
            ),
          );
        },
      ),
    ),
  );
}
}

class _TeacherTopHeader extends StatelessWidget {
  const _TeacherTopHeader({
    required this.teacher,
    required this.searchController,
    this.isMobile = false,
    this.onLogout,
  });

  final Teacher teacher;
  final TextEditingController searchController;
  final bool isMobile;
  final VoidCallback? onLogout;

  Widget _buildProfileAvatar(BuildContext context, {required double radius, required double fontSize}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopupMenuButton<String>(
      tooltip: 'Profile & Settings',
      offset: const Offset(0, 44),
      onSelected: (value) {
        if (value == 'settings') {
          context.go('/teacher/settings');
        } else if (value == 'support') {
          context.go('/teacher/support');
        } else if (value == 'logout') {
          onLogout?.call();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                teacher.fullName.isNotEmpty ? teacher.fullName : 'Teacher',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              Text(
                (teacher.email != null && teacher.email!.isNotEmpty)
                    ? teacher.email!
                    : (teacher.assignedClassName != null
                        ? 'Class ${teacher.assignedClassName}'
                        : 'Teacher Portal'),
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: 'settings',
          child: Row(
            children: [
              Icon(Icons.settings_outlined, size: 20),
              SizedBox(width: 12),
              Text('Settings'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'support',
          child: Row(
            children: [
              Icon(Icons.help_outline, size: 20),
              SizedBox(width: 12),
              Text('Support'),
            ],
          ),
        ),
        if (onLogout != null) ...[
          const PopupMenuDivider(),
          const PopupMenuItem<String>(
            value: 'logout',
            child: Row(
              children: [
                Icon(Icons.logout, size: 20, color: Colors.redAccent),
                SizedBox(width: 12),
                Text('Logout', style: TextStyle(color: Colors.redAccent)),
              ],
            ),
          ),
        ],
      ],
      child: CircleAvatar(
        radius: radius,
        backgroundColor: const Color(0xFF131B2E),
        backgroundImage: (teacher.avatarUrl != null && teacher.avatarUrl!.trim().isNotEmpty)
            ? NetworkImage(getFullImageUrl(teacher.avatarUrl))
            : null,
        child: (teacher.avatarUrl == null || teacher.avatarUrl!.trim().isEmpty)
            ? Text(
                teacher.photoInitials,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: fontSize,
                ),
              )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor =
        isDark ? const Color(0xFF374151) : const Color(0xFFC6C6CD);
    final bgColor = isDark ? const Color(0xFF1E293B) : Colors.white;

    if (isMobile) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border(bottom: BorderSide(color: borderColor, width: 0.8)),
        ),
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 38,
                child: TextField(
                  controller: searchController,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search...',
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    prefixIcon: const Icon(
                      Icons.search,
                      size: 20,
                      color: Color(0xFF45464D),
                    ),
                    filled: true,
                    fillColor:
                        isDark
                            ? const Color(0xFF0F172A)
                            : const Color(0xFFF2F4F6),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: borderColor, width: 0.8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Color(0xFF000000),
                        width: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            _buildProfileAvatar(context, radius: 18, fontSize: 12),
          ],
        ),
      );
    }

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(bottom: BorderSide(color: borderColor, width: 0.8)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Academic Portal',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF000000),
            ),
          ),
          Row(
            children: [
              SizedBox(
                width: 256,
                height: 38,
                child: TextField(
                  controller: searchController,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search...',
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    prefixIcon: const Icon(
                      Icons.search,
                      size: 20,
                      color: Color(0xFF45464D),
                    ),
                    filled: true,
                    fillColor:
                        isDark
                            ? const Color(0xFF0F172A)
                            : const Color(0xFFF2F4F6),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: borderColor, width: 0.8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: isDark ? Colors.white : const Color(0xFF000000),
                        width: 1,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No new notifications')),
                  );
                },
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: Color(0xFF45464D),
                ),
                tooltip: 'Notifications',
              ),
              ValueListenableBuilder<ThemeMode>(
                valueListenable: ThemeManager.themeModeNotifier,
                builder: (context, themeMode, _) {
                  return IconButton(
                    onPressed: ThemeManager.toggleTheme,
                    icon: Icon(
                      ThemeManager.getThemeIcon(themeMode),
                      color: const Color(0xFF45464D),
                    ),
                    tooltip: ThemeManager.getThemeTooltip(themeMode),
                  );
                },
              ),
              const SizedBox(width: 8),
              _buildProfileAvatar(context, radius: 20, fontSize: 14),
            ],
          ),
        ],
      ),
    );
  }
}

class _TeacherSidebar extends StatelessWidget {
  const _TeacherSidebar({
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.onLogout,
    required this.teacher,
  });

  final List<_TeacherDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final VoidCallback onLogout;
  final Teacher teacher;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor =
        isDark ? const Color(0xFF374151) : const Color(0xFFC6C6CD);
    final bgColor = isDark ? const Color(0xFF1E293B) : Colors.white;

    return Container(
      width: 256,
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(right: BorderSide(color: borderColor, width: 0.8)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              child: Column(
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    width: 52,
                    height: 52,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'HIDAYATHUL ANAM\nMADRASA',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Serif',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Faculty Portal',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF44474E),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ListView(
                  children: [
                    for (var index = 0; index < destinations.length; index++)
                      _TeacherNavTile(
                        destination: destinations[index],
                        selected: selectedIndex == index,
                        onTap: () => onDestinationSelected(index),
                      ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: borderColor, width: 0.8),
                ),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF2F4F6),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : const Color(0xFFE5E7EB),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: const Color(0xFF131B2E),
                      backgroundImage: (teacher.avatarUrl != null && teacher.avatarUrl!.trim().isNotEmpty)
                          ? NetworkImage(getFullImageUrl(teacher.avatarUrl))
                          : null,
                      child: (teacher.avatarUrl == null || teacher.avatarUrl!.trim().isEmpty)
                          ? Text(
                              teacher.photoInitials,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            teacher.fullName.isNotEmpty ? teacher.fullName : 'Teacher',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: isDark ? Colors.white : const Color(0xFF1E293B),
                            ),
                          ),
                          Text(
                            (teacher.email != null && teacher.email!.isNotEmpty)
                                ? teacher.email!
                                : 'teacher@portal.edu',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isDark ? Colors.grey.shade400 : const Color(0xFF45464D),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Logout',
                      onPressed: onLogout,
                      icon: const Icon(Icons.logout, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TeacherNavTile extends StatefulWidget {
  const _TeacherNavTile({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final _TeacherDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_TeacherNavTile> createState() => _TeacherNavTileState();
}

class _TeacherNavTileState extends State<_TeacherNavTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.selected;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color bgColor = Colors.transparent;
    Color iconColor = const Color(0xFF45464D);
    Color textColor = isDark ? Colors.grey.shade300 : const Color(0xFF45464D);
    FontWeight fontWeight = FontWeight.w500;

    if (isSelected) {
      bgColor =
          isDark ? const Color(0xFF334155) : const Color(0xFFF2F4F6);
      iconColor = isDark ? Colors.white : const Color(0xFF000000);
      textColor = isDark ? Colors.white : const Color(0xFF000000);
      fontWeight = FontWeight.bold;
    } else if (_isHovered) {
      bgColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFE6E8EA);
      iconColor = isDark ? Colors.white : const Color(0xFF000000);
      textColor = isDark ? Colors.white : const Color(0xFF000000);
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
            border: isSelected
                ? Border(
                    right: BorderSide(
                      color: isDark ? Colors.white : const Color(0xFF000000),
                      width: 2,
                    ),
                  )
                : null,
          ),
          child: Row(
            children: [
              Icon(widget.destination.icon, size: 20, color: iconColor),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.destination.label,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: fontWeight,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TeacherDestination {
  const _TeacherDestination(this.label, this.icon);

  final String label;
  final IconData icon;
}
