import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // <-- Added this import
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_attendance/core/theme/app_theme.dart';
import 'package:smart_attendance/presentation/providers/connectivity_provider.dart';
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
    final isOnline = ref.watch(connectivityProvider).asData?.value ?? true;

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
            child: Column(
              children: [
                if (!isOnline) const _OfflineBanner(),
                Expanded(child: body),
              ],
            ),
          ),
          floatingActionButton: floatingActionButton,
          bottomNavigationBar: bottomNavigationBar,
        ),
      ),
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.orange.shade700,
      child: const SizedBox(
        width: double.infinity,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              Icon(Icons.wifi_off, size: 16, color: Colors.white),
              SizedBox(width: 8),
              Flexible(
                child: Text(
                  'You are offline — changes will sync when reconnected',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Alias for gradual migration from GradientScaffold.
typedef GradientScaffold = ApScaffold;
