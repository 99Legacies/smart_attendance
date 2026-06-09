import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:smart_attendance/core/theme/app_theme.dart';
import 'package:smart_attendance/presentation/widgets/design_system/ap_background.dart';

/// Glassmorphism card — drop-in replacement for core AppCard in presentation layer.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.animate = true,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final card = ApGlassPanel(
      padding: padding,
      borderRadius: AppTheme.borderRadius,
      onTap: onTap,
      child: child,
    );

    if (!animate) return card;
    return card
        .animate()
        .fadeIn(duration: 300.ms, curve: Curves.easeOut)
        .slideY(begin: 0.04, end: 0, duration: 300.ms, curve: Curves.easeOut);
  }
}
