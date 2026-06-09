import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_attendance/core/utils/role_routes.dart';
import 'package:smart_attendance/core/widgets/app_app_bar.dart';
import 'package:smart_attendance/core/widgets/gradient_scaffold.dart';
import 'package:smart_attendance/domain/entities/user_role.dart';
import 'package:smart_attendance/domain/repositories/auth_repository.dart';
import 'package:smart_attendance/presentation/providers/providers.dart';
import 'package:smart_attendance/presentation/screens/admin/admin_dashboard_screen.dart';
import 'package:smart_attendance/presentation/screens/admin/admin_users_screen.dart';
import 'package:smart_attendance/presentation/screens/auth/forgot_password_screen.dart';
import 'package:smart_attendance/presentation/screens/auth/login_screen.dart';
import 'package:smart_attendance/presentation/screens/auth/register_screen.dart';
import 'package:smart_attendance/presentation/screens/auth/splash_screen.dart';
import 'package:smart_attendance/presentation/screens/lecturer/lecturer_shell_screen.dart';
import 'package:smart_attendance/presentation/screens/student/student_shell_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: GoRouterRefreshStream(
      ref.watch(authRepositoryProvider).authStateChanges,
    ),
    redirect: (context, state) {
      final path = state.matchedLocation;
      final isAuthRoute =
          path == '/login' ||
          path == '/signup' ||
          path == '/register' ||
          path == '/forgot-password';
      final onSplash = path == '/';
      final onDashboard =
          path.startsWith('/student-dashboard') ||
          path.startsWith('/lecturer') ||
          path.startsWith('/admin-dashboard') ||
          path.startsWith('/admin');

      // Still loading — never redirect
      if (authState.isLoading) return null;

      // No value yet (stream hasn't emitted first value) — don't redirect
      if (!authState.hasValue) return null;

      // Auth errored — stay on auth/splash, go to login from elsewhere
      // But don't kick from dashboard — wait for stream to recover
      if (authState.hasError) {
        if (isAuthRoute || onSplash || onDashboard) return null;
        return '/login';
      }

      final user = authState.value;

      // user is null — only redirect to login if NOT on a dashboard
      // This prevents kicking the user during the brief null emission
      // that happens right after login while Firestore resolves the profile
      if (user == null) {
        if (isAuthRoute || onSplash) return null;
        // If on a dashboard, stay put — auth stream may still be resolving
        if (onDashboard) return null;
        return '/login';
      }

      // User is authenticated — send to their home if on auth/splash routes
      final roleHome = RoleRoutes.homeFor(user.role);

      if (isAuthRoute || onSplash) {
        return roleHome;
      }

      // Prevent cross-role access
      if (user.role == UserRole.student &&
          (path.startsWith('/admin') || path.startsWith('/lecturer'))) {
        return '/student-dashboard';
      }
      if (user.role == UserRole.lecturer &&
          (path.startsWith('/admin') ||
              path.startsWith('/student-dashboard'))) {
        return '/lecturer';
      }
      if (user.role == UserRole.admin &&
          (path.startsWith('/student-dashboard') ||
              path.startsWith('/lecturer'))) {
        return '/admin-dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/register', redirect: (_, __) => '/signup'),
      GoRoute(
        path: '/forgot-password',
        builder: (_, __) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/student-dashboard',
        builder: (_, __) => const StudentShellScreen(),
      ),
      GoRoute(path: '/student', redirect: (_, __) => '/student-dashboard'),
      GoRoute(
        path: '/admin-dashboard',
        builder: (_, __) => const AdminDashboardScreen(),
      ),
      GoRoute(path: '/admin', redirect: (_, __) => '/admin-dashboard'),
      GoRoute(
        path: '/admin/users',
        builder: (_, __) => const AdminUsersShellScreen(),
      ),
      GoRoute(
        path: '/lecturer',
        builder: (_, __) => const LecturerShellScreen(),
      ),
    ],
  );
});

class AdminUsersShellScreen extends ConsumerWidget {
  const AdminUsersShellScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GradientScaffold(
      appBar: AppAppBar(
        title: const Text('User Management'),
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin-dashboard'),
        ),
      ),
      body: const AdminUsersScreen(),
    );
  }
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<AuthUser?> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<AuthUser?> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
