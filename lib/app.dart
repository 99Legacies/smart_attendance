import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_attendance/core/theme/app_theme.dart';
import 'package:smart_attendance/core/utils/app_system_ui.dart';
import 'package:smart_attendance/domain/repositories/auth_repository.dart';
import 'package:smart_attendance/features/auth/services/session_guard.dart';
import 'package:smart_attendance/presentation/providers/providers.dart';
import 'package:smart_attendance/presentation/providers/theme_provider.dart';
import 'package:smart_attendance/presentation/router/app_router.dart';

class _WebScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        ...super.dragDevices,
        PointerDeviceKind.mouse,
      };
}

class AttendProApp extends ConsumerWidget {
  const AttendProApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeModeProvider);
    final router = ref.watch(routerProvider);

    // Start/stop SessionGuard in lock-step with the auth state.
    // Using ref.listen here (inside build) is the standard Riverpod pattern —
    // the listener is registered once and survives rebuilds.
    ref.listen<AsyncValue<AuthUser?>>(authStateProvider, (prev, next) {
      final prevUser = prev?.asData?.value;
      final nextUser = next.asData?.value;

      if (prevUser == null && nextUser != null) {
        // Transition from signed-out → signed-in: start the guard.
        SessionGuard.start(
          onSessionInvalidated: () {
            // Navigate to login and carry the reason as GoRouter extra so
            // LoginScreen can display it as a SnackBar.
            router.go(
              '/login',
              extra: 'Session expired on another device',
            );
          },
        );
      } else if (prevUser != null && nextUser == null) {
        // Transition from signed-in → signed-out: stop the guard.
        SessionGuard.stop();
      }
    });

    AppSystemUi.applyGradientOverlay(isDark: isDark);

    return MaterialApp.router(
      title: 'AttendPro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      routerConfig: router,
      scrollBehavior: _WebScrollBehavior(),
      builder: (context, child) {
        AppSystemUi.applyGradientOverlay(isDark: isDark);
        return child ?? const SizedBox.shrink();
      },
    );
  }
}
