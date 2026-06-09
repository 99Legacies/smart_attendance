import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_attendance/core/theme/app_theme.dart';
import 'package:smart_attendance/core/utils/app_system_ui.dart';
import 'package:smart_attendance/presentation/providers/theme_provider.dart';

/// Scaffold with gradient background, optional app bar, and unified system UI.
///
/// Body is laid out below the [appBar] (never behind it). Use [ShellTabBody]
/// inside shell tabs that need bounded height for [Column] + [Expanded].
class GradientScaffold extends ConsumerWidget {
  const GradientScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.drawer,
    this.floatingActionButton,
    this.bottomNavigationBar,
  });

  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? drawer;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeModeProvider);
    final overlay = AppSystemUi.overlayForGradient(isDark: isDark);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlay,
      child: Container(
        decoration: AppTheme.gradientBackground(isDark),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: appBar,
          drawer: drawer,
          body: SafeArea(
            top: appBar == null,
            bottom: bottomNavigationBar == null,
            child: body,
          ),
          floatingActionButton: floatingActionButton,
          bottomNavigationBar: bottomNavigationBar,
        ),
      ),
    );
  }
}
