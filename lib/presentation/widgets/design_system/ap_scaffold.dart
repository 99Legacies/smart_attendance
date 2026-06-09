import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // <-- Added this import
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_attendance/core/theme/app_theme.dart';
import 'package:smart_attendance/presentation/providers/theme_provider.dart';
import 'package:smart_attendance/presentation/widgets/design_system/ap_background.dart';

/// Premium shell scaffold with gradient background and safe layout.
class ApScaffold extends ConsumerWidget {
  const ApScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.drawer,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.showOrbs = true,
  });

  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? drawer;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final bool showOrbs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeModeProvider);
    final overlay = AppTheme.systemOverlay(isDark);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlay,
      child: ApBackground(
        showOrbs: showOrbs,
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

/// Alias for gradual migration from GradientScaffold.
typedef GradientScaffold = ApScaffold;
