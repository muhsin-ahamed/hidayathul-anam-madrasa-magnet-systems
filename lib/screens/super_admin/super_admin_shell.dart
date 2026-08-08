// super_admin_shell.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../data/controllers/auth_controller.dart';
import '../../theme/theme_manager.dart';
import '../../widgets/responsive.dart';
import '../../widgets/image_crop_dialog.dart';

class SuperAdminShell extends StatefulWidget {
  const SuperAdminShell({super.key, required this.child});

  final Widget child;

  @override
  State<SuperAdminShell> createState() => _SuperAdminShellState();
}

class _SuperAdminShellState extends State<SuperAdminShell> {
  static const _destinations = [
    _AdminDestination('Dashboard', Icons.dashboard),
    _AdminDestination('Students', Icons.group_outlined),
    _AdminDestination('Teachers', Icons.co_present_outlined),
    _AdminDestination('Classes', Icons.meeting_room_outlined),
    _AdminDestination('Academic', Icons.description_outlined),
    _AdminDestination('Settings', Icons.settings_outlined),
    _AdminDestination('Support', Icons.help_outline),
  ];

  int get _selectedIndex {
    final path = GoRouterState.of(context).uri.path;
    if (path.startsWith('/super-admin/dashboard')) return 0;
    if (path.startsWith('/super-admin/students')) return 1;
    if (path.startsWith('/super-admin/teachers')) return 2;
    if (path.startsWith('/super-admin/classes')) return 3;
    if (path.startsWith('/super-admin/academic')) return 4;
    if (path.startsWith('/super-admin/settings')) return 5;
    if (path.startsWith('/super-admin/support')) return 6;
    return 0;
  }

  void _selectPage(int index) {
    final paths = [
      '/super-admin/dashboard',
      '/super-admin/students',
      '/super-admin/teachers',
      '/super-admin/classes',
      '/super-admin/academic',
      '/super-admin/settings',
      '/super-admin/support',
    ];
    if (index >= 0 && index < paths.length) {
      context.go(paths[index]);
    }
  }

  void _handleLogout() async {
    final authController = context.read<AuthController>();
    await authController.logout();
    if (mounted) {
      context.go('/login');
    }
  }

  String _getPageTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Super Admin Dashboard';
      case 1:
        return 'Student Management';
      case 2:
        return 'Teacher Management';
      case 3:
        return 'Class Management';
      case 4:
        return 'Academic Modules';
      case 5:
        return 'Settings';
      case 6:
        return 'Support & Help';
      default:
        return 'Super Admin Dashboard';
    }
  }

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    final profile = authController.currentProfile;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < AppBreakpoints.tablet;

        if (!isMobile) {
          return Scaffold(
            body: Row(
              children: [
                _AdminSidebar(
                  destinations: _destinations,
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: _selectPage,
                  onLogout: _handleLogout,
                  adminName: profile?.fullName ?? 'Super Admin',
                  adminEmail: profile?.email ?? 'admin@portal.edu',
                  adminAvatarUrl: profile?.avatarUrl,
                ),
                Expanded(
                  child: Column(
                    children: [
                      _AdminHeader(title: _getPageTitle()),
                      Expanded(child: widget.child),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: Text(_getPageTitle()),
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
              const SizedBox(width: 4),
              PopupMenuButton<String>(
                tooltip: 'Profile & Settings',
                offset: const Offset(0, 48),
                onSelected: (value) {
                  if (value == 'settings') {
                    context.go('/super-admin/settings');
                  } else if (value == 'support') {
                    context.go('/super-admin/support');
                  } else if (value == 'logout') {
                    _handleLogout();
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
                          profile?.fullName ?? 'Super Admin',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black87,
                          ),
                        ),
                        Text(
                          profile?.email ?? 'admin@portal.edu',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
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
                child: CircleAvatar(
                  backgroundColor: const Color(0xFF131B2E),
                  radius: 16,
                  backgroundImage: (profile?.avatarUrl != null && profile!.avatarUrl!.trim().isNotEmpty)
                      ? NetworkImage(getFullImageUrl(profile.avatarUrl))
                      : null,
                  child: (profile?.avatarUrl == null || profile!.avatarUrl!.trim().isEmpty)
                      ? Text(
                          _getInitials(profile?.fullName ?? 'Super Admin'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 12),
            ],
          ),
          body: widget.child,
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
    );
  }
}

class _AdminHeader extends StatelessWidget {
  const _AdminHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).colorScheme.surface : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : const Color(0xFFE5E7EB),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
          ),
          Row(
            children: [
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
              _HeaderIconButton(
                icon: Icons.notifications_outlined,
                onPressed: () {},
              ),
              const SizedBox(width: 12),
              _HeaderIconButton(
                icon: Icons.search_outlined,
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFE5E7EB),
        ),
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, size: 20),
        onPressed: onPressed,
      ),
    );
  }
}

class _AdminSidebar extends StatelessWidget {
  const _AdminSidebar({
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.onLogout,
    required this.adminName,
    required this.adminEmail,
    this.adminAvatarUrl,
  });

  final List<_AdminDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final VoidCallback onLogout;
  final String adminName;
  final String adminEmail;
  final String? adminAvatarUrl;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).colorScheme.surface : Colors.white,
        border: Border(
          right: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : const Color(0xFFE5E7EB),
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Branding
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    Image.asset(
                      'assets/images/logo.png',
                      width: 44,
                      height: 44,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'HIDAYATHUL ANAM MADRASA',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // Main Navigation
              Expanded(
                child: ListView(
                  physics: const ClampingScrollPhysics(),
                  children: [
                    for (var index = 0; index < 5; index++)
                      _AdminNavTile(
                        destination: destinations[index],
                        selected: selectedIndex == index,
                        onTap: () => onDestinationSelected(index),
                      ),
                  ],
                ),
              ),
              // Footer Navigation
              Container(
                padding: const EdgeInsets.only(top: 16),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : const Color(0xFFE5E7EB),
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    _FooterNavTile(
                      label: 'Settings',
                      icon: Icons.settings_outlined,
                      selected: selectedIndex == 5,
                      onTap: () => onDestinationSelected(5),
                    ),
                    const SizedBox(height: 4),
                    _FooterNavTile(
                      label: 'Support',
                      icon: Icons.help_outline,
                      selected: selectedIndex == 6,
                      onTap: () => onDestinationSelected(6),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // User Profile Mini
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF2F4F6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : const Color(0xFFE5E7EB),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: const Color(0xFF131B2E),
                      radius: 16,
                      backgroundImage: (adminAvatarUrl != null && adminAvatarUrl!.trim().isNotEmpty)
                          ? NetworkImage(getFullImageUrl(adminAvatarUrl))
                          : null,
                      child: (adminAvatarUrl == null || adminAvatarUrl!.trim().isEmpty)
                          ? Text(
                              _getInitials(adminName),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
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
                            adminName,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: isDark ? Colors.white : const Color(0xFF191C1E),
                            ),
                          ),
                          Text(
                            adminEmail,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isDark ? Colors.grey.shade400 : const Color(0xFF45464D),
                              fontSize: 10,
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
            ],
          ),
        ),
      ),
    );
  }
}

String _getInitials(String name) {
  if (name.isEmpty) return 'SA';
  final parts = name.trim().split(' ');
  if (parts.length >= 2) {
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
  return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
}

class _AdminNavTile extends StatefulWidget {
  const _AdminNavTile({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final _AdminDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_AdminNavTile> createState() => _AdminNavTileState();
}

class _AdminNavTileState extends State<_AdminNavTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.selected;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color bgColor = Colors.transparent;
    Color iconColor = isDark ? Colors.grey.shade400 : const Color(0xFF45464D);
    Color textColor = isDark ? Colors.grey.shade300 : const Color(0xFF45464D);

    if (isSelected) {
      bgColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFECEEF0);
      iconColor = isDark ? Colors.white : Colors.black;
      textColor = isDark ? Colors.white : Colors.black;
    } else if (_isHovered) {
      bgColor = isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF2F4F6);
      iconColor = isDark ? Colors.white : Colors.black;
      textColor = isDark ? Colors.white : Colors.black;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
            border: Border(
              left: isSelected
                  ? const BorderSide(color: Color(0xFF9B4500), width: 4)
                  : BorderSide.none,
            ),
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
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
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

class _FooterNavTile extends StatefulWidget {
  const _FooterNavTile({
    required this.label,
    required this.icon,
    required this.onTap,
    this.selected = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool selected;

  @override
  State<_FooterNavTile> createState() => _FooterNavTileState();
}

class _FooterNavTileState extends State<_FooterNavTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.selected;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color bgColor = Colors.transparent;
    Color iconColor = isDark ? Colors.grey.shade400 : const Color(0xFF45464D);
    Color textColor = isDark ? Colors.grey.shade300 : const Color(0xFF45464D);

    if (isSelected) {
      bgColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFECEEF0);
      iconColor = isDark ? Colors.white : Colors.black;
      textColor = isDark ? Colors.white : Colors.black;
    } else if (_isHovered) {
      bgColor = isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFECEEF0);
      iconColor = isDark ? Colors.white : Colors.black;
      textColor = isDark ? Colors.white : Colors.black;
    }

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
            borderRadius: BorderRadius.circular(8),
            border: Border(
              left: isSelected
                  ? const BorderSide(color: Color(0xFF9B4500), width: 4)
                  : BorderSide.none,
            ),
          ),
          child: Row(
            children: [
              Icon(widget.icon, size: 20, color: iconColor),
              const SizedBox(width: 12),
              Text(
                widget.label,
                style: TextStyle(
                  color: textColor,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminDestination {
  const _AdminDestination(this.label, this.icon);

  final String label;
  final IconData icon;
}
