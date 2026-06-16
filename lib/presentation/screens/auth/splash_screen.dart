import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_attendance/core/theme/app_theme.dart';
import 'package:smart_attendance/presentation/providers/startup_provider.dart';
import 'package:smart_attendance/presentation/widgets/design_system/ap_background.dart';
import 'package:shimmer/shimmer.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Trigger startup logic — result is intentionally ignored here.
    // The router's redirect function watches authStateProvider and will
    // automatically navigate away from '/' once auth resolves.
    // DO NOT call context.go() from here — it races with the router
    // and causes a null-user redirect to '/login'.
    ref.watch(startupProvider);

    // Splash is always dark — the logo was designed for dark backgrounds
    // and the orb animation looks best on navy.
    return Theme(
      data: AppTheme.dark(),
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: AppTheme.systemOverlay(true),
        child: ApBackground(
          showOrbs: true,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOutCubic,
                      builder: (_, value, child) => Opacity(
                        opacity: value,
                        child: Transform.scale(
                          scale: 0.9 + (0.1 * value),
                          child: child,
                        ),
                      ),
                      child: Image.asset(
                            'assets/images/splash_screen.png',
                            width: MediaQuery.of(context).size.width * 0.55,
                            fit: BoxFit.contain,
                          )
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .shimmer(duration: 2000.ms, color: Colors.white24),
                    ),
                    const SizedBox(height: 24),
                    Text(
                          'University attendance, reimagined',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.onBackground.withValues(alpha: 0.55),
                          ),
                        )
                        .animate()
                        .fadeIn(delay: 400.ms, duration: 400.ms),
                    const SizedBox(height: 48),
                    Shimmer.fromColors(
                          baseColor: AppTheme.primary.withValues(alpha: 0.3),
                          highlightColor: AppTheme.primary,
                          child: Container(
                            width: 52,
                            height: 52,
                            decoration: const BoxDecoration(
                              color: AppTheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        )
                        .animate()
                        .fadeIn(delay: 600.ms, duration: 300.ms),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
