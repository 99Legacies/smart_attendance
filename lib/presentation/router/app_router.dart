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

// Consistent fade transition used across all routes. 350ms forward, 250ms
// reverse — fast enough to feel snappy on mid-range hardware.
CustomTransitionPage<T> _fadePage<T>(
  BuildContext context,
  GoRouterState state,
  Widget child,
) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 350),
    reverseTransitionDuration: const Duration(milliseconds: 250),
    transitionsBuilder: (ctx, anim, secondaryAnim, transChild) => FadeTransition(
      opacity: CurveTween(curve: Curves.easeInOut).animate(anim),
      child: transChild,
    ),
  );
}

// Auth-state notifier — GoRouter listens to this and re-runs redirect only
// when the user identity or loading/error state actually changes.
final _routerRefreshNotifier = _AuthStateRefreshNotifier();

// Notifier that fires when loginDialogActiveProvider changes so GoRouter
// re-evaluates the redirect and suppresses navigation while a dialog is open.
final _loginDialogNotifier = _LoginDialogChangeNotifier();

/// Exposes the root navigator key so callers (e.g. LoginScreen) can push
/// modal routes (BiometricSetupScreen) on top of GoRouter-managed pages.
final navigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  ref.listen<AsyncValue<AuthUser?>>(
    authStateProvider,
    (_, next) => _routerRefreshNotifier.update(next),
    fireImmediately: true,
  );

  // Re-trigger GoRouter redirect whenever a login dialog is shown/hidden.
  ref.listen<bool>(loginDialogActiveProvider, (prev, next) {
    _loginDialogNotifier.ping();
  });

  return GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: '/',
    refreshListenable: Listenable.merge([
      _routerRefreshNotifier,
      _loginDialogNotifier,
    ]),
    redirect: (context, state) {
      // Suppress all redirects while a device-conflict or biometric dialog
      // is showing — the login screen resolves those dialogs first.
      if (ref.read(loginDialogActiveProvider)) return null;

      final authState =
          _routerRefreshNotifier.state ?? const AsyncValue.loading();
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

      if (authState.isLoading) return null;
      if (!authState.hasValue) return null;

      if (authState.hasError) {
        if (isAuthRoute || onSplash || onDashboard) return null;
        return '/login';
      }

      final user = authState.value;

      if (user == null) {
        if (isAuthRoute) return null;
        return '/login';
      }

      final roleHome = RoleRoutes.homeFor(user.role);
      if (isAuthRoute || onSplash) return roleHome;

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
      GoRoute(
        path: '/',
        pageBuilder: (ctx, state) => _fadePage(ctx, state, const SplashScreen()),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (ctx, state) => _fadePage(
          ctx,
          state,
          // Pass the session-expired reason (if any) down to the login screen.
          LoginScreen(logoutReason: state.extra as String?),
        ),
      ),
      GoRoute(
        path: '/signup',
        pageBuilder: (ctx, state) => _fadePage(ctx, state, const RegisterScreen()),
      ),
      GoRoute(path: '/register', redirect: (_, _) => '/signup'),
      GoRoute(
        path: '/forgot-password',
        pageBuilder: (ctx, state) =>
            _fadePage(ctx, state, const ForgotPasswordScreen()),
      ),
      GoRoute(
        path: '/student-dashboard',
        pageBuilder: (ctx, state) =>
            _fadePage(ctx, state, const StudentShellScreen()),
      ),
      GoRoute(path: '/student', redirect: (_, _) => '/student-dashboard'),
      GoRoute(
        path: '/admin-dashboard',
        pageBuilder: (ctx, state) =>
            _fadePage(ctx, state, const AdminDashboardScreen()),
      ),
      GoRoute(path: '/admin', redirect: (_, _) => '/admin-dashboard'),
      GoRoute(
        path: '/admin/users',
        pageBuilder: (ctx, state) =>
            _fadePage(ctx, state, const AdminUsersShellScreen()),
      ),
      GoRoute(
        path: '/lecturer',
        pageBuilder: (ctx, state) =>
            _fadePage(ctx, state, const LecturerShellScreen()),
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

class _AuthStateRefreshNotifier extends ChangeNotifier {
  AsyncValue<AuthUser?>? _state;

  AsyncValue<AuthUser?>? get state => _state;

  void update(AsyncValue<AuthUser?> next) {
    final prev = _state;
    if (prev == null) {
      _state = next;
      notifyListeners();
      return;
    }

    final prevUser = prev.asData?.value;
    final nextUser = next.asData?.value;

    final changed =
        prev.isLoading != next.isLoading ||
        prev.hasError != next.hasError ||
        prevUser?.uid != nextUser?.uid ||
        prevUser?.role != nextUser?.role;

    _state = next;
    if (changed) notifyListeners();
  }
}

class _LoginDialogChangeNotifier extends ChangeNotifier {
  void ping() => notifyListeners();
}
