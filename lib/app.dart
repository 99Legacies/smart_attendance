import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_attendance/core/theme/app_theme.dart';
import 'package:smart_attendance/core/utils/app_system_ui.dart';
import 'package:smart_attendance/presentation/providers/theme_provider.dart';
import 'package:smart_attendance/presentation/router/app_router.dart';

class AttendProApp extends ConsumerWidget {
  const AttendProApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeModeProvider);
    final router = ref.watch(routerProvider);

    AppSystemUi.applyGradientOverlay(isDark: isDark);

    return MaterialApp.router(
      title: 'AttendPro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      routerConfig: router,
      builder: (context, child) {
        AppSystemUi.applyGradientOverlay(isDark: isDark);
        return child ?? const SizedBox.shrink();
      },
    );
  }
}
