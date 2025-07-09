import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/info_daftar_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/contacts_screen.dart';
import 'screens/guide_screen.dart';
import 'screens/user_detail_screen.dart';
import 'screens/user_stats_screen.dart';
import 'screens/report_detail_screen.dart'; // Import screen detail laporan
import 'screens/officer_report_form_screen.dart'; // Import officer report form screen

final navigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: authState.isAuthenticated ? '/home' : '/login',
    debugLogDiagnostics: true,
    routes: [
      // Splash screen di-nonaktifkan, langsung ke /home atau /login
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/info-daftar',
        builder: (context, state) => const InfoDaftarScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/reports',
        builder: (context, state) => const ReportsScreen(),
      ),
      GoRoute(
        path: '/contacts',
        builder: (context, state) => const ContactsScreen(),
      ),
      GoRoute(
        path: '/guide',
        builder: (context, state) => const GuideScreen(),
      ),
      GoRoute(
        path: '/user/:username',
        builder: (context, state) {
          final username = state.pathParameters['username'];
          if (username == null || username.isEmpty) {
            return const Center(child: Text('Username tidak valid'));
          }
          return UserDetailScreen(username: username);
        },
      ),
      GoRoute(
        path: '/reports/user-stats',
        builder: (context, state) => const UserStatsScreen(),
      ),
      GoRoute(
        path: '/reports/user-stats/:username',
        builder: (context, state) {
          final username = state.pathParameters['username'];
          if (username == null || username.isEmpty) {
            return const UserStatsScreen(); // Fallback to current user
          }
          return UserStatsScreen(username: username);
        },
      ),
      // Tambahkan route baru untuk detail laporan
      GoRoute(
        path: '/report-detail/:reportId',
        builder: (context, state) {
          final reportId = state.pathParameters['reportId'];
          if (reportId == null || reportId.isEmpty) {
            return const Center(child: Text('ID Laporan tidak valid'));
          }
          return ReportDetailScreen(reportId: reportId);
        },
      ),
      GoRoute(
        path: '/officer-report-form',
        builder: (context, state) => const OfficerReportFormScreen(),
      ),
    ],
    redirect: (context, state) {
      // If app is checking authentication, show splash screen
      if (state.matchedLocation == '/splash') return null;

      final isLoggedIn = authState.isAuthenticated;
      final isGoingToLogin = state.matchedLocation == '/login';
      final isGoingToInfoDaftar = state.matchedLocation == '/info-daftar';

      // Allow access to login and info-daftar pages regardless of authentication status
      if (isGoingToInfoDaftar || isGoingToLogin) return null;

      // If not logged in, redirect to login unless already going there
      if (!isLoggedIn) {
        return '/login';
      }

      // No redirect needed
      return null;
    },
  );
});
