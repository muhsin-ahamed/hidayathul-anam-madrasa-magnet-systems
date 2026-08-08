// main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/repositories/repository_interfaces.dart';
import 'data/repositories/api_repositories.dart';
import 'data/repositories/auth_repository.dart' as local_auth;
import 'data/controllers/auth_controller.dart';
import 'data/repositories/dashboard_repository.dart';
import 'data/providers/dashboard_provider.dart';
import 'screens/app_router.dart';
import 'theme/app_theme.dart';
import 'theme/theme_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ThemeManager.init();

  runApp(
    MultiProvider(
      providers: [
        // Repository Bindings
        Provider<AuthRepository>(
          create: (_) => local_auth.AuthRepository(),
        ),
        Provider<ProfileRepository>(
          create: (_) => ApiProfileRepository(),
        ),
        Provider<DashboardRepository>(
          create: (_) => DashboardRepository(),
        ),
        Provider<StudentRepository>(
          create: (_) => ApiStudentRepository(),
        ),
        Provider<TeacherRepository>(
          create: (_) => ApiTeacherRepository(),
        ),
        Provider<ClassRepository>(
          create: (_) => ApiClassRepository(),
        ),
        Provider<SubjectRepository>(
          create: (_) => ApiSubjectRepository(),
        ),
        Provider<ExamRepository>(
          create: (_) => ApiExamRepository(),
        ),
        Provider<ResultRepository>(
          create: (_) => ApiResultRepository(),
        ),
        Provider<NotesRepository>(
          create: (_) => ApiNotesRepository(),
        ),
        Provider<HallTicketRepository>(
          create: (_) => ApiHallTicketRepository(),
        ),
        Provider<AnnouncementRepository>(
          create: (_) => ApiAnnouncementRepository(),
        ),
        Provider<SettingsRepository>(
          create: (_) => ApiSettingsRepository(),
        ),
        Provider<ActivityLogRepository>(
          create: (_) => ApiActivityLogRepository(),
        ),

        // Controller Bindings
        ChangeNotifierProxyProvider2<
          AuthRepository,
          ProfileRepository,
          AuthController
        >(
          create: (context) => AuthController(
            authRepo: context.read<AuthRepository>(),
            profileRepo: context.read<ProfileRepository>(),
          ),
          update: (context, authRepo, profileRepo, previous) =>
              previous ??
              AuthController(authRepo: authRepo, profileRepo: profileRepo),
        ),
        ChangeNotifierProxyProvider<DashboardRepository, DashboardProvider>(
          create: (context) => DashboardProvider(
            dashboardRepo: context.read<DashboardRepository>(),
          ),
          update: (context, dashboardRepo, previous) =>
              previous ?? DashboardProvider(dashboardRepo: dashboardRepo),
        ),
      ],
      child: const StudentPortalApp(),
    ),
  );
}

class StudentPortalApp extends StatelessWidget {
  const StudentPortalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeManager.themeModeNotifier,
      builder: (context, themeMode, _) {
        return MaterialApp.router(
          title: 'HIDAYATHUL ANAM MADRASA Student & Admin Portal',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: themeMode,
          routerConfig: AppRouter.router(context),
        );
      },
    );
  }
}

