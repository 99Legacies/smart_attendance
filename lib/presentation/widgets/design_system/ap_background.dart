import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:smart_attendance/core/theme/app_theme.dart';

/// Animated deep-space gradient with floating orbs (CustomPainter).
class ApBackground extends StatefulWidget {
  const ApBackground({
    super.key,
    required this.child,
    this.showOrbs = true,
  });

  final Widget child;
  final bool showOrbs;

  @override
  State<ApBackground> createState() => _ApBackgroundState();
}

class _ApBackgroundState extends State<ApBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: AppTheme.gradientBackground(isDark),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (widget.showOrbs)
            AnimatedBuilder(
              animation: _controller,
              builder: (_, _) => CustomPaint(
                painter: _OrbPainter(
                  progress: _controller.value,
                  isDark: isDark,
                ),
              ),
            ),
          widget.child,
        ],
      ),
    );
  }
}

class _OrbPainter extends CustomPainter {
  _OrbPainter({required this.progress, required this.isDark});

  final double progress;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final orbs = [
      (color: AppTheme.primary.withValues(alpha: 0.18), x: 0.15, y: 0.2, r: 120.0),
      (color: const Color(0xFF7C3AED).withValues(alpha: 0.12), x: 0.85, y: 0.15, r: 90.0),
      (color: AppTheme.secondary.withValues(alpha: 0.08), x: 0.7, y: 0.75, r: 100.0),
    ];

    for (var i = 0; i < orbs.length; i++) {
      final orb = orbs[i];
      final drift = math.sin((progress + i * 0.3) * 2 * math.pi) * 20;
      final cx = size.width * orb.x;
      final cy = size.height * orb.y + drift;
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [orb.color, orb.color.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: orb.r));
      canvas.drawCircle(Offset(cx, cy), orb.r, paint);
    }
  }

  @override
  bool shouldRepaint(_OrbPainter old) =>
      old.progress != progress || old.isDark != isDark;
}

/// Frosted glass panel.
class ApGlassPanel extends StatelessWidget {
  const ApGlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = AppTheme.borderRadiusLg,
    this.onTap,
  });

  final Widget child;
  final EdgeInsets padding;
  final double borderRadius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final panel = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: AppTheme.glassFill(isDark),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: AppTheme.glassBorder(isDark)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );

    if (onTap == null) return panel;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: panel,
      ),
    );
  }
}
