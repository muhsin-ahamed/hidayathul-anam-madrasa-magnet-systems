// app_router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/controllers/auth_controller.dart';
import '../models/user_role.dart';
import 'auth_state_pages.dart';
import 'login_page.dart';
import 'student/student_shell.dart';
import 'student/student_dashboard_page.dart';
import 'student/result_page.dart';
import 'student/notes_page.dart';
import 'student/hall_ticket_page.dart';
import 'student/profile_page.dart';

// Shell references for Teacher and Super Admin
import 'teacher/teacher_shell.dart';
import 'teacher/teacher_dashboard_page.dart';
import 'teacher/teacher_students_page.dart';
import 'teacher/teacher_results_page.dart';
import 'teacher/teacher_notes_page.dart';
import 'teacher/teacher_hall_tickets_page.dart';
import 'teacher/teacher_announcements_page.dart';
import 'teacher/teacher_settings_page.dart';
import 'teacher/teacher_support_page.dart';

import 'super_admin/super_admin_shell.dart';
import 'super_admin/super_admin_dashboard_page.dart';
import 'super_admin/super_admin_students_page.dart';
import 'super_admin/super_admin_teachers_page.dart';
import 'super_admin/super_admin_classes_page.dart';
import 'super_admin/super_admin_academic_page.dart';
import 'super_admin/super_admin_settings_page.dart';
import 'super_admin/super_admin_support_page.dart';

class AppRouter {
  static GoRouter? _router;

  static GoRouter router(BuildContext context) {
    final authController = Provider.of<AuthController>(context, listen: false);

    _router ??= GoRouter(
      initialLocation: '/login',
      refreshListenable: authController,
      redirect: (context, state) {
        final authenticated = authController.isAuthenticated;
        final profile = authController.currentProfile;
        final path = state.uri.path;

        // Public/Auth routes
        final isAuthRoute =
            path == '/login' ||
            path == '/forgot-password' ||
            path == '/reset-password';

        if (!authenticated || profile == null) {
          if (isAuthRoute) return null;
          return '/login';
        }

        // Active check
        if (!profile.isActive) {
          return '/account-disabled';
        }

        // Redirect logged-in users away from login pages
        if (isAuthRoute) {
          switch (profile.role) {
            case UserRole.student:
              return '/student/dashboard';
            case UserRole.classTeacher:
              return '/teacher/dashboard';
            case UserRole.superAdmin:
              return '/super-admin/dashboard';
          }
        }

        // Guards
        if (path.startsWith('/student') && profile.role != UserRole.student) {
          return '/unauthorized';
        }
        if (path.startsWith('/teacher') &&
            profile.role != UserRole.classTeacher) {
          return '/unauthorized';
        }
        if (path.startsWith('/super-admin') &&
            profile.role != UserRole.superAdmin) {
          return '/unauthorized';
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => LoginPage(
            onLogin: (role) {
              // Standard login callback is handled inside the LoginPage state directly
            },
          ),
        ),
        GoRoute(
          path: '/forgot-password',
          builder: (context, state) => const ForgotPasswordPage(),
        ),
        GoRoute(
          path: '/reset-password',
          builder: (context, state) => const ResetPasswordPage(),
        ),
        GoRoute(
          path: '/unauthorized',
          builder: (context, state) => const UnauthorizedPage(),
        ),
        GoRoute(
          path: '/account-disabled',
          builder: (context, state) => const AccountDisabledPage(),
        ),

        // STUDENT WORKSPACE SHELL
        ShellRoute(
          builder: (context, state, child) => StudentShell(child: child),
          routes: [
            GoRoute(
              path: '/student/dashboard',
              builder: (context, state) => StudentDashboardPage(
                onNavigate: (index) {
                  // Inside GoRouter, navigation is path-based
                  final paths = [
                    '/student/dashboard',
                    '/student/result',
                    '/student/notes',
                    '/student/hall-ticket',
                    '/student/profile',
                  ];
                  context.go(paths[index]);
                },
              ),
            ),
            GoRoute(
              path: '/student/result',
              builder: (context, state) => const ResultPage(),
            ),
            GoRoute(
              path: '/student/notes',
              builder: (context, state) => const NotesPage(),
            ),
            GoRoute(
              path: '/student/hall-ticket',
              builder: (context, state) => const HallTicketPage(),
            ),
            GoRoute(
              path: '/student/profile',
              builder: (context, state) => const ProfilePage(),
            ),
          ],
        ),

        // CLASS TEACHER WORKSPACE SHELL
        ShellRoute(
          builder: (context, state, child) => TeacherShell(child: child),
          routes: [
            GoRoute(
              path: '/teacher/dashboard',
              builder: (context, state) => const TeacherDashboardPage(),
            ),
            GoRoute(
              path: '/teacher/students',
              builder: (context, state) => const TeacherStudentsPage(),
            ),
            GoRoute(
              path: '/teacher/results',
              builder: (context, state) => const TeacherResultsPage(),
            ),
            GoRoute(
              path: '/teacher/notes',
              builder: (context, state) => const TeacherNotesPage(),
            ),
            GoRoute(
              path: '/teacher/hall-tickets',
              builder: (context, state) => const TeacherHallTicketsPage(),
            ),
            GoRoute(
              path: '/teacher/announcements',
              builder: (context, state) => const TeacherAnnouncementsPage(),
            ),
            GoRoute(
              path: '/teacher/settings',
              builder: (context, state) => const TeacherSettingsPage(),
            ),
            GoRoute(
              path: '/teacher/support',
              builder: (context, state) => const TeacherSupportPage(),
            ),
          ],
        ),

        // SUPER ADMIN WORKSPACE SHELL
        ShellRoute(
          builder: (context, state, child) => SuperAdminShell(child: child),
          routes: [
            GoRoute(
              path: '/super-admin/dashboard',
              builder: (context, state) => const SuperAdminDashboardPage(),
            ),
            GoRoute(
              path: '/super-admin/students',
              builder: (context, state) => const SuperAdminStudentsPage(),
            ),
            GoRoute(
              path: '/super-admin/teachers',
              builder: (context, state) => const SuperAdminTeachersPage(),
            ),
            GoRoute(
              path: '/super-admin/classes',
              builder: (context, state) => const SuperAdminClassesPage(),
            ),
            GoRoute(
              path: '/super-admin/academic',
              builder: (context, state) => const SuperAdminAcademicPage(),
            ),
            GoRoute(
              path: '/super-admin/settings',
              builder: (context, state) => const SuperAdminSettingsPage(),
            ),
            GoRoute(
              path: '/super-admin/support',
              builder: (context, state) => const SuperAdminSupportPage(),
            ),
          ],
        ),
      ],
      errorBuilder: (context, state) =>
          Scaffold(body: Center(child: Text('Page not found: ${state.error}'))),
    );
    return _router!;
  }
}
