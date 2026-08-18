import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../constants/roles.dart';
import '../../features/auth/splash_page.dart';
import '../../features/auth/login_page.dart';
import '../../features/student/student_dashboard_page.dart';
import '../../features/student/assignment_view.dart';
import '../../features/student/material_view_page.dart';
import '../../features/student/grades_page.dart';
import '../../features/student/schedule_page.dart';
import '../../features/student/attendance_page.dart';
import '../../features/teacher/teacher_dashboard_page.dart';
import '../../features/teacher/upload_material_page.dart';
import '../../features/teacher/create_assignment_page.dart';
import '../../features/teacher/attendance_input_page.dart';
import '../../features/teacher/grading_page.dart';
import '../../features/wali_kelas/wali_dashboard_page.dart';
import '../../features/wali_kelas/class_monitoring_page.dart';
import '../../features/bk/bk_dashboard_page.dart';
import '../../features/bk/case_tracking_page.dart';
import '../../features/bk/counseling_schedule_page.dart';
import '../../features/piket/piket_dashboard_page.dart';
import '../../features/piket/quick_scan_page.dart';
import '../../features/piket/daily_log_page.dart';
import '../../features/admin/admin_dashboard_page.dart';
import '../../features/shared/chat_room_page.dart';
import '../../features/shared/notification_list_page.dart';
import '../../features/shared/announcement_page.dart';
import '../../features/shared/violation_page.dart';
import '../../features/shared/forum_page.dart';
import '../../features/shared/forum_thread_page.dart';
import '../../features/teacher/teacher_stats_page.dart';

class AppRouter {
  AppRouter._();

  static GoRouter router(AuthProvider authProvider) {
    return GoRouter(
      initialLocation: '/splash',
      refreshListenable: authProvider,
      redirect: (BuildContext context, GoRouterState state) {
        final isLoading = authProvider.isLoading;
        final isLoggedIn = authProvider.isLoggedIn;

        if (isLoading) return '/splash';

        if (!isLoggedIn) {
          if (state.matchedLocation == '/login') return null;
          return '/login';
        }

        final role = authProvider.userModel?.role;
        final loc = state.matchedLocation;

        // Redirect from auth pages when logged in
        if (loc == '/splash' || loc == '/login') {
          return _homeRouteForRole(role);
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/splash',
          builder: (_, __) => const SplashPage(),
        ),
        GoRoute(
          path: '/login',
          builder: (_, __) => const LoginPage(),
        ),

        // Student routes
        GoRoute(
          path: '/student',
          builder: (_, __) => const StudentDashboardPage(),
          routes: [
            GoRoute(
              path: 'assignments',
              builder: (_, __) => const AssignmentView(),
            ),
            GoRoute(
              path: 'materials',
              builder: (_, __) => const MaterialViewPage(),
            ),
            GoRoute(
              path: 'grades',
              builder: (_, __) => const GradesPage(),
            ),
            GoRoute(
              path: 'schedule',
              builder: (_, __) => const SchedulePage(),
            ),
            GoRoute(
              path: 'attendance',
              builder: (_, __) => const AttendancePage(),
            ),
          ],
        ),

        // Teacher routes
        GoRoute(
          path: '/teacher',
          builder: (_, __) => const TeacherDashboardPage(),
          routes: [
            GoRoute(
              path: 'upload-material',
              builder: (_, __) => const UploadMaterialPage(),
            ),
            GoRoute(
              path: 'create-assignment',
              builder: (_, __) => const CreateAssignmentPage(),
            ),
            GoRoute(
              path: 'attendance',
              builder: (_, __) => const AttendanceInputPage(),
            ),
            GoRoute(
              path: 'grading/:assignmentId',
              builder: (_, state) => GradingPage(
                assignmentId: state.pathParameters['assignmentId']!,
              ),
            ),
          ],
        ),

        // Wali Kelas routes
        GoRoute(
          path: '/wali-kelas',
          builder: (_, __) => const WaliDashboardPage(),
          routes: [
            GoRoute(
              path: 'monitoring',
              builder: (_, __) => const ClassMonitoringPage(),
            ),
          ],
        ),

        // BK routes
        GoRoute(
          path: '/bk',
          builder: (_, __) => const BkDashboardPage(),
          routes: [
            GoRoute(
              path: 'cases',
              builder: (_, __) => const CaseTrackingPage(),
            ),
            GoRoute(
              path: 'schedule',
              builder: (_, __) => const CounselingSchedulePage(),
            ),
          ],
        ),

        // Piket routes
        GoRoute(
          path: '/piket',
          builder: (_, __) => const PiketDashboardPage(),
          routes: [
            GoRoute(
              path: 'scan',
              builder: (_, __) => const QuickScanPage(),
            ),
            GoRoute(
              path: 'log',
              builder: (_, __) => const DailyLogPage(),
            ),
          ],
        ),

        // Admin routes
        GoRoute(
          path: '/admin',
          builder: (_, __) => const AdminDashboardPage(),
        ),

        // Shared routes
        GoRoute(
          path: '/chat/:roomId',
          builder: (_, state) => ChatRoomPage(
            roomId: state.pathParameters['roomId']!,
          ),
        ),
        GoRoute(
          path: '/notifications',
          builder: (_, __) => const NotificationListPage(),
        ),
        GoRoute(
          path: '/announcements',
          builder: (_, __) => const AnnouncementPage(),
        ),
        GoRoute(
          path: '/violations/:studentId',
          builder: (_, state) => ViolationPage(
            studentId: state.pathParameters['studentId']!,
          ),
        ),
        GoRoute(
          path: '/forum',
          builder: (_, __) => const ForumPage(),
        ),
        GoRoute(
          path: '/forum/:postId',
          builder: (_, state) => ForumThreadPage(
            postId: state.pathParameters['postId']!,
            postData: state.extra as Map<String, dynamic>?,
          ),
        ),
        GoRoute(
          path: '/teacher/stats',
          builder: (_, __) => const TeacherStatsPage(),
        ),
      ],
    );
  }

  static String _homeRouteForRole(String? role) {
    switch (role) {
      case AppRoles.siswa:
        return '/student';
      case AppRoles.guruMapel:
        return '/teacher';
      case AppRoles.waliKelas:
        return '/wali-kelas';
      case AppRoles.guruBk:
        return '/bk';
      case AppRoles.guruPiket:
        return '/piket';
      case AppRoles.admin:
        return '/admin';
      default:
        return '/login';
    }
  }
}
